extends Node
## ConsoleLog - In-game event logger

signal entry_added(entry: Dictionary)

const MAX_ENTRIES := 500

var entries: Array = []
var _enabled_categories: Dictionary = {}


func _ready() -> void:
	_init_categories()


func _init_categories() -> void:
	var categories := ["SYSTEM", "INPUT", "STATS", "WORK", "TRAVEL", "STORE", 
					   "ITEM", "QUOTE", "COMMENT", "PROMOTION", "DEMOTION", "ROYALTY", "WARNING"]
	for cat in categories:
		_enabled_categories[cat] = true


func log_entry(category: String, message: String, data: Dictionary = {}) -> void:
	if not _enabled_categories.get(category, false):
		return
	
	var time_dict := TimeManager.get_time_dict()
	var entry := {
		"ts_game": "%02d:%02d" % [time_dict.hour, time_dict.minute],
		"day": time_dict.day,
		"category": category,
		"message": message,
		"data": data
	}
	
	entries.append(entry)
	
	# Trim old entries
	while entries.size() > MAX_ENTRIES:
		entries.pop_front()
	
	entry_added.emit(entry)
	
	# Also print to Godot console for debugging
	print("[Day %d | %s] [%s] %s" % [entry.day, entry.ts_game, category, message])


func format_entry(entry: Dictionary) -> String:
	return "[Day %d | %s] [%s] %s" % [
		entry.get("day", 1),
		entry.get("ts_game", "00:00"),
		entry.get("category", "SYSTEM"),
		entry.get("message", "")
	]


# Convenience methods
func log_system(message: String, data: Dictionary = {}) -> void:
	log_entry("SYSTEM", message, data)


func log_input(message: String, data: Dictionary = {}) -> void:
	log_entry("INPUT", message, data)


func log_stats(message: String, data: Dictionary = {}) -> void:
	log_entry("STATS", message, data)


func log_work(message: String, data: Dictionary = {}) -> void:
	log_entry("WORK", message, data)


func log_travel(message: String, data: Dictionary = {}) -> void:
	log_entry("TRAVEL", message, data)


func log_store(message: String, data: Dictionary = {}) -> void:
	log_entry("STORE", message, data)


func log_item(message: String, data: Dictionary = {}) -> void:
	log_entry("ITEM", message, data)


func log_quote(message: String, data: Dictionary = {}) -> void:
	log_entry("QUOTE", message, data)


func log_comment(message: String, data: Dictionary = {}) -> void:
	log_entry("COMMENT", message, data)


func log_promotion(message: String, data: Dictionary = {}) -> void:
	log_entry("PROMOTION", message, data)


func log_demotion(message: String, data: Dictionary = {}) -> void:
	log_entry("DEMOTION", message, data)


func log_royalty(message: String, data: Dictionary = {}) -> void:
	log_entry("ROYALTY", message, data)


func log_warning(message: String, data: Dictionary = {}) -> void:
	log_entry("WARNING", message, data)


func set_category_enabled(category: String, enabled: bool) -> void:
	_enabled_categories[category] = enabled


func is_category_enabled(category: String) -> bool:
	return _enabled_categories.get(category, false)


func get_entries_filtered(categories: Array = []) -> Array:
	if categories.is_empty():
		return entries.duplicate()
	
	var filtered := []
	for entry in entries:
		if entry.get("category", "") in categories:
			filtered.append(entry)
	return filtered


func clear() -> void:
	entries.clear()


func get_recent(count: int = 50) -> Array:
	var start := maxi(0, entries.size() - count)
	return entries.slice(start)


func save_state() -> Array:
	return get_recent(100)


func load_state(data: Array) -> void:
	entries = data.duplicate()

