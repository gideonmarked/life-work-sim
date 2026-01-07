extends Node
## GameState - Manages character state and game progression

signal money_changed(new_amount: int)
signal stats_changed()
signal needs_changed()
signal position_changed(branch: String, level: int, title: String)
signal living_changed(tier: int, name: String)
signal inventory_changed()
signal royalty_received(amount: int, source: String)

# Character info
var character_name: String = ""
var category: String = ""
var branch: String = ""

# Position
var position_level: int = 1
var progress_points: float = 0.0

# Living
var living_tier: int = 1

# Money
var money: int = 0

# Career stats (base from living + items)
var base_comfort: int = 0
var base_productivity: int = 0
var base_reputation: int = 0
var base_stability: int = 0

# Item bonuses
var item_comfort: int = 0
var item_productivity: int = 0
var item_reputation: int = 0
var item_stability: int = 0
var item_storage: int = 0

# Needs (0-100)
var hunger: int = 30  # Lower is better (less hungry)
var rest: int = 80    # Higher is better (more rested)
var mood: int = 50

# Inventory - Character carries items on person (2 slots max)
var character_inventory: Array = []  # Array of {item_id, quantity}
const MAX_CHARACTER_INVENTORY: int = 2

# Living Arrangement inventory - storage at home (depends on LA tier)
var la_inventory: Array = []  # Array of {item_id, quantity}
var max_la_inventory_slots: int = 4  # From living arrangement stats

# Equipped fashion items
var equipped_headgear: String = ""  # item_id or empty
var equipped_top: String = ""
var equipped_bottom: String = ""
var equipped_shoes: String = ""

# Legacy compatibility alias
var inventory: Array:
	get: return character_inventory
var max_inventory_slots: int:
	get: return MAX_CHARACTER_INVENTORY + max_la_inventory_slots

# Royalties
var active_royalties: Array = []  # [{source, monthly_amount, months_left}]

# Pending promotion (checked at end of day)
var _pending_promotion: bool = false

# Demotion tracking
var demotion_risk_days: int = 0

# State flags
var is_traveling: bool = false
var travel_destination: String = ""
var travel_minutes_left: int = 0
var is_working: bool = false
var is_sleeping: bool = false

# Character state tracking
var _last_work_tick: int = 0


func _ready() -> void:
	TimeManager.minute_passed.connect(_on_minute_passed)
	TimeManager.hour_passed.connect(_on_hour_passed)
	TimeManager.day_started.connect(_on_day_started)
	TimeManager.day_ended.connect(_on_day_ended)


func _on_minute_passed(_time: Dictionary) -> void:
	# Travel completion is now handled by ActionQueue._complete_current_action
	# No need to track travel timer here
	
	# Passive need changes
	_update_passive_needs()
	
	# Work tick
	if is_working and not is_traveling:
		_do_work_tick()
	
	# Sleep rest
	if is_sleeping:
		_do_sleep_tick()


func _on_hour_passed(_time: Dictionary) -> void:
	# Hourly wage if working
	if is_working and not is_traveling:
		var pos := Balance.get_position(branch, position_level)
		var wage: int = pos.get("base_pay_per_hour", 0)
		add_money(wage)
		ConsoleLog.log_work("Earned %d coins (hourly)" % wage)
	
	# Random comment chance
	if randf() < 0.15:
		_trigger_random_comment()


func _on_day_started(day: int) -> void:
	DebugProfiler.log_function_enter("GameState._on_day_started(%d)" % day)
	ConsoleLog.log_system("Day %d started" % day)
	
	# Process royalties
	_process_royalties()
	
	# Show morning quote
	var quote := Balance.get_random_quote()
	ConsoleLog.log_quote('"%s" (%ds)' % [quote, Balance.get_quote_display_seconds()])
	DebugProfiler.log_function_exit("GameState._on_day_started")


func _on_day_ended(day: int) -> void:
	DebugProfiler.log_function_enter("GameState._on_day_ended(%d)" % day)
	ConsoleLog.log_system("Day %d ended" % day)
	
	# Process pending promotion at end of day
	if _pending_promotion:
		_promote()
		_pending_promotion = false
	
	# Check demotion risk
	_check_demotion_risk()
	DebugProfiler.log_function_exit("GameState._on_day_ended")


