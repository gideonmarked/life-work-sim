extends Control
## GameScreen - Main gameplay screen with action queue and floating windows

# Window controls
@onready var close_btn: Button = $CloseBtn
@onready var move_btn: Button = $MoveBtn
@onready var hover_fade_timer: Timer = $HoverFadeTimer

# Top bar
@onready var time_label: Label = $TopBar/HBox/TimeLabel
@onready var money_label: Label = $TopBar/HBox/MoneyLabel
@onready var character_label: Label = $TopBar/HBox/CharacterLabel

# Left panel - needs
@onready var hunger_bar: ProgressBar = $MainContainer/LeftPanel/VBox/NeedsContainer/HungerBar/Bar
@onready var hunger_val: Label = $MainContainer/LeftPanel/VBox/NeedsContainer/HungerBar/Val
@onready var rest_bar: ProgressBar = $MainContainer/LeftPanel/VBox/NeedsContainer/RestBar/Bar
@onready var rest_val: Label = $MainContainer/LeftPanel/VBox/NeedsContainer/RestBar/Val
@onready var mood_bar: ProgressBar = $MainContainer/LeftPanel/VBox/NeedsContainer/MoodBar/Bar
@onready var mood_val: Label = $MainContainer/LeftPanel/VBox/NeedsContainer/MoodBar/Val

# Left panel - career stats
@onready var comfort_label: Label = $MainContainer/LeftPanel/VBox/CareerStatsContainer/ComfortLabel
@onready var productivity_label: Label = $MainContainer/LeftPanel/VBox/CareerStatsContainer/ProductivityLabel
@onready var reputation_label: Label = $MainContainer/LeftPanel/VBox/CareerStatsContainer/ReputationLabel
@onready var stability_label: Label = $MainContainer/LeftPanel/VBox/CareerStatsContainer/StabilityLabel

# Left panel - progress
@onready var progress_bar: ProgressBar = $MainContainer/LeftPanel/VBox/ProgressContainer/ProgressBar
@onready var progress_label: Label = $MainContainer/LeftPanel/VBox/ProgressContainer/ProgressLabel
@onready var living_label: Label = $MainContainer/LeftPanel/VBox/LivingLabel
@onready var storage_label: Label = $MainContainer/LeftPanel/VBox/StorageLabel
@onready var royalties_label: Label = $MainContainer/LeftPanel/VBox/RoyaltiesLabel

# Center panel
@onready var comment_label: Label = $MainContainer/CenterPanel/CenterVBox/CommentLabel
@onready var quote_overlay: Panel = $MainContainer/CenterPanel/QuoteOverlay
@onready var quote_label: Label = $MainContainer/CenterPanel/QuoteOverlay/QuoteLabel

# Right panel - Action Queue
@onready var current_action_label: Label = $MainContainer/RightPanel/VBox/CurrentActionPanel/CurrentVBox/CurrentActionLabel
@onready var current_time_label: Label = $MainContainer/RightPanel/VBox/CurrentActionPanel/CurrentVBox/CurrentTimeLabel
@onready var current_progress_bar: ProgressBar = $MainContainer/RightPanel/VBox/CurrentActionPanel/CurrentVBox/CurrentProgressBar
@onready var queue_container: VBoxContainer = $MainContainer/RightPanel/VBox/QueueContainer

# Action buttons
@onready var work_btn: Button = $MainContainer/RightPanel/VBox/AddActionContainer/Row1/WorkBtn
@onready var sleep_btn: Button = $MainContainer/RightPanel/VBox/AddActionContainer/Row1/SleepBtn
@onready var rest_btn: Button = $MainContainer/RightPanel/VBox/AddActionContainer/Row1/RestBtn
@onready var grocery_btn: Button = $MainContainer/RightPanel/VBox/AddActionContainer/Row2/GroceryBtn
@onready var mall_btn: Button = $MainContainer/RightPanel/VBox/AddActionContainer/Row2/MallBtn
@onready var skip_btn: Button = $MainContainer/RightPanel/VBox/AddActionContainer/Row2/SkipBtn

# Bottom bar
@onready var status_label: Label = $BottomBar/HBox/StatusLabel
@onready var ai_btn: Button = $BottomBar/HBox/AIBtn
@onready var speed_1x: Button = $BottomBar/HBox/SpeedContainer/Speed1x
@onready var speed_2x: Button = $BottomBar/HBox/SpeedContainer/Speed2x
@onready var speed_5x: Button = $BottomBar/HBox/SpeedContainer/Speed5x
@onready var speed_10x: Button = $BottomBar/HBox/SpeedContainer/Speed10x
@onready var pause_btn: Button = $BottomBar/HBox/SpeedContainer/PauseBtn
@onready var console_btn: Button = $BottomBar/HBox/ConsoleBtn
@onready var inventory_btn: Button = $BottomBar/HBox/InventoryBtn
@onready var housing_btn: Button = $BottomBar/HBox/HousingBtn
@onready var save_btn: Button = $BottomBar/HBox/SaveBtn
@onready var menu_btn: Button = $BottomBar/HBox/MenuBtn

# Floating windows
@onready var console_window: Panel = $FloatingWindows/ConsoleWindow
@onready var console_log: RichTextLabel = $FloatingWindows/ConsoleWindow/Content/ConsoleScroll/ConsoleLog
@onready var inventory_window: Panel = $FloatingWindows/InventoryWindow
@onready var inv_items: VBoxContainer = $FloatingWindows/InventoryWindow/Content/InvScroll/InvItems
@onready var housing_window: Panel = $FloatingWindows/HousingWindow
@onready var housing_current_label: Label = $FloatingWindows/HousingWindow/Content/VBox/CurrentLabel
@onready var housing_items: VBoxContainer = $FloatingWindows/HousingWindow/Content/VBox/HousingScroll/HousingItems

