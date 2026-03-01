extends Control

@onready var grid = $GridContainer

func _ready():
	var index: LevelsIndex = load("res://levels/levels_index.tres")
	for level_name in index.levels:
		var level_path := Global.levels_path + "/" + level_name
		
		var button := LevelButton.new()
		button.text = level_name.get_basename()
		button.custom_minimum_size = Vector2(100, 100)
		button.pressed.connect(_on_level_selected.bind(level_path))
		
		grid.add_child(button)

func _on_level_selected(level_path: String):
	GameState.level = load(level_path + "/data.tres") as LevelData
	if not GameState.level:
		push_error("Failed to load level: " + level_path)
		return
	get_tree().change_scene_to_file(Global.level_scene_path)

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file(Global.main_menu_scene_path)
