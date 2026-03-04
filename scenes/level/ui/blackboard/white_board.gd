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
		if stroke.size() == 1:
			draw_circle(stroke[0], brush_width, brush_color, true)
		elif stroke.size() >= 2:
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
	
func to_image() -> Image:
	var img := Image.create(size.x as int, size.y as int, false, Image.FORMAT_RGBA8)
	
	# Fundo branco (ou transparente se preferir)
	img.fill(Color.WHITE)
	
	# Desenhar cada stroke manualmente
	for stroke in strokes:
		for i in range(stroke.size() - 1):
			_draw_line_on_image(
				img,
				stroke[i],
				stroke[i + 1],
				brush_color,
				int(brush_width)
			)
	
	return img
	
func _draw_line_on_image(img: Image, from: Vector2, to: Vector2, color: Color, width: int):
	var distance := from.distance_to(to)
	var steps := int(distance)
	
	for i in range(steps):
		var t := float(i) / float(steps)
		var pos := from.lerp(to, t)
		
		for x in range(-width, width):
			for y in range(-width, width):
				var px := int(pos.x) + x
				var py := int(pos.y) + y
				
				if px >= 0 and px < img.get_width() and py >= 0 and py < img.get_height():
					img.set_pixel(px, py, color)

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