# Career window
@onready var career_btn: Button = $BottomBar/HBox/CareerBtn
@onready var career_window: Panel = $FloatingWindows/CareerWindow
@onready var career_branch_label: Label = $FloatingWindows/CareerWindow/Content/HBox/LeftVBox/BranchLabel
@onready var career_title_label: Label = $FloatingWindows/CareerWindow/Content/HBox/LeftVBox/TitleLabel
@onready var career_level_label: Label = $FloatingWindows/CareerWindow/Content/HBox/LeftVBox/LevelLabel
@onready var career_base_pay: Label = $FloatingWindows/CareerWindow/Content/HBox/LeftVBox/BasePayLabel
@onready var career_ep_label: Label = $FloatingWindows/CareerWindow/Content/HBox/LeftVBox/EPLabel
@onready var career_hourly_label: Label = $FloatingWindows/CareerWindow/Content/HBox/LeftVBox/HourlyLabel
@onready var career_daily_label: Label = $FloatingWindows/CareerWindow/Content/HBox/LeftVBox/DailyLabel
@onready var career_next_pos: Label = $FloatingWindows/CareerWindow/Content/HBox/LeftVBox/NextPosLabel
@onready var career_next_pay: Label = $FloatingWindows/CareerWindow/Content/HBox/LeftVBox/NextPayLabel
@onready var career_req_pp: Label = $FloatingWindows/CareerWindow/Content/HBox/LeftVBox/ReqPPLabel
@onready var career_req_items: Label = $FloatingWindows/CareerWindow/Content/HBox/LeftVBox/ReqItemsLabel
@onready var career_branch_select: OptionButton = $FloatingWindows/CareerWindow/Content/HBox/RightVBox/BranchSelect
@onready var career_tree_items: VBoxContainer = $FloatingWindows/CareerWindow/Content/HBox/RightVBox/TreeScroll/TreeItems

# Daily stats overlay
@onready var daily_stats_overlay: Panel = $DailyStatsOverlay
@onready var daily_title: Label = $DailyStatsOverlay/CenterContainer/StatsPanel/VBox/Title
@onready var daily_money_value: Label = $DailyStatsOverlay/CenterContainer/StatsPanel/VBox/StatsGrid/MoneyValue
@onready var daily_earned_value: Label = $DailyStatsOverlay/CenterContainer/StatsPanel/VBox/StatsGrid/EarnedValue
@onready var daily_spent_value: Label = $DailyStatsOverlay/CenterContainer/StatsPanel/VBox/StatsGrid/SpentValue
@onready var daily_royalties_value: Label = $DailyStatsOverlay/CenterContainer/StatsPanel/VBox/StatsGrid/RoyaltiesValue
@onready var daily_promotion_label: Label = $DailyStatsOverlay/CenterContainer/StatsPanel/VBox/PromotionLabel
@onready var daily_position_label: Label = $DailyStatsOverlay/CenterContainer/StatsPanel/VBox/PositionLabel
@onready var daily_progress_label: Label = $DailyStatsOverlay/CenterContainer/StatsPanel/VBox/ProgressLabel
@onready var daily_hours_label: Label = $DailyStatsOverlay/CenterContainer/StatsPanel/VBox/HoursWorkedLabel
@onready var daily_hunger_label: Label = $DailyStatsOverlay/CenterContainer/StatsPanel/VBox/NeedsGrid/HungerLabel
@onready var daily_rest_label: Label = $DailyStatsOverlay/CenterContainer/StatsPanel/VBox/NeedsGrid/RestLabel
@onready var daily_mood_label: Label = $DailyStatsOverlay/CenterContainer/StatsPanel/VBox/NeedsGrid/MoodLabel
@onready var daily_saved_label: Label = $DailyStatsOverlay/CenterContainer/StatsPanel/VBox/SavedLabel
@onready var daily_continue_btn: Button = $DailyStatsOverlay/CenterContainer/StatsPanel/VBox/ContinueBtn
@onready var auto_continue_timer: Timer = $DailyStatsOverlay/AutoContinueTimer

var _quote_timer: float = 0.0
var _auto_continue_seconds: int = 60

# Daily tracking
var _day_start_money: int = 0
var _last_tracked_money: int = 0
var _money_earned_today: int = 0
var _money_spent_today: int = 0
var _royalties_earned_today: int = 0
var _hours_worked_today: int = 0
var _promoted_today: bool = false
var _promotion_title: String = ""

# Window control state
var _is_dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
var _mouse_inside: bool = false
var _controls_visible: bool = false
var _fade_tween: Tween = null

const FADE_DURATION := 0.2


func _ready() -> void:
	print("[GameScreen] _ready() starting")
	_setup_window_controls()
	_connect_signals()
	_update_all_ui()
	# Rebuild console to show any existing log entries (from loaded save)
	_rebuild_console_from_log()
	# Open console window by default
	console_window.visible = true
	print("[GameScreen] About to start time")
	# Resume time if paused (TimeManager.start() is called in GameState.new_game())
	# Only call resume() - start() was already called for new games
	if TimeManager.is_paused():
		print("[GameScreen] TimeManager was paused, resuming")
		TimeManager.resume()
	else:
		print("[GameScreen] TimeManager already running")
	print("[GameScreen] Time started, is_paused: %s" % TimeManager.is_paused())


func _process(delta: float) -> void:
	if _quote_timer > 0:
		_quote_timer -= delta
		if _quote_timer <= 0:
			quote_overlay.visible = false
	
	# Handle window dragging (only works in standalone window, not embedded)
	if _is_dragging and not _is_embedded():
		var window := get_window()
		window.position = DisplayServer.mouse_get_position() - Vector2i(_drag_offset)


func _input(event: InputEvent) -> void:
	# Track mouse entering/leaving window
	if event is InputEventMouseMotion:
		var mouse_pos := get_global_mouse_position()
		var rect := get_rect()
		var was_inside := _mouse_inside
		_mouse_inside = rect.has_point(mouse_pos)
		
		if _mouse_inside and not was_inside:
			_on_mouse_entered_window()
		elif not _mouse_inside and was_inside:
			_on_mouse_exited_window()
	
	# Handle drag release
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_is_dragging = false


func _setup_window_controls() -> void:
	# Initially hide window controls
	close_btn.modulate.a = 0.0
	move_btn.modulate.a = 0.0
	
	# Connect signals
	close_btn.pressed.connect(_on_close_window)
	move_btn.button_down.connect(_on_move_button_down)
	move_btn.button_up.connect(_on_move_button_up)
	hover_fade_timer.timeout.connect(_on_hover_fade_timeout)
	mouse_entered.connect(_on_mouse_entered_window)
	mouse_exited.connect(_on_mouse_exited_window)


func _on_mouse_entered_window() -> void:
	_mouse_inside = true
	hover_fade_timer.stop()
	_show_window_controls()


func _on_mouse_exited_window() -> void:
	_mouse_inside = false
	hover_fade_timer.start()


func _on_hover_fade_timeout() -> void:
	if not _mouse_inside and not _is_dragging:
		_hide_window_controls()


func _show_window_controls() -> void:
	if _controls_visible:
		return
	_controls_visible = true
	
	if _fade_tween:
		_fade_tween.kill()
	
	_fade_tween = create_tween()
	_fade_tween.set_parallel(true)
	_fade_tween.tween_property(close_btn, "modulate:a", 1.0, FADE_DURATION)
	_fade_tween.tween_property(move_btn, "modulate:a", 1.0, FADE_DURATION)


