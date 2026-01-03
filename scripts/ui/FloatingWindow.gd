class_name FloatingWindow
extends Panel
## A draggable floating window component for in-game windowed panels

signal close_requested()
signal minimized()
signal window_moved(new_position: Vector2)

@export var window_title: String = "Window"
@export var show_close_button: bool = true
@export var show_minimize_button: bool = false
@export var min_size: Vector2 = Vector2(200, 150)
@export var initial_position: Vector2 = Vector2(100, 100)

var title_label: Label
var close_btn: Button
var content_container: Control

var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	# Find child nodes
	title_label = get_node_or_null("TitleBar/TitleLabel")
	close_btn = get_node_or_null("TitleBar/CloseBtn")
	content_container = get_node_or_null("Content")
	
	_setup_style()
	_connect_signals()
	custom_minimum_size = min_size


func _setup_style() -> void:
	# Main background
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.08, 0.1, 0.95)
	bg.border_color = Color(0.3, 0.3, 0.35, 0.8)
	bg.set_border_width_all(1)
	bg.set_corner_radius_all(4)
	add_theme_stylebox_override("panel", bg)
	
	# Style title bar if it exists
	var title_bar := get_node_or_null("TitleBar")
	if title_bar and title_bar is Panel:
		var title_bg := StyleBoxFlat.new()
		title_bg.bg_color = Color(0.12, 0.12, 0.15, 1.0)
		title_bg.set_corner_radius_all(0)
		title_bg.corner_radius_top_left = 4
		title_bg.corner_radius_top_right = 4
		title_bar.add_theme_stylebox_override("panel", title_bg)
	
	# Style close button
	if close_btn:
		close_btn.flat = true
		close_btn.add_theme_font_size_override("font_size", 14)
		close_btn.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
		close_btn.add_theme_color_override("font_hover_color", Color(1, 0.4, 0.4, 1))
	
	# Style title label
	if title_label:
		title_label.text = window_title
		title_label.add_theme_font_size_override("font_size", 12)
		title_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85, 1))


func _connect_signals() -> void:
	# Connect title bar drag
	var title_bar := get_node_or_null("TitleBar")
	if title_bar:
		title_bar.gui_input.connect(_on_title_bar_input)
	
	# Connect close button
	if close_btn:
		if not close_btn.pressed.is_connected(_on_close_pressed):
			close_btn.pressed.connect(_on_close_pressed)


func _on_title_bar_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				drag_offset = get_global_mouse_position() - global_position
				bring_to_front()
			else:
				is_dragging = false
	
	elif event is InputEventMouseMotion and is_dragging:
		var new_pos := get_global_mouse_position() - drag_offset
		# Clamp to parent bounds
		var parent_ctrl := get_parent_control()
		if parent_ctrl:
			var parent_rect := parent_ctrl.get_rect()
			new_pos.x = clampf(new_pos.x, 0, parent_rect.size.x - size.x)
			new_pos.y = clampf(new_pos.y, 0, parent_rect.size.y - size.y)
		global_position = new_pos
		window_moved.emit(new_pos)


func _on_close_pressed() -> void:
	close_requested.emit()
	visible = false


func get_content() -> Control:
	return content_container


func bring_to_front() -> void:
	var parent := get_parent()
	if parent:
		parent.move_child(self, parent.get_child_count() - 1)
