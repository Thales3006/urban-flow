class_name Tutorial
extends Control

@onready var click: TextureRect = $click
@onready var drag: TextureRect = $drag
@onready var draw_icon: TextureRect = $draw

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
		if hint is DrawHint:
			hint.node = level_root.blackboard.whiteboard
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
		
	if current_hint is DrawHint:
		var whiteboard: PanelContainer = current_hint.node as PanelContainer

		await get_tree().create_timer(1.5).timeout
		# Unlike create_tween(), this timer isn't bound to this node's
		# lifetime -- if the level was exited while this was pending,
		# resuming here would touch a freed node. Bail out instead.
		if not is_inside_tree():
			return
		var wb_pos := whiteboard.global_position
		var wb_size := whiteboard.size

		const AMPLITUDE := 40.0
		const DURATION := 2.0
		const STEPS := 60
		const frequency := 3
		const COVERAGE := 0.6  
		const VERTICAL_OFFSET := 20.0
		draw_icon.visible = true
		draw_icon.modulate.a = 0.0
		tween = create_tween()
		tween.set_loops()
		# Fade in inicial
		tween.tween_property(draw_icon, "modulate:a", 1.0, 0.25)
		# Anima manualmente via método
		var full_width := wb_size.x - draw_icon.size.x
		var margin := full_width * (1.0 - COVERAGE) * 0.5
		var start_x := wb_pos.x + margin
		var end_x := wb_pos.x + full_width - margin
		var center_y := wb_pos.y + wb_size.y * 0.5 - draw_icon.size.y * 0.5 + VERTICAL_OFFSET
		draw_icon.global_position = Vector2(start_x, center_y)
		for i in range(STEPS + 1):
			var t := float(i) / float(STEPS)
			var x := start_x + t * (end_x - start_x)
			var y := center_y + sin(t * TAU * frequency) * AMPLITUDE
			tween.tween_property(draw_icon, "global_position", Vector2(x, y), DURATION / STEPS)
		tween.tween_property(draw_icon, "modulate:a", 0.0, 0.25)
		tween.tween_callback(func():
			draw_icon.global_position = Vector2(start_x, center_y)
		)
		tween.tween_interval(0.4)



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
	draw_icon.visible = false
	Signals.enable_all.emit()
	
	
func parse_node(node_path: String) -> Node:
	var tokens := node_path.split(" ")
	var query := tokens[0]

	var result: Node = null
	if query == "cell":
		result = level_root.grid.get_cell(
			Vector2i(tokens[1].to_int(), tokens[2].to_int())
		)
	elif query == "catalog_button" and tokens[1] == "f":
		result = get_first_building_catalog_button()
	elif query == "house":
		result = level_root.grid.get_building(BuildingData.Kind.HOUSE, tokens[1].to_int())
	elif query == "blackboard_confirm":
		result = level_root.blackboard

	if result == null:
		push_warning("Tutorial: could not resolve hint node path '%s'" % node_path)
	return result
	
func get_first_building_catalog_button() -> Button:
	var catalog_buttons: Control = level_root.catalog_buttons
	for button: Button in catalog_buttons.get_children():
		return button
	return null
