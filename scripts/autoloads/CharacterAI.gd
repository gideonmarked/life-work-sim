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
var _planned_grocery_purchases: Array = []  # Items planned to buy when shopping completes


func _ready() -> void:
	print("[CharacterAI] _ready() starting")
	# Load settings from Balance data
	_load_settings()
	# Connect to action completion to auto-queue next action
	ActionQueue.action_completed.connect(_on_action_completed)
	ActionQueue.action_started.connect(_on_action_started)
	# Connect to day start to refill queue after daily reset
	TimeManager.day_started.connect(_on_day_started)
	# Connect to minute passed to enforce bedtime
	TimeManager.minute_passed.connect(_on_minute_passed)
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
		ActionQueue.ActionType.NAP: Balance.get_ai_action_weight("nap"),
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


func _on_minute_passed(_time: Dictionary) -> void:
	if not _enabled:
		return
	
	# Check bedtime enforcement every minute
	_check_bedtime_enforcement()


func _on_action_completed(_action: Dictionary) -> void:
	if not _enabled:
		return
	
	# Check if bedtime enforcement is needed
	if _check_bedtime_enforcement():
		return  # Bedtime was enforced, don't fill with other actions
	
	# Auto-fill queue when action completes
	_fill_queue_to_capacity()


func check_emergency_hunger() -> bool:
	## Called when hunger becomes critical (> 85, Belly Alarm < 15)
	## Interrupts work and queues urgent eat action
	## Returns true if emergency was handled
	## NOTE: Does NOT interrupt sleep - character will eat in the morning
	if not _enabled:
		return false
	
	var hunger: int = GameState.hunger
	if hunger <= 85:
		return false  # Not critical
	
	# BEDTIME OVERRIDE: Don't interrupt sleep for hunger - eat tomorrow
	var hour: int = TimeManager.current_hour
	var is_bedtime: bool = hour >= 22 or hour < 6
	var current := ActionQueue.get_current_action()
	var is_sleeping: bool = current.get("type", -1) == ActionQueue.ActionType.SLEEP
	
	if is_bedtime and is_sleeping:
		# Don't interrupt sleep - hunger can wait until morning
		return false
	
	# If it's bedtime but not sleeping yet, let them sleep instead of eat
	if is_bedtime:
		return false
	
	# Check if we have food or can buy some
	var has_food: bool = _has_food_in_inventory()
	if not has_food:
		# Try to buy food urgently
		var purchased := _try_instant_grocery_purchase()
		if not purchased.is_empty():
			has_food = true
	
	if not has_food:
		ConsoleLog.log_warning("⚠ STARVING but no food and can't afford any!")
		return false
	
	# If currently working, interrupt work with partial PP
	if current.get("type", -1) == ActionQueue.ActionType.WORK:
		ActionQueue.interrupt_work_for_emergency()
		ConsoleLog.log_system("⚠ Too hungry to continue working!")
	
	# Check if eat is already queued or in progress
	var queue := ActionQueue.get_queue()
	var eat_in_queue: bool = _count_action_in_queue(queue, ActionQueue.ActionType.EAT) > 0
	var currently_eating: bool = current.get("type", -1) == ActionQueue.ActionType.EAT
	
	if not eat_in_queue and not currently_eating:
		# Queue urgent eat action at front of queue
		var food_id: String = _get_food_from_inventory()
		if not food_id.is_empty():
			ActionQueue.add_action_urgent(ActionQueue.ActionType.EAT, {"item_id": food_id})
			ConsoleLog.log_system("⚠ Emergency: Must eat NOW!")
			
			# Start eating immediately if no current action
			if ActionQueue.get_current_action().is_empty():
				ActionQueue.call_deferred("_start_next_action")
	
	return true


