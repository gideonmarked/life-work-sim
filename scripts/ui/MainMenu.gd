extends Control
## MainMenu - Main menu screen with transparent background and hover window controls

@onready var close_btn: Button = $CloseBtn
@onready var move_btn: Button = $MoveBtn

@onready var new_game_btn: Button = $VBox/NewGameBtn
@onready var continue_btn: Button = $VBox/ContinueBtn
@onready var settings_btn: Button = $VBox/SettingsBtn

@onready var new_game_panel: Panel = $NewGamePanel
@onready var name_input: LineEdit = $NewGamePanel/VBox/NameContainer/NameInput
@onready var business_btn: Button = $NewGamePanel/VBox/CategoryContainer/BusinessBtn
@onready var art_btn: Button = $NewGamePanel/VBox/CategoryContainer/ArtBtn
@onready var innovation_btn: Button = $NewGamePanel/VBox/CategoryContainer/InnovationBtn
@onready var branch_container: HBoxContainer = $NewGamePanel/VBox/BranchContainer
@onready var branch_label: Label = $NewGamePanel/VBox/BranchLabel
@onready var branch1_btn: Button = $NewGamePanel/VBox/BranchContainer/Branch1Btn
@onready var branch2_btn: Button = $NewGamePanel/VBox/BranchContainer/Branch2Btn
@onready var branch3_btn: Button = $NewGamePanel/VBox/BranchContainer/Branch3Btn
@onready var cancel_btn: Button = $NewGamePanel/VBox/ButtonContainer/CancelBtn
@onready var start_btn: Button = $NewGamePanel/VBox/ButtonContainer/StartBtn

@onready var slot_panel: Panel = $SlotPanel
@onready var slot_container: VBoxContainer = $SlotPanel/VBox/SlotContainer
@onready var slot_close_btn: Button = $SlotPanel/VBox/CloseBtn

@onready var hover_fade_timer: Timer = $HoverFadeTimer

var selected_category: String = ""
var selected_branch: String = ""
var _slot_mode: String = ""  # "new" or "load"

# Window control state
var _is_dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
var _mouse_inside: bool = false
var _controls_visible: bool = false
var _fade_tween: Tween = null

const FADE_DURATION := 0.2


func _ready() -> void:
	_connect_signals()
	_update_continue_button()
	_hide_branch_selection()
	
	# Initially hide window controls
	close_btn.modulate.a = 0.0
	move_btn.modulate.a = 0.0


func _process(_delta: float) -> void:
	# Handle window dragging (only works in standalone window, not embedded)
	if _is_dragging and not _is_embedded():
		var window := get_window()
		window.position = DisplayServer.mouse_get_position() - Vector2i(_drag_offset)


func _is_embedded() -> bool:
	# Check if running in editor (window can't be moved in embedded mode)
	return OS.has_feature("editor")


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


