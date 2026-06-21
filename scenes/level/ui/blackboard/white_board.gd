extends PanelContainer
class_name WhiteBoard

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

static func draw_strokes_on(node: CanvasItem, target_strokes: Array[PackedVector2Array], color: Color, width: float) -> void:
	for stroke in target_strokes:
		if stroke.size() == 1:
			node.draw_circle(stroke[0], width, color, true)
		elif stroke.size() >= 2:
			node.draw_polyline(stroke, color, width, true)

func _draw():
	draw_strokes_on(self, strokes, brush_color, brush_width)

func clear():
	strokes.clear()
	queue_redraw()

func has_drawing() -> bool:
	return not strokes.is_empty()

func to_image() -> Image:
	var render_size := Vector2i(maxi(int(size.x), 1), maxi(int(size.y), 1))

	var sub_viewport := SubViewport.new()
	sub_viewport.size = render_size
	sub_viewport.transparent_bg = false
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

	var background := ColorRect.new()
	background.color = Color.WHITE
	background.size = render_size
	sub_viewport.add_child(background)

	var canvas := StrokeCanvas.new()
	canvas.strokes = strokes
	canvas.brush_color = brush_color
	canvas.brush_width = brush_width
	canvas.size = render_size
	sub_viewport.add_child(canvas)

	add_child(sub_viewport)
	# SubViewport needs a couple of frames in the tree before its
	# render target texture is actually populated.
	await get_tree().process_frame
	await get_tree().process_frame

	var img := sub_viewport.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)

	sub_viewport.queue_free()
	return img

func trim_white_borders(img: Image) -> Image:
	var width = img.get_width()
	var height = img.get_height()
	
	var min_x = width
	var min_y = height
	var max_x = -1
	var max_y = -1
	
	for y in range(height):
		for x in range(width):
			var pixel = img.get_pixel(x, y)
			if pixel.r < 0.99 or pixel.g < 0.99 or pixel.b < 0.99:
				min_x = min(min_x, x)
				min_y = min(min_y, y)
				max_x = max(max_x, x)
				max_y = max(max_y, y)
				
	if max_x < min_x or max_y < min_y:
		return img
	
	var rect = Rect2i(
		min_x,
		min_y,
		max_x - min_x + 1,
		max_y - min_y + 1
	)
	
	return img.get_region(rect)

func trim_with_padding(img: Image, padding: int = 10) -> Image:
	var trimmed = trim_white_borders(img)
	
	var new_w = trimmed.get_width() + padding * 2
	var new_h = trimmed.get_height() + padding * 2
	
	var final_img = Image.create(new_w, new_h, false, Image.FORMAT_RGBA8)
	final_img.fill(Color.WHITE)
	
	final_img.blit_rect(
		trimmed,
		Rect2i(0, 0, trimmed.get_width(), trimmed.get_height()),
		Vector2i(padding, padding)
	)
	
	return final_img
