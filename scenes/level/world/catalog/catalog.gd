extends Node2D

var children: Array[BuildingCatalog] = []

func _ready() -> void:
	var dict: Dictionary[BuildingData.Kind, int] = GameState.level.available_buildings
	for kind in dict:
		var child := BuildingCatalog.create(kind, dict[kind])
		children.push_back(child)
		$Control/PanelContainer/List.add_child(child)
	GameState.set_buildings(get_buildings())

func get_buildings() -> Array[Building]:
	var buildings: Array[Building] = []
	for child: BuildingCatalog in children:
		for building in child.buildings:
			buildings.push_back(building)
	return buildings