func _check_bedtime_enforcement() -> bool:
	## Enforces bedtime rules - CANCELS everything and forces sleep when it's late
	## Returns true if bedtime was enforced (caller should not queue other actions)
	var hour: int = TimeManager.current_hour
	var is_late_night: bool = hour >= 22 or hour < 5  # 10pm to 5am
	
	if not is_late_night:
		return false
	
	var current := ActionQueue.get_current_action()
	var current_type: int = current.get("type", -1)
	
	# Already sleeping - good!
	if current_type == ActionQueue.ActionType.SLEEP:
		return false
	
	# No current action and queue is empty or has sleep - let normal flow handle it
	if current_type == -1:
		return false
	
	# IT'S BEDTIME! Cancel EVERYTHING and force sleep NOW
	ConsoleLog.log_system("💤 BEDTIME! Cancelling all tasks and going to sleep NOW")
	
	# Clear the entire queue first
	ActionQueue.clear_queue()
	
	# Cancel current action immediately (whatever it is)
	ActionQueue.cancel_current_action()
	
	# Queue sleep (will start immediately since queue is empty)
	ActionQueue.add_action(ActionQueue.ActionType.SLEEP, {})
	
	# Force start the sleep action now
	ActionQueue.call_deferred("_start_next_action")
	
	return true


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
	scores[ActionQueue.ActionType.NAP] = _score_nap(rest, current_queue)
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
	
	# HARD BLOCK: Cannot work if Belly Alarm < 15 (hunger > 85)
	# Belly Alarm = 100 - hunger, so hunger > 85 means Belly Alarm < 15
	if hunger > 85:
		score = -200
		reason = "too hungry to work (need food!)"
		return {"score": score, "reason": reason}
	
	# HARD BLOCK: Cannot work if too exhausted (rest < 15)
	if rest < 15:
		score = -200
		reason = "too tired to work (need rest!)"
		return {"score": score, "reason": reason}
	
	# Reduce work priority if needs are concerning
	if hunger >= HIGH_HUNGER:
		score -= 30
		reason = "getting hungry"
	
	if rest <= HIGH_TIRED:
		score -= 40
		reason = "getting tired"
	
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
	
	# === SLEEP IS HIGHEST PRIORITY AT NIGHT ===
	# When it's bedtime, sleep overrides EVERYTHING including hunger
	
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
	
	# Time-based modifiers - SLEEP IS KING AT NIGHT
	if hour >= 23 or hour < 4:
		# Very late night / early morning - MUST SLEEP (overrides hunger)
		score += 200
		reason = "bedtime! sleep first"
	elif hour >= 22:
		# Late evening (10pm-11pm) - strong priority
		score += 150
		reason = "late, time for bed"
	elif hour >= 21:
		# Early evening (9pm-10pm) - moderate but still high
		score += 80
		reason = "evening, should sleep soon"
	
	return {"score": score, "reason": reason}


func _score_nap(rest: int, queue: Array) -> Dictionary:
	var score: float = base_weights.get(ActionQueue.ActionType.NAP, 25)
	var reason: String = "taking a nap"
	
	# HARD BLOCK: Only nap when rest is at DANGER level (below 30)
	if rest > HIGH_TIRED:
		score = -100  # Don't nap unless tired
		reason = "not tired enough to nap"
		return {"score": score, "reason": reason}
	
	# HARD BLOCK: Only ONE nap action allowed (in queue or currently executing)
	var nap_count := _count_action_in_queue(queue, ActionQueue.ActionType.NAP)
	var currently_napping: bool = ActionQueue.get_current_action().get("type", -1) == ActionQueue.ActionType.NAP
	if nap_count > 0 or currently_napping:
		score = -200
		reason = "nap already queued (limit 1)"
		return {"score": score, "reason": reason}
	
	# HARD BLOCK: No napping at night - sleep instead (9pm - 6am)
	var hour: int = TimeManager.current_hour
	var is_nighttime: bool = hour >= 21 or hour < 6
	if is_nighttime:
		score = -200
		reason = "nighttime - should sleep instead"
		return {"score": score, "reason": reason}
	
	# === Daytime nap scoring - only when in danger zone ===
	
	# Critical rest (below 15) - STRONGLY prefer nap or sleep
	if rest < CRITICAL_REST:
		score += 100
		reason = "exhausted, desperately need nap"
	# Low rest (15-30) - need nap
	elif rest <= HIGH_TIRED:
		score += 70
		reason = "tired, need a nap"
	
	# Don't nap if sleep is already queued
	if _count_action_in_queue(queue, ActionQueue.ActionType.SLEEP) > 0:
		score -= 50
		reason = "sleep already queued"
	
	# Afternoon nap bonus (1pm - 4pm)
	if hour >= 13 and hour < 16:
		score += 15
		reason = "afternoon siesta time"
	
	return {"score": score, "reason": reason}


