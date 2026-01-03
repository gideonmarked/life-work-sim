extends Control
## Settings screen with transparent background and hover window controls

@onready var close_btn: Button = $CloseBtn
@onready var move_btn: Button = $MoveBtn
@onready var volume_slider: HSlider = $VBox/VolumeContainer/VolumeSlider
@onready var fullscreen_check: CheckBox = $VBox/FullscreenContainer/FullscreenCheck
@onready var back_btn: Button = $VBox/BackBtn
@onready var hover_fade_timer: Timer = $HoverFadeTimer

# Window control state
var _is_dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
var _mouse_inside: bool = false
var _controls_visible: bool = false
var _fade_tween: Tween = null

const FADE_DURATION := 0.2


func _ready() -> void:
	# Window controls
	close_btn.pressed.connect(_on_close_pressed)
	move_btn.button_down.connect(_on_move_button_down)
	move_btn.button_up.connect(_on_move_button_up)
	
	# Settings controls
	back_btn.pressed.connect(_on_back_pressed)
	volume_slider.value_changed.connect(_on_volume_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	
	# Hover handling
	hover_fade_timer.timeout.connect(_on_hover_fade_timeout)
	mouse_entered.connect(_on_mouse_entered_window)
	mouse_exited.connect(_on_mouse_exited_window)
	
	# Load current settings
	fullscreen_check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	
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
	if event is InputEventMouseMotion:
		var mouse_pos := get_global_mouse_position()
		var rect := get_rect()
		var was_inside := _mouse_inside
		_mouse_inside = rect.has_point(mouse_pos)
		
		if _mouse_inside and not was_inside:
			_on_mouse_entered_window()
		elif not _mouse_inside and was_inside:
			_on_mouse_exited_window()
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_is_dragging = false


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


func _on_close_pressed() -> void:
	get_tree().quit()


func _on_move_button_down() -> void:
	if not _is_embedded():
		_is_dragging = true
		_drag_offset = get_global_mouse_position()


func _on_move_button_up() -> void:
	_is_dragging = false


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/screens/MainMenu.tscn")


func _on_volume_changed(value: float) -> void:
	var db := linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(0, db)


func _on_fullscreen_toggled(toggled: bool) -> void:
	if toggled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
