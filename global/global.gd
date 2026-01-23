extends Node

const resource_path: String = "res://"
const levels_path: String = "res://levels/"
const main_menu_scene_path: String = "res://scenes/main_menu/main_menu.tscn"
const level_selector_scene_path: String = "res://scenes/level_selection/selection.tscn"
const level_scene_path: String = "res://scenes/level/level.tscn"

var current_level_path: String
var is_dragging: bool = false