func _score_eat(hunger: int, has_food: bool, queue: Array) -> Dictionary:
	var score: float = base_weights[ActionQueue.ActionType.EAT]
	var reason: String = "eating"
	
	# Limit eat actions based on hunger level
	# Starving (hunger > 70): Allow up to 3 eat actions to fill up
	# Normal: Allow only 1 eat action
	var eat_count := _count_action_in_queue(queue, ActionQueue.ActionType.EAT)
	var currently_eating: bool = ActionQueue.get_current_action().get("type", -1) == ActionQueue.ActionType.EAT
	var max_eats: int = 1 if hunger <= 70 else 3  # Allow more eats when very hungry
	
	if eat_count >= max_eats or currently_eating:
		score = -200  # Hard block - at limit
		reason = "eating already queued (limit %d)" % max_eats
		return {"score": score, "reason": reason}
	
	# BEDTIME CHECK: At night (10pm+), sleep takes priority over eating
	# Character will eat in the morning instead
	var hour: int = TimeManager.current_hour
	var is_bedtime: bool = hour >= 22 or hour < 4
	if is_bedtime:
		score -= 100  # Reduce priority - sleep first, eat tomorrow
		reason = "bedtime, will eat tomorrow"
		return {"score": score, "reason": reason}
	
	# If Belly Alarm < 50 (hunger > 50), try to buy food from grocery
	# This happens regardless of current food inventory to ensure we have food
	if hunger > 50 and not has_food:
		var purchased := _try_instant_grocery_purchase()
		if not purchased.is_empty():
			has_food = true  # Now we have food!
	
	if not has_food:
		score = -100  # Can't eat without food
		reason = "no food available"
		return {"score": score, "reason": reason}
	
	# Scoring based on Belly Alarm level (hunger inverted)
	# hunger > 85 = Belly Alarm < 15 = critical
	# hunger > 70 = Belly Alarm < 30 = high priority
	# hunger > 50 = Belly Alarm < 50 = should eat
	if hunger > 85:
		score += 100
		reason = "starving, must eat now!"
	elif hunger > 70:
		score += 60
		reason = "very hungry"
	elif hunger > 50:
		score += 30
		reason = "getting hungry"
	elif hunger < 30:
		score -= 40  # Not hungry (Belly Alarm > 70)
		reason = "not hungry"
	
	return {"score": score, "reason": reason}


func _score_rest(rest: int, mood: int, queue: Array) -> Dictionary:
	var score: float = base_weights[ActionQueue.ActionType.REST]
	var reason: String = "taking a break"
	
	# HARD BLOCK: Only rest when rest is at DANGER level (below 30) or mood is critical
	if rest > HIGH_TIRED and mood > LOW_MOOD:
		score = -100  # Don't rest if not tired and mood is fine
		reason = "not tired enough to rest"
		return {"score": score, "reason": reason}
	
	# HARD BLOCK: Maximum 1 rest action in queue
	var total_rests := _count_action_in_queue(queue, ActionQueue.ActionType.REST)
	if total_rests >= 1:
		score = -200  # Hard block - only 1 rest in queue
		reason = "rest already queued"
		return {"score": score, "reason": reason}
	
	# HARD BLOCK: Don't rest if sleep is more appropriate (very tired)
	if rest <= CRITICAL_REST:
		score = -100  # Sleep or nap is better when critically tired
		reason = "too tired, need sleep not rest"
		return {"score": score, "reason": reason}
	
	# Rest for mood recovery when mood is critical
	if mood <= LOW_MOOD:
		score += 50
		reason = "need break for mood (critical)"
	
	# Rest when moderately tired (danger zone but not critical)
	if rest <= HIGH_TIRED and rest > CRITICAL_REST:
		score += 40
		reason = "tired, need rest"
	
	return {"score": score, "reason": reason}