func _hide_window_controls() -> void:
	if not _controls_visible:
		return
	_controls_visible = false
	
	if _fade_tween:
		_fade_tween.kill()
	
	_fade_tween = create_tween()
	_fade_tween.set_parallel(true)
	_fade_tween.tween_property(close_btn, "modulate:a", 0.0, FADE_DURATION)
	_fade_tween.tween_property(move_btn, "modulate:a", 0.0, FADE_DURATION)


func _is_embedded() -> bool:
	# Check if running in editor (window can't be moved in embedded mode)
	return OS.has_feature("editor")


func _on_close_window() -> void:
	get_tree().quit()


func _on_move_button_down() -> void:
	if not _is_embedded():
		_is_dragging = true
		_drag_offset = get_global_mouse_position()


func _on_move_button_up() -> void:
	_is_dragging = false


func _connect_signals() -> void:
	# Time signals
	TimeManager.minute_passed.connect(_on_minute_passed)
	TimeManager.day_started.connect(_on_day_started)
	TimeManager.day_ended.connect(_on_day_ended)
	
	# GameState signals
	GameState.money_changed.connect(_on_money_changed)
	GameState.stats_changed.connect(_on_stats_changed)
	GameState.needs_changed.connect(_on_needs_changed)
	GameState.position_changed.connect(_on_position_changed)
	GameState.inventory_changed.connect(_on_inventory_changed)
	
	# ActionQueue signals
	ActionQueue.action_started.connect(_on_action_started)
	ActionQueue.action_completed.connect(_on_action_completed)
	ActionQueue.action_progress.connect(_on_action_progress)
	ActionQueue.queue_changed.connect(_on_queue_changed)
	
	# Console signals
	ConsoleLog.entry_added.connect(_on_console_entry)
	
	# CharacterAI signals
	CharacterAI.decision_made.connect(_on_ai_decision)
	
	# Action buttons
	work_btn.pressed.connect(_on_work_pressed)
	sleep_btn.pressed.connect(_on_sleep_pressed)
	rest_btn.pressed.connect(_on_rest_pressed)
	grocery_btn.pressed.connect(_on_grocery_pressed)
	mall_btn.pressed.connect(_on_mall_pressed)
	skip_btn.pressed.connect(_on_skip_pressed)
	
	# Bottom bar buttons
	ai_btn.toggled.connect(_on_ai_toggled)
	ai_btn.button_pressed = CharacterAI.is_enabled()
	_update_ai_button_text()
	console_btn.pressed.connect(_on_console_pressed)
	inventory_btn.pressed.connect(_on_inventory_pressed)
	housing_btn.pressed.connect(_on_housing_pressed)
	career_btn.pressed.connect(_on_career_pressed)
	save_btn.pressed.connect(_on_save_pressed)
	menu_btn.pressed.connect(_on_menu_pressed)
	
	# Speed buttons
	speed_1x.pressed.connect(_on_speed_1x)
	speed_2x.pressed.connect(_on_speed_2x)
	speed_5x.pressed.connect(_on_speed_5x)
	speed_10x.pressed.connect(_on_speed_10x)
	pause_btn.toggled.connect(_on_pause_toggled)
	
	# Floating window close buttons
	console_window.close_requested.connect(func(): console_window.visible = false)
	inventory_window.close_requested.connect(func(): inventory_window.visible = false)
	housing_window.close_requested.connect(func(): housing_window.visible = false)
	career_window.close_requested.connect(func(): career_window.visible = false)
	career_branch_select.item_selected.connect(_on_career_branch_selected)
	
	# Daily stats overlay
	daily_continue_btn.pressed.connect(_on_daily_continue_pressed)
	auto_continue_timer.timeout.connect(_on_auto_continue_tick)
	
	# Initialize career branch selector
	_init_career_branch_selector()
	
	# Initialize daily tracking
	_day_start_money = GameState.money
	_last_tracked_money = GameState.money


func _update_all_ui() -> void:
	_update_time_display()
	_update_money_display()
	_update_character_display()
	_update_needs_display()
	_update_stats_display()
	_update_progress_display()
	_update_queue_display()


func _update_time_display() -> void:
	var mem_mb := OS.get_static_memory_usage() / 1048576.0
	time_label.text = "%s | MEM: %.1fMB" % [TimeManager.get_day_time_string(), mem_mb]


func _update_money_display() -> void:
	money_label.text = "%d coins" % GameState.money


func _update_character_display() -> void:
	var title := GameState.get_position_title()
	var branch := GameState.branch
	if branch == "VisualArtist":
		branch = "Visual Artist"
	character_label.text = "%s - %s (%s Lv%d)" % [
		GameState.character_name,
		title,
		branch,
		GameState.position_level
	]


func _update_needs_display() -> void:
	# Belly Alarm: invert hunger so 100 = full, 0 = starving
	var belly_alarm: int = 100 - GameState.hunger
	hunger_bar.value = belly_alarm
	hunger_val.text = str(belly_alarm)
	hunger_val.add_theme_color_override("font_color", _get_need_color(belly_alarm))
	
	rest_bar.value = GameState.rest
	rest_val.text = str(GameState.rest)
	rest_val.add_theme_color_override("font_color", _get_need_color(GameState.rest))
	
	mood_bar.value = GameState.mood
	mood_val.text = str(GameState.mood)
	mood_val.add_theme_color_override("font_color", _get_need_color(GameState.mood))


func _get_need_color(value: int) -> Color:
	## Returns color based on need value: red (0-15), yellow (16-74), green (75-100)
	if value <= 15:
		return Color(1.0, 0.3, 0.3)  # Red - danger
	elif value <= 74:
		return Color(1.0, 0.85, 0.3)  # Yellow - caution
	else:
		return Color(0.3, 1.0, 0.4)  # Green - good


