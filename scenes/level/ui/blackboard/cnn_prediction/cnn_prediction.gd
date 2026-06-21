extends Node
class_name CnnPrediction

const PREDICTION_ADDRESS = Global.server_url + "/predict"
const REQUEST_TIMEOUT_SECONDS := 10.0

const MODEL_PATH := "res://server_predict/model.tflite"
const MODEL_INPUT_SIZE := 324
const CLASS_NAMES := ["Reciclagem", "Saneamento", "Hospital", "Escola", "Moradia", "nonsense"]

@onready var http: HTTPRequest = $HTTPRequest

var local_predictor: Object = null
var local_predictor_ready := false

func _ready() -> void:
	http.timeout = REQUEST_TIMEOUT_SECONDS
	_try_load_local_predictor()

# Tries to load the TFLite model via the tflite_gdext GDExtension so
# predictions can run on-device with no network round-trip. Falls back to
# the HTTP server (get_prediction() below) if the extension isn't present
# on this platform/build or the model fails to load.
func _try_load_local_predictor() -> void:
	if not ClassDB.class_exists("TFLitePredictor"):
		return
	var predictor = ClassDB.instantiate("TFLitePredictor")
	if predictor.load_model(MODEL_PATH):
		local_predictor = predictor
		local_predictor_ready = true
	else:
		push_warning("CnnPrediction: local TFLite model failed to load, will use server instead")

func get_prediction(img: Image) -> Dictionary[String, float]:
	if local_predictor_ready:
		var result := _predict_local(img)
		if not result.is_empty():
			return result
		push_warning("CnnPrediction: local inference failed, falling back to server")

	return await _predict_remote(img)

func _predict_local(img: Image) -> Dictionary[String, float]:
	var output: PackedFloat32Array = local_predictor.predict(_image_to_model_input(img))
	if output.size() != CLASS_NAMES.size():
		return {}

	var result: Dictionary[String, float] = {}
	for i in range(CLASS_NAMES.size()):
		result[CLASS_NAMES[i]] = output[i]
	return result

# Same preprocessing as server_predict/server.py: resize to the model's
# input size, flip RGB to BGR, then MobileNetV2 preprocess_input (mode='tf'):
# scale to [-1, 1].
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

func _predict_remote(img: Image) -> Dictionary[String, float]:
	send_image(img)

	var result = await http.request_completed

	var response_code = result[1]
	var body = result[3]

	if response_code != 200:
		print("Erro:", response_code)
		return {}

	var json = JSON.parse_string(body.get_string_from_utf8())
	if json == null:
		print("Erro ao parsear JSON")
		return {}

	var result_dict_raw: Dictionary = json["result"]
	if result_dict_raw.is_empty():
		return {}

	var result_dict: Dictionary[String, float] = {}
	for key in result_dict_raw.keys():
		result_dict[String(key)] = float(result_dict_raw[key])

	return result_dict

func send_image(img: Image):

	if img == null:
		print("Imagem inválida")
		return

	if img.get_format() != Image.FORMAT_RGB8:
		img.convert(Image.FORMAT_RGB8)

	var png_bytes: PackedByteArray = img.save_png_to_buffer()
	var base64_str = Marshalls.raw_to_base64(png_bytes)

	var json_body = {
		"image": base64_str
	}

	var body_text = JSON.stringify(json_body)
	var headers = ["Content-Type: application/json"]

	http.request(
		PREDICTION_ADDRESS,
		headers,
		HTTPClient.METHOD_POST,
		body_text
	)
