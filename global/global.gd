extends Node

const resource_path: String = "res://"
const levels_path: String = "res://levels/"
const main_menu_scene_path: String = "res://scenes/main_menu/main_menu.tscn"
const level_selector_scene_path: String = "res://scenes/selection/selection.tscn"
const level_scene_path: String = "res://scenes/level/level.tscn"
const level_settings_scene_path: String = "res://scenes/settings/settings.tscn"
@onready var master_bus := AudioServer.get_bus_index("Master")

const levels_locked: bool = false

var is_dragging: bool = false
var levels_unlocked: int = 1
var first_time: bool = true


var volume_level: float = 50.0:
	set(value):
		volume_level = clamp(value, 0, 100)
		var linear := volume_level / 100.0

		AudioServer.set_bus_mute(master_bus, linear == 0)
		if linear > 0:
			AudioServer.set_bus_volume_db(master_bus, linear_to_db(linear))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F11:
		var window := get_window()
		if window.mode == Window.MODE_WINDOWED:
			window.mode = Window.MODE_FULLSCREEN
		else:
			window.mode = Window.MODE_WINDOWED
