extends Control

@onready var sound_slider: HSlider = $Options/Option/SoundSlider

func _ready() -> void:
	sound_slider.value = Global.volume_level

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file(Global.main_menu_scene_path)


func _on_sound_slider_value_changed(value: float) -> void:
	Global.volume_level = value
