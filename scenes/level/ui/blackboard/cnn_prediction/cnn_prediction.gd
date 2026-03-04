extends Node
class_name CnnPrediction

@onready var http: HTTPRequest = $HTTPRequest
const PREDICTION_ADDRESS = "http://[2001:1284:f514:aa26:114e:9ae1:8dd4:d45e]:8000/predict"
	
func get_prediction(img: Image) -> Dictionary[String, float]:
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
