extends Control
class_name NumberWheel

signal value_changed(value:int)

@export var min_value := 1
@export var max_value := 10
@export var item_height := 48
@export var visible_items := 5
@export var default_value := 1

var labels := []
var value := 0
var real_value := 0
var offset := 0.0
var velocity := 0.0
var dragging := false
var last_mouse_y := 0.0

@onready var items := $Items

func _ready():
	assert(visible_items % 2 == 1)
	value = clamp(default_value, min_value, max_value)
	_build_items()
	_center_on_value(value)
	set_process(true)

func _build_items():
	for c in items.get_children():
		c.queue_free()
	labels.clear()
	var count := visible_items + 2
	for i in count:
		var lbl := Label.new()
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.custom_minimum_size = Vector2(size.x, item_height)
		lbl.size = Vector2(size.x, item_height)
		lbl.anchors_preset = Control.PRESET_FULL_RECT  # fill available width
		items.add_child(lbl)
		labels.append(lbl)
	_update_labels()

func _update_labels():
	var snapped_steps := int(floor(offset / item_height))
	var local_offset := offset - snapped_steps * item_height
	var center := labels.size() >> 1
	var center_y := size.y / 2.0

	for i in labels.size():
		var relative := i - center + snapped_steps
		var v := _wrap_value(value + relative)
		labels[i].text = str(v)

		var pos_y := (
			i * item_height
			- center * item_height
			- local_offset
			+ center_y
		)
		labels[i].position = Vector2(0.0, pos_y)
		labels[i].size = Vector2(items.size.x, item_height)

		var label_center_y := pos_y + item_height
		var dist: float = abs(label_center_y - center_y) / item_height
		var alpha: float = clamp(1.0 - dist / (visible_items / 2.0), 0.15, 1.0)
		labels[i].modulate = Color(1, 1, 1, alpha)
		labels[i].z_index = int(alpha * 10.0)
		
func _process(delta):
	if dragging:
		return
	if abs(velocity) > 0.1:
		offset += velocity * delta
		velocity *= 0.2
		_update_labels()
	else:
		velocity = 0
		_snap()

func _snap():
	var target: float = round(offset / item_height) * item_height
	offset = lerp(offset, target, 0.3)

	if abs(offset - target) < 0.5:
		offset = target
		var delta := int(round(offset / item_height))
		value = _wrap_value(value + delta)
		real_value = _wrap_value(value - 1)
		offset = 0.0
		_update_labels()
		if delta != 0:
			value_changed.emit(real_value)
		return

	_update_labels()

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
				velocity = 0.0
				last_mouse_y = event.position.y
			else:
				dragging = false
				if abs(velocity) < 50.0:
					velocity = 0.0
					_snap()

	if event is InputEventMouseMotion and dragging:
		var dy: float = event.position.y - last_mouse_y
		last_mouse_y = event.position.y
		offset -= dy
		velocity = -dy / get_process_delta_time()
		_update_labels()

func _wrap_value(v: int) -> int:
	var range_size := max_value - min_value + 1
	return min_value + posmod(v - min_value, range_size)

func _center_on_value(v: int):
	value = v
	offset = 0.0
	_update_labels()

func set_value(v: int):
	v = clamp(v, min_value, max_value)
	value = v
	offset = 0.0
	_update_labels()
	value_changed.emit(value)

func get_value() -> int:
	return value
