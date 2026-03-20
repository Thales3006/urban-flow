extends Node

const server_url = "https://urban.thales3006.dev.br"
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
