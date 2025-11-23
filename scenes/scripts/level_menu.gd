extends Control

@onready var grid = $MarginContainer/VBoxContainer/GridContainer

func _ready():
	var dir := DirAccess.open("res://resources/levels")
	if dir == null:
		push_error("Levels folder not found!")
		return
	
	for file_name in dir.get_files():
		if file_name.ends_with(".tres"):
			var level_data: LevelData = load("res://resources/levels/" + file_name)
			
			var button := Button.new()
			button.text = level_data.level_name if level_data else file_name.get_basename()
			button.custom_minimum_size = Vector2(80, 80)
			button.focus_mode = Control.FOCUS_NONE
			button.connect("pressed", Callable(self, "_on_level_selected").bind(file_name))
			grid.add_child(button)

func _on_level_selected(file_name: String):
	global.current_level_path = "res://resources/levels/" + file_name
	get_tree().change_scene_to_file("res://scenes/level.tscn")

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