func _score_travel_grocery(hunger: int, has_food: bool, queue: Array) -> Dictionary:
	var score: float = base_weights[ActionQueue.ActionType.TRAVEL_GROCERY]
	var reason: String = "going to grocery"
	var scoring: Dictionary = Balance.get_grocery_scoring()
	
	# Check if grocery is open (account for travel time too)
	var current_hour: int = TimeManager.current_hour
	var travel_time_mins: int = Balance.get_travel_time(GameState.living_tier, "Grocery")
	var arrival_hour: int = current_hour + (travel_time_mins / 60)
	
	if not Balance.is_location_open("Grocery", current_hour):
		score = -100
		reason = Balance.get_location_closed_message("Grocery")
		return {"score": score, "reason": reason}
	
	# Check inventory space - use smart slot calculation
	var available_slots: int = _calculate_smart_available_slots()
	if available_slots <= 0:
		score -= 50
		reason = "no inventory space"
		return {"score": score, "reason": reason}
	
	# Count current food VALUE (how much hunger it can satisfy)
	var food_value: int = _calculate_food_inventory_value()
	
	# KEY RULE: If we have food, EAT IT FIRST before shopping!
	# Only go to grocery when truly low on food
	if has_food:
		# If we have food and are hungry, we should EAT not shop
		if hunger >= HIGH_HUNGER:
			score = -50  # Hard block - go eat instead!
			reason = "have food, should eat first!"
			return {"score": score, "reason": reason}
		
		# If we have enough food value to fill hunger, don't shop
		if food_value >= hunger:
			score = -30
			reason = "have enough food stored"
			return {"score": score, "reason": reason}
		
		# Have some food but not enough - low priority shopping
		score -= 40
		reason = "have some food, low priority"
	
	# NO food at all - must go to grocery
	if food_value == 0:
		score += scoring.get("no_food_bonus", 80)
		reason = "no food! need to shop"
		
		# Extra urgency if hungry AND no food
		if hunger >= HIGH_HUNGER:
			score += 40
			reason = "urgently need food!"
	# Low food value (can satisfy < 30 hunger)
	elif food_value < 30:
		score += scoring.get("low_food_bonus", 40)
		reason = "running low on food"
	
	# Don't travel if already going there
	if _is_action_in_queue(queue, ActionQueue.ActionType.TRAVEL_GROCERY):
		score -= scoring.get("already_traveling_penalty", 100)
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
	## Includes food, snacks, and drinks with hunger reduction
	# Check character inventory first
	for slot: Dictionary in GameState.character_inventory:
		var item_id: String = slot.get("item_id", "")
		var item: Dictionary = Balance.get_item(item_id)
		var tags: Array = item.get("tags", [])
		var effects: Dictionary = item.get("effects", {})
		# Must be consumable with hunger effect
		if ("food" in tags or "snack" in tags or "drink" in tags) and effects.get("hunger", 0) < 0:
			return item_id
	
	# Then check LA inventory
	for slot: Dictionary in GameState.la_inventory:
		var item_id: String = slot.get("item_id", "")
		var item: Dictionary = Balance.get_item(item_id)
		var tags: Array = item.get("tags", [])
		var effects: Dictionary = item.get("effects", {})
		# Must be consumable with hunger effect
		if ("food" in tags or "snack" in tags or "drink" in tags) and effects.get("hunger", 0) < 0:
			return item_id
	
	return ""


func _calculate_food_inventory_value() -> int:
	## Calculate total hunger reduction value of all food in inventory
	var total_value: int = 0
	var all_slots: Array = GameState.character_inventory + GameState.la_inventory
	
	for slot in all_slots:
		var item_id: String = slot.get("item_id", "")
		var quantity: int = slot.get("quantity", 1)
		var item: Dictionary = Balance.get_item(item_id)
		var tags: Array = item.get("tags", [])
		
		if "food" in tags or "snack" in tags or "drink" in tags:
			var hunger_effect: int = abs(item.get("effects", {}).get("hunger", 0))
			total_value += hunger_effect * quantity
	
	return total_value


func _calculate_smart_available_slots() -> int:
	## Calculate how many new food items can be bought considering:
	## - Empty slots in character inventory and housing
	## - Existing stacks that aren't at max_stack yet
	var total_capacity: int = 0
	
	# Count empty slots
	var char_empty: int = GameState.MAX_CHARACTER_INVENTORY - GameState.character_inventory.size()
	var la_empty: int = GameState.max_la_inventory_slots - GameState.la_inventory.size()
	total_capacity += char_empty + la_empty
	
	# Count space in existing food stacks (can add more to existing stacks)
	var all_slots: Array = GameState.character_inventory + GameState.la_inventory
	for slot in all_slots:
		var item_id: String = slot.get("item_id", "")
		var quantity: int = slot.get("quantity", 1)
		var item: Dictionary = Balance.get_item(item_id)
		var tags: Array = item.get("tags", [])
		
		# Only count food/drink stacks
		if "food" in tags or "snack" in tags or "drink" in tags:
			var stackable: bool = item.get("stackable", false)
			if stackable:
				var max_stack: int = item.get("max_stack", 1)
				var space_in_stack: int = max_stack - quantity
				if space_in_stack > 0:
					# Each space in stack can hold 1 more of that item
					total_capacity += space_in_stack
	
	return total_capacity