func _update_passive_needs() -> void:
	var old_hunger := hunger
	var old_rest := rest
	var old_mood := mood
	
	# Hunger is now drained on action COMPLETION (see ActionQueue._complete_current_action)
	# No passive per-minute hunger drain - it's handled by action_costs.json
	
	# Rest is now drained on action COMPLETION (see ActionQueue._complete_current_action)
	# No passive per-minute rest drain - it's handled by action_costs.json
	
	# Mood affected by needs
	if hunger >= 80 or rest <= 20:
		if Balance.roll_chance("needs", "mood_decrease_from_needs_chance"):
			mood = maxi(mood - 1, 0)
	
	# Random character remarks based on state
	_try_trigger_random_remark()
	
	# Log critical need warnings (only when crossing thresholds)
	# Belly Alarm is displayed inverted: 100 - hunger (so low = bad)
	var belly_alarm: int = 100 - hunger
	var old_belly: int = 100 - old_hunger
	
	# EMERGENCY: If Belly Alarm drops to critical (< 15), interrupt work and eat
	if belly_alarm < 15 and old_belly >= 15:
		ConsoleLog.log_stats("⚠ CRITICAL: Belly Alarm at %d! Must eat NOW!" % belly_alarm)
		CharacterAI.check_emergency_hunger()
	elif belly_alarm <= 10 and old_belly > 10:
		ConsoleLog.log_stats("⚠ CRITICAL: Belly Alarm at %d! Eat something soon!" % belly_alarm)
	elif belly_alarm <= 30 and old_belly > 30:
		ConsoleLog.log_stats("Warning: Belly Alarm dropping (%d)" % belly_alarm)
	
	if rest <= 10 and old_rest > 10:
		ConsoleLog.log_stats("⚠ CRITICAL: Eye-Lid Budget at %d! Sleep needed!" % rest)
	elif rest <= 30 and old_rest > 30:
		ConsoleLog.log_stats("Warning: Eye-Lid Budget low (%d)" % rest)
	
	if mood <= 20 and old_mood > 20:
		ConsoleLog.log_stats("⚠ CRITICAL: Vibe Spice at %d! Take a break!" % mood)
	elif mood <= 35 and old_mood > 35:
		ConsoleLog.log_stats("Warning: Vibe Spice dropping (%d)" % mood)


func _do_work_tick() -> void:
	# Work tick just maintains working state - PP is awarded on work COMPLETION
	# (See ActionQueue._complete_current_action for PP gain)
	pass


func add_work_pp() -> float:
	## Called when a work action COMPLETES - awards PP based on stats
	var ep := calculate_effective_productivity()
	var rep := get_total_reputation()
	var stab := get_total_stability()
	
	# Calculate PP using Balance formula
	var pp_gain: float = Balance.calculate_work_pp(ep, rep, stab)
	progress_points += pp_gain
	
	# Check for promotion eligibility (actual promotion happens at end of day)
	var threshold := Balance.get_promotion_threshold(branch, position_level)
	if progress_points >= threshold and position_level < 10 and not _pending_promotion:
		# Also check if we have required items for NEXT level
		if has_required_items_for_promotion():
			_pending_promotion = true
			ConsoleLog.log_work("🎯 Promotion threshold reached! Will be promoted at end of day.")
		else:
			var missing := get_missing_items_for_promotion()
			var missing_names: Array = []
			for item_id in missing:
				var item := Balance.get_item(item_id)
				missing_names.append(item.get("name", item_id))
			ConsoleLog.log_work("⚠ PP threshold reached but missing items: %s" % ", ".join(missing_names))
	
	stats_changed.emit()
	return pp_gain


func _do_sleep_tick() -> void:
	# Rest recovery while sleeping
	if Balance.roll_chance("sleep", "rest_recovery_chance"):
		rest = mini(rest + 2, 100)
	
	# Hunger still increases but slower
	if Balance.roll_chance("sleep", "hunger_while_sleeping_chance"):
		hunger = mini(hunger + 1, 100)
	
	# Wake up if fully rested or morning
	if rest >= 95 or (TimeManager.current_hour >= 6 and TimeManager.current_hour < 7):
		stop_sleeping()


func _promote() -> void:
	position_level += 1
	progress_points = 0.0
	
	var pos := Balance.get_position(branch, position_level)
	var title: String = pos.get("title", "Unknown")
	
	ConsoleLog.log_promotion("═══════════════════════════════════")
	ConsoleLog.log_promotion("🎉 PROMOTED to Level %d!" % position_level)
	ConsoleLog.log_promotion("New Title: %s" % title)
	ConsoleLog.log_promotion("Progress Points reset to 0")
	ConsoleLog.log_promotion("═══════════════════════════════════")
	
	position_changed.emit(branch, position_level, title)
	stats_changed.emit()  # Salary/stats change with position
	
	# Character remark on promotion
	var remark: String = Balance.get_random_remark("promoted")
	ConsoleLog.log_comment('💭 "%s"' % remark)
	
	# Grant items
	var grants: Array = pos.get("grants", [])
	for item_id in grants:
		if not has_item(item_id):
			add_item(item_id, 1, true)  # Log the acquisition
			var item := Balance.get_item(item_id)
			ConsoleLog.log_item("Promotion bonus: %s" % item.get("name", item_id))
	
	# Trigger promotion comment
	_trigger_comment_for_event("promotion")


func _check_demotion_risk() -> void:
	var drs := calculate_demotion_risk_score()
	var rules := Balance.get_demotion_rules()
	var threshold: int = rules.get("drs_threshold", 8)
	
	if drs >= threshold:
		demotion_risk_days += 1
		var pp_loss: int = rules.get("pp_loss_per_day", 50)
		progress_points -= pp_loss
		
		ConsoleLog.log_demotion("DRS=%d (>=%d) PP-%d -> %.1f" % [drs, threshold, pp_loss, progress_points])
		
		var demote_threshold: int = rules.get("demote_pp_threshold", -100)
		if progress_points < demote_threshold and position_level > 1:
			_demote()
		elif position_level == 1:
			# At level 1, can't demote further - cap PP at 0 minimum
			progress_points = maxf(0.0, progress_points)
			if progress_points == 0:
				ConsoleLog.log_demotion("PP capped at 0 (cannot demote from level 1)")
	else:
		demotion_risk_days = 0


