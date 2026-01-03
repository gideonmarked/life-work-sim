extends Node
## CharacterAI - Autonomous decision making for the character based on needs and priorities

signal decision_made(action_type: int, reason: String)

# Priority thresholds (loaded from Balance)
var CRITICAL_HUNGER := 85
var HIGH_HUNGER := 70
var CRITICAL_REST := 15
var HIGH_TIRED := 30
var LOW_MOOD := 25

# Action weights (higher = more likely to be chosen)
var base_weights: Dictionary = {}

var _enabled: bool = true
var _last_decision_time: int = 0
var _consecutive_work_hours: int = 0


func _ready() -> void:
	print("[CharacterAI] _ready() starting")
	# Load settings from Balance data
	_load_settings()
	# Connect to action completion to auto-queue next action
	ActionQueue.action_completed.connect(_on_action_completed)
	ActionQueue.action_started.connect(_on_action_started)
	# Connect to day start to refill queue after daily reset
	TimeManager.day_started.connect(_on_day_started)
	# Fill queue on startup (deferred to ensure all autoloads ready)
	print("[CharacterAI] Calling deferred _fill_queue_to_capacity")
	call_deferred("_fill_queue_to_capacity")


func _load_settings() -> void:
	# Load thresholds from Balance
	CRITICAL_HUNGER = Balance.get_ai_threshold("critical_hunger")
	HIGH_HUNGER = Balance.get_ai_threshold("high_hunger")
	CRITICAL_REST = Balance.get_ai_threshold("critical_rest")
	HIGH_TIRED = Balance.get_ai_threshold("high_tired")
	LOW_MOOD = Balance.get_ai_threshold("low_mood")
	
	# Load base weights
	base_weights = {
		ActionQueue.ActionType.WORK: Balance.get_ai_action_weight("work"),
		ActionQueue.ActionType.SLEEP: Balance.get_ai_action_weight("sleep"),
		ActionQueue.ActionType.EAT: Balance.get_ai_action_weight("eat"),
		ActionQueue.ActionType.REST: Balance.get_ai_action_weight("rest"),
		ActionQueue.ActionType.TRAVEL_GROCERY: Balance.get_ai_action_weight("travel_grocery"),
		ActionQueue.ActionType.TRAVEL_MALL: Balance.get_ai_action_weight("travel_mall"),
		ActionQueue.ActionType.IDLE: Balance.get_ai_action_weight("idle"),
		ActionQueue.ActionType.CREATE_RELEASE: Balance.get_ai_action_weight("create_release"),
	}


func _on_action_started(action: Dictionary) -> void:
	if action.get("type", -1) == ActionQueue.ActionType.WORK:
		_consecutive_work_hours += 1
	else:
		_consecutive_work_hours = 0


func _on_day_started(_day: int) -> void:
	## Reset tracking and refill queue for the new day
	DebugProfiler.log_function_enter("CharacterAI._on_day_started(%d)" % _day)
	_consecutive_work_hours = 0
	# Deferred to let ActionQueue reset first
	call_deferred("_fill_queue_to_capacity")
	DebugProfiler.log_function_exit("CharacterAI._on_day_started")


func _on_action_completed(_action: Dictionary) -> void:
	if not _enabled:
		return
	
	# Auto-fill queue when action completes
	_fill_queue_to_capacity()


func _fill_queue_to_capacity() -> void:
	## Keep the queue filled with smart decisions
	print("[CharacterAI] _fill_queue_to_capacity() called, _enabled: %s" % _enabled)
	if not _enabled:
		print("[CharacterAI] AI is disabled, returning")
		return
	
	DebugProfiler.log_function_enter("CharacterAI._fill_queue_to_capacity")
	
	var queue: Array = ActionQueue.get_queue()
	var max_queue: int = 6  # 6 queued + 1 current = 7 total
	var iterations: int = 0
	var max_iterations: int = 20  # Safety limit
	
	while queue.size() < max_queue and iterations < max_iterations:
		iterations += 1
		
		var next_action: Dictionary = _decide_next_action(queue)
		if next_action.is_empty():
			DebugProfiler.log_debug("AI: No valid action found, breaking")
			break
		
		var action_type: int = next_action.get("type", ActionQueue.ActionType.IDLE)
		var action_data: Dictionary = next_action.get("data", {})
		
		if not ActionQueue.add_action(action_type, action_data):
			DebugProfiler.log_debug("AI: Failed to add action, breaking")
			break
		
		queue = ActionQueue.get_queue()  # Refresh queue
		
		var reason: String = next_action.get("reason", "")
		decision_made.emit(action_type, reason)
		ConsoleLog.log_system("[AI] Queued: %s (%s)" % [
			ActionQueue.ACTION_DATA.get(action_type, {}).get("name", "Unknown"),
			reason
		])
	
	if iterations >= max_iterations:
		DebugProfiler.log_warning("AI: Hit max iterations in _fill_queue_to_capacity")
	
	DebugProfiler.log_function_exit("CharacterAI._fill_queue_to_capacity")