func _update_stats_display() -> void:
	var comfort := GameState.get_total_comfort()
	var productivity := GameState.get_total_productivity()
	var reputation := GameState.get_total_reputation()
	var stability := GameState.get_total_stability()
	
	comfort_label.text = "Back Pain Index: %d" % comfort
	productivity_label.text = "Focus Fuel: %d (EP:%d)" % [productivity, GameState.calculate_effective_productivity()]
	reputation_label.text = "Street Cred: %d" % reputation
	stability_label.text = "Panic Control: %d" % stability
	
	living_label.text = "Living: %s" % GameState.get_living_name()
	var pocket_count: int = GameState.character_inventory.size()
	var home_count: int = GameState.la_inventory.size()
	storage_label.text = "Hoard Capacity: %d/%d (P) + %d/%d (H)" % [
		pocket_count, GameState.MAX_CHARACTER_INVENTORY,
		home_count, GameState.max_la_inventory_slots
	]
	
	# Calculate total royalties income
	var total_royalty := 0
	for royalty in GameState.active_royalties:
		total_royalty += royalty.get("monthly_amount", 0)
	
	if total_royalty > 0:
		royalties_label.text = "Royalties: %d/day (%d)" % [total_royalty, GameState.active_royalties.size()]
		royalties_label.visible = true
	else:
		royalties_label.visible = GameState.can_create_release()
		if royalties_label.visible:
			royalties_label.text = "Royalties: 0/day"


func _update_progress_display() -> void:
	var threshold := Balance.get_promotion_threshold(GameState.branch, GameState.position_level)
	var pp := GameState.progress_points
	
	progress_bar.max_value = threshold
	progress_bar.value = pp
	progress_label.text = "%.0f / %d PP" % [pp, threshold]


func _update_queue_display() -> void:
	# Update current action
	var current := ActionQueue.get_current_action()
	if not current.is_empty():
		current_action_label.text = "%s %s" % [current.get("icon", "○"), current.get("name", "Idle")]
		current_time_label.text = ActionQueue.get_time_remaining_string() + " remaining"
		current_progress_bar.value = ActionQueue.get_progress_percent()
		status_label.text = "Status: %s" % current.get("name", "Idle")
	
	# Update queue (FIFO display - first added at top)
	var queue := ActionQueue.get_queue()
	var queue_labels := queue_container.get_children()
	
	for i in range(queue_labels.size()):
		var label: Label = queue_labels[i]
		if i < queue.size():
			var action: Dictionary = queue[i]
			label.text = "%d. %s %s (%dm)" % [
				i + 1,
				action.get("icon", "○"),
				action.get("name", "Idle"),
				action.get("duration", 30)
			]
			label.modulate.a = 1.0 - (i * 0.1)  # Fade out later items
		else:
			label.text = "%d. - empty -" % [i + 1]
			label.modulate.a = 0.3


# === Signal handlers ===

func _on_minute_passed(_time: Dictionary) -> void:
	_update_time_display()
	_update_needs_display()
	_update_progress_display()
	# Live update career window if visible (PP changes while working)
	if career_window.visible:
		_update_career_progress_labels()


func _on_day_started(_day: int) -> void:
	DebugProfiler.log_function_enter("GameScreen._on_day_started(%d)" % _day)
	# Reset daily tracking for new day
	_day_start_money = GameState.money
	_last_tracked_money = GameState.money
	_money_earned_today = 0
	_money_spent_today = 0
	_royalties_earned_today = 0
	_hours_worked_today = 0
	_promoted_today = false
	_promotion_title = ""
	
	# Show morning quote
	var quote := Balance.get_random_quote()
	quote_label.text = '"%s"' % quote
	quote_overlay.visible = true
	_quote_timer = Balance.get_quote_display_seconds()
	DebugProfiler.log_function_exit("GameScreen._on_day_started")


func _on_day_ended(day: int) -> void:
	DebugProfiler.log_function_enter("GameScreen._on_day_ended(%d)" % day)
	# Pause the game
	TimeManager.pause()
	ActionQueue.pause()
	
	# Auto-save to current slot
	SaveManager.save_to_current_slot()
	var slot := SaveManager.get_current_slot()
	
	# Log daily summary to console
	_log_daily_summary(day, slot)
	
	# Show daily stats
	_show_daily_stats(day)
	DebugProfiler.log_function_exit("GameScreen._on_day_ended")


func _log_daily_summary(day: int, save_slot: int) -> void:
	ConsoleLog.log_system("═══════════════════════════════════")
	ConsoleLog.log_system("       DAY %d COMPLETE" % day)
	ConsoleLog.log_system("═══════════════════════════════════")
	
	# Promotion notification (if applicable)
	if _promoted_today:
		ConsoleLog.log_promotion("🎉 You were PROMOTED today!")
		ConsoleLog.log_promotion("New Title: %s (Level %d)" % [_promotion_title, GameState.position_level])
	
	# Money summary
	var money_change: int = GameState.money - _day_start_money
	var change_str: String = ""
	if money_change >= 0:
		change_str = "+%d" % money_change
	else:
		change_str = "%d" % money_change
	ConsoleLog.log_stats("Money: %d coins (%s)" % [GameState.money, change_str])
	ConsoleLog.log_stats("Earned Today: %d coins" % _money_earned_today)
	ConsoleLog.log_stats("Spent Today: %d coins" % _money_spent_today)
	
	# Royalties
	var royalty_income: int = 0
	for royalty: Dictionary in GameState.active_royalties:
		royalty_income += royalty.get("monthly_amount", 0)
	if royalty_income > 0 or GameState.active_royalties.size() > 0:
		ConsoleLog.log_royalty("Royalties: %d coins (%d active)" % [royalty_income, GameState.active_royalties.size()])
	
	# Position and progress
	var branch_display: String = GameState.branch
	if branch_display == "VisualArtist":
		branch_display = "Visual Artist"
	ConsoleLog.log_work("Position: %s (%s Lv%d)" % [
		GameState.get_position_title(),
		branch_display,
		GameState.position_level
	])
	
	var threshold := Balance.get_promotion_threshold(GameState.branch, GameState.position_level)
	ConsoleLog.log_work("Progress: %.0f / %d PP (%.1f%%)" % [
		GameState.progress_points,
		threshold,
		(GameState.progress_points / float(threshold)) * 100.0 if threshold > 0 else 0.0
	])
	ConsoleLog.log_work("Hours Worked: %d" % _hours_worked_today)
	
	# Needs status
	ConsoleLog.log_stats("End of Day Status:")
	ConsoleLog.log_stats("  Belly Alarm: %d | Eye-Lid Budget: %d | Vibe Spice: %d" % [
		100 - GameState.hunger,  # Inverted: 100 = full, 0 = starving
		GameState.rest,
		GameState.mood
	])
	
	# Stats
	ConsoleLog.log_stats("  Back Pain Index: %d | Focus Fuel: %d | EP: %d" % [
		GameState.get_total_comfort(),
		GameState.get_total_productivity(),
		GameState.calculate_effective_productivity()
	])
	ConsoleLog.log_stats("  Street Cred: %d | Panic Control: %d" % [
		GameState.get_total_reputation(),
		GameState.get_total_stability()
	])
	
	# Living situation
	ConsoleLog.log_stats("Living: %s (Tier %d)" % [GameState.get_living_name(), GameState.living_tier])
	ConsoleLog.log_stats("Hoard Capacity: %d/%d slots used" % [GameState.get_total_items_count(), GameState.get_total_inventory_space()])
	
	# Save confirmation
	ConsoleLog.log_system("Game auto-saved to slot %d" % save_slot)
	ConsoleLog.log_system("═══════════════════════════════════")


