extends Node2D
class_name Cell

const cell = preload("res://scenes/level/world/cell/cell.tscn")
var affecting: Array[Building] = []

@onready var sprite: Sprite2D = $MainSprite
@onready var negative: Sprite2D = $NegativeEffect
@onready var clean: Sprite2D = $CleanEffect
@onready var water: Sprite2D = $WaterEffect
@onready var positive: Sprite2D = $PositiveEffect
@onready var trash: Sprite2D = $Trash

@onready var body: StaticBody2D = $Content
@onready var collision_shape: CollisionShape2D = $Content/CollisionShape2D

signal was_filled()

var tile: Vector2i
var is_filled: bool = false
var is_trashed: bool = false
var is_disabled: bool = false
	
static func create(pos: Vector2, tile_coord: Vector2i) -> Cell:
	var new_cell: Cell = cell.instantiate()
	new_cell.global_position = pos
	new_cell.tile = tile_coord
	return new_cell
	
func _ready() -> void:
	Signals.disable_others.connect(_on_disable_others)
	
func get_size() -> Vector2:
	return collision_shape.shape.size
	
func is_being_affected_by(kind: BuildingData.Kind) -> bool:
	for b: Building in affecting:
		if b.data.kind == kind:
			return true
	return false
	
func _on_disable_others(nodes: Array[Node]):
	is_disabled = not nodes.has(self)

func is_recycled() -> bool:
	return is_being_affected_by(BuildingData.Kind.RECYCLING)
	
func has_hospital() -> bool:
	return is_being_affected_by(BuildingData.Kind.HOSPITAL)
	
func has_water() -> bool:
	return is_being_affected_by(BuildingData.Kind.WATER)
	


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