func _demote() -> void:
	position_level = maxi(1, position_level - 1)
	progress_points = 0.0
	demotion_risk_days = 0
	
	var pos := Balance.get_position(branch, position_level)
	var title: String = pos.get("title", "Unknown")
	
	ConsoleLog.log_demotion("Demoted to Level %d: %s" % [position_level, title])
	position_changed.emit(branch, position_level, title)
	stats_changed.emit()  # Salary/stats change with position


func _process_royalties() -> void:
	var expired := []
	for i in range(active_royalties.size()):
		var royalty: Dictionary = active_royalties[i]
		var amount: int = royalty.get("monthly_amount", 0)
		var source: String = royalty.get("source", "Unknown")
		
		add_money(amount)
		ConsoleLog.log_royalty("Received %d from %s (%d months left)" % [
			amount, source, royalty.get("months_left", 0) - 1
		])
		royalty_received.emit(amount, source)
		
		royalty["months_left"] = royalty.get("months_left", 1) - 1
		if royalty["months_left"] <= 0:
			expired.append(i)
	
	# Remove expired royalties (reverse order)
	for i in range(expired.size() - 1, -1, -1):
		var exp_royalty: Dictionary = active_royalties[expired[i]]
		ConsoleLog.log_royalty("Royalty expired: %s (earned total over contract)" % exp_royalty.get("source", "Unknown"))
		active_royalties.remove_at(expired[i])


func _complete_travel() -> void:
	is_traveling = false
	ConsoleLog.log_travel("Arrived at %s" % travel_destination)
	
	# Chance to trigger comment after travel
	if randf() < 0.25:
		_trigger_comment_for_event("travel")
	
	travel_destination = ""


func _try_trigger_random_remark() -> void:
	## Try to trigger a random character remark based on current state
	if not Balance.roll_chance("character_remarks", "random_remark_chance"):
		return
	
	# Pick a category based on current state
	var category: String = "general"
	var hour: int = TimeManager.current_hour
	
	# Time-based categories
	if hour >= 5 and hour < 10:
		if randi() % 2 == 0:
			category = "morning"
	elif hour >= 17 and hour < 22:
		if randi() % 2 == 0:
			category = "evening"
	
	# State-based categories (override time sometimes)
	if hunger >= 70 and randi() % 3 == 0:
		category = "hungry"
	elif rest <= 30 and randi() % 3 == 0:
		category = "tired"
	elif mood >= 70 and randi() % 4 == 0:
		category = "happy"
	elif money < 20 and randi() % 4 == 0:
		category = "broke"
	elif is_working and randi() % 3 == 0:
		category = "working"
	
	# Chance for jokes
	if randi() % 10 == 0:
		category = "jokes"
	
	var remark: String = Balance.get_random_remark(category)
	ConsoleLog.log_comment('💭 "%s"' % remark)


func _trigger_random_comment() -> void:
	_trigger_comment_for_event("random")


func _trigger_comment_for_event(event: String) -> void:
	var category_pool := ["general"]
	
	# Add state-based categories
	if hunger >= 70:
		category_pool.append("hungry")
	if rest <= 30:
		category_pool.append("tired")
	if mood >= 70:
		category_pool.append("mood_high")
	if mood <= 30:
		category_pool.append("mood_low")
	
	# Add event-specific weighting
	match event:
		"purchase":
			category_pool.append("general")  # Double chance for general
		"travel":
			category_pool.append("general")
		"promotion":
			category_pool.append("mood_high")
		"release":
			category_pool.append("mood_high")
	
	# Branch-specific comments
	var branch_cat := branch.to_lower()
	if branch == "VisualArtist":
		branch_cat = "visual_artist"
	if Balance.comments_by_category.has(branch_cat):
		category_pool.append(branch_cat)
	
	var chosen_cat: String = category_pool[randi() % category_pool.size()]
	var comment := Balance.get_random_comment(chosen_cat)
	
	ConsoleLog.log_comment('Character said: "%s"' % comment.get("text", "..."))


# === Public API ===

