extends Resource
class_name LevelData

@export var level: int
@export var max_score: int
@export var layout: PackedScene
@export var available_buildings: Dictionary[BuildingData.Kind, int] = {}
