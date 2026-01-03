extends Control
## DailyStats - End of day summary screen

@onready var title_label: Label = $Panel/VBox/Title
@onready var earnings_value: Label = $Panel/VBox/StatsGrid/EarningsValue
@onready var spent_value: Label = $Panel/VBox/StatsGrid/SpentValue
@onready var pp_value: Label = $Panel/VBox/StatsGrid/PPValue
@onready var hours_worked_value: Label = $Panel/VBox/StatsGrid/HoursWorkedValue
@onready var meals_value: Label = $Panel/VBox/StatsGrid/MealsValue
@onready var position_label: Label = $Panel/VBox/PositionLabel
@onready var living_label: Label = $Panel/VBox/LivingLabel
@onready var continue_btn: Button = $Panel/VBox/ContinueBtn

# These would be tracked during gameplay
var daily_earnings: int = 0
var daily_spent: int = 0
var daily_pp: float = 0.0
var daily_hours_worked: int = 0
var daily_meals: int = 0


func _ready() -> void:
	continue_btn.pressed.connect(_on_continue_pressed)
	_update_display()


func set_daily_stats(data: Dictionary) -> void:
	daily_earnings = data.get("earnings", 0)
	daily_spent = data.get("spent", 0)
	daily_pp = data.get("pp", 0.0)
	daily_hours_worked = data.get("hours_worked", 0)
	daily_meals = data.get("meals", 0)
	_update_display()


func _update_display() -> void:
	title_label.text = "Day %d Summary" % TimeManager.current_day
	earnings_value.text = "%d" % daily_earnings
	spent_value.text = "%d" % daily_spent
	pp_value.text = "%.1f PP" % daily_pp
	hours_worked_value.text = "%d" % daily_hours_worked
	meals_value.text = "%d" % daily_meals
	position_label.text = "Current Position: %s (Lv%d)" % [GameState.get_position_title(), GameState.position_level]
	living_label.text = "Living: %s" % GameState.get_living_name()


func _on_continue_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/screens/GameScreen.tscn")

