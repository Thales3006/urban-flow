extends Node2D

const CATALOG_MARGIN = 0

@onready var grid := $Grid
@onready var camera:Camera2D = $Camera2D 

func _ready():
	get_viewport().size_changed.connect(_on_window_resized)
	_on_window_resized()

func _on_window_resized():
	fit_world()

func fit_world() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var rect: Rect2 = grid.get_tilemap_world_rect()

	if rect.size == Vector2.ZERO:
		return
		
	var scale_x := viewport_size.x / rect.size.x
	var scale_y := viewport_size.y / rect.size.y
	var fit_scale: float = min(scale_x, scale_y)

	camera.zoom = Vector2.ONE * fit_scale
	
