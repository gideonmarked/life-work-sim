extends Node
## ActionQueue - Manages 7 queued actions with time-based execution

signal action_started(action: Dictionary)
signal action_completed(action: Dictionary)
signal action_progress(action: Dictionary, remaining: float)
signal queue_changed()

const MAX_QUEUE_SIZE := 7

# Action types
enum ActionType {
	IDLE,
	WORK,
	SLEEP,
	EAT,
	TRAVEL_GROCERY,
	TRAVEL_MALL,
	SHOP,
	REST,
	CREATE_RELEASE
}

# Action definitions with base durations (in game minutes)
const ACTION_DATA := {
	ActionType.IDLE: {"name": "Idle", "duration": 30, "icon": "○"},
	ActionType.WORK: {"name": "Work", "duration": 60, "icon": "⚙"},
	ActionType.SLEEP: {"name": "Sleep", "duration": 480, "icon": "☾"},
	ActionType.EAT: {"name": "Eat", "duration": 15, "icon": "🍴"},
	ActionType.TRAVEL_GROCERY: {"name": "Go to Grocery", "duration": 30, "icon": "→"},
	ActionType.TRAVEL_MALL: {"name": "Go to Mall", "duration": 30, "icon": "→"},
	ActionType.SHOP: {"name": "Shop", "duration": 20, "icon": "🛒"},
	ActionType.REST: {"name": "Rest", "duration": 30, "icon": "◇"},
	ActionType.CREATE_RELEASE: {"name": "Create Release", "duration": 120, "icon": "★"}
}

var queue: Array = []  # Array of action dictionaries
var current_action: Dictionary = {}
var time_remaining: float = 0.0  # In game minutes
var is_paused: bool = false

var _tick_accumulator: float = 0.0
var _fast_forwarding: bool = false  # Guard against processing during sleep fast-forward


func _ready() -> void:
	TimeManager.minute_passed.connect(_on_minute_passed)
	TimeManager.day_started.connect(_on_day_started)
	# AI will fill queue after ready - defer to let CharacterAI initialize
	call_deferred("_initial_setup")


func _initial_setup() -> void:
	# Start with idle until AI fills the queue
	print("[ActionQueue] _initial_setup() called, current_action.is_empty: %s" % current_action.is_empty())
	if current_action.is_empty():
		_start_next_action()
	print("[ActionQueue] After _initial_setup, current_action: %s" % current_action)


func _fill_queue_with_idle() -> void:
	## Fill empty queue slots with Idle actions
	var max_queue: int = MAX_QUEUE_SIZE - 1  # 6 slots (1 is current)
	while queue.size() < max_queue:
		queue.append(_create_action(ActionType.IDLE))
	
	if current_action.is_empty():
		_start_next_action()
	
	queue_changed.emit()


func _create_action(type: ActionType, data: Dictionary = {}) -> Dictionary:
	var base: Dictionary = ACTION_DATA.get(type, ACTION_DATA[ActionType.IDLE])
	var duration: int = data.get("duration", base.get("duration", 30))
	var action_name: String = base.get("name", "Unknown")
	
	# Adjust duration based on action type
	if type == ActionType.TRAVEL_GROCERY:
		duration = Balance.get_travel_time(GameState.living_tier, "Grocery")
	elif type == ActionType.TRAVEL_MALL:
		duration = Balance.get_travel_time(GameState.living_tier, "Mall")
	elif type == ActionType.SLEEP:
		# Sleep until rested or morning
		duration = 480  # 8 hours max
	elif type == ActionType.WORK:
		# Generate witty task name based on current position
		var title: String = GameState.get_position_title()
		action_name = Balance.get_random_work_task(GameState.branch, title)
	
	return {
		"type": type,
		"name": action_name,
		"icon": base.get("icon", "○"),
		"duration": duration,
		"data": data
	}


