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
	return result

# Same preprocessing the model was trained/exported with: resize to the
# model's input size, flip RGB to BGR, then MobileNetV2 preprocess_input
# (mode='tf'): scale to [-1, 1].
func _image_to_model_input(img: Image) -> PackedFloat32Array:
	var resized: Image = img.duplicate()
	resized.convert(Image.FORMAT_RGB8)
	resized.resize(MODEL_INPUT_SIZE, MODEL_INPUT_SIZE, Image.INTERPOLATE_BILINEAR)
	var data := resized.get_data()

	var floats := PackedFloat32Array()
	floats.resize(MODEL_INPUT_SIZE * MODEL_INPUT_SIZE * 3)
	for y in range(MODEL_INPUT_SIZE):
		for x in range(MODEL_INPUT_SIZE):
			var idx := (y * MODEL_INPUT_SIZE + x) * 3
			var r := float(data[idx])
			var g := float(data[idx + 1])
			var b := float(data[idx + 2])
			floats[idx] = b / 127.5 - 1.0
			floats[idx + 1] = g / 127.5 - 1.0
			floats[idx + 2] = r / 127.5 - 1.0
	return floats
