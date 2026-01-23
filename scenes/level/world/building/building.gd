extends Node2D
class_name Building

const building = preload("res://scenes/level/world/building/building.tscn")
const BUILDING_DATA := {
	BuildingData.Kind.HOUSE: preload("res://buildings/house.tres"),
	BuildingData.Kind.HOSPITAL: preload("res://buildings/hospital.tres"),
}

enum State {
	LOCKED,
	FIXED,
	FREE
}

@export var data: BuildingData
var mouse_in: bool = false
var dragging: bool = false
var current_cell: Cell = null
var state: State = State.FREE
var will_affect = []
var affecting = []

var area2D: Area2D
var initialPos: Vector2
var initialScale: Vector2

static func create(kind: BuildingData.Kind, pos: Vector2) -> Building:
	var new := building.instantiate()
	new.position = pos
	new.initialPos = pos
	new.data = BUILDING_DATA[kind]
	
	return new

func _ready() -> void:
	if data == null:
		push_error("Building sem tipo!")
		return
	area2D = $Drag
	$Sprite2D.texture = data.sprite
	$Sprite2D.scale *= data.sprite_scale
	initialScale = $Sprite2D.scale
	var shape = $EffectArea/Shape.shape.duplicate()
	if shape is RectangleShape2D:
			shape.size = Vector2.ONE * data.radius * 180
	if shape is CircleShape2D:
			shape.radius = data.radius * 100
	$EffectArea/Shape.shape = shape


func _input(event: InputEvent) -> void:
	if state != State.FREE:
		return
	if event is InputEventMouseMotion and dragging:
		global_position = get_global_mouse_position()
	if event is InputEventMouseButton:
		if not mouse_in:
			return
		# Grabbed building ======================
		if event.pressed and not global.is_dragging:
			dragging = true
			global.is_dragging = true
			if current_cell != null:
				current_cell.is_filled = false
				current_cell = null
			for cell: Cell in get_overlapping_cells(): 
				will_affect.push_back(cell)
				set_affect_feedback(cell)
			remove_affect_all()
			global_position = get_global_mouse_position()
			
	 	# Droped building =======================
		elif not event.pressed and dragging:
			dragging = false
			global.is_dragging = false
		
			var tween = get_tree().create_tween()
			var closest_cell: Cell = get_closest_overlapping_cell()
			if closest_cell and not closest_cell.is_filled:
				closest_cell.is_filled = true
				current_cell = closest_cell
				push_affect_all()
				tween.tween_property(self, "global_position", closest_cell.global_position, 0.2).set_ease(Tween.EASE_OUT)
			else:
				tween.tween_property(self, "position", initialPos, 0.5).set_ease(Tween.EASE_OUT)
			for cell in will_affect:
				remove_affect_feedback(cell)
			will_affect.clear()
					

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
	$Sprite2D.modulate.a = 1

func set_locked():
	state = State.LOCKED
	$Sprite2D.modulate.a = 0.5

func set_fixed():
	state = State.FIXED
	$Sprite2D.modulate.a = 1


func set_affect_feedback(cell: Cell):
	cell.set_negative()

func remove_affect_feedback(cell: Cell):
	cell.remove_negative()
	
	
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
	if not global.is_dragging:
		return
	var cell = body.get_parent()
	if cell is Cell:
		get_tree().create_tween().tween_property(cell, "scale", Vector2(1.1,1.1), 0.2).set_ease(Tween.EASE_OUT)
		
func _on_area_2d_body_exited(body) -> void:
	if not global.is_dragging:
		return
	var cell = body.get_parent()
	if cell is Cell:
		get_tree().create_tween().tween_property(cell, "scale", Vector2(1,1), 0.2).set_ease(Tween.EASE_OUT)
		
func _on_area_2d_mouse_entered() -> void:
	if not global.is_dragging:
		mouse_in = true
		get_tree().create_tween().tween_property($Sprite2D, "scale", initialScale * 1.05, 0.05).set_ease(Tween.EASE_OUT)

func _on_area_2d_mouse_exited() -> void:
	if not global.is_dragging:
		mouse_in = false
		get_tree().create_tween().tween_property($Sprite2D, "scale", initialScale, 0.05).set_ease(Tween.EASE_OUT)
	
func _on_effect_area_entered(body) -> void:
	if not global.is_dragging:
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
