extends HBoxContainer
class_name BuildingCatalog

const buildingCatalog = preload("res://scenes/level/world/catalog/building_catalog.tscn")
const distance = 30

static func create(kind: BuildingData.Kind, n: int) -> BuildingCatalog:
	var new := buildingCatalog.instantiate()
	for i in n:
		var new_y = sin((i + new.global_position.y - new.global_position.x) * 4) * 10
		new.add_child(Building.create(kind, new.position + Vector2(distance * i, new_y)))
	return new

func _ready() -> void:
	pass
