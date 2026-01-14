extends Node2D
class_name Building

const building = preload("res://scenes/level/grid/building/building.tscn")
const BUILDING_DATA := {
	BuildingData.Kind.HOUSE: preload("res://buildings/house.tres"),
	BuildingData.Kind.HOSPITAL: preload("res://buildings/hospital.tres"),
}

@export var data: BuildingData
var mouse_in: bool = false
var dragging: bool = false
var current_cell: Cell = null
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
	var shape = $EffectArea/Shape.shape
	if shape is CircleShape2D:
		shape = shape.duplicate()
		shape.radius = data.radius * 100
		$EffectArea/Shape.shape = shape


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and dragging:
		global_position = get_global_mouse_position()
	if event is InputEventMouseButton:
		if not mouse_in:
			return
		if event.pressed and not global.is_dragging:
			dragging = true
			global.is_dragging = true
			if current_cell != null:
				current_cell.is_filled = false
				current_cell = null
			global_position = get_global_mouse_position()
		elif not event.pressed and dragging:
			dragging = false
			global.is_dragging = false
		
			var tween = get_tree().create_tween()
			var closest_cell: Cell = get_closest_overlapping_cell()
			if closest_cell and not closest_cell.is_filled:
				closest_cell.is_filled = true
				current_cell = closest_cell
				tween.tween_property(self, "global_position", closest_cell.global_position, 0.2).set_ease(Tween.EASE_OUT)
			else:
				tween.tween_property(self, "position", initialPos, 0.2).set_ease(Tween.EASE_OUT)

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

func _on_area_2d_body_entered(body) -> void:
	var cell = body.get_parent()
	get_tree().create_tween().tween_property(cell, "scale", Vector2(1.1,1.1), 0.2).set_ease(Tween.EASE_OUT)

func _on_area_2d_body_exited(body) -> void:
	var cell = body.get_parent()
	get_tree().create_tween().tween_property(cell, "scale", Vector2(1,1), 0.2).set_ease(Tween.EASE_OUT)
		
func _on_area_2d_mouse_entered() -> void:
	if not global.is_dragging:
		mouse_in = true
		get_tree().create_tween().tween_property($Sprite2D, "scale", initialScale * 1.05, 0.05).set_ease(Tween.EASE_OUT)

func _on_area_2d_mouse_exited() -> void:
	if not global.is_dragging:
		mouse_in = false
		get_tree().create_tween().tween_property($Sprite2D, "scale", initialScale, 0.05).set_ease(Tween.EASE_OUT)
	
