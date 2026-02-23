class_name Tutorial
extends Control

@onready var click: TextureRect = $click
@onready var drag: TextureRect = $drag

var level_root: LevelScene
var hints: Array[Hint] = []
var current_hint: Hint = null
var tween: Tween = null

func _ready() -> void:
	Signals.hint_executed.connect(_next_hint)
	get_tree().root.size_changed.connect(_on_window_resized)

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
			hint.initial_node = parse_node(hint.initial_node_path)
			hint.end_node = parse_node(hint.end_node_path)
			hint.setup_signal(hint.end_node)
		if hint is InvisibleHint:
			hint.node = parse_node(hint.node_path)
			hint.setup_signal(hint.node)
	
	if len(hints) >= 1:
		current_hint = hints[0]
		show_hint()
	
func _next_hint(hint: Hint):
	if current_hint != hint:
		return
	clear_hint()
	
	hints.pop_front()
	if len(hints) >= 1:
		current_hint = hints[0]
		show_hint()
	else:
		return
	
func _on_window_resized():
	show_hint()

func show_hint():
	if current_hint == null:
		click.visible = false
		drag.visible = false
		return
		
	current_hint.disable_others()
	if tween:
			tween.kill()
	
	if current_hint is ClickHint:
		var node: Node = current_hint.node
		
		click.global_position = get_node_view_pos(node)
		click.visible = true
		click.modulate.a = 0.0
		
		tween = create_tween()
		tween.tween_interval(0.2)
		tween.tween_property(
			click,
			"modulate:a",
			1.0,
			0.25
		)
		
	if current_hint is DragHint:

		var start_pos := get_node_view_pos(current_hint.initial_node)
		var end_pos := get_node_view_pos(current_hint.end_node)

		drag.global_position = start_pos
		drag.modulate.a = 0.0
		drag.visible = true

		tween = create_tween()
		tween.set_loops()

		tween.tween_callback(func():
			drag.global_position = start_pos
		)
		tween.tween_interval(0.8)
		tween.tween_property(
			drag,
			"modulate:a",
			1.0,
			0.25
		)
		tween.tween_property(
			drag,
			"global_position",
			end_pos,
			1.5
		)
		tween.tween_interval(0.4)
		tween.tween_property(
			drag,
			"modulate:a",
			0.0,
			0.25
		)


func get_node_view_pos(node: Node) -> Vector2:
	if node is Control:
		return node.global_position + node.size * 0.5
	if node is Node2D:
		var viewport := level_root.get_viewport()
		return viewport.get_canvas_transform() * node.global_position
	return Vector2.ZERO

func clear_hint():
	current_hint = null
	click.visible = false
	drag.visible = false
	Signals.enable_all.emit()
	
	
func parse_node(node_path: String) -> Node:
	var tokens := node_path.split(" ")
	var query := tokens[0]
	
	if query == "cell":
		return level_root.grid.get_cell(
			Vector2i(tokens[1].to_int(), tokens[2].to_int())
		)
	if query == "catalog_button" and tokens[1] == "f":
		return get_first_building_catalog_button()
	if query == "house":
		return level_root.grid.get_building(BuildingData.Kind.HOUSE, tokens[1].to_int())
	if query == "blackboard_confirm":
		return level_root.blackboard
	return null
	
func get_first_building_catalog_button() -> Button:
	var catalog: VBoxContainer = level_root.catalog.buildingVBox
	for building_catalog: BuildingCatalog in catalog.get_children():
		return building_catalog.button
	return null
