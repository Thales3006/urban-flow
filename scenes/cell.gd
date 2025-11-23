extends StaticBody2D
class_name Cell

const cell = preload("res://scenes/cell.tscn")

func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
	
static func create(pos: Vector2) -> Cell:
	var new_cell: Cell = cell.instantiate()
	new_cell.position = pos
	return new_cell
	
func get_size() -> Vector2:
	return $CollisionShape2D.shape.size
