class_name Tutorial
extends Control

@onready var click: TextureRect = $click

var level_root: LevelScene
var hints: Array[Hint] = []
var current_hint: Hint = null

func _ready() -> void:
	Signals.hint_executed.connect(_on_hint_executed)

func setup_tutorial(level: LevelScene):
	level_root = level
	hints = GameState.level.tutorial_hints
	visible = true
	clear_hint()
	
	for hint in hints:
		if hint is ClickHint:
			hint.node = parse_node(hint.node_path)
			hint.setup_signal(hint.node)
		if hint is DragHint:
			hint.intial_node = parse_node(hint.initial_node_path)
			hint.end_node = parse_node(hint.end_node_path)
			hint.setup_signal(hint.end_node)
	show_hint()
	
func _on_hint_executed(hint: Hint):
	if current_hint != hint:
		return
	clear_hint()
	
	hints.pop_front()
	show_hint()
	

func show_hint():
	if len(hints) >= 1:
		current_hint = hints[0]
	else:
		return

	if current_hint is ClickHint:
		click.global_position = current_hint.node.global_position + current_hint.node.size * 0.5
		click.visible = true
	if current_hint is DragHint:
		click.global_position = current_hint.end_node.global_position
		click.visible = true
	
func clear_hint():
	current_hint = null
	click.visible = false
	
	
func parse_node(node_path: String) -> Node:
	var tokens := node_path.split(" ")
	var query := tokens[0]
	var order := tokens[1]
	
	if query == "empty_cell" and order == "f":
		return level_root.grid.get_first_empty_cell()
	if query == "catalog_button" and order == "f":
		return get_first_building_catalog_button()
	return null
	
func get_first_building_catalog_button() ->Button:
	var catalog: Node = level_root.catalog
	for building_catalog: BuildingCatalog in catalog.get_children():
		return building_catalog.button
	return null
