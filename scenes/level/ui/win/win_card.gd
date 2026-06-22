extends Control

@onready var win_sound := $AudioStreamPlayer
@onready var dimmer := $Dimmer
@onready var card := $Card
@onready var beaver := $Beaver
@onready var star_hbox := $Card/VBoxContainer/Control/VBoxContainer/StarHBox

func _ready() -> void:
	# var star_level := GameState.compute_percentage() / 25 as int
	for index in 5:
		star_hbox.set_lit(index)

func _on_restart_button_pressed() -> void:
	AudioManager.play_click()
	_on_level_selected(Global.levels_path + "/" + str(GameState.level.level))


func _on_menu_button_pressed() -> void:
	GameState.clear()
	AudioManager.play_click()
	get_tree().change_scene_to_file(Global.level_selector_scene_path)


func _on_next_button_pressed() -> void:
	AudioManager.play_click()
	_on_level_selected(Global.levels_path + "/" + str(GameState.level.level + 1))
	
func _on_level_selected(level_path: String):
	GameState.clear()
	GameState.level = load(level_path + "/data.tres") as LevelData
	if not GameState.level:
		push_error("Failed to load level: " + level_path)
		return
	get_tree().change_scene_to_file(Global.level_scene_path)

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
