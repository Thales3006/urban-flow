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

# Most phones fall between 16:9 (~1.778) and 20:9 (~2.222) in landscape.
# Within that range, expand to fill the screen with no letterboxing --
# outside it (e.g. a desktop monitor, an unusually square/tall device),
# fall back to letterboxing so the UI never distorts or clips.
const MIN_PHONE_ASPECT := 16.0 / 9.0
const MAX_PHONE_ASPECT := 20.0 / 9.0

func _ready() -> void:
	get_window().size_changed.connect(_update_stretch_aspect)
	_update_stretch_aspect()

func _update_stretch_aspect() -> void:
	var window := get_window()
	if window.size.y <= 0:
		return
	var aspect := float(window.size.x) / float(window.size.y)
	if aspect >= MIN_PHONE_ASPECT and aspect <= MAX_PHONE_ASPECT:
		window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	else:
		window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
