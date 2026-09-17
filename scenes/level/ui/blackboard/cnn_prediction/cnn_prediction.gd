extends Node
class_name CnnPrediction

const MODEL_PATH := "res://model/model.tflite"
const MODEL_INPUT_SIZE := 324
const CLASS_NAMES := ["Reciclagem", "Saneamento", "Hospital", "Escola", "Moradia", "nonsense"]

var local_predictor: Object = null
var local_predictor_ready := false

func _ready() -> void:
	_try_load_local_predictor()

func _try_load_local_predictor() -> void:
	if not ClassDB.class_exists("TFLitePredictor"):
		push_error("CnnPrediction: TFLitePredictor GDExtension not available on this platform/build")
		return
	var predictor = ClassDB.instantiate("TFLitePredictor")
	if predictor.load_model(MODEL_PATH):
		local_predictor = predictor
		local_predictor_ready = true
	else:
		push_error("CnnPrediction: failed to load model at " + MODEL_PATH)

func get_prediction(img: Image) -> Dictionary[String, float]:
	if not local_predictor_ready:
		return {}

	var output: PackedFloat32Array = local_predictor.predict(_image_to_model_input(img))
	if output.size() != CLASS_NAMES.size():
		return {}

	var result: Dictionary[String, float] = {}
	for i in range(CLASS_NAMES.size()):
		result[CLASS_NAMES[i]] = output[i]
	print(result)
	return result

# Preprocessing contract mirrors training_common.py exactly:
#   1. Letterbox resize to MODEL_INPUT_SIZE (aspect-preserving + white padding).
#      A squash resize distorts wide words (Reciclagem, Saneamento) far more
#      than compact ones (Escola), which biases the classifier — this was the
#      squash-resize bug fixed in the training pipeline in Round 1.
#   2. Flip RGB→BGR to match cv2.imread channel order used during training.
#   3. Pass raw [0, 255] floats — normalization is baked into the TFLite model
#      (Rescaling layer), so applying it here would double-normalize and collapse
#      all pixel variance into a tiny band around -1.0.
func _image_to_model_input(img: Image) -> PackedFloat32Array:
	var src: Image = img.duplicate()
	src.convert(Image.FORMAT_RGB8)

	# Letterbox: scale uniformly so the larger dimension fills MODEL_INPUT_SIZE,
	# then center-paste onto a white canvas.
	var w: float = float(src.get_width())
	var h: float = float(src.get_height())
	var scale: float = minf(float(MODEL_INPUT_SIZE) / w, float(MODEL_INPUT_SIZE) / h)
	var new_w: int = int(round(w * scale))
	var new_h: int = int(round(h * scale))
	if new_w < 1: new_w = 1
	if new_h < 1: new_h = 1
	src.resize(new_w, new_h, Image.INTERPOLATE_BILINEAR)

	var canvas: Image = Image.create(MODEL_INPUT_SIZE, MODEL_INPUT_SIZE, false, Image.FORMAT_RGB8)
	canvas.fill(Color.WHITE)
	var x_off: int = (MODEL_INPUT_SIZE - new_w) / 2
	var y_off: int = (MODEL_INPUT_SIZE - new_h) / 2
	canvas.blit_rect(src, Rect2i(0, 0, new_w, new_h), Vector2i(x_off, y_off))

	var data: PackedByteArray = canvas.get_data()
	var floats: PackedFloat32Array = PackedFloat32Array()
	floats.resize(MODEL_INPUT_SIZE * MODEL_INPUT_SIZE * 3)
	for y: int in range(MODEL_INPUT_SIZE):
		for x: int in range(MODEL_INPUT_SIZE):
			var idx: int = (y * MODEL_INPUT_SIZE + x) * 3
			var r: float = float(data[idx])
			var g: float = float(data[idx + 1])
			var b: float = float(data[idx + 2])
			floats[idx] = b
			floats[idx + 1] = g
			floats[idx + 2] = r
	return floats