func _show_daily_stats(day: int) -> void:
	# Calculate money change
	var money_change: int = GameState.money - _day_start_money
	var change_str: String = ""
	if money_change >= 0:
		change_str = "(+%d)" % money_change
	else:
		change_str = "(%d)" % money_change
	
	# Calculate royalties from active royalties (these were paid at day start)
	var royalty_income: int = 0
	for royalty: Dictionary in GameState.active_royalties:
		royalty_income += royalty.get("monthly_amount", 0)
	
	# Update overlay labels
	daily_title.text = "DAY %d COMPLETE" % day
	daily_money_value.text = "%d coins %s" % [GameState.money, change_str]
	daily_earned_value.text = "%d coins" % _money_earned_today
	daily_spent_value.text = "%d coins" % _money_spent_today
	daily_royalties_value.text = "%d coins" % royalty_income
	
	# Show promotion if it happened today
	if _promoted_today:
		daily_promotion_label.text = "🎉 PROMOTED to: %s!" % _promotion_title
		daily_promotion_label.visible = true
	else:
		daily_promotion_label.visible = false
	
	# Position info
	var branch_display: String = GameState.branch
	if branch_display == "VisualArtist":
		branch_display = "Visual Artist"
	daily_position_label.text = "Position: %s (%s Lv%d)" % [
		GameState.get_position_title(),
		branch_display,
		GameState.position_level
	]
	
	# Progress
	var threshold := Balance.get_promotion_threshold(GameState.branch, GameState.position_level)
	daily_progress_label.text = "Progress: %.0f / %d PP" % [GameState.progress_points, threshold]
	daily_hours_label.text = "Hours Worked: %d" % _hours_worked_today
	
	# Needs (Belly Alarm is inverted: 100 - hunger)
	daily_hunger_label.text = "Belly Alarm: %d" % (100 - GameState.hunger)
	daily_rest_label.text = "Eye-Lid Budget: %d" % GameState.rest
	daily_mood_label.text = "Vibe Spice: %d" % GameState.mood
	
	# Saved message
	daily_saved_label.text = "Game auto-saved."
	
	# Start auto-continue countdown
	_auto_continue_seconds = 60
	daily_continue_btn.text = "Continue (%ds)" % _auto_continue_seconds
	auto_continue_timer.start(1.0)
	
	# Show overlay
	daily_stats_overlay.visible = true


func _on_daily_continue_pressed() -> void:
	_close_daily_stats()


func _on_auto_continue_tick() -> void:
	_auto_continue_seconds -= 1
	daily_continue_btn.text = "Continue (%ds)" % _auto_continue_seconds
	
	if _auto_continue_seconds <= 0:
		_close_daily_stats()
	else:
		auto_continue_timer.start(1.0)


func _close_daily_stats() -> void:
	auto_continue_timer.stop()
	daily_stats_overlay.visible = false
	
	# Log continuation
	ConsoleLog.log_system("Continuing to Day %d..." % (TimeManager.current_day + 1))
	
	# Resume game
	TimeManager.resume()
	ActionQueue.resume()


func _on_money_changed(new_amount: int) -> void:
	# Track money changes for daily stats
	if _last_tracked_money > 0:
		var diff: int = new_amount - _last_tracked_money
		if diff > 0:
			_money_earned_today += diff
		elif diff < 0:
			_money_spent_today += abs(diff)
	_last_tracked_money = new_amount
	
	_update_money_display()


func _on_stats_changed() -> void:
	_update_stats_display()
	_update_progress_display()
	# Live update career window if visible
	if career_window.visible:
		_populate_career_window()


func _on_needs_changed() -> void:
	_update_needs_display()


func _on_position_changed(_branch: String, _level: int, title: String) -> void:
	_update_character_display()
	_update_progress_display()
	_update_stats_display()  # Salary info changes with position
	# Refresh career window if visible
	if career_window.visible:
		_populate_career_window()
	# Track promotion for daily summary
	_promoted_today = true
	_promotion_title = title


func _on_inventory_changed() -> void:
	_update_stats_display()
	if inventory_window.visible:
		_populate_inventory()


func _on_action_started(_action: Dictionary) -> void:
	_update_queue_display()


func _on_action_completed(action: Dictionary) -> void:
	_update_queue_display()
	
	# Track work hours for daily stats
	if action.get("type", -1) == ActionQueue.ActionType.WORK:
		var duration: int = action.get("duration", 60)
		_hours_worked_today += duration / 60  # Convert minutes to hours


func _on_action_progress(_action: Dictionary, _remaining: float) -> void:
	_update_queue_display()


func _on_queue_changed() -> void:
	_update_queue_display()


const CONSOLE_MAX_LINES := 500  # Prevent unbounded text growth
var _console_needs_rebuild := false

func _on_console_entry(entry: Dictionary) -> void:
	var category: String = entry.get("category", "SYSTEM")
	var color := _get_category_color(category)
	var timestamp_color := Balance.get_console_special_color("timestamp")
	var time_str: String = entry.get("ts_game", "00:00")
	var day: int = entry.get("day", 1)
	var message: String = entry.get("message", "")
	
	# Format with colored category tag (colors loaded from config)
	var formatted: String = "[color=%s][Day %d %s][/color] [color=%s][%s][/color] %s" % [
		timestamp_color, day, time_str, color, category, message
	]
	console_log.append_text(formatted + "\n")
	
	# Prevent memory leak: mark for rebuild if too many lines
	var line_count := console_log.get_line_count()
	if line_count > CONSOLE_MAX_LINES:
		_console_needs_rebuild = true
		# Rebuild will happen when console is opened or on next tick
		if console_window.visible:
			_rebuild_console_from_log()
			_console_needs_rebuild = false


func _get_category_color(category: String) -> String:
	# Load colors from Balance config file
	return Balance.get_console_category_color(category)


