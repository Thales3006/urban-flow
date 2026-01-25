extends Node2D
class_name Cell

const cell = preload("res://scenes/level/world/cell/cell.tscn")
var affecting = []

@onready var negative = $NegativeEffect
@onready var clean = $CleanEffect
@onready var water = $WaterEffect
@onready var positive = $PositiveEffect

var tile: Vector2i
var is_filled: bool = false
	
static func create(pos: Vector2, tile_coord: Vector2i) -> Cell:
	var new_cell: Cell = cell.instantiate()
	new_cell.global_position = pos
	new_cell.tile = tile_coord
	return new_cell
	
func get_size() -> Vector2:
	return $Content/CollisionShape2D.shape.size

func set_no_effect():
	negative.visible = false
	positive.visible = false
	water.visible = false
	clean.visible = false

func set_negative():
	negative.visible = true
	positive.visible = false
	water.visible = false
	clean.visible = false
	
func set_positive():
	negative.visible = false
	positive.visible = true
	water.visible = false
	clean.visible = false

func set_water():
	negative.visible = false
	positive.visible = false
	water.visible = true
	clean.visible = false

func set_clean():
	negative.visible = false
	positive.visible = false
	water.visible = false
	clean.visible = true