func new_game(p_name: String, p_category: String, p_branch: String) -> void:
	character_name = p_name
	category = p_category
	branch = p_branch
	
	position_level = 1
	progress_points = 0.0
	living_tier = 1
	money = 10  # Starting money
	
	hunger = 30
	rest = 80
	mood = 50
	
	character_inventory.clear()
	la_inventory.clear()
	active_royalties.clear()
	demotion_risk_days = 0
	
	# Clear equipped fashion
	equipped_headgear = ""
	equipped_top = ""
	equipped_bottom = ""
	equipped_shoes = ""
	
	_recalculate_stats()
	
	# Grant starter consumables (1 food + 1 drink in character inventory)
	add_item_to_character("banana_chips", 1)
	add_item_to_character("cheap_water", 1)
	
	# Grant starting items from career (go to LA inventory)
	var pos := Balance.get_position(branch, 1)
	var grants: Array = pos.get("grants", [])
	for item_id in grants:
		add_item_to_la(item_id, 1)
	
	# Give notebook to careers that need it at level 1
	var requires: Array = pos.get("requires", [])
	if "notebook" in requires and not has_item("notebook"):
		add_item_to_la("notebook", 1)
	
	ConsoleLog.log_input("New game started: %s" % character_name)
	ConsoleLog.log_input("Selected Category: %s | Branch: %s" % [category, branch])
	ConsoleLog.log_item("Starting items: Banana Chips, Cheap Water")
	
	# Assign a save slot for this new game
	SaveManager.set_current_slot(-1)  # Auto-assign first empty slot
	
	TimeManager.reset()
	TimeManager.start()


func _recalculate_stats() -> void:
	var living := Balance.get_living_arrangement(living_tier)
	var stats: Dictionary = living.get("stats", {})
	
	base_comfort = stats.get("comfort", 0)
	base_productivity = stats.get("productivity", 0)
	base_reputation = stats.get("reputation", 0)
	base_stability = stats.get("stability", 0)
	max_la_inventory_slots = stats.get("storage", 4)
	
	# Reset item bonuses
	item_comfort = 0
	item_productivity = 0
	item_reputation = 0
	item_stability = 0
	item_storage = 0
	
	# Calculate from both inventories
	var all_items: Array = character_inventory + la_inventory
	for slot in all_items:
		var item := Balance.get_item(slot.get("item_id", ""))
		var effects: Dictionary = item.get("effects", {})
		var qty: int = slot.get("quantity", 1)
		
		# Only count first instance for non-stackable permanent effects
		var mult := 1 if not item.get("stackable", false) else qty
		
		item_comfort += effects.get("comfort", 0) * mult
		item_productivity += effects.get("productivity", 0) * mult
		item_reputation += effects.get("reputation", 0) * mult
		item_stability += effects.get("stability", 0) * mult
		item_storage += effects.get("storage", 0) * mult
	
	max_la_inventory_slots += item_storage
	
	stats_changed.emit()


func get_total_comfort() -> int:
	return base_comfort + item_comfort


func get_total_productivity() -> int:
	return base_productivity + item_productivity


func get_total_reputation() -> int:
	return base_reputation + item_reputation


func get_total_stability() -> int:
	return base_stability + item_stability


func calculate_effective_productivity() -> int:
	var bp := get_total_productivity()
	var cm := Balance.get_comfort_modifier(get_total_comfort())
	var mm := Balance.get_mood_modifier(mood)
	var np := Balance.get_hunger_penalty(hunger) + Balance.get_rest_penalty(rest)
	
	return maxi(0, bp + cm + mm + np)


func calculate_demotion_risk_score() -> int:
	var drs := 0
	var comfort := get_total_comfort()
	
	if comfort < 0:
		drs += abs(comfort)
	if mood < 30:
		drs += 2
	if hunger >= 95:
		drs += 3
	if rest <= 5:
		drs += 3
	if get_total_stability() <= 2:
		drs += 2
	
	return drs


func add_money(amount: int) -> void:
	money += amount
	money_changed.emit(money)


func spend_money(amount: int) -> bool:
	if money >= amount:
		money -= amount
		money_changed.emit(money)
		return true
	return false


func start_travel(destination: String) -> void:
	var minutes := Balance.get_travel_time(living_tier, destination)
	is_traveling = true
	travel_destination = destination
	travel_minutes_left = minutes
	ConsoleLog.log_travel("From=Home To=%s TravelTime=%dmin" % [destination, minutes])


func start_working() -> void:
	is_working = true
	ConsoleLog.log_work("Started working")


func stop_working() -> void:
	is_working = false
	ConsoleLog.log_work("Stopped working")


func start_sleeping() -> void:
	is_sleeping = true
	is_working = false
	ConsoleLog.log_system("Started sleeping")


func stop_sleeping() -> void:
	is_sleeping = false
	ConsoleLog.log_system("Woke up (Eye-Lid Budget: %d)" % rest)


func eat_item(item_id: String) -> bool:
	if not has_item(item_id):
		return false
	
	var item := Balance.get_item(item_id)
	var effects: Dictionary = item.get("effects", {})
	var tags: Array = item.get("tags", [])
	
	# Handle mystery soup random effect
	if item_id == "mystery_soup":
		var outcomes := [
			{"hunger": -25, "mood": 3, "msg": "Delicious!"},
			{"hunger": -15, "mood": -2, "msg": "Weird taste..."},
			{"hunger": -10, "mood": -5, "msg": "That was a mistake."},
			{"hunger": -20, "mood": 1, "rest": 5, "msg": "Surprisingly good!"},
			{"hunger": -5, "mood": -3, "rest": -5, "msg": "Stomach rumbles ominously."}
		]
		var outcome: Dictionary = outcomes[randi() % outcomes.size()]
		hunger = clampi(hunger + outcome.get("hunger", 0), 0, 100)
		mood = clampi(mood + outcome.get("mood", 0), 0, 100)
		rest = clampi(rest + outcome.get("rest", 0), 0, 100)
		remove_item(item_id, 1)
		needs_changed.emit()
		ConsoleLog.log_store("Ate Mystery Soup: %s Hunger=%d Mood=%d" % [outcome.get("msg", ""), hunger, mood])
		return true
	
	# Apply normal effects
	hunger = clampi(hunger + effects.get("hunger", 0), 0, 100)
	mood = clampi(mood + effects.get("mood", 0), 0, 100)
	rest = clampi(rest + effects.get("rest", 0), 0, 100)
	
	remove_item(item_id, 1)
	needs_changed.emit()
	
	ConsoleLog.log_store("Ate %s: Hunger=%d Mood=%d" % [item.get("name", item_id), hunger, mood])
	return true


