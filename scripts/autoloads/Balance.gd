extends Node
## Balance - Autoload singleton that loads and provides access to all balance data

const DATA_PATH := "res://data/balance/"

# Loaded data
var time_scale: Dictionary = {}
var careers: Dictionary = {}  # Combined positions + promotion requirements
var living_arrangements: Array = []
var travel_times: Dictionary = {}
var items: Dictionary = {}  # Keyed by item id
var items_by_store: Dictionary = {}  # Keyed by store id
var items_by_category: Dictionary = {}  # Keyed by category
var item_categories: Dictionary = {}  # Category metadata
var needs_rules: Dictionary = {}
var quotes: Dictionary = {}
var comments: Array = []
var comments_by_category: Dictionary = {}
var console_settings: Dictionary = {}
var ai_settings: Dictionary = {}
var chances: Dictionary = {}
var character_remarks: Dictionary = {}
var console_colors: Dictionary = {}
var work_settings: Dictionary = {}
var events: Dictionary = {}
var schedules: Dictionary = {}
var work_tasks: Dictionary = {}
var action_costs: Dictionary = {}
var auto_grocery: Dictionary = {}

# Branch metadata
const CATEGORIES := {
	"Business": ["Corporate", "Merchant", "Investor"],
	"Art": ["Author", "VisualArtist", "Musician"],
	"Innovation": ["Coder", "Scientist", "Engineer"]
}

const BRANCH_TO_CATEGORY := {
	"Corporate": "Business",
	"Merchant": "Business",
	"Investor": "Business",
	"Author": "Art",
	"VisualArtist": "Art",
	"Musician": "Art",
	"Coder": "Innovation",
	"Scientist": "Innovation",
	"Engineer": "Innovation"
}


func _ready() -> void:
	_load_all_data()


func _load_all_data() -> void:
	time_scale = _load_json("time_scale.json")
	quotes = _load_json("quotes.json")
	needs_rules = _load_json("needs_rules.json")
	console_settings = _load_json("console_settings.json")
	careers = _load_json("careers.json")
	ai_settings = _load_json("ai_settings.json")
	chances = _load_json("chances.json")
	character_remarks = _load_json("character_remarks.json")
	console_colors = _load_json("console_colors.json")
	work_settings = _load_json("work_settings.json")
	events = _load_json("events.json")
	schedules = _load_json("schedules.json")
	work_tasks = _load_json("work_tasks.json")
	action_costs = _load_json("action_costs.json")
	auto_grocery = _load_json("auto_grocery.json")
	
	var la_data := _load_json("living_arrangements.json")
	living_arrangements = la_data.get("arrangements", [])
	
	var tt_data := _load_json("travel_times.json")
	travel_times = tt_data.get("travel_minutes", {}).get("by_tier", {})
	
	_load_items()
	_load_comments()
	
	print("[Balance] All data loaded successfully")


func _load_json(filename: String) -> Dictionary:
	var path := DATA_PATH + filename
	if not FileAccess.file_exists(path):
		push_error("[Balance] File not found: " + path)
		return {}
	
	var file := FileAccess.open(path, FileAccess.READ)
	var json_text := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var err := json.parse(json_text)
	if err != OK:
		push_error("[Balance] JSON parse error in %s: %s" % [filename, json.get_error_message()])
		return {}
	
	return json.data


func _load_items() -> void:
	var data := _load_json("items.json")
	var items_array: Array = data.get("items", [])
	item_categories = data.get("categories", {})
	
	items.clear()
	items_by_store.clear()
	items_by_category.clear()
	items_by_store["Grocery"] = []
	items_by_store["Mall"] = []
	
	for item in items_array:
		var id: String = item.get("id", "")
		if id.is_empty():
			continue
		items[id] = item
		var store: String = item.get("store", "")
		
		# Handle "Both" store - add to both Grocery and Mall
		if store == "Both":
			items_by_store["Grocery"].append(item)
			items_by_store["Mall"].append(item)
		elif items_by_store.has(store):
			items_by_store[store].append(item)
		
		# Also organize by category
		var category: String = item.get("category", "other")
		if not items_by_category.has(category):
			items_by_category[category] = []
		items_by_category[category].append(item)


func _load_comments() -> void:
	var data := _load_json("comments.json")
	comments = data.get("comments", [])
	
	comments_by_category.clear()
	for comment in comments:
		var cat: String = comment.get("category", "general")
		if not comments_by_category.has(cat):
			comments_by_category[cat] = []
		comments_by_category[cat].append(comment)


