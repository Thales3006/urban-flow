extends Control

@onready var form: Form = $InitialForm
@onready var sound_button: Button = $SoundButton

@export var icon_on: Texture2D
@export var icon_off: Texture2D


func _ready() -> void:
	form._on_appear()

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file(Global.level_selector_scene_path)


func _on_exit_button_pressed() -> void:
	get_tree().quit()


func _on_settings_button_pressed() -> void:
	get_tree().change_scene_to_file(Global.level_settings_scene_path)


func _on_button_toggled(toggled_on: bool) -> void:
	AudioServer.set_bus_mute(Global.master_bus, toggled_on)
	if not toggled_on:
		sound_button.icon = icon_on
	else:
		sound_button.icon = icon_off
