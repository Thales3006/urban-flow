class_name Catalog
extends PanelContainer

@onready var buildingVBox: VBoxContainer = $PanelContainer/List

signal buildings_ready(buildings: Array[Building])

var children: Array[BuildingCatalog] = []

func _ready() -> void:
	var dict: Dictionary[BuildingData.Kind, int] = GameState.level.available_buildings
	for kind in dict:
		var child := BuildingCatalog.create(kind, dict[kind])
		children.push_back(child)
		buildingVBox.add_child(child)
	call_deferred("set_game_state_buildings")

func set_game_state_buildings():
	GameState.set_buildings(get_buildings())
	
	var buildings: Array[Building] = []
	for child: BuildingCatalog in children:
		buildings += child.buildings
	buildings_ready.emit(buildings)
	
func get_buildings() -> Array[Building]:
	var buildings: Array[Building] = []
	for child: BuildingCatalog in children:
		for building in child.buildings:
			buildings.push_back(building)
	return buildings
