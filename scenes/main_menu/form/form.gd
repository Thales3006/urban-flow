extends Control
class_name Form

@onready var dimmer := $Dimmer
@onready var panel := $Panel
@onready var male_button = $Panel/GenderContainer/MaleButton
@onready var female_button = $Panel/GenderContainer/FemaleButton
@onready var day := $Panel/Date/PanelContainer/HBoxContainer/Day
@onready var month := $Panel/Date/PanelContainer/HBoxContainer/Month
@onready var year := $Panel/Date/PanelContainer/HBoxContainer/Year
var date : Array[int] = [0, 0, 0]

func _ready() -> void:
	day.value_changed.connect(_on_date_changed)
	month.value_changed.connect(_on_date_changed)
	year.value_changed.connect(_on_date_changed)
	
func _on_date_changed(_value: int):
	date[0] = day.real_value
	date[1] = month.real_value
	date[2] = year.real_value
	print(date)
	
	
func _on_confirm_button_pressed() -> void:
	_on_disapear()
	
func _on_appear():
	var viewport_size := get_viewport().get_visible_rect().size

	panel.position.y = -panel.size.y
	var target_y: float = viewport_size.y / 2 - panel.size.y / 2
	
	dimmer.modulate.a = 0.0

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(panel, "position:y", target_y, 0.6)
	tween.parallel().tween_property(
		dimmer,
		"modulate:a",
		0.6,
		0.4,
	)
	visible = true
	
func _on_disapear():
	var viewport_size := get_viewport().get_visible_rect().size
	
	var target_y: float = viewport_size.y

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(panel, "position:y", target_y, 0.4)

	tween.parallel().tween_property(
		dimmer,
		"modulate:a",
		0.0,
		0.2,
	)
	
	await tween.finished
	visible = false


func _on_date_button_pressed() -> void:
	pass
