extends Control
class_name StrokeCanvas

var strokes: Array[PackedVector2Array] = []
var brush_color: Color = Color.BLACK
var brush_width: float = 4.0

func _draw() -> void:
	WhiteBoard.draw_strokes_on(self, strokes, brush_color, brush_width)
