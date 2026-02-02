extends Node2D
class_name Building

const building = preload("res://scenes/level/world/building/building.tscn")
const BUILDING_DATA := {
	BuildingData.Kind.HOUSE: preload("res://buildings/house.tres"),
	BuildingData.Kind.HOSPITAL: preload("res://buildings/hospital.tres"),
	BuildingData.Kind.RECYCLING: preload("res://buildings/recycling.tres"),
}

enum State {
	LOCKED,
	FIXED,
	FREE,
}

var dragging: bool = false
var current_cell: Cell = null
var state: State = State.FREE
var will_affect = []
var affecting = []

@onready var sprite: Sprite2D = $Sprite2D
@export var data: BuildingData
@export var catalog: BuildingCatalog
var area2D: Area2D
var initialPos: Vector2
var initialScale: Vector2

static func create(kind: BuildingData.Kind, pos: Vector2) -> Building:
	var new : Building = building.instantiate()
	new.initialPos = pos
	new.data = BUILDING_DATA[kind]
	return new

func _ready() -> void:
	if data == null:
		push_error("Building sem tipo!")
		return
	area2D = $Drag
	sprite.texture = data.sprite
	sprite.scale *= data.sprite_scale
	initialScale = sprite.scale
	var shape = $EffectArea/Shape.shape.duplicate()
	if shape is RectangleShape2D:
			shape.size = Vector2.ONE * data.radius * 180
	if shape is CircleShape2D:
			shape.radius = data.radius * 100
	$EffectArea/Shape.shape = shape
	get_viewport().size_changed.connect(_on_window_resized)
	
	call_deferred("_post_ready")

func _post_ready():
	_on_window_resized()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and dragging:
		global_position = get_global_mouse_position()
	if event is InputEventMouseButton:
		if not event.pressed and dragging:
			dragging = false
			Global.is_dragging = false
		
			var tween = get_tree().create_tween()
			var closest_cell: Cell = get_closest_overlapping_cell()
			if closest_cell and not closest_cell.is_filled:
				closest_cell.is_filled = true
				current_cell = closest_cell
				push_affect_all()
				tween.tween_property(self, "global_position", closest_cell.global_position, 0.2).set_ease(Tween.EASE_OUT)
			else:
				current_cell = null
				tween.tween_property(self, "global_position", get_world_catalog_pos() + initialPos, 0.5).set_ease(Tween.EASE_OUT)
			for cell in will_affect:
				remove_affect_feedback(cell)
			Signals.building_placed.emit()
			will_affect.clear()

func compute_score() -> float:
	if current_cell == null:
		return 0
	var affected := {
		BuildingData.Kind.HOUSE: false,
		BuildingData.Kind.HOSPITAL: false,
		BuildingData.Kind.RECYCLING: false,
	}
	var is_happy := false
	var score := data.score
	for effect: Building in current_cell.affecting:
		if effect == self:
			continue
		match effect.data.kind:
			BuildingData.Kind.HOSPITAL:
				if affected[BuildingData.Kind.HOSPITAL]:
					continue
					
				if data.kind != BuildingData.Kind.HOUSE:
					continue
					
				is_happy = true
				score *= effect.data.effect
				affected[BuildingData.Kind.HOSPITAL] = true
	$happy.visible = is_happy
	return score
# =============================
# Overlaping cells
# =============================

func get_closest_overlapping_cell():
	if not area2D:
		return null
	var overlapping_bodies = area2D.get_overlapping_bodies()
	var dropable_cells = []
	for body in overlapping_bodies:
		if body.is_in_group('dropable'):
			dropable_cells.append(body)
			
	var closest_cell = null
	var min_distance = INF
	for cell in dropable_cells:
		var distance = global_position.distance_to(cell.global_position)
		if distance < min_distance:
			min_distance = distance
			closest_cell = cell
	if closest_cell != null:
		return closest_cell.get_parent()
	else:
		return null

func get_overlapping_cells() -> Array[Cell]: 
	var cells: Array[Cell]
	for body in $EffectArea.get_overlapping_bodies():
		var cell = body.get_parent()
		if cell is Cell:
			cells.push_back(cell)
	return cells

# VISUAL FEEDBACK =========================

func set_free():
	state = State.FREE
	$Sprite2D.modulate = Color(1, 1, 1, 1)

func set_locked():
	state = State.LOCKED
	$Sprite2D.modulate = Color(0.1, 0.1, 0.1, 1.0)

func set_fixed():
	state = State.FIXED
	$Sprite2D.modulate = Color(1, 1, 1, 1)


func set_affect_feedback(cell: Cell):
	match data.kind:
		BuildingData.Kind.HOUSE:
			pass
		BuildingData.Kind.HOSPITAL:
			cell.set_positive()
		BuildingData.Kind.RECYCLING:
			cell.set_clean()
			
	
func remove_affect_feedback(cell: Cell):
	cell.set_no_effect()
	
	
func push_affect_all():
	for cell in will_affect:
		cell.affecting.push_back(self)
		affecting.push_back(cell)

func remove_affect_all():
	for cell in affecting:
		cell.affecting.erase(self)


# =============================
#  Signals
# =============================

func _on_area_2d_body_entered(body) -> void:
	if not Global.is_dragging:
		return
	var cell = body.get_parent()
	if cell is Cell:
		get_tree().create_tween().tween_property(cell, "scale", Vector2(1.1,1.1), 0.2).set_ease(Tween.EASE_OUT)
		
func _on_area_2d_body_exited(body) -> void:
	if not Global.is_dragging:
		return
	var cell = body.get_parent()
	if cell is Cell:
		get_tree().create_tween().tween_property(cell, "scale", Vector2(1,1), 0.2).set_ease(Tween.EASE_OUT)
		
func _on_area_2d_mouse_entered() -> void:
	if not Global.is_dragging and  state == State.FREE:
		get_tree().create_tween().tween_property(sprite, "scale", initialScale * 1.05, 0.05).set_ease(Tween.EASE_OUT)

func _on_area_2d_mouse_exited() -> void:
		get_tree().create_tween().tween_property(sprite, "scale", initialScale, 0.05).set_ease(Tween.EASE_OUT)
	
func _on_effect_area_entered(body) -> void:
	if not Global.is_dragging:
		return
	var cell = body.get_parent()
	
	if cell is Cell:
		will_affect.push_back(cell)
		set_affect_feedback(cell)

func _on_effect_area_exited(body) -> void:
	var cell = body.get_parent()
	if cell is Cell:
		will_affect.erase(cell)
		remove_affect_feedback(cell)


func _on_drag_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if state != State.FREE:
		return
	if event is InputEventMouseButton:
		# Grabbed building ======================
		if event.pressed and not Global.is_dragging:
			dragging = true
			Global.is_dragging = true
			if current_cell != null:
				current_cell.is_filled = false
				current_cell = null
			for cell: Cell in get_overlapping_cells(): 
				will_affect.push_back(cell)
				set_affect_feedback(cell)
			remove_affect_all()
			global_position = get_global_mouse_position()
			Signals.building_placed.emit()

func _on_window_resized():
	var viewport := get_viewport()
	var cam := viewport.get_camera_2d()
	
	global_position = get_world_catalog_pos() + initialPos
	
func get_world_catalog_pos() -> Vector2:
	var viewport := get_viewport()
	var cam := viewport.get_camera_2d()

	var screen_pos: Vector2 = catalog.buildingHBox.get_global_rect().position
	return viewport.get_canvas_transform().affine_inverse() * screen_pos