func has_item(item_id: String) -> bool:
	return has_item_in_character(item_id) or has_item_in_la(item_id)


func has_item_in_character(item_id: String) -> bool:
	for slot in character_inventory:
		if slot.get("item_id", "") == item_id and slot.get("quantity", 0) > 0:
			return true
	return false


func has_item_in_la(item_id: String) -> bool:
	for slot in la_inventory:
		if slot.get("item_id", "") == item_id and slot.get("quantity", 0) > 0:
			return true
	return false


func get_item_quantity(item_id: String) -> int:
	return get_item_quantity_character(item_id) + get_item_quantity_la(item_id)


func get_item_quantity_character(item_id: String) -> int:
	for slot in character_inventory:
		if slot.get("item_id", "") == item_id:
			return slot.get("quantity", 0)
	return 0


func get_item_quantity_la(item_id: String) -> int:
	for slot in la_inventory:
		if slot.get("item_id", "") == item_id:
			return slot.get("quantity", 0)
	return 0


func add_item(item_id: String, quantity: int = 1, log_acquisition: bool = false) -> bool:
	## Smart add: food/drink goes to character inventory first, other items to LA
	var item := Balance.get_item(item_id)
	if item.is_empty():
		return false
	
	var tags: Array = item.get("tags", [])
	
	# Check for housing upgrade items (cardboard_box, camping_tent)
	if "housing_upgrade" in tags:
		return _handle_housing_upgrade_item(item_id, item, log_acquisition)
	
	# Food and drinks go to character inventory first
	if "food" in tags or "drink" in tags or "snack" in tags:
		if add_item_to_character(item_id, quantity, log_acquisition):
			return true
		# Fall back to LA if character is full
		return add_item_to_la(item_id, quantity, log_acquisition)
	else:
		# Non-consumables go to LA
		return add_item_to_la(item_id, quantity, log_acquisition)


func _handle_housing_upgrade_item(item_id: String, item: Dictionary, log_acquisition: bool) -> bool:
	## Handle shelter items that upgrade housing tier
	var target_tier: int = item.get("housing_tier", 0)
	if target_tier <= 0:
		return false
	
	# Check if this is an upgrade (must be higher than current tier)
	if target_tier <= living_tier:
		ConsoleLog.log_store("Already have better housing than %s!" % item.get("name", item_id))
		return false
	
	# Upgrade housing
	var old_name := get_living_name()
	living_tier = target_tier
	_recalculate_stats()
	living_changed.emit(living_tier, get_living_name())
	stats_changed.emit()
	
	if log_acquisition:
		ConsoleLog.log_item("🏠 Housing upgraded: %s → %s" % [old_name, get_living_name()])
	
	return true


func add_item_to_character(item_id: String, quantity: int = 1, log_acquisition: bool = false) -> bool:
	## Add item to character inventory (2 slots max)
	var item := Balance.get_item(item_id)
	if item.is_empty():
		return false
	
	var stackable: bool = item.get("stackable", false)
	var max_stack: int = item.get("max_stack", 1)
	
	# Check existing slot in character inventory
	for slot in character_inventory:
		if slot.get("item_id", "") == item_id:
			if stackable:
				slot["quantity"] = mini(slot.get("quantity", 0) + quantity, max_stack)
				_recalculate_stats()
				inventory_changed.emit()
				if log_acquisition:
					ConsoleLog.log_item("Acquired (pocket): %s x%d" % [item.get("name", item_id), quantity])
				return true
			else:
				return false  # Already have non-stackable
	
	# Need new slot
	if character_inventory.size() >= MAX_CHARACTER_INVENTORY:
		return false  # Character inventory full
	
	character_inventory.append({"item_id": item_id, "quantity": quantity})
	_recalculate_stats()
	inventory_changed.emit()
	if log_acquisition:
		ConsoleLog.log_item("Acquired (pocket): %s x%d" % [item.get("name", item_id), quantity])
	return true


