extends Node
## TimeManager - Handles in-game time progression

signal minute_passed(game_time: Dictionary)
signal hour_passed(game_time: Dictionary)
signal day_started(day: int)
signal day_ended(day: int)

var current_day: int = 1
var current_hour: int = 6  # Start at 6 AM
var current_minute: int = 0

var _tick_accumulator: float = 0.0
var _paused: bool = true
var _time_scale_multiplier: float = 1.0
var _fast_forwarding: bool = false  # Suppress day_ended/day_started during fast-forward


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	if _paused:
		return
	
	var seconds_per_minute := Balance.get_real_seconds_per_game_minute()
	if seconds_per_minute <= 0:
		push_error("[TimeManager] Invalid seconds_per_minute: %f" % seconds_per_minute)
		return
	
	_tick_accumulator += delta * _time_scale_multiplier
	
	while _tick_accumulator >= seconds_per_minute:
		_tick_accumulator -= seconds_per_minute
		_advance_minute()


func _advance_minute() -> void:
	current_minute += 1
	
	# Debug: print every 10 minutes
	if current_minute % 10 == 0:
		print("[TimeManager] Time: Day %d, %02d:%02d" % [current_day, current_hour, current_minute])
	
	if current_minute >= 60:
		current_minute = 0
		current_hour += 1
		
		if current_hour >= 24:
			current_hour = 0
			_end_day()
			current_day += 1
			_start_day()
		else:
			hour_passed.emit(get_time_dict())
	
	minute_passed.emit(get_time_dict())


func _start_day() -> void:
	# During fast-forward (sleep), suppress day signals to avoid triggering overlays/pauses
	if not _fast_forwarding:
		day_started.emit(current_day)


func _end_day() -> void:
	# During fast-forward (sleep), suppress day signals to avoid triggering overlays/pauses
	if not _fast_forwarding:
		day_ended.emit(current_day)


# === Public API ===

func start() -> void:
	print("[TimeManager] start() called")
	_paused = false
	if current_day == 1 and current_hour == 6 and current_minute == 0:
		print("[TimeManager] Emitting day_started for day 1")
		_start_day()


func pause() -> void:
	_paused = true


func resume() -> void:
	print("[TimeManager] resume() called - was paused: %s" % _paused)
	_paused = false


func is_paused() -> bool:
	return _paused


func set_time_scale(multiplier: float) -> void:
	_time_scale_multiplier = maxf(0.1, multiplier)


func get_time_scale() -> float:
	return _time_scale_multiplier


func get_time_dict() -> Dictionary:
	return {
		"day": current_day,
		"hour": current_hour,
		"minute": current_minute
	}


func get_time_string() -> String:
	return "%02d:%02d" % [current_hour, current_minute]


func get_day_time_string() -> String:
	return "Day %d | %s" % [current_day, get_time_string()]


func get_period_of_day() -> String:
	if current_hour >= 5 and current_hour < 12:
		return "morning"
	elif current_hour >= 12 and current_hour < 17:
		return "afternoon"
	elif current_hour >= 17 and current_hour < 21:
		return "evening"
	else:
		return "night"


func is_sleeping_hours() -> bool:
	return current_hour >= 22 or current_hour < 6


func advance_time(minutes: int, suppress_day_signals: bool = true) -> void:
	DebugProfiler.log_function_enter("TimeManager.advance_time(%d)" % minutes)
	
	# Set flag to suppress day_ended/day_started signals during bulk advance (e.g., sleep)
	var was_fast_forwarding := _fast_forwarding
	_fast_forwarding = suppress_day_signals
	
	# Track if we crossed a day boundary
	var start_day := current_day
	
	# Safety cap to prevent infinite loops
	var safe_minutes := mini(minutes, 1440)  # Max 24 hours
	if minutes != safe_minutes:
		DebugProfiler.log_warning("TimeManager: Capped advance_time from %d to %d" % [minutes, safe_minutes])
	
	for i in range(safe_minutes):
		_advance_minute()
		
		# Check for potential hang every 100 minutes
		if i > 0 and i % 100 == 0:
			DebugProfiler.log_debug("TimeManager: Advanced %d/%d minutes" % [i, safe_minutes])
	
	# Restore flag
	_fast_forwarding = was_fast_forwarding
	
	# Log if we crossed days
	if current_day != start_day:
		DebugProfiler.log_debug("TimeManager: advance_time crossed from day %d to day %d" % [start_day, current_day])
	
	DebugProfiler.log_function_exit("TimeManager.advance_time")


func reset() -> void:
	current_day = 1
	current_hour = 6
	current_minute = 0
	_tick_accumulator = 0.0
	_paused = true


func load_state(data: Dictionary) -> void:
	current_day = data.get("day", 1)
	current_hour = data.get("hour", 6)
	current_minute = data.get("minute", 0)
	_tick_accumulator = 0.0


func save_state() -> Dictionary:
	return {
		"day": current_day,
		"hour": current_hour,
		"minute": current_minute
	}