# === Accessors ===

func get_real_seconds_per_game_minute() -> float:
	return time_scale.get("real_seconds_per_game_minute", 0.5)


func get_quote_display_seconds() -> int:
	return quotes.get("display_seconds", 7)


func get_random_quote() -> String:
	var quote_list: Array = quotes.get("quotes", [])
	if quote_list.is_empty():
		return "Stay positive!"
	return quote_list[randi() % quote_list.size()]


func get_positions_for_branch(branch: String) -> Array:
	var branches: Dictionary = careers.get("branches", {})
	var branch_data: Dictionary = branches.get(branch, {})
	return branch_data.get("positions", [])


func get_position(branch: String, level: int) -> Dictionary:
	var branch_positions := get_positions_for_branch(branch)
	for pos in branch_positions:
		if pos.get("level", 0) == level:
			return pos
	return {}


func get_position_pay(branch: String, level: int) -> int:
	var pos := get_position(branch, level)
	return pos.get("base_pay_per_hour", 0)


func get_promotion_threshold(branch: String, current_level: int) -> int:
	var pos := get_position(branch, current_level)
	var pp_to_next = pos.get("pp_to_next", null)
	if pp_to_next == null:
		return 999999  # Max level
	return int(pp_to_next)


func get_branch_data(branch: String) -> Dictionary:
	var branches: Dictionary = careers.get("branches", {})
	return branches.get(branch, {})


func get_category_data(category: String) -> Dictionary:
	var categories: Dictionary = careers.get("categories", {})
	return categories.get(category, {})


func get_all_branches() -> Array:
	return careers.get("branches", {}).keys()


func get_all_categories() -> Array:
	return careers.get("categories", {}).keys()


func get_branches_in_category(category: String) -> Array:
	var cat_data := get_category_data(category)
	return cat_data.get("branches", [])


func can_branch_create_releases(branch: String) -> bool:
	var branch_data := get_branch_data(branch)
	return branch_data.get("can_create_releases", false)


func get_branch_release_type(branch: String) -> String:
	var branch_data := get_branch_data(branch)
	return branch_data.get("release_type", "Release")


func get_branch_display_name(branch: String) -> String:
	var branch_data := get_branch_data(branch)
	return branch_data.get("display_name", branch)


func get_progression_settings() -> Dictionary:
	return careers.get("progression_settings", {})


# === Work Tasks ===

func get_random_work_task(branch: String, title: String) -> String:
	## Get a random witty task name for the given position
	var tasks_by_branch: Dictionary = work_tasks.get("tasks", {})
	var branch_tasks: Dictionary = tasks_by_branch.get(branch, {})
	var position_tasks: Array = branch_tasks.get(title, [])
	
	if position_tasks.is_empty():
		# Try fallback tasks
		var fallbacks: Array = work_tasks.get("fallback_tasks", ["Working..."])
		return fallbacks[randi() % fallbacks.size()]
	
	return position_tasks[randi() % position_tasks.size()]


func get_work_pp_settings() -> Dictionary:
	## Get PP calculation settings from work_tasks.json
	return work_tasks.get("pp_settings", {
		"base_pp_per_work": 12,
		"productivity_multiplier": 0.5,
		"reputation_bonus": 0.1,
		"stability_bonus": 0.1
	})


func calculate_work_pp(productivity: int, reputation: int, stability: int) -> float:
	## Calculate PP earned from completing one work action
	var settings := get_work_pp_settings()
	var base: float = settings.get("base_pp_per_work", 12)
	var prod_mult: float = settings.get("productivity_multiplier", 0.5)
	var rep_bonus: float = settings.get("reputation_bonus", 0.1)
	var stab_bonus: float = settings.get("stability_bonus", 0.1)
	
	# PP = base * (1 + prod * mult) * (1 + rep * bonus) * (1 + stab * bonus)
	var pp: float = base * (1.0 + productivity * prod_mult) * (1.0 + reputation * rep_bonus) * (1.0 + stability * stab_bonus)
	return pp


func get_living_arrangement(tier: int) -> Dictionary:
	for arr in living_arrangements:
		if arr.get("tier", 0) == tier:
			return arr
	return {}


func get_living_arrangement_price(tier: int) -> int:
	var arr := get_living_arrangement(tier)
	return arr.get("price", 0)


func get_travel_time(living_tier: int, store: String) -> int:
	var tier_key := str(living_tier)
	if travel_times.has(tier_key):
		return travel_times[tier_key].get(store, 30)
	return 30


