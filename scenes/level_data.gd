extends Resource
class_name LevelData

enum CellType {
	EMPTY,
	FILLED,
	BLOCKED
}

@export var level_name: String = ""
@export var grid_width: int = 0
@export var grid_height: int = 0
@export var grid_layout: Array[CellType] = []
@export var available_buildings: Dictionary = {}