func add_item_to_la(item_id: String, quantity: int = 1, log_acquisition: bool = false) -> bool:
	## Add item to living arrangement inventory
	var item := Balance.get_item(item_id)
	if item.is_empty():
		return false
	
	var stackable: bool = item.get("stackable", false)
	var max_stack: int = item.get("max_stack", 1)
	
	# Check existing slot in LA inventory
	for slot in la_inventory:
		if slot.get("item_id", "") == item_id:
			if stackable:
				slot["quantity"] = mini(slot.get("quantity", 0) + quantity, max_stack)
				_recalculate_stats()
				inventory_changed.emit()
				if log_acquisition:
					ConsoleLog.log_item("Acquired (home): %s x%d" % [item.get("name", item_id), quantity])
				return true
			else:
				return false  # Already have non-stackable
	
	# Need new slot
	if la_inventory.size() >= max_la_inventory_slots:
		ConsoleLog.log_item("Home storage full! Cannot add %s" % item.get("name", item_id))
		return false
	
	la_inventory.append({"item_id": item_id, "quantity": quantity})
	_recalculate_stats()
	inventory_changed.emit()
	if log_acquisition:
		ConsoleLog.log_item("Acquired (home): %s x%d" % [item.get("name", item_id), quantity])
	return true


func remove_item(item_id: String, quantity: int = 1) -> bool:
	## Remove from character inventory first, then LA
	if remove_item_from_character(item_id, quantity):
		return true
	return remove_item_from_la(item_id, quantity)


func remove_item_from_character(item_id: String, quantity: int = 1) -> bool:
	for i in range(character_inventory.size()):
		if character_inventory[i].get("item_id", "") == item_id:
			character_inventory[i]["quantity"] = character_inventory[i].get("quantity", 0) - quantity
			if character_inventory[i]["quantity"] <= 0:
				character_inventory.remove_at(i)
			_recalculate_stats()
			inventory_changed.emit()
			return true
	return false


func remove_item_from_la(item_id: String, quantity: int = 1) -> bool:
	for i in range(la_inventory.size()):
		if la_inventory[i].get("item_id", "") == item_id:
			la_inventory[i]["quantity"] = la_inventory[i].get("quantity", 0) - quantity
			if la_inventory[i]["quantity"] <= 0:
				la_inventory.remove_at(i)
			_recalculate_stats()
			inventory_changed.emit()
			return true
	return false


func move_item_to_housing(item_id: String, quantity: int = 1) -> bool:
	## Move item from character inventory to housing inventory
	if not has_item_in_character(item_id):
		return false
	
	# Check if housing has space
	var available_slots := get_available_la_slots()
	var item := Balance.get_item(item_id)
	var stackable: bool = item.get("stackable", false)
	
	# If not stackable and no space, fail
	if not stackable and available_slots <= 0:
		# Check if item already exists in LA (shouldn't for non-stackable but just in case)
		if not has_item_in_la(item_id):
			ConsoleLog.log_warning("No space in housing inventory!")
			return false
	
	# If stackable, check if we can stack or need new slot
	if stackable:
		var existing_in_la := false
		for slot in la_inventory:
			if slot.get("item_id", "") == item_id:
				existing_in_la = true
				break
		if not existing_in_la and available_slots <= 0:
			ConsoleLog.log_warning("No space in housing inventory!")
			return false
	
	# Remove from character
	if not remove_item_from_character(item_id, quantity):
		return false
	
	# Add to housing
	add_item_to_la(item_id, quantity, false)
	ConsoleLog.log_store("Moved %s to housing" % item.get("name", item_id))
	return true


func move_item_to_character(item_id: String, quantity: int = 1) -> bool:
	## Move item from housing inventory to character inventory
	if not has_item_in_la(item_id):
		return false
	
	# Check if character has space
	var available_slots := get_available_character_slots()
	var item := Balance.get_item(item_id)
	var stackable: bool = item.get("stackable", false)
	
	# If not stackable and no space, fail
	if not stackable and available_slots <= 0:
		if not has_item_in_character(item_id):
			ConsoleLog.log_warning("No space in character inventory!")
			return false
	
	# If stackable, check if we can stack or need new slot
	if stackable:
		var existing_in_char := false
		for slot in character_inventory:
			if slot.get("item_id", "") == item_id:
				existing_in_char = true
				break
		if not existing_in_char and available_slots <= 0:
			ConsoleLog.log_warning("No space in character inventory!")
			return false
	
	# Remove from housing
	if not remove_item_from_la(item_id, quantity):
		return false
	
	# Add to character
	add_item_to_character(item_id, quantity, false)
	ConsoleLog.log_store("Moved %s to pocket" % item.get("name", item_id))
	return true


func get_total_inventory_space() -> int:
	## Total space across both inventories
	return MAX_CHARACTER_INVENTORY + max_la_inventory_slots


func get_total_items_count() -> int:
	## Total items across both inventories
	return character_inventory.size() + la_inventory.size()


func can_add_food_or_drink() -> bool:
	## Check if we can add more food/drinks (character inv or LA)
	if character_inventory.size() < MAX_CHARACTER_INVENTORY:
		return true
	return la_inventory.size() < max_la_inventory_slots


func count_food_items() -> int:
	## Count total food/snack items in both inventories
	var count: int = 0
	var all_slots: Array = character_inventory + la_inventory
	for slot in all_slots:
		var item_id: String = slot.get("item_id", "")
		var item: Dictionary = Balance.get_item(item_id)
		var tags: Array = item.get("tags", [])
		if "food" in tags or "snack" in tags or "drink" in tags:
			count += slot.get("quantity", 1)
	return count


