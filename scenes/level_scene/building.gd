extends Node2D
class_name Building

const building = preload("res://scenes/level_scene/building.tscn")

var mouse_in: bool = false
var dragging: bool = false
var area2D: Area2D
var initialPos: Vector2

static func create(pos: Vector2) -> Building:
	var new_building: Building = building.instantiate()
	new_building.position = pos
	new_building.initialPos = pos
	return new_building

func _ready() -> void:
	area2D = $Area2D
	
func _process(_delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and dragging:
		global_position = get_global_mouse_position()
	if event is InputEventMouseButton:
		if not mouse_in:
			return
		if event.pressed:
			dragging = true
			global.is_dragging = true
		elif not event.pressed and dragging:
			dragging = false
			global.is_dragging = false
		
			var tween = get_tree().create_tween()
			var closest_cell = get_closest_overlapping_cell()
			if closest_cell:
				tween.tween_property(self, "global_position", closest_cell.global_position, 0.2).set_ease(Tween.EASE_OUT)
			else:
				tween.tween_property(self, "global_position", initialPos, 0.2).set_ease(Tween.EASE_OUT)

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
	return closest_cell

func _on_area_2d_body_entered(body) -> void:
	get_tree().create_tween().tween_property(body, "scale", Vector2(1.05,1.1), 0.2).set_ease(Tween.EASE_OUT)

func _on_area_2d_body_exited(body) -> void:
	get_tree().create_tween().tween_property(body, "scale", Vector2(1,1), 0.2).set_ease(Tween.EASE_OUT)
		
func _on_area_2d_mouse_entered() -> void:
	if not global.is_dragging:
		mouse_in = true
		get_tree().create_tween().tween_property(self, "scale", Vector2(1.05,1.05), 0.05).set_ease(Tween.EASE_OUT)

func _on_area_2d_mouse_exited() -> void:
	if not global.is_dragging:
		mouse_in = false
		get_tree().create_tween().tween_property(self, "scale", Vector2(1,1), 0.05).set_ease(Tween.EASE_OUT)
	
