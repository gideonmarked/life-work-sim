extends Node
## DebugProfiler - Memory and performance monitoring to detect hangs

const LOG_FILE_PATH := "user://debug_log.txt"
const MEMORY_CHECK_INTERVAL := 1.0  # Check memory every second

var _log_file: FileAccess = null
var _memory_timer: float = 0.0
var _last_memory_mb: float = 0.0
var _frame_count: int = 0
var _last_frame_time: float = 0.0
var _function_stack: Array[String] = []
var _enabled: bool = true

# Track potentially problematic areas
var _loop_counters: Dictionary = {}
var _max_loop_iterations: int = 10000


func _ready() -> void:
	_open_log_file()
	log_debug("=== DEBUG PROFILER STARTED ===")
	log_debug("Time: %s" % Time.get_datetime_string_from_system())
	log_memory("Initial memory state")
	
	# Connect to key signals for tracking (deferred to ensure autoloads are ready)
	call_deferred("_connect_signals")


func _connect_signals() -> void:
	if TimeManager:
		TimeManager.minute_passed.connect(_on_minute_passed)
		TimeManager.day_started.connect(_on_day_started)
		TimeManager.day_ended.connect(_on_day_ended)


func _process(delta: float) -> void:
	if not _enabled:
		return
	
	_frame_count += 1
	_memory_timer += delta
	
	# Check for frame time spikes (potential hang indicators)
	if delta > 0.5:  # Half second frame = major lag
		log_warning("⚠ FRAME SPIKE: %.2fs (frame %d)" % [delta, _frame_count])
		log_memory("Memory at frame spike")
		_log_function_stack()
	
	# Periodic memory check
	if _memory_timer >= MEMORY_CHECK_INTERVAL:
		_memory_timer = 0.0
		_check_memory_growth()


func _open_log_file() -> void:
	_log_file = FileAccess.open(LOG_FILE_PATH, FileAccess.WRITE)
	if not _log_file:
		push_error("[DebugProfiler] Failed to open log file")


func _check_memory_growth() -> void:
	var current_mb := get_memory_mb()
	var growth := current_mb - _last_memory_mb
	
	# Log significant memory growth (>5MB in 1 second)
	if abs(growth) > 5.0:
		log_warning("⚠ MEMORY CHANGE: %.1f MB (%.1f -> %.1f)" % [growth, _last_memory_mb, current_mb])
	
	_last_memory_mb = current_mb


func get_memory_mb() -> float:
	return OS.get_static_memory_usage() / 1048576.0  # Bytes to MB


func log_debug(message: String, to_console: bool = false) -> void:
	var timestamp := Time.get_time_string_from_system()
	var full_msg := "[%s] %s" % [timestamp, message]
	
	print(full_msg)
	
	if _log_file:
		_log_file.store_line(full_msg)
		_log_file.flush()
	
	# Optionally also log to game console
	if to_console and is_instance_valid(ConsoleLog) and ConsoleLog.has_method("log_system"):
		ConsoleLog.log_system("[DBG] %s" % message)


func log_warning(message: String) -> void:
	var timestamp := Time.get_time_string_from_system()
	var full_msg := "[%s] ⚠ %s" % [timestamp, message]
	
	push_warning(full_msg)
	print(full_msg)
	
	if _log_file:
		_log_file.store_line(full_msg)
		_log_file.flush()
	
	# Always log warnings to game console so user sees them
	if is_instance_valid(ConsoleLog) and ConsoleLog.has_method("log_system"):
		ConsoleLog.log_system("[⚠ DEBUG] %s" % message)


func log_memory(context: String = "", to_console: bool = false) -> void:
	var mem_mb := get_memory_mb()
	var msg := "MEMORY: %.1f MB" % mem_mb
	if not context.is_empty():
		msg += " (%s)" % context
	log_debug(msg, to_console)


func log_both(message: String) -> void:
	## Log to both file AND game console
	log_debug(message, true)


func log_function_enter(func_name: String) -> void:
	_function_stack.append(func_name)
	log_debug(">>> ENTER: %s (depth: %d)" % [func_name, _function_stack.size()])


func log_function_exit(func_name: String) -> void:
	log_debug("<<< EXIT: %s" % func_name)
	if not _function_stack.is_empty() and _function_stack[-1] == func_name:
		_function_stack.pop_back()


func _log_function_stack() -> void:
	if _function_stack.is_empty():
		log_debug("Function stack: (empty)")
	else:
		log_debug("Function stack: %s" % " -> ".join(_function_stack))


func track_loop(loop_id: String) -> bool:
	## Call this inside loops to detect infinite loops. Returns false if loop exceeded max.
	if not _loop_counters.has(loop_id):
		_loop_counters[loop_id] = 0
	
	_loop_counters[loop_id] += 1
	
	if _loop_counters[loop_id] > _max_loop_iterations:
		log_warning("⚠ INFINITE LOOP DETECTED: %s (iterations: %d)" % [loop_id, _loop_counters[loop_id]])
		log_memory("Memory at infinite loop")
		_log_function_stack()
		return false  # Signal to break the loop
	
	return true


func reset_loop(loop_id: String) -> void:
	## Call this after a loop completes normally
	_loop_counters.erase(loop_id)


func log_state_snapshot() -> void:
	## Log current game state for debugging
	log_debug("=== STATE SNAPSHOT ===")
	log_memory("Current")
	
	if is_instance_valid(GameState):
		log_debug("GameState: day=%d, money=%d, hunger=%d, rest=%d, mood=%d" % [
			TimeManager.current_day if is_instance_valid(TimeManager) else 0,
			GameState.money,
			GameState.hunger,
			GameState.rest,
			GameState.mood
		])
		log_debug("Inventory: char=%d, la=%d" % [
			GameState.character_inventory.size(),
			GameState.la_inventory.size()
		])
	
	if is_instance_valid(ActionQueue) and ActionQueue.has_method("get_current_action"):
		var current := ActionQueue.get_current_action()
		log_debug("ActionQueue: current=%s, queue_size=%d, time_remaining=%.1f" % [
			current.get("name", "none"),
			ActionQueue.get_queue().size(),
			ActionQueue.get_time_remaining()
		])
	
	if is_instance_valid(ConsoleLog):
		log_debug("ConsoleLog entries: %d" % ConsoleLog.entries.size())
	
	log_debug("=== END SNAPSHOT ===")


# Signal handlers for key events
func _on_minute_passed(_time: Dictionary) -> void:
	# Log every 10 game minutes
	if TimeManager.current_minute % 10 == 0:
		log_debug("Time: Day %d, %02d:%02d" % [
			TimeManager.current_day,
			TimeManager.current_hour,
			TimeManager.current_minute
		])


func _on_day_started(day: int) -> void:
	log_debug("=== DAY %d STARTED ===" % day)
	log_state_snapshot()


func _on_day_ended(day: int) -> void:
	log_debug("=== DAY %d ENDED ===" % day)
	log_memory("End of day")


func set_enabled(enabled: bool) -> void:
	_enabled = enabled
	log_debug("Profiler %s" % ("ENABLED" if enabled else "DISABLED"))


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		if _log_file:
			log_debug("=== DEBUG PROFILER STOPPED ===")
			_log_file.close()