func _connect_signals() -> void:
	# Window controls
	close_btn.pressed.connect(_on_close_pressed)
	move_btn.button_down.connect(_on_move_button_down)
	move_btn.button_up.connect(_on_move_button_up)
	
	# Menu buttons
	new_game_btn.pressed.connect(_on_new_game_pressed)
	continue_btn.pressed.connect(_on_continue_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	
	# Category buttons
	business_btn.pressed.connect(_on_category_selected.bind("Business"))
	art_btn.pressed.connect(_on_category_selected.bind("Art"))
	innovation_btn.pressed.connect(_on_category_selected.bind("Innovation"))
	
	# Branch buttons
	branch1_btn.pressed.connect(_on_branch_selected.bind(0))
	branch2_btn.pressed.connect(_on_branch_selected.bind(1))
	branch3_btn.pressed.connect(_on_branch_selected.bind(2))
	
	# New game panel
	cancel_btn.pressed.connect(_on_cancel_new_game)
	start_btn.pressed.connect(_on_start_game)
	slot_close_btn.pressed.connect(_on_close_slot_panel)
	
	# Hover timer
	hover_fade_timer.timeout.connect(_on_hover_fade_timeout)
	
	# Mouse tracking for the main control
	mouse_entered.connect(_on_mouse_entered_window)
	mouse_exited.connect(_on_mouse_exited_window)


func _on_mouse_entered_window() -> void:
	_mouse_inside = true
	hover_fade_timer.stop()
	_show_window_controls()


func _on_mouse_exited_window() -> void:
	_mouse_inside = false
	# Start timer to hide controls after delay
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


func _on_close_pressed() -> void:
	get_tree().quit()


func _on_move_button_down() -> void:
	if not _is_embedded():
		_is_dragging = true
		_drag_offset = get_global_mouse_position()


func _on_move_button_up() -> void:
	_is_dragging = false


func _update_continue_button() -> void:
	continue_btn.disabled = not SaveManager.has_any_saves()
	if continue_btn.disabled:
		continue_btn.modulate.a = 0.5
	else:
		continue_btn.modulate.a = 1.0


func _hide_branch_selection() -> void:
	branch_label.visible = false
	branch_container.visible = false


func _show_branch_selection() -> void:
	branch_label.visible = true
	branch_container.visible = true


func _on_new_game_pressed() -> void:
	var empty_slot := SaveManager.get_first_empty_slot()
	if empty_slot == -1:
		# All slots full, show slot selection to overwrite
		_slot_mode = "new"
		_show_slot_panel()
	else:
		_show_new_game_panel()


func _show_new_game_panel() -> void:
	new_game_panel.visible = true
	name_input.text = ""
	selected_category = ""
	selected_branch = ""
	_hide_branch_selection()
	business_btn.button_pressed = false
	art_btn.button_pressed = false
	innovation_btn.button_pressed = false
	name_input.grab_focus()


func _on_continue_pressed() -> void:
	var recent := SaveManager.get_most_recent_slot()
	if recent > 0:
		if SaveManager.load_game(recent):
			get_tree().change_scene_to_file("res://scenes/screens/GameScreen.tscn")
	else:
		_slot_mode = "load"
		_show_slot_panel()


func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/screens/Settings.tscn")


func _on_category_selected(category: String) -> void:
	selected_category = category
	selected_branch = ""
	
	var branches: Array = Balance.CATEGORIES.get(category, [])
	if branches.size() >= 3:
		branch1_btn.text = _format_branch_name(branches[0])
		branch2_btn.text = _format_branch_name(branches[1])
		branch3_btn.text = _format_branch_name(branches[2])
		branch1_btn.button_pressed = false
		branch2_btn.button_pressed = false
		branch3_btn.button_pressed = false
		_show_branch_selection()


func _format_branch_name(branch: String) -> String:
	if branch == "VisualArtist":
		return "Visual Artist"
	return branch


func _on_branch_selected(index: int) -> void:
	var branches: Array = Balance.CATEGORIES.get(selected_category, [])
	if index < branches.size():
		selected_branch = branches[index]


func _on_cancel_new_game() -> void:
	new_game_panel.visible = false


func _on_start_game() -> void:
	var char_name := name_input.text.strip_edges()
	if char_name.is_empty():
		char_name = "Player"
	
	if selected_category.is_empty() or selected_branch.is_empty():
		return
	
	new_game_panel.visible = false
	
	GameState.new_game(char_name, selected_category, selected_branch)
	
	# Auto-save to first empty slot
	var slot := SaveManager.get_first_empty_slot()
	if slot > 0:
		SaveManager.save_game(slot)
	
	get_tree().change_scene_to_file("res://scenes/screens/GameScreen.tscn")


func _show_slot_panel() -> void:
	# Clear existing slot buttons
	for child in slot_container.get_children():
		child.queue_free()
	
	# Create slot buttons
	var slots := SaveManager.get_all_slots_info()
	for info in slots:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(350, 35)
		
		if info.get("empty", false):
			btn.text = "Slot %d - Empty" % info.get("slot", 0)
			if _slot_mode == "load":
				btn.disabled = true
		else:
			btn.text = "Slot %d - %s (Day %d, Lv%d %s)" % [
				info.get("slot", 0),
				info.get("character_name", "Unknown"),
				info.get("day", 1),
				info.get("position_level", 1),
				info.get("branch", "")
			]
		
		btn.pressed.connect(_on_slot_selected.bind(info.get("slot", 1)))
		slot_container.add_child(btn)
	
	slot_panel.visible = true


func _on_slot_selected(slot: int) -> void:
	slot_panel.visible = false
	
	if _slot_mode == "load":
		if SaveManager.load_game(slot):
			get_tree().change_scene_to_file("res://scenes/screens/GameScreen.tscn")
	elif _slot_mode == "new":
		SaveManager.delete_slot(slot)
		_show_new_game_panel()


func _on_close_slot_panel() -> void:
	slot_panel.visible = false