func get_available_food_slots() -> int:
	## Get number of slots available for food (character + LA storage)
	var char_available: int = MAX_CHARACTER_INVENTORY - character_inventory.size()
	var la_available: int = max_la_inventory_slots - la_inventory.size()
	return char_available + la_available


func get_available_character_slots() -> int:
	## Get slots available in character inventory specifically
	return MAX_CHARACTER_INVENTORY - character_inventory.size()


func get_available_la_slots() -> int:
	## Get slots available in living arrangement storage
	return max_la_inventory_slots - la_inventory.size()


# === Fashion/Equipment ===

func get_fashion_slot(slot: String) -> String:
	## Get equipped item_id for a fashion slot
	match slot:
		"headgear": return equipped_headgear
		"top": return equipped_top
		"bottom": return equipped_bottom
		"shoes": return equipped_shoes
	return ""


func get_fashion_item(slot: String) -> Dictionary:
	## Get the item data for an equipped fashion slot
	var item_id := get_fashion_slot(slot)
	if item_id.is_empty():
		return {}
	return Balance.get_item(item_id)


func equip_fashion(slot: String, item_id: String) -> bool:
	## Equip an item to a fashion slot (must own the item)
	if not has_item(item_id):
		return false
	
	var item := Balance.get_item(item_id)
	var tags: Array = item.get("tags", [])
	
	# Verify item is appropriate for slot
	var valid := false
	match slot:
		"headgear":
			valid = "headgear" in tags or "accessory" in tags or "cap" in item_id or "hat" in item_id
		"top":
			valid = "clothing" in tags and ("shirt" in item_id or "hoodie" in item_id or "jacket" in item_id or "suit" in item_id or "tshirt" in item_id or "pajamas" in item_id)
		"bottom":
			valid = "clothing" in tags and ("jeans" in item_id or "slacks" in item_id or "pants" in item_id or "shorts" in item_id)
		"shoes":
			valid = "shoes" in tags or "sneakers" in item_id or "shoes" in item_id
	
	if not valid:
		return false
	
	# Unequip current item first
	unequip_fashion(slot)
	
	# Equip new item
	match slot:
		"headgear": equipped_headgear = item_id
		"top": equipped_top = item_id
		"bottom": equipped_bottom = item_id
		"shoes": equipped_shoes = item_id
	
	ConsoleLog.log_item("Equipped %s: %s" % [slot, item.get("name", item_id)])
	inventory_changed.emit()
	return true


func unequip_fashion(slot: String) -> void:
	## Unequip an item from a fashion slot
	var current := get_fashion_slot(slot)
	if current.is_empty():
		return
	
	match slot:
		"headgear": equipped_headgear = ""
		"top": equipped_top = ""
		"bottom": equipped_bottom = ""
		"shoes": equipped_shoes = ""
	
	var item := Balance.get_item(current)
	ConsoleLog.log_item("Unequipped %s: %s" % [slot, item.get("name", current)])
	inventory_changed.emit()


func get_all_equipped() -> Dictionary:
	## Get all equipped fashion items
	return {
		"headgear": equipped_headgear,
		"top": equipped_top,
		"bottom": equipped_bottom,
		"shoes": equipped_shoes
	}


func buy_item(item_id: String, quantity: int = 1) -> bool:
	var item := Balance.get_item(item_id)
	if item.is_empty():
		return false
	
	var price: int = item.get("price", 0) * quantity
	if not spend_money(price):
		return false
	
	if not add_item(item_id, quantity):
		# Refund if can't add
		add_money(price)
		return false
	
	ConsoleLog.log_store("Purchased %s x%d for %d coins" % [item.get("name", item_id), quantity, price])
	
	# Chance to trigger comment after purchase
	if randf() < 0.3:
		_trigger_comment_for_event("purchase")
	
	return true


func upgrade_living(new_tier: int) -> bool:
	if new_tier <= living_tier or new_tier > 25:
		return false
	
	var price := Balance.get_living_arrangement_price(new_tier)
	if not spend_money(price):
		return false
	
	living_tier = new_tier
	_recalculate_stats()
	
	var living := Balance.get_living_arrangement(living_tier)
	ConsoleLog.log_system("Upgraded living to: %s for %d coins" % [living.get("name", "Unknown"), price])
	living_changed.emit(living_tier, living.get("name", ""))
	
	return true


func can_afford_living(tier: int) -> bool:
	var price := Balance.get_living_arrangement_price(tier)
	return money >= price


func add_royalty(source: String, monthly_amount: int, months: int) -> void:
	active_royalties.append({
		"source": source,
		"monthly_amount": monthly_amount,
		"months_left": months
	})
	ConsoleLog.log_royalty("New royalty: %s - %d/month for %d months" % [source, monthly_amount, months])


# === Release/Royalty Creation (for Coder and Art branches) ===

func can_create_release() -> bool:
	# Coder can create releases at level 4+, Art branches at level 4+
	if position_level < 4:
		return false
	return branch in ["Coder", "Author", "VisualArtist", "Musician"]


