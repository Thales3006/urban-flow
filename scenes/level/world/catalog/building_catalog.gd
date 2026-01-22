extends Control
class_name BuildingCatalog

const buildingCatalog = preload("res://scenes/level/world/catalog/building_catalog.tscn")
const distance = 30

var buildings: Array[Building] = []

static func create(kind: BuildingData.Kind, n: int) -> BuildingCatalog:
	var new := buildingCatalog.instantiate()
	var hbox := new.get_node("AvailableBuilding")
	for i in n:
		var new_y = sin((i + new.global_position.y - new.global_position.x) * 4) * 10
		var building := Building.create(kind, hbox.position + Vector2(distance * i, new_y))
		building.set_locked()
		hbox.add_child(building)
		new.buildings.push_back(building)
		
	return new

func _ready() -> void:
	pass


func _on_button_pressed() -> void:
	for building: Building in buildings:
		building.set_free()
