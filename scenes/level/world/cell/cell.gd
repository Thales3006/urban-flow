extends Node2D
class_name Cell

const cell = preload("res://scenes/level/world/cell/cell.tscn")
var affecting = []

@onready var sprite: Sprite2D = $MainSprite
@onready var negative: Sprite2D = $NegativeEffect
@onready var clean: Sprite2D = $CleanEffect
@onready var water: Sprite2D = $WaterEffect
@onready var positive: Sprite2D = $PositiveEffect
@onready var trash: Sprite2D = $Trash

@onready var collision_shape: CollisionShape2D = $Content/CollisionShape2D


var tile: Vector2i
var is_filled: bool = false
var is_trashed: bool = false
	
static func create(pos: Vector2, tile_coord: Vector2i) -> Cell:
	var new_cell: Cell = cell.instantiate()
	new_cell.global_position = pos
	new_cell.tile = tile_coord
	return new_cell
	
func get_size() -> Vector2:
	return collision_shape.shape.size

func is_recycled():
	for b: Building in affecting:
		if b.data.kind == BuildingData.Kind.RECYCLING:
			return true
	return false

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
	
func set_trashed():
	trash.visible = true
	is_trashed = true