func _get_existing_food_stacks() -> Dictionary:
	## Returns a dict of item_id -> {quantity, max_stack, space_left} for all food stacks
	var stacks: Dictionary = {}
	var all_slots: Array = GameState.character_inventory + GameState.la_inventory
	
	for slot in all_slots:
		var item_id: String = slot.get("item_id", "")
		var quantity: int = slot.get("quantity", 1)
		var item: Dictionary = Balance.get_item(item_id)
		var tags: Array = item.get("tags", [])
		
		if "food" in tags or "snack" in tags or "drink" in tags:
			var stackable: bool = item.get("stackable", false)
			var max_stack: int = item.get("max_stack", 1) if stackable else 1
			
			if stacks.has(item_id):
				stacks[item_id]["quantity"] += quantity
			else:
				stacks[item_id] = {
					"quantity": quantity,
					"max_stack": max_stack,
					"stackable": stackable
				}
	
	# Calculate space left in each stack
	for item_id: String in stacks:
		var stack: Dictionary = stacks[item_id]
		if stack["stackable"]:
			stack["space_left"] = stack["max_stack"] - stack["quantity"]
		else:
			stack["space_left"] = 0
	
	return stacks


func _queue_eating_until_full() -> void:
	## Queue multiple eat actions to fill up hunger completely
	## Respects bedtime - won't queue eating at night
	var hour: int = TimeManager.current_hour
	var is_bedtime: bool = hour >= 22 or hour < 5
	if is_bedtime:
		return  # Sleep takes priority at night
	
	var hunger: int = GameState.hunger  # 0 = full, 100 = starving
	if hunger < 30:
		return  # Not hungry enough to bother
	
	# Get list of all food items available
	var food_items: Array = _get_all_food_from_inventory()
	if food_items.is_empty():
		return
	
	# Calculate how many eat actions to queue
	var hunger_remaining: int = hunger
	var eat_actions_queued: int = 0
	var max_eat_actions: int = 5  # Safety limit
	
	for food_id in food_items:
		if hunger_remaining <= 0 or eat_actions_queued >= max_eat_actions:
			break
		
		var item: Dictionary = Balance.get_item(food_id)
		var hunger_effect: int = abs(item.get("effects", {}).get("hunger", 0))
		
		# Queue this eat action
		ActionQueue.add_action_urgent(ActionQueue.ActionType.EAT, {"item_id": food_id})
		hunger_remaining -= hunger_effect
		eat_actions_queued += 1
	
	if eat_actions_queued > 0:
		if hunger >= 70:
			ConsoleLog.log_system("🍽️ Very hungry! Eating %d items to fill up!" % eat_actions_queued)
		else:
			ConsoleLog.log_system("🍽️ Eating %d items" % eat_actions_queued)


func _get_all_food_from_inventory() -> Array:
	## Returns array of all food item_ids in inventory (character first, then LA)
	## Each item appears once per quantity (so 3 banana_chips = 3 entries)
	var food_list: Array = []
	
	# Character inventory first
	for slot: Dictionary in GameState.character_inventory:
		var item_id: String = slot.get("item_id", "")
		var quantity: int = slot.get("quantity", 1)
		var item: Dictionary = Balance.get_item(item_id)
		var tags: Array = item.get("tags", [])
		var effects: Dictionary = item.get("effects", {})
		
		if ("food" in tags or "snack" in tags or "drink" in tags) and effects.get("hunger", 0) < 0:
			for _i in range(quantity):
				food_list.append(item_id)
	
	# Then LA inventory
	for slot: Dictionary in GameState.la_inventory:
		var item_id: String = slot.get("item_id", "")
		var quantity: int = slot.get("quantity", 1)
		var item: Dictionary = Balance.get_item(item_id)
		var tags: Array = item.get("tags", [])
		var effects: Dictionary = item.get("effects", {})
		
		if ("food" in tags or "snack" in tags or "drink" in tags) and effects.get("hunger", 0) < 0:
			for _i in range(quantity):
				food_list.append(item_id)
	
	return food_list


