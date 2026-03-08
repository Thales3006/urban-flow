extends Control
class_name FinalWinCard

@onready var win_sound := $AudioStreamPlayer
@onready var dimmer := $Dimmer
@onready var card := $Card
@onready var beaver := $Beaver

func _on_main_menu_button_pressed() -> void:
	GameState.clear()
	AudioManager.play_click()
	get_tree().change_scene_to_file(Global.main_menu_scene_path)

func set_won():
	win_sound.play()
	
	var viewport_size := get_viewport().get_visible_rect().size

	card.position.y = viewport_size.y + card.size.y
	var target_y: float = viewport_size.y / 2 - card.size.y / 2
	
	dimmer.modulate.a = 0.0

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(card, "position:y", target_y, 0.6)

	tween.parallel().tween_property(
		dimmer,
		"modulate:a",
		0.6,
		0.4,
	)
	
	var beaver_pos: Vector2 = beaver.position
	beaver.global_position = viewport_size
	tween.parallel().tween_property(
		beaver,
		"position",
		beaver_pos,
		0.8
	)
	
	visible = true