func _rebuild_console_from_log() -> void:
	## Rebuild console text from all stored entries
	console_log.clear()
	
	var all_entries: Array = ConsoleLog.get_recent(CONSOLE_MAX_LINES)
	
	if all_entries.is_empty():
		console_log.append_text("[color=#666]Console initialized...[/color]")
		return
	
	for entry: Dictionary in all_entries:
		var category: String = entry.get("category", "SYSTEM")
		var color := _get_category_color(category)
		var timestamp_color := Balance.get_console_special_color("timestamp")
		var time_str: String = entry.get("ts_game", "00:00")
		var day: int = entry.get("day", 1)
		var message: String = entry.get("message", "")
		
		var formatted: String = "[color=%s][Day %d %s][/color] [color=%s][%s][/color] %s" % [
			timestamp_color, day, time_str, color, category, message
		]
		console_log.append_text(formatted + "\n")


# === Action handlers ===

func _on_work_pressed() -> void:
	ConsoleLog.log_input("Player queued: Work (60min)")
	ActionQueue.add_action(ActionQueue.ActionType.WORK, {"duration": 60})


func _on_sleep_pressed() -> void:
	# Sleep is only allowed at night (9pm - 6am)
	var hour := TimeManager.current_hour
	var is_nighttime: bool = hour >= 21 or hour < 6
	if not is_nighttime:
		ConsoleLog.log_warning("Can only sleep at night (9pm - 6am)")
		return
	ConsoleLog.log_input("Player queued: Sleep")
	ActionQueue.add_action(ActionQueue.ActionType.SLEEP)


func _on_rest_pressed() -> void:
	ConsoleLog.log_input("Player queued: Rest (30min)")
	ActionQueue.add_action(ActionQueue.ActionType.REST, {"duration": 30})


func _on_grocery_pressed() -> void:
	var hour := TimeManager.current_hour
	if not Balance.is_location_open("Grocery", hour):
		ConsoleLog.log_warning(Balance.get_location_closed_message("Grocery"))
		return
	ConsoleLog.log_input("Player queued: Travel to Grocery")
	ActionQueue.add_action(ActionQueue.ActionType.TRAVEL_GROCERY)


func _on_mall_pressed() -> void:
	var hour := TimeManager.current_hour
	if not Balance.is_location_open("Mall", hour):
		ConsoleLog.log_warning(Balance.get_location_closed_message("Mall"))
		return
	ConsoleLog.log_input("Player queued: Travel to Mall")
	ActionQueue.add_action(ActionQueue.ActionType.TRAVEL_MALL)


func _on_skip_pressed() -> void:
	ConsoleLog.log_input("Player skipped current action")
	ActionQueue.skip_current()


# === Floating window handlers ===

func _on_console_pressed() -> void:
	console_window.visible = not console_window.visible
	if console_window.visible:
		console_window.bring_to_front()
		# Rebuild console to show all past entries (or if needs rebuild due to overflow)
		if _console_needs_rebuild or console_log.get_parsed_text().length() < 100:
			_rebuild_console_from_log()
			_console_needs_rebuild = false


func _on_inventory_pressed() -> void:
	inventory_window.visible = not inventory_window.visible
	if inventory_window.visible:
		inventory_window.bring_to_front()
		_populate_inventory()


func _on_housing_pressed() -> void:
	housing_window.visible = not housing_window.visible
	if housing_window.visible:
		housing_window.bring_to_front()
		_populate_housing()


func _populate_inventory() -> void:
	## Populate Character window - Fashion + Pocket (character inventory)
	for child in inv_items.get_children():
		child.queue_free()
	
	# === Fashion Section ===
	var fashion_header := Label.new()
	fashion_header.text = "👔 Fashion"
	fashion_header.add_theme_color_override("font_color", Color(0.9, 0.6, 0.8))
	fashion_header.add_theme_font_size_override("font_size", 11)
	inv_items.add_child(fashion_header)
	
	_add_fashion_slot_row("Headgear", "headgear")
	_add_fashion_slot_row("Top", "top")
	_add_fashion_slot_row("Bottom", "bottom")
	_add_fashion_slot_row("Shoes", "shoes")
	
	# Add separator
	var sep1 := HSeparator.new()
	sep1.custom_minimum_size = Vector2(0, 8)
	inv_items.add_child(sep1)
	
	# === Character inventory (Pocket) ===
	var pocket_header := Label.new()
	pocket_header.text = "📦 Pocket (%d/%d)" % [GameState.character_inventory.size(), GameState.MAX_CHARACTER_INVENTORY]
	pocket_header.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))
	pocket_header.add_theme_font_size_override("font_size", 11)
	inv_items.add_child(pocket_header)
	
	if GameState.character_inventory.is_empty():
		var empty_label := Label.new()
		empty_label.text = "  (empty)"
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		empty_label.add_theme_font_size_override("font_size", 10)
		inv_items.add_child(empty_label)
	else:
		for slot in GameState.character_inventory:
			var item_id: String = slot.get("item_id", "")
			var qty: int = slot.get("quantity", 1)
			var item := Balance.get_item(item_id)
			var row := _create_inventory_row(item, qty, "character")
			inv_items.add_child(row)


func _add_fashion_slot_row(display_name: String, slot_id: String) -> void:
	## Add a row showing a fashion slot and what's equipped
	var row := HBoxContainer.new()
	
	var slot_label := Label.new()
	slot_label.text = "  %s:" % display_name
	slot_label.custom_minimum_size = Vector2(70, 0)
	slot_label.add_theme_font_size_override("font_size", 10)
	slot_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	row.add_child(slot_label)
	
	var item_id := GameState.get_fashion_slot(slot_id)
	var value_label := Label.new()
	value_label.add_theme_font_size_override("font_size", 10)
	
	if item_id.is_empty():
		value_label.text = "(empty)"
		value_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	else:
		var item := Balance.get_item(item_id)
		value_label.text = item.get("name", item_id)
		value_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	
	row.add_child(value_label)
	inv_items.add_child(row)


