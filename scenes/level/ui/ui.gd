extends Control

@onready var win_card := $WinCard
@onready var completion_status: CompletionStatus = $CompletionStatus
@onready var catalog_buttons : Control = $CatalogButtons

func _ready() -> void:
	Signals.level_won.connect(_on_level_won)
	Signals.building_placed.connect(_on_building_placed)
	Signals.create_front_catalog_button.connect(_on_catalog_button)
	
	Signals.progress_state_changed.emit(0)

func _on_back_pressed() -> void:
	GameState.clear()
	get_tree().change_scene_to_file(Global.level_selector_scene_path)

func _on_building_placed():
	Signals.progress_state_changed.emit(GameState.compute_percentage())
	print("Total score: ", GameState.compute_score())

func _on_level_won():
	await get_tree().create_timer(0.5).timeout
	win_card.set_won()
	
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
