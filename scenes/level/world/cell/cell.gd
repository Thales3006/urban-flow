extends Node2D
class_name Cell

const cell = preload("res://scenes/level/world/cell/cell.tscn")
var affecting = []

var tile: Vector2i
var is_filled: bool = false
	
static func create(pos: Vector2, tile_coord: Vector2i) -> Cell:
	var new_cell: Cell = cell.instantiate()
	new_cell.global_position = pos
	new_cell.tile = tile_coord
	return new_cell
	
func get_size() -> Vector2:
	return $Content/CollisionShape2D.shape.size
	
func set_negative():
	$NegativeEffect.visible = true
	
func remove_negative():
	$NegativeEffect.visible = false