func _try_instant_grocery_purchase() -> String:
	## If hungry and no food, try to buy food instantly from grocery (no travel)
	## Chooses food based on budget: cheap food if low budget, better food if higher budget
	## Returns the item_id purchased, or empty string if failed
	if not Balance.is_location_open("Grocery", TimeManager.current_hour):
		return ""  # Store closed
	
	if not GameState.can_add_food_or_drink():
		return ""  # Inventory full
	
	var money: int = GameState.money
	
	# Determine budget tier and max price to spend
	var max_price: int
	var budget_type: String
	if money < 20:
		max_price = 6  # Low budget: only very cheap food
		budget_type = "low budget"
	elif money < 50:
		max_price = 15  # Medium budget: decent food
		budget_type = "medium budget"
	else:
		max_price = 35  # Good budget: quality food (but not luxury)
		budget_type = "good budget"
	
	# Find best food within budget (best hunger reduction per coin)
	var best_food: Dictionary = {}
	var best_value: float = 0.0  # hunger reduction per coin
	
	var all_items: Array = Balance.get_all_items()
	for item: Dictionary in all_items:
		var tags: Array = item.get("tags", [])
		if not ("food" in tags or "snack" in tags or "drink" in tags):
			continue
		
		# Skip "bad" food unless desperate (very low budget)
		if "bad" in tags and money >= 10:
			continue
		
		var store: String = item.get("store", "")
		if store != "Grocery":
			continue
		
		var price: int = item.get("price", 0)
		if price > max_price or price > money:
			continue
		
		# Calculate value: hunger reduction per coin spent
		var effects: Dictionary = item.get("effects", {})
		var hunger_reduction: int = abs(effects.get("hunger", 0))
		if hunger_reduction <= 0:
			continue
		
		var value: float = float(hunger_reduction) / float(price) if price > 0 else 0.0
		
		# Bonus for mood boost
		var mood_boost: int = effects.get("mood", 0)
		if mood_boost > 0:
			value += mood_boost * 0.1
		
		if value > best_value:
			best_value = value
			best_food = item
	
	if best_food.is_empty():
		return ""  # Can't find affordable food
	
	# Instant purchase!
	var item_id: String = best_food.get("id", "")
	var price: int = best_food.get("price", 0)
	if GameState.buy_item(item_id, 1):
		ConsoleLog.log_store("AI bought %s for %d coins (%s)" % [
			best_food.get("name", item_id), price, budget_type
		])
		return item_id
	
	return ""


