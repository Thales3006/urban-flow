class_name LevelScene
extends Node

@onready var tutorial: Tutorial = $UILayer/Tutorial
@onready var catalog: Catalog = $Background/Catalog
@onready var grid: Grid = $WorldLayer/World/Grid
@onready var blackboard: Blackboard = $UILayer/UI/Blackboard
@onready var catalog_buttons := $UILayer/UI/CatalogButtons

func _ready() -> void:
	catalog.buildings_ready.connect(_on_buildings_ready)

func _on_buildings_ready(buildings: Array[Building]):
	grid.set_buildings(buildings)
	tutorial.setup_tutorial(self)
	
	
