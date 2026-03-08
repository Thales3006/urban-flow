extends Control
class_name BirthdayForm

@onready var panel := $FormPanel
@onready var day := $FormPanel/Numbers/Day
@onready var month := $FormPanel/Numbers/Month
@onready var year := $FormPanel/Numbers/Year

var date : PlayerInfo.Date = PlayerInfo.Date.new()

signal birthdateChoosen(birthdate: PlayerInfo.Date)

func _ready() -> void:
	day.value_changed.connect(_on_date_changed)
	month.value_changed.connect(_on_date_changed)
	year.value_changed.connect(_on_date_changed)
	
	_on_date_changed(0)
	
func _on_date_changed(_value: int):
	date.day = day.value
	date.month = month.value
	date.year = year.value
	
	print(date.day, "/", date.month, "/",date.year)
	
	
func _on_confirm_button_pressed() -> void:
	AudioManager.play_click()
	birthdateChoosen.emit(date)
	
func _on_appear():
	var viewport_size := get_viewport().get_visible_rect().size

	panel.position.y = -panel.size.y
	var target_y: float = viewport_size.y / 2 - panel.size.y / 2
	
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(panel, "position:y", target_y, 0.6)
	visible = true
	
func _on_disapear():
	var viewport_size := get_viewport().get_visible_rect().size
	
	var target_y: float = viewport_size.y

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(panel, "position:y", target_y, 0.4)
	
	await tween.finished
	visible = false
