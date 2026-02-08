extends TextureRect

@export var frames: SpriteFrames
@export var anim_name := "click"
@export var fps := 6.0

var _time := 0.0
var _frame := 0

func _process(delta):
	if not visible or not frames:
		return

	_time += delta
	var frame_time := 1.0 / fps

	if _time >= frame_time:
		_time = 0.0
		_frame = (_frame + 1) % frames.get_frame_count(anim_name)
		texture = frames.get_frame_texture(anim_name, _frame)