func _on_minute_passed(_time: Dictionary) -> void:
	# Skip processing during sleep fast-forward to prevent cascading calls
	if _fast_forwarding:
		return
	if is_paused:
		return
	if current_action.is_empty():
		print("[ActionQueue] _on_minute_passed: current_action is empty, starting next action")
		_start_next_action()
		if current_action.is_empty():
			return
	
	time_remaining -= 1.0
	
	# Execute per-minute effects
	_execute_action_tick()
	
	action_progress.emit(current_action, time_remaining)
	
	if time_remaining <= 0:
		_complete_current_action()


func _on_day_started(_day: int) -> void:
	## Reset queue at the start of each day for fresh AI decisions
	DebugProfiler.log_function_enter("ActionQueue._on_day_started")
	queue.clear()
	current_action = {}
	time_remaining = 0.0
	queue_changed.emit()
	ConsoleLog.log_system("New day - action queue reset")
	DebugProfiler.log_debug("ActionQueue: Queue cleared, waiting for AI to refill")
	DebugProfiler.log_function_exit("ActionQueue._on_day_started")
	# AI will refill the queue via CharacterAI's _fill_queue_to_capacity


func _execute_action_tick() -> void:
	match current_action.type:
		ActionType.WORK:
			GameState.is_working = true
			GameState.is_sleeping = false
		ActionType.SLEEP:
			GameState.is_sleeping = true
			GameState.is_working = false
			# Check if fully rested
			if GameState.rest >= 95:
				time_remaining = 0  # End sleep early
		ActionType.TRAVEL_GROCERY, ActionType.TRAVEL_MALL:
			GameState.is_traveling = true
		_:
			GameState.is_working = false
			GameState.is_sleeping = false


func _complete_current_action() -> void:
	var completed: Dictionary = current_action.duplicate()
	
	# Execute completion effects
	match completed.type:
		ActionType.WORK:
			GameState.is_working = false
			# Award PP on work completion
			var pp_gained: float = GameState.add_work_pp()
			ConsoleLog.log_work("Completed: %s (+%.1f PP)" % [completed.name, pp_gained])
		ActionType.SLEEP:
			GameState.is_sleeping = false
		ActionType.EAT:
			var item_id: String = completed.data.get("item_id", "")
			if not item_id.is_empty():
				if GameState.has_item(item_id):
					GameState.eat_item(item_id)
				else:
					ConsoleLog.log_warning("Cannot eat - no %s in inventory!" % item_id)
		ActionType.TRAVEL_GROCERY, ActionType.TRAVEL_MALL:
			GameState.is_traveling = false
		ActionType.CREATE_RELEASE:
			GameState.create_release()
	
	action_completed.emit(completed)
	
	# Log completion (work already logged with PP info above)
	if completed.type != ActionType.WORK:
		ConsoleLog.log_system("Completed: %s" % completed.name)
	
	_start_next_action()


func _start_next_action() -> void:
	## FIFO: Take action from front of queue
	DebugProfiler.log_function_enter("ActionQueue._start_next_action")
	
	if queue.is_empty():
		# No actions queued, start idle
		DebugProfiler.log_debug("ActionQueue: Queue empty, starting IDLE")
		current_action = _create_action(ActionType.IDLE)
		time_remaining = float(current_action.duration)
		action_started.emit(current_action)
		queue_changed.emit()
		ConsoleLog.log_system("Started: %s (%d min)" % [current_action.name, current_action.duration])
		DebugProfiler.log_function_exit("ActionQueue._start_next_action")
		return
	
	# Pop from front (FIFO)
	current_action = queue.pop_front()
	time_remaining = float(current_action.duration)
	
	DebugProfiler.log_debug("ActionQueue: Starting action %s (duration: %d)" % [current_action.name, current_action.duration])
	
	action_started.emit(current_action)
	queue_changed.emit()
	
	# Handle sleep special case - fast forward to 6am
	if current_action.type == ActionType.SLEEP:
		DebugProfiler.log_debug("ActionQueue: Sleep action, calling fast forward")
		_handle_sleep_fast_forward()
		DebugProfiler.log_function_exit("ActionQueue._start_next_action")
		return
	
	ConsoleLog.log_system("Started: %s (%d min)" % [current_action.name, current_action.duration])
	DebugProfiler.log_function_exit("ActionQueue._start_next_action")