func queue_grocery_shopping() -> void:
	## Called when character arrives at grocery - plan purchases and queue SHOP action
	## Smart shopping: considers max_stack, variety, and available slots
	DebugProfiler.log_function_enter("CharacterAI.queue_grocery_shopping")
	ConsoleLog.log_store("🏪 Arrived at grocery store")
	
	if not Balance.is_location_open("Grocery", TimeManager.current_hour):
		ConsoleLog.log_store("Grocery is closed!")
		DebugProfiler.log_function_exit("CharacterAI.queue_grocery_shopping")
		return
	
	var rules: Dictionary = Balance.get_grocery_shopping_rules()
	var max_items: int = rules.get("max_items_per_trip", 5)
	var min_reserve: int = rules.get("min_money_reserve", 2)
	var min_mins: int = rules.get("minutes_per_item_min", 1)
	var max_mins: int = rules.get("minutes_per_item_max", 3)
	
	# Get empty slots and existing stacks
	var char_empty: int = GameState.get_available_character_slots()
	var la_empty: int = GameState.get_available_la_slots()
	var empty_slots: int = char_empty + la_empty
	var existing_stacks: Dictionary = _get_existing_food_stacks()
	
	ConsoleLog.log_store("Budget: %d coins, empty slots: %d (pocket: %d, home: %d)" % [
		GameState.money, empty_slots, char_empty, la_empty
	])
	
	# Calculate how much hunger we need to fill
	var current_hunger: int = GameState.hunger  # 0-100, higher = more hungry
	var existing_food_value: int = _calculate_food_inventory_value()
	var hunger_to_fill: int = maxi(0, current_hunger - existing_food_value)
	
	ConsoleLog.log_store("Hunger to fill: %d (have %d worth of food already)" % [current_hunger, existing_food_value])
	
	# Plan what to buy (don't buy yet, just plan)
	_planned_grocery_purchases.clear()
	var simulated_money: int = GameState.money
	var planned_hunger_value: int = 0
	var simulated_stacks: Dictionary = existing_stacks.duplicate(true)
	var simulated_empty_slots: int = empty_slots
	var items_already_planned: Dictionary = {}  # item_id -> count planned to buy
	
	for _i in range(max_items):
		if simulated_money <= min_reserve:
			ConsoleLog.log_store("Budget limit reached (reserve: %d)" % min_reserve)
			break
		
		# Stop if we have enough food planned AND we've bought at least 1 thing
		if planned_hunger_value >= hunger_to_fill and _planned_grocery_purchases.size() > 0:
			break
		
		# Check if we have any space at all
		var can_buy_something: bool = false
		
		# Can we add to existing stacks?
		for stack_id: String in simulated_stacks:
			var stack: Dictionary = simulated_stacks[stack_id]
			if stack.get("space_left", 0) > 0:
				can_buy_something = true
				break
		
		# Or do we have empty slots?
		if simulated_empty_slots > 0:
			can_buy_something = true
		
		if not can_buy_something:
			ConsoleLog.log_store("No more inventory space!")
			break
		
		var budget_tier: Dictionary = Balance.get_grocery_budget_tier(simulated_money)
		var max_price: int = budget_tier.get("max_price_per_item", 10)
		var prefer_tags: Array = budget_tier.get("prefer_tags", ["food", "snack"])
		var avoid_tags: Array = budget_tier.get("avoid_tags", ["bad"])
		
		var adjusted_max_price: int = mini(max_price, simulated_money - min_reserve)
		if adjusted_max_price <= 0:
			break
		
		# Find best food, excluding items we can't fit more of
		var excluded_items: Array = []
		for stack_id: String in simulated_stacks:
			var stack: Dictionary = simulated_stacks[stack_id]
			# Exclude items at max stack if we have no empty slots
			if stack.get("space_left", 0) <= 0 and simulated_empty_slots <= 0:
				excluded_items.append(stack_id)
		
		var best_food: Dictionary = _find_best_grocery_item(adjusted_max_price, prefer_tags, avoid_tags, excluded_items)
		if best_food.is_empty():
			break
		
		var item_id: String = best_food.get("id", "")
		var price: int = best_food.get("price", 0)
		var hunger_effect: int = abs(best_food.get("effects", {}).get("hunger", 0))
		var stackable: bool = best_food.get("stackable", false)
		var max_stack: int = best_food.get("max_stack", 1) if stackable else 1
		
		# Check if this item can fit
		var can_fit: bool = false
		if simulated_stacks.has(item_id):
			# Already have this item - check stack space
			if simulated_stacks[item_id].get("space_left", 0) > 0:
				can_fit = true
				simulated_stacks[item_id]["space_left"] -= 1
				simulated_stacks[item_id]["quantity"] += 1
		else:
			# New item - need empty slot
			if simulated_empty_slots > 0:
				can_fit = true
				simulated_empty_slots -= 1
				simulated_stacks[item_id] = {
					"quantity": 1,
					"max_stack": max_stack,
					"stackable": stackable,
					"space_left": max_stack - 1
				}
		
		if not can_fit:
			# Can't fit this item, add to excluded and try again
			excluded_items.append(item_id)
			continue
		
		# Add to planned purchases
		_planned_grocery_purchases.append({
			"item_id": item_id, 
			"price": price, 
			"name": best_food.get("name", item_id),
			"hunger_value": hunger_effect
		})
		simulated_money -= price
		planned_hunger_value += hunger_effect
		items_already_planned[item_id] = items_already_planned.get(item_id, 0) + 1
	
	if _planned_grocery_purchases.is_empty():
		ConsoleLog.log_store("Can't afford any food or no space!")
		DebugProfiler.log_function_exit("CharacterAI.queue_grocery_shopping")
		return
	
	# Calculate shopping duration: 1-3 minutes per item (random)
	var total_duration: int = 0
	var total_hunger_planned: int = 0
	for _item in _planned_grocery_purchases:
		total_duration += randi_range(min_mins, max_mins)
		total_hunger_planned += _item.get("hunger_value", 0)
	
	# Log what variety we're buying
	var buy_summary: Array = []
	var item_counts: Dictionary = {}
	for purchase in _planned_grocery_purchases:
		var name: String = purchase.get("name", "")
		item_counts[name] = item_counts.get(name, 0) + 1
	for item_name: String in item_counts:
		buy_summary.append("%s x%d" % [item_name, item_counts[item_name]])
	
	ConsoleLog.log_store("🛒 Shopping: %s (+%d hunger, %d mins)" % [
		", ".join(buy_summary), total_hunger_planned, total_duration
	])
	
	# Queue the SHOP action with calculated duration
	ActionQueue.add_action_urgent(ActionQueue.ActionType.SHOP, {"duration": total_duration})
	
	DebugProfiler.log_function_exit("CharacterAI.queue_grocery_shopping")


