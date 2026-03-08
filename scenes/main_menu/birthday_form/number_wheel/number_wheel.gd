extends Control
class_name NumberWheel

signal value_changed(value:int)

@export var min_value := 1
@export var max_value := 10
@export var default_value := 1

var value := 0

@onready var label := $NumberWheelBackground/NumberWheelLabel

func _ready():
	await get_tree().process_frame  # espera o layout calcular o tamanho real
	_fit_font_size()
	set_value(default_value)

func _fit_font_size():
	# label.size.x é 1.0 pq não tem size_flags horizontal
	# usamos o pai como referência real
	var available_width: float = size.x * 0.8  # 80% para dar margem
	var available_height: float = size.y * 0.8
	var test_string := "0000"
	var font: Font = label.get_theme_font("font")
	
	var best := 8
	for s in range(8, 300, 2):
		var tw: float = font.get_string_size(test_string, HORIZONTAL_ALIGNMENT_LEFT, -1, s).x
		var th: float = font.get_ascent(s) + font.get_descent(s)
		if tw > available_width or th > available_height:
			break
		best = s
	
	label.add_theme_font_size_override("font_size", best)
	
func _wrap_value(v: int) -> int:
	var range_size := max_value - min_value + 1
	return min_value + posmod(v - min_value, range_size)

func set_value(v: int):
	if v != _wrap_value(v):
		return
	value = v
	value_changed.emit(value)
	label.text = str(value)

func _on_button_up_pressed() -> void:
	set_value(value + 1)
	AudioManager.play_click()

func _on_button_down_pressed() -> void:
	set_value(value - 1)
	AudioManager.play_click()