func _create_inventory_row(item: Dictionary, qty: int, inv_type: String = "character") -> HBoxContainer:
	var row := HBoxContainer.new()
	
	var name_label := Label.new()
	var item_name: String = item.get("name", "Unknown")
	if qty > 1:
		item_name += " x%d" % qty
	name_label.text = "  " + item_name
	name_label.custom_minimum_size = Vector2(100, 0)
	name_label.add_theme_font_size_override("font_size", 10)
	row.add_child(name_label)
	
	# Add use button for consumables
	var tags: Array = item.get("tags", [])
	if "food" in tags or "drink" in tags or "snack" in tags:
		var use_btn := Button.new()
		use_btn.text = "Eat"
		use_btn.custom_minimum_size = Vector2(30, 20)
		use_btn.add_theme_font_size_override("font_size", 9)
		use_btn.pressed.connect(_on_use_item.bind(item.get("id", ""), inv_type))
		row.add_child(use_btn)
	
	# Add move button based on inventory type
	var move_btn := Button.new()
	if inv_type == "character":
		move_btn.text = "→🏠"
		move_btn.tooltip_text = "Move to Housing"
		move_btn.pressed.connect(_on_move_to_housing.bind(item.get("id", "")))
	else:
		move_btn.text = "→📦"
		move_btn.tooltip_text = "Move to Pocket"
		move_btn.pressed.connect(_on_move_to_character.bind(item.get("id", "")))
	
	move_btn.custom_minimum_size = Vector2(32, 20)
	move_btn.add_theme_font_size_override("font_size", 9)
	row.add_child(move_btn)
	
	return row


func _on_move_to_housing(item_id: String) -> void:
	if GameState.move_item_to_housing(item_id):
		_populate_inventory()
		if housing_window.visible:
			_populate_housing()


func _on_move_to_character(item_id: String) -> void:
	if GameState.move_item_to_character(item_id):
		_populate_housing()
		if inventory_window.visible:
			_populate_inventory()


func _on_use_item(item_id: String, _inv_type: String = "character") -> void:
	# Queue eat action - the eat action will handle removing from the correct inventory
	ActionQueue.queue_eat(item_id)


func _populate_housing() -> void:
	## Populate Housing window - current LA info + stats + home inventory
	var arr := Balance.get_living_arrangement(GameState.living_tier)
	var stats: Dictionary = arr.get("stats", {})
	
	housing_current_label.text = "🏠 %s (Tier %d)" % [GameState.get_living_name(), GameState.living_tier]
	
	for child in housing_items.get_children():
		child.queue_free()
	
	# === Housing Stats Section ===
	var stats_header := Label.new()
	stats_header.text = "📊 Stats"
	stats_header.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7))
	stats_header.add_theme_font_size_override("font_size", 11)
	housing_items.add_child(stats_header)
	
	# Show current housing stats
	var stat_entries := [
		["Back Pain Index", stats.get("comfort", 0)],
		["Focus Fuel", stats.get("productivity", 0)],
		["Street Cred", stats.get("reputation", 0)],
		["Panic Control", stats.get("stability", 0)],
		["Hoard Capacity", stats.get("storage", 0)]
	]
	
	for entry in stat_entries:
		var row := HBoxContainer.new()
		var name_label := Label.new()
		name_label.text = "  %s:" % entry[0]
		name_label.custom_minimum_size = Vector2(120, 0)
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		row.add_child(name_label)
		
		var val_label := Label.new()
		val_label.text = "+%d" % entry[1] if entry[1] > 0 else "%d" % entry[1]
		val_label.add_theme_font_size_override("font_size", 10)
		val_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.5))
		row.add_child(val_label)
		
		housing_items.add_child(row)
	
	# Add separator
	var sep := HSeparator.new()
	sep.custom_minimum_size = Vector2(0, 10)
	housing_items.add_child(sep)
	
	# === Home Inventory Section ===
	var inv_header := Label.new()
	inv_header.text = "📦 Home Storage (%d/%d)" % [GameState.la_inventory.size(), GameState.max_la_inventory_slots]
	inv_header.add_theme_color_override("font_color", Color(0.5, 0.8, 0.9))
	inv_header.add_theme_font_size_override("font_size", 11)
	housing_items.add_child(inv_header)
	
	if GameState.la_inventory.is_empty():
		var empty_label := Label.new()
		empty_label.text = "  (empty)"
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		empty_label.add_theme_font_size_override("font_size", 10)
		housing_items.add_child(empty_label)
	else:
		for slot in GameState.la_inventory:
			var item_id: String = slot.get("item_id", "")
			var qty: int = slot.get("quantity", 1)
			var item := Balance.get_item(item_id)
			var row := _create_inventory_row(item, qty, "la")
			housing_items.add_child(row)
	
	# Add separator
	var sep2 := HSeparator.new()
	sep2.custom_minimum_size = Vector2(0, 10)
	housing_items.add_child(sep2)
	
	# Housing upgrades removed - upgrades handled through gameplay progression


# === Career window handlers ===

func _on_career_pressed() -> void:
	career_window.visible = not career_window.visible
	if career_window.visible:
		career_window.bring_to_front()
		_populate_career_window()


func _init_career_branch_selector() -> void:
	career_branch_select.clear()
	var branches: Array = ["Corporate", "Merchant", "Investor", "Coder", "Scientist", "Engineer", "Author", "VisualArtist", "Musician"]
	for i in range(branches.size()):
		var branch: String = branches[i]
		var display_name: String = branch
		if branch == "VisualArtist":
			display_name = "Visual Artist"
		career_branch_select.add_item(display_name, i)
		if branch == GameState.branch:
			career_branch_select.select(i)


func _on_career_branch_selected(index: int) -> void:
	_populate_career_tree(index)


func _update_career_progress_labels() -> void:
	## Quick update of just PP-related labels in career window (called every minute)
	var ep: int = GameState.calculate_effective_productivity()
	career_ep_label.text = "Focus Fuel (EP): %d (x%.1f)" % [ep, ep / 10.0]
	
	if GameState.position_level < 10:
		var req_pp: int = Balance.get_promotion_threshold(GameState.branch, GameState.position_level)
		career_req_pp.text = "Required: %d PP (have %.0f)" % [req_pp, GameState.progress_points]


