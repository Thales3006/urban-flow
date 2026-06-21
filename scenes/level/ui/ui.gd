extends Control

@onready var win_card := $WinCard
@onready var final_win_card := $FinalWinCard
@onready var completion_status: CompletionStatus = $"../../Background/CompletionStatus"
@onready var catalog_buttons : Control = $CatalogButtons

func _ready() -> void:
	Signals.level_won.connect(_on_level_won)
	Signals.building_placed.connect(_on_building_placed)
	Signals.create_front_catalog_button.connect(_on_catalog_button)
	
	Signals.progress_state_changed.emit(0)

func _on_back_pressed() -> void:
	GameState.clear()
	get_tree().change_scene_to_file(Global.level_selector_scene_path)
	AudioManager.play_click()

func _on_building_placed():
	Signals.progress_state_changed.emit(GameState.compute_percentage())
	print("Total score: ", GameState.compute_score())

func _on_level_won():
	await get_tree().create_timer(0.5).timeout
	# Unlike create_tween(), this timer isn't bound to this node's lifetime --
	# if the level scene was freed (e.g. player navigated back) while this
	# was pending, bail out instead of touching a freed node.
	if not is_inside_tree():
		return

	var index: LevelsIndex = load("res://levels/levels_index.tres")
	if len(index.levels) <= GameState.level.level:
		final_win_card.set_won()
	else:
		win_card.set_won()
		Global.levels_unlocked = GameState.level.level + 1 
	
func _on_catalog_button(catalog: BuildingCatalog):
	catalog.front_button = catalog.button.duplicate()
	catalog_buttons.add_child(catalog.front_button)
	catalog.button.disabled = true
	catalog.button.visible = false
	catalog.button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	catalog.button.resized.connect(func(): _sync_button(catalog.button, catalog.front_button))
	_sync_button(catalog.button, catalog.front_button)

func _sync_button(original: Control, overlay: Control):
	overlay.global_position = original.global_position
	overlay.size = original.size