func _decide_next_action(current_queue: Array) -> Dictionary:
	## Evaluate all possible actions and choose the best one
	var scores: Dictionary = {}
	
	# Get current state
	var hunger: int = GameState.hunger
	var rest: int = GameState.rest
	var mood: int = GameState.mood
	var has_food: bool = _has_food_in_inventory()
	var at_store: bool = _is_traveling_to_store(current_queue)
	
	# Calculate scores for each action
	scores[ActionQueue.ActionType.WORK] = _score_work(hunger, rest, mood, current_queue)
	scores[ActionQueue.ActionType.SLEEP] = _score_sleep(rest, current_queue)
	scores[ActionQueue.ActionType.EAT] = _score_eat(hunger, has_food, current_queue)
	scores[ActionQueue.ActionType.REST] = _score_rest(rest, mood, current_queue)
	scores[ActionQueue.ActionType.TRAVEL_GROCERY] = _score_travel_grocery(hunger, has_food, current_queue)
	scores[ActionQueue.ActionType.TRAVEL_MALL] = _score_travel_mall(current_queue)
	scores[ActionQueue.ActionType.CREATE_RELEASE] = _score_create_release(current_queue)
	scores[ActionQueue.ActionType.IDLE] = _score_idle(current_queue)
	
	# Find highest scoring action
	var best_action: int = ActionQueue.ActionType.IDLE
	var best_score: float = -999.0
	var best_reason: String = "default"
	
	for action_type: int in scores:
		var score_data: Dictionary = scores[action_type]
		var score: float = score_data.get("score", 0.0)
		if score > best_score:
			best_score = score
			best_action = action_type
			best_reason = score_data.get("reason", "")
	
	return {
		"type": best_action,
		"data": _get_action_data(best_action),
		"reason": best_reason,
		"score": best_score
	}


func _score_work(hunger: int, rest: int, mood: int, queue: Array) -> Dictionary:
	var score: float = base_weights[ActionQueue.ActionType.WORK]
	var reason: String = "earning money"
	
	# Reduce work priority if needs are critical
	if hunger >= CRITICAL_HUNGER:
		score -= 80
		reason = "too hungry to work"
	elif hunger >= HIGH_HUNGER:
		score -= 30
	
	if rest <= CRITICAL_REST:
		score -= 80
		reason = "too tired to work"
	elif rest <= HIGH_TIRED:
		score -= 40
	
	if mood <= LOW_MOOD:
		score -= 20
	
	# Count work in queue
	var work_in_queue: int = _count_action_in_queue(queue, ActionQueue.ActionType.WORK)
	
	# BOOST: If no work queued and needs are okay, prioritize work
	if work_in_queue == 0 and hunger < HIGH_HUNGER and rest > HIGH_TIRED:
		score += 50
		reason = "should do some work"
	
	# Don't stack too much work
	if work_in_queue >= 4:
		score -= 40
		reason = "enough work queued"
	
	# Bonus for consecutive work (momentum)
	if _consecutive_work_hours > 0 and _consecutive_work_hours < 4:
		score += 10
	elif _consecutive_work_hours >= 4:
		score -= 20  # Need a break
	
	# Daytime work bonus (work during working hours 8am-6pm)
	var hour: int = TimeManager.current_hour
	if hour >= 8 and hour < 18:
		score += 20
		reason = "working hours"
	
	return {"score": score, "reason": reason}


