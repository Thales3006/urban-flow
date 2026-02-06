extends PanelContainer

@export var brush_color: Color = Color.BLACK
@export var brush_width: float = 4.0
@export var min_point_distance: float = 2.0

var strokes: Array[PackedVector2Array] = []
var current_stroke: PackedVector2Array
var drawing := false

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		drawing = event.pressed

		if drawing:
			current_stroke = PackedVector2Array()
			current_stroke.append(event.position)
			strokes.append(current_stroke)
			queue_redraw()

	elif event is InputEventMouseMotion and drawing:
		if current_stroke.is_empty():
			current_stroke.append(event.position)
			queue_redraw()
			return

		var last := current_stroke[-1]
		if last.distance_to(event.position) >= min_point_distance:
			current_stroke.append(event.position)
			queue_redraw()

func _draw():
	for stroke in strokes:
		if stroke.size() >= 2:
			draw_polyline(
				stroke,
				brush_color,
				brush_width,
				true
			)

func clear():
	strokes.clear()
	queue_redraw()

func has_drawing() -> bool:
	return not strokes.is_empty()
	
func to_image(resolution: Vector2i) -> Image:
	var vp := SubViewport.new()
	vp.size = resolution
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	vp.transparent_bg = true

	add_child(vp)

	var clone := duplicate()
	clone.position = Vector2.ZERO
	clone.size = resolution
	vp.add_child(clone)

	await RenderingServer.frame_post_draw

	var img := vp.get_texture().get_image()

	remove_child(vp)
	vp.queue_free()

	return img
