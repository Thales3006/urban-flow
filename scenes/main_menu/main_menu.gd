extends Control


func _ready() -> void:
	pass


func _process(_delta: float) -> void:
	pass


func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file(Global.level_selector_scene_path)


func _on_exit_button_pressed() -> void:
	get_tree().quit()
