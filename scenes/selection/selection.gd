extends Control

@onready var grid = $GridContainer

func _ready():
	var dir := DirAccess.open(Global.levels_path)
	if dir == null:
		push_error("Levels folder not found!")
		return
	for level_name in dir.get_directories():
		var level_path := Global.levels_path + "/" + level_name
		var level_dir := DirAccess.open(level_path)
		if level_dir == null:
			continue
		
		if not level_dir.file_exists("data.tres") or not level_dir.file_exists("layout.tscn"):
			continue
		
		var button := Button.new()
		button.text = level_name.get_basename()
		button.custom_minimum_size = Vector2(80, 80)
		button.focus_mode = Control.FOCUS_NONE
		button.connect("pressed", Callable(self, "_on_level_selected").bind(level_path))
		grid.add_child(button)

func _on_level_selected(level_path: String):
	GameState.level = load(level_path + "/data.tres") as LevelData
	if not GameState.level:
		push_error("Failed to load level: " + level_path)
		return
	get_tree().change_scene_to_file(Global.level_scene_path)

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file(Global.main_menu_scene_path)
