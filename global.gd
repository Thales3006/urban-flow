extends Node

const resource_path: String = "res://resources/"
const levels_path: String = "res://resources/levels/"
const main_menu_scene_path: String = "res://scenes/main_menu.tscn"
const level_selector_scene_path: String = "res://scenes/level_scene.tscn"
const level_scene_path: String = "res://scenes/level_scene/level.tscn"

var current_level_path: String
var level: LevelData
var is_dragging: bool = false