func _handle_sleep_fast_forward() -> void:
	## Fast forward to 6am and calculate rest based on sleep duration
	DebugProfiler.log_function_enter("ActionQueue._handle_sleep_fast_forward")
	
	# Set flag to prevent _on_minute_passed from processing during fast-forward
	_fast_forwarding = true
	
	GameState.is_sleeping = true
	GameState.is_working = false
	
	# Calculate minutes until 6am
	var current_hour := TimeManager.current_hour
	var current_minute := TimeManager.current_minute
	
	DebugProfiler.log_debug("Sleep: Current time %02d:%02d" % [current_hour, current_minute])
	
	var hours_until_6am: int
	if current_hour >= 6:
		# Sleep until next day 6am
		hours_until_6am = (24 - current_hour) + 6
	else:
		# Sleep until 6am same day
		hours_until_6am = 6 - current_hour
	
	var minutes_until_6am := hours_until_6am * 60 - current_minute
	
	DebugProfiler.log_debug("Sleep: hours_until_6am=%d, minutes=%d" % [hours_until_6am, minutes_until_6am])
	
	# Safety check - prevent excessive time advance
	if minutes_until_6am > 1440:  # More than 24 hours
		DebugProfiler.log_warning("Sleep: Invalid minutes_until_6am=%d, capping at 720" % minutes_until_6am)
		minutes_until_6am = 720  # 12 hours max
	
	# Calculate rest gained based on sleep duration
	# Base: 10 rest per hour of sleep, max rest is 100
	var rest_per_hour := 10.0
	var rest_gained := hours_until_6am * rest_per_hour
	
	# Bonus rest for sleeping during ideal hours (10pm-6am)
	var ideal_hours := 0
	var check_hour := current_hour
	for i in range(mini(hours_until_6am, 24)):  # Cap loop iterations
		if check_hour >= 22 or check_hour < 6:
			ideal_hours += 1
		check_hour = (check_hour + 1) % 24
	
	# 20% bonus for ideal sleep hours
	rest_gained += ideal_hours * 2.0
	
	# Apply rest
	GameState.rest = minf(100.0, GameState.rest + rest_gained)
	
	# Log the sleep
	ConsoleLog.log_system("💤 Sleeping... (%d hours until 6am)" % hours_until_6am)
	ConsoleLog.log_stats("Eye-Lid Budget gained: +%.0f (Total: %.0f)" % [rest_gained, GameState.rest])
	
	# Track if we'll cross a day boundary
	var start_day := TimeManager.current_day
	
	# Fast forward time to 6am (signals suppressed during fast-forward)
	DebugProfiler.log_debug("Sleep: Advancing time by %d minutes" % minutes_until_6am)
	TimeManager.advance_time(minutes_until_6am, true)  # true = suppress day signals
	DebugProfiler.log_debug("Sleep: Time advance complete")
	
	# Clear fast-forward flag
	_fast_forwarding = false
	
	# Sleep is complete
	GameState.is_sleeping = false
	current_action = {}
	time_remaining = 0.0
	
	ConsoleLog.log_system("☀ Woke up at 6:00 AM, Day %d" % TimeManager.current_day)
	
	# If we crossed day boundaries during sleep, emit day_started now (after sleep complete)
	# This allows daily tracking to reset properly
	if TimeManager.current_day != start_day:
		DebugProfiler.log_debug("Sleep: Crossed days %d -> %d, emitting day_started" % [start_day, TimeManager.current_day])
		# Note: We don't emit day_ended because we don't want to show daily stats/pause for sleep nights
		TimeManager.day_started.emit(TimeManager.current_day)
	
	action_completed.emit({"type": ActionType.SLEEP, "name": "Sleep", "duration": minutes_until_6am})
	
	DebugProfiler.log_function_exit("ActionQueue._handle_sleep_fast_forward")
	
	# Start next action
	call_deferred("_start_next_action")


