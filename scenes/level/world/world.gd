extends Node2D

const CATALOG_MARGIN = 0

func _ready():
	get_viewport().size_changed.connect(_on_window_resized)
	fit_world()
	move_catalog()

func _on_window_resized():
	fit_world()

func fit_world():
	var viewport_size := get_viewport_rect().size
	var rect : Rect2 = $Grid.get_tilemap_world_rect()

	var scale_x := viewport_size.x / rect.size.x
	var scale_y := viewport_size.y / rect.size.y

	var camera_scale: float = min(scale_x, scale_y)

	$Camera2D.zoom = Vector2.ONE * camera_scale * 0.8
	$Camera2D.global_position = rect.position + rect.size

func move_catalog():
	var rect: Rect2 = $Grid.get_tilemap_world_rect()

	var catalog := $Catalog

	await get_tree().process_frame

	catalog.global_position = Vector2(
		rect.position.x - 100 - CATALOG_MARGIN,
		catalog.global_position.y
	)
	catalog.global_position.x = max(
		catalog.global_position.x,
		get_viewport_rect().position.x + 8
	)
