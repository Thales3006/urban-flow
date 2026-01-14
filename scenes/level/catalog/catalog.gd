extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$List.add_child(BuildingCatalog.create(BuildingData.Kind.HOUSE, 2))
	$List.add_child(BuildingCatalog.create(BuildingData.Kind.HOSPITAL, 3))
