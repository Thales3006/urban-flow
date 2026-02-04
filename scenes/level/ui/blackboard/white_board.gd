extends PanelContainer

var points: PackedVector2Array = []
var drawing := false
var draw_color := Color.WHITE
var draw_width := 3.0

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			drawing = event.pressed
			if drawing:
				points.clear()
				points.append(event.position)
				queue_redraw()

	elif event is InputEventMouseMotion and drawing:
		points.append(event.position)
		queue_redraw()

func _draw() -> void:
	if points.size() < 2:
		return

	for i in range(points.size() - 1):
		draw_line(points[i], points[i + 1], draw_color, draw_width)