func _score_sleep(rest: int, queue: Array) -> Dictionary:
	var score: float = base_weights[ActionQueue.ActionType.SLEEP]
	var reason: String = "getting rest"
	
	# HARD BLOCK: Only ONE sleep action allowed in queue at a time
	var sleep_count := _count_action_in_queue(queue, ActionQueue.ActionType.SLEEP)
	if sleep_count > 0:
		score = -200  # Hard block - never queue more than one sleep
		reason = "sleep already queued (limit 1)"
		return {"score": score, "reason": reason}
	
	# HARD BLOCK: Sleep is only allowed at night (9pm - 6am)
	var hour: int = TimeManager.current_hour
	var is_nighttime: bool = hour >= 21 or hour < 6
	
	if not is_nighttime:
		score = -200  # Hard block - no sleeping during the day
		reason = "can only sleep at night (9pm-6am)"
		return {"score": score, "reason": reason}
	
	# === Nighttime scoring - when to actually go to sleep ===
	
	# Base score from tiredness
	if rest <= CRITICAL_REST:
		score += 100
		reason = "exhausted, must sleep"
	elif rest <= HIGH_TIRED:
		score += 60
		reason = "tired, need sleep"
	elif rest <= 50:
		score += 30
		reason = "getting tired"
	elif rest >= 80:
		score -= 20  # Already well rested - still might sleep at very late hours
		reason = "not very tired"
	
	# Time-based modifiers for nighttime
	if hour >= 23 or hour < 4:
		# Very late night / early morning - strong push to sleep
		score += 50
		reason = "very late, should sleep"
	elif hour >= 21:
		# Early evening (9pm-11pm) - moderate
		score += 20
		reason = "evening, could sleep"
	
	return {"score": score, "reason": reason}


func _score_eat(hunger: int, has_food: bool, queue: Array) -> Dictionary:
	var score: float = base_weights[ActionQueue.ActionType.EAT]
	var reason: String = "eating"
	
	# If no food and hungry, try instant grocery purchase
	if not has_food and hunger >= 50:
		var purchased := _try_instant_grocery_purchase()
		if not purchased.is_empty():
			has_food = true  # Now we have food!
	
	if not has_food:
		score = -100  # Can't eat without food
		reason = "no food available"
		return {"score": score, "reason": reason}
	
	# Critical hunger
	if hunger >= CRITICAL_HUNGER:
		score += 100
		reason = "starving, must eat now"
	elif hunger >= HIGH_HUNGER:
		score += 60
		reason = "very hungry"
	elif hunger >= 50:
		score += 20
		reason = "getting hungry"
	elif hunger < 30:
		score -= 40  # Not hungry
		reason = "not hungry"
	
	# Check if eat already queued
	if _count_action_in_queue(queue, ActionQueue.ActionType.EAT) > 0:
		score -= 60
		reason = "eating already queued"
	
	return {"score": score, "reason": reason}


func _score_rest(rest: int, mood: int, queue: Array) -> Dictionary:
	var score: float = base_weights[ActionQueue.ActionType.REST]
	var reason: String = "taking a break"
	
	# HARD BLOCK: Maximum 2 rest actions in entire queue
	var total_rests := _count_action_in_queue(queue, ActionQueue.ActionType.REST)
	if total_rests >= 2:
		score = -200  # Hard block - no more than 2 in queue
		reason = "max 2 rests in queue"
		return {"score": score, "reason": reason}
	
	# Limit consecutive rests
	var consecutive_rests := _count_consecutive_rest_at_end(queue)
	if consecutive_rests >= 1:
		score -= 80  # Strong penalty for consecutive rest
		reason = "rest already queued"
	
	# Rest for mood recovery
	if mood <= LOW_MOOD:
		score += 40
		reason = "need break for mood"
	
	# Light rest if somewhat tired
	if rest <= 50 and rest > HIGH_TIRED:
		score += 20
		reason = "light rest"
	
	# Don't rest if sleep is more appropriate
	if rest <= HIGH_TIRED:
		score -= 30  # Sleep is better
	
	return {"score": score, "reason": reason}