func get_release_type() -> String:
	match branch:
		"Coder": return "App/Game"
		"Author": return "Book"
		"VisualArtist": return "Art Collection"
		"Musician": return "Album"
		_: return "Release"


func create_release() -> bool:
	if not can_create_release():
		return false
	
	# Cost to create a release (time investment simulated as money)
	var creation_cost := 50 + (position_level * 20)
	if not spend_money(creation_cost):
		return false
	
	# Calculate royalty based on position level and stats
	var base_monthly := 10 + (position_level * 5)
	var rep_bonus := get_total_reputation()
	var monthly_amount := base_monthly + rep_bonus
	
	# Duration 3-24 months based on level and luck
	var min_months := 3 + position_level
	var max_months := mini(24, 6 + position_level * 2)
	var months := randi_range(min_months, max_months)
	
	var release_type := get_release_type()
	var release_name := "%s #%d" % [release_type, active_royalties.size() + 1]
	
	add_royalty(release_name, monthly_amount, months)
	_trigger_comment_for_event("release")
	
	return true


func get_position_title() -> String:
	var pos := Balance.get_position(branch, position_level)
	return pos.get("title", "Unknown")


func get_living_name() -> String:
	var living := Balance.get_living_arrangement(living_tier)
	return living.get("name", "Unknown")


func has_required_items_for_promotion() -> bool:
	## Check if we have items required for the NEXT level (for promotion)
	var next_pos := Balance.get_position(branch, position_level + 1)
	var requires: Array = next_pos.get("requires", [])
	
	for item_id in requires:
		if not has_item(item_id):
			return false
	return true


func get_missing_items_for_promotion() -> Array:
	## Get items missing for the NEXT level (for promotion)
	var next_pos := Balance.get_position(branch, position_level + 1)
	var requires: Array = next_pos.get("requires", [])
	var missing := []
	
	for item_id in requires:
		if not has_item(item_id):
			missing.append(item_id)
	return missing


func has_required_items() -> bool:
	## Check if we have items required for CURRENT level
	var pos := Balance.get_position(branch, position_level)
	var requires: Array = pos.get("requires", [])
	
	for item_id in requires:
		if not has_item(item_id):
			return false
	return true


func get_missing_items() -> Array:
	## Get items missing for CURRENT level
	var pos := Balance.get_position(branch, position_level)
	var requires: Array = pos.get("requires", [])
	var missing := []
	
	for item_id in requires:
		if not has_item(item_id):
			missing.append(item_id)
	return missing


# === Save/Load ===

func save_state() -> Dictionary:
	return {
		"character_name": character_name,
		"category": category,
		"branch": branch,
		"position_level": position_level,
		"progress_points": progress_points,
		"living_tier": living_tier,
		"money": money,
		"hunger": hunger,
		"rest": rest,
		"mood": mood,
		"character_inventory": character_inventory.duplicate(true),
		"la_inventory": la_inventory.duplicate(true),
		"equipped_fashion": get_all_equipped(),
		"active_royalties": active_royalties.duplicate(true),
		"demotion_risk_days": demotion_risk_days,
		"time": TimeManager.save_state(),
		"console_log": ConsoleLog.save_state()
	}


func load_state(data: Dictionary) -> void:
	character_name = data.get("character_name", "")
	category = data.get("category", "")
	branch = data.get("branch", "")
	position_level = data.get("position_level", 1)
	progress_points = data.get("progress_points", 0.0)
	living_tier = data.get("living_tier", 1)
	money = data.get("money", 0)
	hunger = data.get("hunger", 30)
	rest = data.get("rest", 80)
	mood = data.get("mood", 50)
	
	# Load new dual inventory format
	if data.has("character_inventory"):
		character_inventory = data.get("character_inventory", []).duplicate(true)
		la_inventory = data.get("la_inventory", []).duplicate(true)
	else:
		# Legacy: migrate old single inventory to new format
		var old_inv: Array = data.get("inventory", [])
		character_inventory.clear()
		la_inventory.clear()
		for slot in old_inv:
			var item := Balance.get_item(slot.get("item_id", ""))
			var tags: Array = item.get("tags", [])
			if ("food" in tags or "drink" in tags) and character_inventory.size() < MAX_CHARACTER_INVENTORY:
				character_inventory.append(slot.duplicate(true))
			else:
				la_inventory.append(slot.duplicate(true))
	
	active_royalties = data.get("active_royalties", []).duplicate(true)
	demotion_risk_days = data.get("demotion_risk_days", 0)
	
	# Load equipped fashion
	var fashion: Dictionary = data.get("equipped_fashion", {})
	equipped_headgear = fashion.get("headgear", "")
	equipped_top = fashion.get("top", "")
	equipped_bottom = fashion.get("bottom", "")
	equipped_shoes = fashion.get("shoes", "")
	
	if data.has("time"):
		TimeManager.load_state(data.get("time"))
	if data.has("console_log"):
		ConsoleLog.load_state(data.get("console_log"))
	
	_recalculate_stats()
	
	is_traveling = false
	is_working = false
	is_sleeping = false