func complete_grocery_shopping() -> void:
	## Called when SHOP action completes - actually buy the planned items
	DebugProfiler.log_function_enter("CharacterAI.complete_grocery_shopping")
	
	if _planned_grocery_purchases.is_empty():
		ConsoleLog.log_store("Nothing to buy!")
		DebugProfiler.log_function_exit("CharacterAI.complete_grocery_shopping")
		return
	
	var items_bought: int = 0
	var total_spent: int = 0
	
	for purchase in _planned_grocery_purchases:
		var item_id: String = purchase.get("item_id", "")
		var price: int = purchase.get("price", 0)
		var item_name: String = purchase.get("name", item_id)
		
		# Check if we can still afford and have space
		if GameState.money < price:
			ConsoleLog.log_store("Can't afford %s anymore!" % item_name)
			continue
		
		if not GameState.can_add_food_or_drink():
			ConsoleLog.log_store("Inventory full, can't buy more!")
			break
		
		if GameState.buy_item(item_id, 1):
			items_bought += 1
			total_spent += price
	
	_planned_grocery_purchases.clear()
	
	if items_bought > 0:
		ConsoleLog.log_store("🛒 Bought %d items for %d coins (remaining: %d)" % [
			items_bought, total_spent, GameState.money
		])
		
		# If hungry, queue eating until full!
		_queue_eating_until_full()
	else:
		ConsoleLog.log_store("Couldn't buy any food!")
	
	DebugProfiler.log_function_exit("CharacterAI.complete_grocery_shopping")


func _find_best_grocery_item(max_price: int, prefer_tags: Array, avoid_tags: Array, excluded_items: Array = []) -> Dictionary:
	## Find the best food item to buy within budget
	## excluded_items: item IDs that shouldn't be selected (e.g., already at max stack)
	var best_item: Dictionary = {}
	var best_score: float = -1.0
	
	var all_items: Array = Balance.get_all_items()
	var checked_count: int = 0
	var food_count: int = 0
	
	for item: Dictionary in all_items:
		checked_count += 1
		var item_id: String = item.get("id", "")
		var tags: Array = item.get("tags", [])
		
		# Skip excluded items (at max stack with no empty slots)
		if item_id in excluded_items:
			continue
		
		# Must be food/snack/drink (consumables with hunger effect)
		if not ("food" in tags or "snack" in tags or "drink" in tags):
			continue
		
		food_count += 1
		
		# Must be from Grocery
		if item.get("store", "") != "Grocery":
			continue
		
		var price: int = item.get("price", 0)
		if price <= 0 or price > max_price or price > GameState.money:
			continue
		
		# Skip avoided tags
		var skip: bool = false
		for avoid_tag in avoid_tags:
			if avoid_tag in tags:
				skip = true
				break
		if skip:
			continue
		
		# Calculate score (value per coin)
		var effects: Dictionary = item.get("effects", {})
		var hunger_reduction: int = abs(effects.get("hunger", 0))
		if hunger_reduction <= 0:
			continue
		
		var score: float = float(hunger_reduction) / float(price)
		
		# Bonus for preferred tags
		for pref_tag in prefer_tags:
			if pref_tag in tags:
				score *= 1.2
		
		# Bonus for mood boost
		var mood_boost: int = effects.get("mood", 0)
		if mood_boost > 0:
			score += mood_boost * 0.1
		
		if score > best_score:
			best_score = score
			best_item = item
	
	if best_item.is_empty():
		DebugProfiler.log_debug("_find_best_grocery_item: checked %d items, %d food items, none matched (max_price=%d, money=%d, excluded=%d)" % [
			checked_count, food_count, max_price, GameState.money, excluded_items.size()
		])
	
	return best_item


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
		ActionQueue.ActionType.NAP:
			return {"duration": 60}  # 1 hour nap
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
