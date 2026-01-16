extends Node2D

func _ready():
	get_viewport().size_changed.connect(_on_window_resized)
	fit_world()

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
