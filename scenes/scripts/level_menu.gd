extends Control

@onready var grid = $MarginContainer/VBoxContainer/GridContainer

func _ready():
	_populate_levels()

func _populate_levels():
	var dir := DirAccess.open("res://scenes/levels")
	if dir == null:
		push_error("Levels folder not found!")
		return

	for file_name in dir.get_files():
		if file_name.ends_with(".tscn"):
			var button := Button.new()
			button.text = file_name.get_basename()[-1]
			button.custom_minimum_size = Vector2(150, 80)
			button.focus_mode = Control.FOCUS_NONE
			button.connect("pressed", Callable(self, "_on_level_selected").bind(file_name))
			grid.add_child(button)

func _on_level_selected(file_name: String):
	var path = "res://scenes/levels/" + file_name
	get_tree().change_scene_to_file(path)


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
