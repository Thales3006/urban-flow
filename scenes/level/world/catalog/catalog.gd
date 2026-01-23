extends Node2D

func _ready() -> void:
	var dict := global.level.available_buildings
	for kind in dict:
		$Control/PanelContainer/List.add_child(BuildingCatalog.create(kind, dict[kind]))
