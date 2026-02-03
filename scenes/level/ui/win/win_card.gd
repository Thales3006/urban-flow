extends Control

@onready var stars :CompletionStatus = $PanelContainer/VBoxContainer/CompletionStatus
@onready var win_sound := $AudioStreamPlayer

func _ready() -> void:
	stars.set_progress(GameState.compute_percentage())

func _on_restart_button_pressed() -> void:
	_on_level_selected(Global.levels_path + "/" + str(GameState.level.level))


func _on_menu_button_pressed() -> void:
	GameState.clear()
	get_tree().change_scene_to_file(Global.level_selector_scene_path)


func _on_next_button_pressed() -> void:
	_on_level_selected(Global.levels_path + "/" + str(GameState.level.level + 1))
	
func _on_level_selected(level_path: String):
	GameState.clear()
	GameState.level = load(level_path + "/data.tres") as LevelData
	if not GameState.level:
		push_error("Failed to load level: " + level_path)
		return
	get_tree().change_scene_to_file(Global.level_scene_path)

func set_won():
	win_sound.play()
	visible = true
	