# === Public API ===

func add_action(type: ActionType, data: Dictionary = {}) -> bool:
	## Add action to end of queue (FIFO - First In, First Out)
	var action: Dictionary = _create_action(type, data)
	
	# Queue holds 6 items (current action is separate)
	var max_queue: int = MAX_QUEUE_SIZE - 1  # 6 slots
	
	# If queue has idle actions at the end, replace the last one
	if queue.size() >= max_queue:
		# Find last idle to replace
		for i in range(queue.size() - 1, -1, -1):
			if queue[i].type == ActionType.IDLE:
				queue.remove_at(i)
				break
	
	# Add to end of queue
	if queue.size() < max_queue:
		queue.append(action)
		queue_changed.emit()
		return true
	
	# Queue is full of non-idle actions
	return false


func add_action_urgent(type: ActionType, data: Dictionary = {}) -> bool:
	## Add action to FRONT of queue (next to execute after current)
	var action: Dictionary = _create_action(type, data)
	
	var max_queue: int = MAX_QUEUE_SIZE - 1
	
	# Remove last idle if full
	if queue.size() >= max_queue:
		for i in range(queue.size() - 1, -1, -1):
			if queue[i].type == ActionType.IDLE:
				queue.remove_at(i)
				break
	
	if queue.size() < max_queue:
		queue.push_front(action)
		queue_changed.emit()
		return true
	
	return false


func remove_action(index: int) -> bool:
	if index < 0 or index >= queue.size():
		return false
	
	queue.remove_at(index)
	queue_changed.emit()
	return true


func clear_queue() -> void:
	queue.clear()
	queue_changed.emit()


func skip_current() -> void:
	time_remaining = 0
	_complete_current_action()


func get_queue() -> Array:
	return queue.duplicate()


func get_current_action() -> Dictionary:
	return current_action


func get_time_remaining() -> float:
	return time_remaining


func get_time_remaining_string() -> String:
	var mins: int = int(time_remaining)
	if mins >= 60:
		return "%dh %dm" % [mins / 60, mins % 60]
	return "%dm" % mins


func get_progress_percent() -> float:
	if current_action.is_empty() or current_action.duration <= 0:
		return 0.0
	return 1.0 - (time_remaining / float(current_action.duration))


func pause() -> void:
	is_paused = true


func resume() -> void:
	is_paused = false


# === Quick action helpers ===

func queue_work(hours: int = 1) -> void:
	add_action(ActionType.WORK, {"duration": hours * 60})


func queue_sleep() -> void:
	add_action(ActionType.SLEEP)


func queue_eat(item_id: String) -> void:
	var item: Dictionary = Balance.get_item(item_id)
	add_action(ActionType.EAT, {"item_id": item_id, "name": "Eat " + item.get("name", "food")})


func queue_travel_grocery() -> void:
	add_action(ActionType.TRAVEL_GROCERY)


func queue_travel_mall() -> void:
	add_action(ActionType.TRAVEL_MALL)


func queue_rest(minutes: int = 30) -> void:
	add_action(ActionType.REST, {"duration": minutes})


func queue_create_release() -> void:
	if GameState.can_create_release():
		add_action(ActionType.CREATE_RELEASE)


# === Save/Load ===

func save_state() -> Dictionary:
	return {
		"queue": queue.duplicate(true),
		"current_action": current_action.duplicate(true),
		"time_remaining": time_remaining
	}


func load_state(data: Dictionary) -> void:
	queue = data.get("queue", []).duplicate(true)
	current_action = data.get("current_action", {}).duplicate(true)
	time_remaining = data.get("time_remaining", 0.0)
	
	if queue.is_empty() and current_action.is_empty():
		_fill_queue_with_idle()
	
	queue_changed.emit()