func _score_travel_grocery(hunger: int, has_food: bool, queue: Array) -> Dictionary:
	var score: float = base_weights[ActionQueue.ActionType.TRAVEL_GROCERY]
	var reason: String = "going to grocery"
	
	# Check if grocery is open (account for travel time too)
	var current_hour: int = TimeManager.current_hour
	var travel_time_mins: int = Balance.get_travel_time(GameState.living_tier, "Grocery")
	var arrival_hour: int = current_hour + (travel_time_mins / 60)
	
	if not Balance.is_location_open("Grocery", current_hour):
		score = -100
		reason = Balance.get_location_closed_message("Grocery")
		return {"score": score, "reason": reason}
	
	# Need food if hungry and no food
	if not has_food and hunger >= 50:
		score += 60
		reason = "need to buy food"
	elif not has_food and hunger >= HIGH_HUNGER:
		score += 90
		reason = "urgently need food"
	elif has_food:
		score -= 30  # Already have food
	
	# Don't travel if already going there
	if _is_action_in_queue(queue, ActionQueue.ActionType.TRAVEL_GROCERY):
		score -= 100
		reason = "already going to grocery"
	
	return {"score": score, "reason": reason}


func _score_travel_mall(queue: Array) -> Dictionary:
	var score: float = base_weights[ActionQueue.ActionType.TRAVEL_MALL]
	var reason: String = "going to mall"
	
	# Check if mall is open
	var current_hour: int = TimeManager.current_hour
	if not Balance.is_location_open("Mall", current_hour):
		score = -100
		reason = Balance.get_location_closed_message("Mall")
		return {"score": score, "reason": reason}
	
	# Lower priority than grocery generally
	# Could increase if need specific items
	
	if _is_action_in_queue(queue, ActionQueue.ActionType.TRAVEL_MALL):
		score -= 100
		reason = "already going to mall"
	
	return {"score": score, "reason": reason}


func _score_create_release(queue: Array) -> Dictionary:
	var score: float = base_weights[ActionQueue.ActionType.CREATE_RELEASE]
	var reason: String = "creating release"
	
	if not GameState.can_create_release():
		score = -100
		reason = "cannot create release"
		return {"score": score, "reason": reason}
	
	# Check if have enough money for the cost
	var cost: int = 50 + (GameState.position_level * 20)
	if GameState.money < cost:
		score = -100
		reason = "not enough money for release"
		return {"score": score, "reason": reason}
	
	# Bonus if no active royalties
	if GameState.active_royalties.is_empty():
		score += 30
		reason = "no passive income yet"
	
	# Don't spam releases
	if _is_action_in_queue(queue, ActionQueue.ActionType.CREATE_RELEASE):
		score -= 80
	
	return {"score": score, "reason": reason}


func _score_idle(queue: Array) -> Dictionary:
	var score: float = base_weights[ActionQueue.ActionType.IDLE]
	var reason: String = "relaxing"
	
	# Idle is fallback, very low priority
	# Only chosen if nothing else makes sense
	
	return {"score": score, "reason": reason}


# === Helper functions ===

func _has_food_in_inventory() -> bool:
	## Check character inventory first, then LA inventory
	return _has_food_in_character() or _has_food_in_la()


func _has_food_in_character() -> bool:
	for slot: Dictionary in GameState.character_inventory:
		var item_id: String = slot.get("item_id", "")
		var item: Dictionary = Balance.get_item(item_id)
		var tags: Array = item.get("tags", [])
		if "food" in tags or "drink" in tags or "snack" in tags:
			return true
	return false


func _has_food_in_la() -> bool:
	for slot: Dictionary in GameState.la_inventory:
		var item_id: String = slot.get("item_id", "")
		var item: Dictionary = Balance.get_item(item_id)
		var tags: Array = item.get("tags", [])
		if "food" in tags or "drink" in tags or "snack" in tags:
			return true
	return false


func _get_food_from_inventory() -> String:
	## Returns item_id of first food item found (character first, then LA)
	# Check character inventory first
	for slot: Dictionary in GameState.character_inventory:
		var item_id: String = slot.get("item_id", "")
		var item: Dictionary = Balance.get_item(item_id)
		var tags: Array = item.get("tags", [])
		if "food" in tags or "snack" in tags:
			return item_id
	
	# Then check LA inventory
	for slot: Dictionary in GameState.la_inventory:
		var item_id: String = slot.get("item_id", "")
		var item: Dictionary = Balance.get_item(item_id)
		var tags: Array = item.get("tags", [])
		if "food" in tags or "snack" in tags:
			return item_id
	
	return ""