func _populate_career_window() -> void:
	# Current position info
	var branch: String = GameState.branch
	var display_branch: String = branch
	if branch == "VisualArtist":
		display_branch = "Visual Artist"
	
	career_branch_label.text = "Branch: %s" % display_branch
	career_title_label.text = "Title: %s" % GameState.get_position_title()
	career_level_label.text = "Level: %d / 10" % GameState.position_level
	
	# Salary info
	var base_pay: int = Balance.get_position_pay(branch, GameState.position_level)
	var ep: int = GameState.calculate_effective_productivity()
	var hourly: int = int(base_pay * ep / 10.0)
	var daily: int = hourly * 8
	
	career_base_pay.text = "Base Pay: %d/hour" % base_pay
	career_ep_label.text = "Focus Fuel (EP): %d (x%.1f)" % [ep, ep / 10.0]
	career_hourly_label.text = "Actual Hourly: %d coins" % hourly
	career_daily_label.text = "8hr/day Potential: %d coins" % daily
	
	# Next promotion info
	if GameState.position_level < 10:
		var next_level: int = GameState.position_level + 1
		var next_pos: Dictionary = Balance.get_position(branch, next_level)
		var next_title: String = next_pos.get("title", "Unknown")
		var next_pay_val: int = next_pos.get("base_pay_per_hour", 0)
		var req_pp: int = Balance.get_promotion_threshold(branch, GameState.position_level)
		var req_items: Array = next_pos.get("requires", [])
		
		career_next_pos.text = "Next: %s" % next_title
		career_next_pay.text = "Pay: %d/hour" % next_pay_val
		career_req_pp.text = "Required: %d PP (have %.0f)" % [req_pp, GameState.progress_points]
		
		if req_items.is_empty():
			career_req_items.text = "Items: None"
		else:
			var item_names: Array = []
			for item_id: String in req_items:
				var item: Dictionary = Balance.get_item(item_id)
				item_names.append(item.get("name", item_id))
			career_req_items.text = "Items: %s" % ", ".join(item_names)
	else:
		career_next_pos.text = "Next: MAX LEVEL"
		career_next_pay.text = ""
		career_req_pp.text = ""
		career_req_items.text = "You've reached the top!"
	
	# Select current branch in dropdown and populate tree
	var branches: Array = ["Corporate", "Merchant", "Investor", "Coder", "Scientist", "Engineer", "Author", "VisualArtist", "Musician"]
	var branch_idx: int = branches.find(branch)
	if branch_idx >= 0:
		career_branch_select.select(branch_idx)
	_populate_career_tree(career_branch_select.selected)


func _populate_career_tree(branch_index: int) -> void:
	# Clear existing items
	for child in career_tree_items.get_children():
		child.queue_free()
	
	var branches: Array = ["Corporate", "Merchant", "Investor", "Coder", "Scientist", "Engineer", "Author", "VisualArtist", "Musician"]
	if branch_index < 0 or branch_index >= branches.size():
		return
	
	var selected_branch: String = branches[branch_index]
	var is_current_branch: bool = (selected_branch == GameState.branch)
	
	# Add positions
	for level in range(1, 11):
		var pos: Dictionary = Balance.get_position(selected_branch, level)
		if pos.is_empty():
			continue
		
		var row := _create_career_row(pos, level, is_current_branch)
		career_tree_items.add_child(row)


func _create_career_row(pos: Dictionary, level: int, is_current_branch: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	
	var is_current: bool = is_current_branch and level == GameState.position_level
	var is_unlocked: bool = is_current_branch and level <= GameState.position_level
	
	# Level indicator
	var level_label := Label.new()
	level_label.text = "Lv%d" % level
	level_label.custom_minimum_size = Vector2(30, 0)
	level_label.add_theme_font_size_override("font_size", 9)
	if is_current:
		level_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	elif is_unlocked:
		level_label.add_theme_color_override("font_color", Color(0.7, 0.85, 0.7))
	else:
		level_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	row.add_child(level_label)
	
	# Title
	var title_label := Label.new()
	var title: String = pos.get("title", "Unknown")
	if is_current:
		title = "► " + title
	title_label.text = title
	title_label.custom_minimum_size = Vector2(130, 0)
	title_label.add_theme_font_size_override("font_size", 9)
	if is_current:
		title_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	elif is_unlocked:
		title_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	else:
		title_label.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
	row.add_child(title_label)
	
	# Pay
	var pay_label := Label.new()
	var pay: int = pos.get("base_pay_per_hour", 0)
	pay_label.text = "%d/hr" % pay
	pay_label.custom_minimum_size = Vector2(40, 0)
	pay_label.add_theme_font_size_override("font_size", 9)
	pay_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.5))
	row.add_child(pay_label)
	
	return row


# === Speed controls ===

func _on_speed_1x() -> void:
	ConsoleLog.log_input("Speed set to 1x")
	TimeManager.set_time_scale(1.0)
	speed_1x.button_pressed = true
	speed_2x.button_pressed = false
	speed_5x.button_pressed = false
	speed_10x.button_pressed = false


func _on_speed_2x() -> void:
	ConsoleLog.log_input("Speed set to 2x")
	TimeManager.set_time_scale(2.0)
	speed_1x.button_pressed = false
	speed_2x.button_pressed = true
	speed_5x.button_pressed = false
	speed_10x.button_pressed = false


func _on_speed_5x() -> void:
	ConsoleLog.log_input("Speed set to 5x")
	TimeManager.set_time_scale(5.0)
	speed_1x.button_pressed = false
	speed_2x.button_pressed = false
	speed_5x.button_pressed = true
	speed_10x.button_pressed = false


func _on_speed_10x() -> void:
	ConsoleLog.log_input("Speed set to 10x")
	TimeManager.set_time_scale(10.0)
	speed_1x.button_pressed = false
	speed_2x.button_pressed = false
	speed_5x.button_pressed = false
	speed_10x.button_pressed = true


func _on_pause_toggled(paused: bool) -> void:
	if paused:
		ConsoleLog.log_input("Game PAUSED")
		TimeManager.pause()
		ActionQueue.pause()
	else:
		ConsoleLog.log_input("Game RESUMED")
		TimeManager.resume()
		ActionQueue.resume()


func _on_save_pressed() -> void:
	# Save to current slot (the one we loaded from or created)
	SaveManager.save_to_current_slot()
	ConsoleLog.log_system("Game saved to slot %d" % SaveManager.get_current_slot())


func _on_menu_pressed() -> void:
	TimeManager.pause()
	get_tree().change_scene_to_file("res://scenes/screens/MainMenu.tscn")


# === AI Control ===

func _on_ai_toggled(enabled: bool) -> void:
	CharacterAI.set_enabled(enabled)
	_update_ai_button_text()
	if enabled:
		ConsoleLog.log_input("Character AI ENABLED - autonomous decisions active")
	else:
		ConsoleLog.log_input("Character AI DISABLED - manual control only")


func _update_ai_button_text() -> void:
	if CharacterAI.is_enabled():
		ai_btn.text = "AI: ON"
		ai_btn.modulate = Color(0.7, 1.0, 0.7)
	else:
		ai_btn.text = "AI: OFF"
		ai_btn.modulate = Color(1.0, 0.7, 0.7)


func _on_ai_decision(action_type: int, reason: String) -> void:
	# Update status to show AI reasoning
	var action_data: Dictionary = ActionQueue.ACTION_DATA.get(action_type, {})
	var action_name: String = action_data.get("name", "Unknown")
	comment_label.text = "[AI] Decided to %s: %s" % [action_name.to_lower(), reason]
