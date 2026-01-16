extends Node2D
class_name Cell

const cell = preload("res://scenes/level/cell/cell.tscn")
var affecting = []

var is_filled: bool = false

func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
	
static func create(pos: Vector2) -> Cell:
	var new_cell: Cell = cell.instantiate()
	new_cell.global_position = pos
	return new_cell
	
func get_size() -> Vector2:
	return $Content/CollisionShape2D.shape.size