func _try_instant_grocery_purchase() -> String:
	## If hungry and no food, try to buy food instantly from grocery (no travel)
	## Returns the item_id purchased, or empty string if failed
	if not Balance.is_location_open("Grocery", TimeManager.current_hour):
		return ""  # Store closed
	
	if not GameState.can_add_food_or_drink():
		return ""  # Inventory full
	
	# Find cheapest food we can afford
	var cheapest_food: Dictionary = {}
	var cheapest_price: int = 999999
	
	var all_items: Array = Balance.get_all_items()
	for item: Dictionary in all_items:
		var tags: Array = item.get("tags", [])
		if not ("food" in tags or "snack" in tags):
			continue
		
		var store: String = item.get("store", "")
		if store != "Grocery":
			continue
		
		var price: int = item.get("price", 0)
		if price < cheapest_price and GameState.money >= price:
			cheapest_price = price
			cheapest_food = item
	
	if cheapest_food.is_empty():
		return ""  # Can't afford anything
	
	# Instant purchase!
	var item_id: String = cheapest_food.get("id", "")
	if GameState.buy_item(item_id, 1):
		ConsoleLog.log_store("AI instantly bought %s for %d coins (was hungry)" % [
			cheapest_food.get("name", item_id), cheapest_price
		])
		return item_id
	
	return ""


func _count_action_in_queue(queue: Array, action_type: int) -> int:
	var count: int = 0
	for action: Dictionary in queue:
		if action.get("type", -1) == action_type:
			count += 1
	return count


func _is_action_in_queue(queue: Array, action_type: int) -> bool:
	return _count_action_in_queue(queue, action_type) > 0


func _is_traveling_to_store(queue: Array) -> bool:
	return _is_action_in_queue(queue, ActionQueue.ActionType.TRAVEL_GROCERY) or \
		   _is_action_in_queue(queue, ActionQueue.ActionType.TRAVEL_MALL)


func _count_consecutive_rest_at_end(queue: Array) -> int:
	## Count how many REST actions are at the end of the queue consecutively
	var count: int = 0
	# Check from the end of queue backwards
	for i in range(queue.size() - 1, -1, -1):
		var action: Dictionary = queue[i]
		if action.get("type", -1) == ActionQueue.ActionType.REST:
			count += 1
		else:
			break  # Stop at first non-REST
	return count


func _get_action_data(action_type: int) -> Dictionary:
	## Generate appropriate data for the action
	match action_type:
		ActionQueue.ActionType.WORK:
			return {"duration": 60}  # 1 hour of work
		ActionQueue.ActionType.SLEEP:
			return {}  # Default sleep duration
		ActionQueue.ActionType.EAT:
			var food_id: String = _get_food_from_inventory()
			if food_id.is_empty():
				return {}
			return {"item_id": food_id}
		ActionQueue.ActionType.REST:
			return {"duration": 30}
		_:
			return {}


# === Public API ===

func set_enabled(enabled: bool) -> void:
	_enabled = enabled
	if enabled:
		_fill_queue_to_capacity()


func is_enabled() -> bool:
	return _enabled


func force_decide() -> void:
	## Force AI to fill the queue now
	_fill_queue_to_capacity()


func get_action_explanation(action_type: int) -> String:
	## Get human-readable explanation for why an action might be chosen
	var queue: Array = ActionQueue.get_queue()
	var score_data: Dictionary = {}
	
	match action_type:
		ActionQueue.ActionType.WORK:
			score_data = _score_work(GameState.hunger, GameState.rest, GameState.mood, queue)
		ActionQueue.ActionType.SLEEP:
			score_data = _score_sleep(GameState.rest, queue)
		ActionQueue.ActionType.EAT:
			score_data = _score_eat(GameState.hunger, _has_food_in_inventory(), queue)
		_:
			score_data = {"score": 0, "reason": "unknown"}
	
	return score_data.get("reason", "")