func get_item(item_id: String) -> Dictionary:
	return items.get(item_id, {})


func get_all_items() -> Array:
	return items.values()


func get_items_for_store(store: String) -> Array:
	return items_by_store.get(store, [])


func get_items_by_category(category: String) -> Array:
	return items_by_category.get(category, [])


func get_item_categories() -> Array:
	return item_categories.keys()


func get_item_category_info(category: String) -> Dictionary:
	return item_categories.get(category, {})


func get_random_comment(category: String = "general") -> Dictionary:
	var pool: Array = comments_by_category.get(category, [])
	if pool.is_empty():
		pool = comments_by_category.get("general", [])
	if pool.is_empty():
		return {"text": "...", "category": "general"}
	return pool[randi() % pool.size()]


func get_needs_range(need: String) -> Dictionary:
	var ranges: Dictionary = needs_rules.get("ranges", {})
	return ranges.get(need, {"min": 0, "max": 100})


func get_hunger_penalty(hunger: int) -> int:
	var penalties: Dictionary = needs_rules.get("need_penalties", {})
	var thresholds: Array = penalties.get("hunger_thresholds", [])
	var result := 0
	for t in thresholds:
		if hunger >= t.get("at_or_above", 100):
			result = t.get("penalty", 0)
	return result


func get_rest_penalty(rest: int) -> int:
	var penalties: Dictionary = needs_rules.get("need_penalties", {})
	var thresholds: Array = penalties.get("rest_thresholds", [])
	var result := 0
	for t in thresholds:
		if rest <= t.get("at_or_below", 0):
			result = t.get("penalty", 0)
	return result


func get_mood_modifier(mood: int) -> int:
	var mm: Dictionary = needs_rules.get("mood_modifier", {})
	var neutral: int = mm.get("neutral", 50)
	var step: int = mm.get("step", 10)
	var min_val: int = mm.get("min", -3)
	var max_val: int = mm.get("max", 3)
	var raw := int(floor(float(mood - neutral) / step))
	return clampi(raw, min_val, max_val)


func get_comfort_modifier(comfort: int) -> int:
	var cm: Dictionary = needs_rules.get("comfort_modifier", {"divisor": 2, "min": -5, "max": 5})
	var divisor: int = cm.get("divisor", 2)
	var min_val: int = cm.get("min", -5)
	var max_val: int = cm.get("max", 5)
	var raw := int(floor(float(comfort) / divisor))
	return clampi(raw, min_val, max_val)


func get_demotion_rules() -> Dictionary:
	return needs_rules.get("demotion", {})


func get_console_max_lines() -> int:
	return console_settings.get("max_lines", 500)


func get_ai_settings() -> Dictionary:
	return ai_settings


func get_ai_threshold(key: String) -> int:
	var thresholds: Dictionary = ai_settings.get("priority_thresholds", {})
	return thresholds.get(key, 50)


func get_ai_action_weight(action: String) -> int:
	var weights: Dictionary = ai_settings.get("base_action_weights", {})
	return weights.get(action, 10)


# === Chances ===

func get_chance(category: String, key: String) -> int:
	var cat_data: Dictionary = chances.get(category, {})
	return cat_data.get(key, 10)


func roll_chance(category: String, key: String) -> bool:
	## Returns true if random roll succeeds against the chance percentage
	var chance: int = get_chance(category, key)
	return randi() % 100 < chance


# === Action Costs ===

func get_action_rest_cost(action_name: String) -> int:
	## Returns a random rest cost for the given action (positive = drains rest, negative = restores)
	var costs: Dictionary = action_costs.get("rest_costs", {})
	var action_data: Dictionary = costs.get(action_name.to_lower(), {})
	
	var min_cost: int = action_data.get("min", 0)
	var max_cost: int = action_data.get("max", 0)
	
	if min_cost == max_cost:
		return min_cost
	
	# Handle inverted ranges (when min > max for negative values)
	if min_cost > max_cost:
		return randi_range(max_cost, min_cost)
	
	return randi_range(min_cost, max_cost)


func get_action_hunger_cost(action_name: String) -> int:
	## Returns a random hunger cost for the given action (positive = increases hunger)
	var costs: Dictionary = action_costs.get("hunger_costs", {})
	var action_data: Dictionary = costs.get(action_name.to_lower(), {})
	
	var min_cost: int = action_data.get("min", 0)
	var max_cost: int = action_data.get("max", 0)
	
	if min_cost == max_cost:
		return min_cost
	
	return randi_range(min_cost, max_cost)


