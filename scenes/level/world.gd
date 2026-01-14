extends Node2D

func _ready():
	get_viewport().size_changed.connect(_on_window_resized)

func _on_window_resized():
	var viewport_size = get_viewport_rect().size
	var base_size = Vector2(1280, 720)

	var on_scale: float = min(
		viewport_size.x / base_size.x,
		viewport_size.y / base_size.y
	)

	$Camera2D.zoom = Vector2(on_scale, on_scale)
