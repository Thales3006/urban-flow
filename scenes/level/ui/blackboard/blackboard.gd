class_name Blackboard
extends Control

@onready var dimmer := $Dimmer
@onready var card := $Card
@onready var label_word := $Card/Word
@onready var whiteboard := $Card/WhiteBoard
@onready var image: TextureRect = $Card/Image
@onready var confirm_button: Button = $Card/ConfirmButton
@onready var repeat_button: Button = $Card/RepeatButton
@onready var cnn_prediction: CnnPrediction = $CnnPrediction

signal correct_word(kind: BuildingData.Kind)

var current_catalog: BuildingCatalog = null 

func _ready() -> void:
	Signals.write_word.connect(_on_appear)

func _on_appear(kind: BuildingData.Kind, catalog: BuildingCatalog):
	whiteboard.clear()
	
	label_word.text = Building.BUILDING_DATA[kind].word
	image.texture = Building.BUILDING_DATA[kind].sprite
	current_catalog = catalog
	
	var viewport_size := get_viewport().get_visible_rect().size

	card.position.y = -card.size.y
	var target_y: float = viewport_size.y / 2 - card.size.y / 2
	
	dimmer.modulate.a = 0.0

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(card, "position:y", target_y, 0.6)

	tween.parallel().tween_property(
		dimmer,
		"modulate:a",
		0.6,
		0.4,
	)
	visible = true

func _on_disapear():
	var viewport_size := get_viewport().get_visible_rect().size
	
	var target_y: float = viewport_size.y

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(card, "position:y", target_y, 0.4)

	tween.parallel().tween_property(
		dimmer,
		"modulate:a",
		0.0,
		0.2,
	)
	
	await tween.finished
	visible = false
	

func _on_confirm_button_pressed() -> void:
	var img: Image = await whiteboard.to_image()
	img = whiteboard.trim_with_padding(img)
	var prediction: Dictionary[String, float] = await cnn_prediction.get_prediction(img)
	img.save_png("res://debug.png")

	print(prediction)
	
	var word: String = Building.BUILDING_DATA[current_catalog.kind].word.capitalize()
	var result: float = prediction.get(word)
	
	if result == null or (result * 100) >= 50:
		right_anwser()
	else:
		try_again()


func right_anwser():
	current_catalog.unlock_buildings()
	_on_disapear()
	correct_word.emit(current_catalog.kind)
	
	
func try_again():
	whiteboard.clear()


func _on_repeat_button_pressed() -> void:
	whiteboard.clear()