# === Auto Grocery ===

func get_grocery_budget_tier(money: int) -> Dictionary:
	## Returns the appropriate budget tier settings based on current money
	var tiers: Dictionary = auto_grocery.get("budget_tiers", {})
	var priority: Array = auto_grocery.get("priority_order", [])
	
	# Go through tiers in order (desperate -> wealthy)
	for tier_name in priority:
		var tier: Dictionary = tiers.get(tier_name, {})
		var max_money: int = tier.get("max_money", 0)
		if money <= max_money:
			tier["tier_name"] = tier_name
			return tier
	
	# Fallback to last tier
	if not priority.is_empty():
		var last_tier: String = priority[-1]
		var tier: Dictionary = tiers.get(last_tier, {})
		tier["tier_name"] = last_tier
		return tier
	
	return {}


func get_grocery_shopping_rules() -> Dictionary:
	return auto_grocery.get("shopping_rules", {})


func get_grocery_scoring() -> Dictionary:
	return auto_grocery.get("scoring", {})


# === Character Remarks ===

func get_random_remark(category: String = "general") -> String:
	var categories: Dictionary = character_remarks.get("categories", {})
	var remarks: Array = categories.get(category, [])
	if remarks.is_empty():
		remarks = categories.get("general", ["..."])
	return remarks[randi() % remarks.size()]


func get_remark_categories() -> Array:
	return character_remarks.get("categories", {}).keys()


# === Console Colors ===

func get_console_category_color(category: String) -> String:
	var colors: Dictionary = console_colors.get("category_colors", {})
	return colors.get(category, get_console_special_color("default"))


func get_console_special_color(key: String) -> String:
	var colors: Dictionary = console_colors.get("special_colors", {})
	return colors.get(key, "#b0b0b0")


func get_console_formatting() -> Dictionary:
	return console_colors.get("formatting", {})


# === Work Settings ===

func get_work_setting(category: String, key: String, default_value: Variant = 0) -> Variant:
	var cat_data: Dictionary = work_settings.get(category, {})
	return cat_data.get(key, default_value)


func get_work_settings() -> Dictionary:
	return work_settings


# === Events (not yet implemented) ===

func get_events_enabled() -> bool:
	var settings: Dictionary = events.get("event_settings", {})
	return settings.get("enabled", false)


func get_event_by_id(event_id: String) -> Dictionary:
	var event_list: Array = events.get("events", [])
	for event in event_list:
		if event.get("id", "") == event_id:
			return event
	return {}


func get_events_by_category(category: String) -> Array:
	var event_list: Array = events.get("events", [])
	var filtered: Array = []
	for event in event_list:
		if event.get("category", "") == category:
			filtered.append(event)
	return filtered


# === Schedules ===

func is_location_open(location_id: String, hour: int) -> bool:
	## Check if a location is open at the given hour
	var locations: Dictionary = schedules.get("locations", {})
	var loc: Dictionary = locations.get(location_id, {})
	
	if loc.get("always_open", false):
		return true
	
	var open_hour: int = loc.get("open_hour", 0)
	var close_hour: int = loc.get("close_hour", 24)
	
	return hour >= open_hour and hour < close_hour


func get_location_closed_message(location_id: String) -> String:
	## Get the closed message for a location
	var locations: Dictionary = schedules.get("locations", {})
	var loc: Dictionary = locations.get(location_id, {})
	return loc.get("closed_message", "%s is closed" % location_id)


func get_location_hours_string(location_id: String) -> String:
	## Get a human-readable hours string for a location
	var locations: Dictionary = schedules.get("locations", {})
	var loc: Dictionary = locations.get(location_id, {})
	
	if loc.get("always_open", false):
		return "24 hours"
	
	var open_hour: int = loc.get("open_hour", 0)
	var close_hour: int = loc.get("close_hour", 24)
	
	var open_str := "%d:00 %s" % [open_hour if open_hour <= 12 else open_hour - 12, "AM" if open_hour < 12 else "PM"]
	var close_str := "%d:00 %s" % [close_hour if close_hour <= 12 else close_hour - 12, "AM" if close_hour < 12 else "PM"]
	
	return "%s - %s" % [open_str, close_str]


func get_ideal_sleep_hours() -> Dictionary:
	return schedules.get("ideal_sleep_hours", {"start": 22, "end": 6})

