extends Control

@onready var grid = $GridContainer

const LEVEL_BUTTON_SCENE = preload("res://scenes/selection/level_button/level_button.tscn")

func _ready():
	var index: LevelsIndex = load("res://levels/levels_index.tres")
	for level_name in index.levels:
		var level_path := Global.levels_path + "/" + level_name
		
		var button: LevelButton = LEVEL_BUTTON_SCENE.instantiate()
		button.text = level_name.get_basename()
		button.custom_minimum_size = Vector2(100, 100)
		button.name = "LeveButton_{level}".format({ "level" : level_name.get_basename()})
		button.pressed.connect(_on_level_selected.bind(button, level_path))
		grid.add_child(button)

		if not Global.levels_locked or Global.levels_unlocked >= level_name.get_basename().to_int():
			button.set_unlock()
		else:
			button.set_lock()

func _on_level_selected(button: LevelButton, level_path: String):
	if button.locked:
		return
		
	AudioManager.play_click()
	GameState.level = load(level_path + "/data.tres") as LevelData
	if not GameState.level:
		push_error("Failed to load level: " + level_path)
		return
	get_tree().change_scene_to_file(Global.level_scene_path)

func _on_button_pressed() -> void:
	AudioManager.play_click()
	get_tree().change_scene_to_file(Global.main_menu_scene_path)
