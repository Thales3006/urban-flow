extends Resource
class_name LevelData

@export var level_name: String
@export var max_score: int
@export var tilemap_scene: PackedScene
@export var available_buildings: Dictionary[BuildingData.Kind, int] = {}
