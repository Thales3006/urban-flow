extends Node2D

const CATALOG_MARGIN = 0

@onready var grid := $Grid
@onready var catalog := $Catalog
@onready var camera:Camera2D = $Camera2D 

func _ready():
	get_viewport().size_changed.connect(_on_window_resized)
	fit_world()
	move_catalog()

func _on_window_resized():
	fit_world()

func fit_world(padding := 0.9) -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var rect: Rect2 = grid.get_tilemap_world_rect()

	if rect.size == Vector2.ZERO:
		return

	# Compute how much of the world fits in the viewport
	var scale_x := viewport_size.x / rect.size.x
	var scale_y := (viewport_size.y - 60) / rect.size.y
	var fit_scale: float = min(scale_x, scale_y) / padding

	# Camera zoom is inverse of scale
	camera.zoom = Vector2.ONE * fit_scale

	# Center camera on the world
	camera.position = rect.position + rect.size - Vector2(0, 60)

func move_catalog():
	var rect: Rect2 = grid.get_tilemap_world_rect()

	await get_tree().process_frame

	catalog.global_position = Vector2(
		rect.position.x - 100 - CATALOG_MARGIN,
		catalog.global_position.y
	)
	catalog.global_position.x = max(
		catalog.global_position.x,
		get_viewport_rect().position.x + 8
	)
