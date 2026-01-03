extends Node
## SaveManager - Handles save/load operations for up to 7 character slots

const SAVE_PATH := "user://saves/"
const MAX_SLOTS := 7

signal save_completed(slot: int)
signal load_completed(slot: int)
signal slot_deleted(slot: int)

# Track the current active slot (the one we loaded from or created)
var current_slot: int = -1


func _ready() -> void:
	_ensure_save_directory()


func _ensure_save_directory() -> void:
	var dir := DirAccess.open("user://")
	if dir and not dir.dir_exists("saves"):
		dir.make_dir("saves")


func get_slot_path(slot: int) -> String:
	return SAVE_PATH + "slot_%d.json" % slot


func save_game(slot: int = -1) -> bool:
	# Use current slot if no slot specified
	if slot == -1:
		slot = current_slot
	
	# If still no valid slot, find one
	if slot < 1 or slot > MAX_SLOTS:
		slot = get_first_empty_slot()
		if slot < 1:
			slot = 1  # Overwrite slot 1 as last resort
	
	var data := GameState.save_state()
	data["last_played"] = Time.get_unix_time_from_system()
	data["slot"] = slot
	
	var json_string := JSON.stringify(data, "\t")
	var file := FileAccess.open(get_slot_path(slot), FileAccess.WRITE)
	if not file:
		push_error("[SaveManager] Failed to open file for writing")
		return false
	
	file.store_string(json_string)
	file.close()
	
	current_slot = slot  # Remember this slot
	ConsoleLog.log_system("Game saved to slot %d" % slot)
	save_completed.emit(slot)
	return true


func load_game(slot: int) -> bool:
	if slot < 1 or slot > MAX_SLOTS:
		push_error("[SaveManager] Invalid slot: %d" % slot)
		return false
	
	var path := get_slot_path(slot)
	if not FileAccess.file_exists(path):
		push_error("[SaveManager] Save file not found: %s" % path)
		return false
	
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("[SaveManager] Failed to open file for reading")
		return false
	
	var json_string := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var err := json.parse(json_string)
	if err != OK:
		push_error("[SaveManager] JSON parse error: %s" % json.get_error_message())
		return false
	
	GameState.load_state(json.data)
	current_slot = slot  # Remember the loaded slot
	ConsoleLog.log_system("Game loaded from slot %d" % slot)
	load_completed.emit(slot)
	return true


func delete_slot(slot: int) -> bool:
	if slot < 1 or slot > MAX_SLOTS:
		return false
	
	var path := get_slot_path(slot)
	if FileAccess.file_exists(path):
		var dir := DirAccess.open(SAVE_PATH)
		if dir:
			dir.remove("slot_%d.json" % slot)
			slot_deleted.emit(slot)
			return true
	return false


func slot_exists(slot: int) -> bool:
	return FileAccess.file_exists(get_slot_path(slot))


func get_slot_info(slot: int) -> Dictionary:
	if not slot_exists(slot):
		return {}
	
	var file := FileAccess.open(get_slot_path(slot), FileAccess.READ)
	if not file:
		return {}
	
	var json_string := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	if json.parse(json_string) != OK:
		return {}
	
	var data: Dictionary = json.data
	return {
		"slot": slot,
		"character_name": data.get("character_name", "Unknown"),
		"branch": data.get("branch", ""),
		"position_level": data.get("position_level", 1),
		"living_tier": data.get("living_tier", 1),
		"money": data.get("money", 0),
		"last_played": data.get("last_played", 0),
		"day": data.get("time", {}).get("day", 1)
	}


func get_all_slots_info() -> Array:
	var slots := []
	for i in range(1, MAX_SLOTS + 1):
		var info := get_slot_info(i)
		if not info.is_empty():
			slots.append(info)
		else:
			slots.append({"slot": i, "empty": true})
	return slots


func get_most_recent_slot() -> int:
	var most_recent := -1
	var most_recent_time := 0.0
	
	for i in range(1, MAX_SLOTS + 1):
		var info := get_slot_info(i)
		if not info.is_empty() and not info.get("empty", true):
			var last_played: float = info.get("last_played", 0)
			if last_played > most_recent_time:
				most_recent_time = last_played
				most_recent = i
	
	return most_recent


func get_first_empty_slot() -> int:
	for i in range(1, MAX_SLOTS + 1):
		if not slot_exists(i):
			return i
	return -1


func has_any_saves() -> bool:
	for i in range(1, MAX_SLOTS + 1):
		if slot_exists(i):
			return true
	return false


func delete_all_saves() -> void:
	## Delete all save slots
	for i in range(1, MAX_SLOTS + 1):
		delete_slot(i)
	current_slot = -1
	ConsoleLog.log_system("All save files deleted")


func set_current_slot(slot: int) -> void:
	## Call this when starting a new game to assign a slot
	if slot >= 1 and slot <= MAX_SLOTS:
		current_slot = slot
	else:
		# Auto-assign first empty slot for new games
		current_slot = get_first_empty_slot()
		if current_slot < 1:
			current_slot = 1


func get_current_slot() -> int:
	return current_slot


func save_to_current_slot() -> bool:
	## Convenience method to save to the current slot
	return save_game(current_slot)

