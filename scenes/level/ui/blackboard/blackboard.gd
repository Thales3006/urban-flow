class_name Blackboard
extends Control

const MAX_TRIES : int = 2

const HINT_FONT_MIN_SIZE := 24
const HINT_FONT_MAX_SIZE := 260
const HINT_FONT_FIT_MARGIN := 0.85 # leave some breathing room from the whiteboard's edges
const HINT_FONT_SIZE_BOOST := 1.2

@onready var dimmer := $Dimmer
@onready var card := $Card
@onready var label_word := $Card/Word
@onready var hint_word := $Card/WordHint
@onready var whiteboard := $Card/WhiteBoard
@onready var image: TextureRect = $Card/Image
@onready var confirm_button: Button = $Card/ConfirmButton
@onready var repeat_button: Button = $Card/RepeatButton
@onready var exit_button: Button = $Card/ExitButton
@onready var cnn_prediction: CnnPrediction = $CnnPrediction
@onready var fail: AudioStreamPlayer = $fail
@onready var correct: AudioStreamPlayer = $correct
@onready var beaver: TextureRect = $Card/Beaver
@onready var correct_icon: TextureRect = $Card/Correct
@onready var question_icon: TextureRect = $Card/Question

signal correct_word(kind: BuildingData.Kind)

var forced_draw: bool = false

var tries : int = 0
var current_catalog: BuildingCatalog = null 

func _ready() -> void:
	Signals.write_word.connect(_on_appear)
	Signals.disable_others.connect(_on_disable_others)
	Signals.enable_all.connect(func(): 
		forced_draw = false
		repeat_button.disabled = false
		confirm_button.disabled = false
		exit_button.disabled = false
	)
	
func _on_disable_others(nodes: Array[Node]):
	if nodes.has(whiteboard):
		forced_draw = true
		repeat_button.disabled = true
		confirm_button.disabled = true
		exit_button.disabled = true
	else:
		forced_draw = false

func _on_appear(kind: BuildingData.Kind, catalog: BuildingCatalog):
	whiteboard.clear()
	_reset_feedback_icons()
	if GameState.level.level == 1:
		hint_word.visible = true
		hint_word.modulate.a = 0
		var a := create_tween()
		a.set_trans(Tween.TRANS_CUBIC)
		a.set_ease(Tween.EASE_OUT)
		a.tween_interval(1)
		a.tween_property(hint_word, "modulate:a", 1.0, 1.5)
	else:
		hint_word.visible = false
	
	var word = Building.BUILDING_DATA[kind].word

	label_word.text = word
	hint_word.text = word
	_fit_hint_word_to_whiteboard(word)
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

# Sizes hint_word's font as large as possible while still fitting within
# the whiteboard's actual on-screen bounds (with a small margin), instead
# of relying on a fixed font size that's wrong for short/long words and
# doesn't adapt to the whiteboard's real size across devices.
func _fit_hint_word_to_whiteboard(word: String) -> void:
	var target_size: Vector2 = whiteboard.size * HINT_FONT_FIT_MARGIN
	var font: Font = hint_word.get_theme_font("normal_font")
	if font == null or target_size.x <= 0 or target_size.y <= 0:
		return

	var best_size := HINT_FONT_MIN_SIZE
	for size in range(HINT_FONT_MAX_SIZE, HINT_FONT_MIN_SIZE - 1, -2):
		var text_size := font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
		if text_size.x <= target_size.x and text_size.y <= target_size.y:
			best_size = size
			break

	hint_word.add_theme_font_size_override("normal_font_size", roundi(best_size * HINT_FONT_SIZE_BOOST))

func _reset_feedback_icons() -> void:
	correct_icon.visible = false
	question_icon.visible = false
	correct_icon.scale = Vector2.ONE
	question_icon.scale = Vector2.ONE
	correct_icon.modulate.a = 1.0
	question_icon.modulate.a = 1.0
	beaver.rotation = 0.0

func _show_correct_feedback() -> void:
	correct_icon.pivot_offset = correct_icon.size / 2
	correct_icon.visible = true
	correct_icon.scale = Vector2.ZERO

	var icon_tween := create_tween()
	icon_tween.set_trans(Tween.TRANS_BACK)
	icon_tween.set_ease(Tween.EASE_OUT)
	icon_tween.tween_property(correct_icon, "scale", Vector2.ONE, 0.4)

	beaver.pivot_offset = Vector2(beaver.size.x / 2, beaver.size.y)
	var beaver_tween := create_tween()
	beaver_tween.set_trans(Tween.TRANS_BACK)
	beaver_tween.set_ease(Tween.EASE_OUT)
	beaver_tween.tween_property(beaver, "rotation", deg_to_rad(4), 0.15)
	beaver_tween.tween_property(beaver, "rotation", 0.0, 0.2)

func _show_question_feedback() -> void:
	question_icon.pivot_offset = question_icon.size / 2
	question_icon.visible = true
	question_icon.scale = Vector2.ZERO
	question_icon.modulate.a = 1.0

	var icon_tween := create_tween()
	icon_tween.set_trans(Tween.TRANS_BACK)
	icon_tween.set_ease(Tween.EASE_OUT)
	icon_tween.tween_property(question_icon, "scale", Vector2.ONE, 0.3)
	icon_tween.tween_interval(0.9)
	icon_tween.tween_property(question_icon, "modulate:a", 0.0, 0.3)
	icon_tween.tween_callback(func(): question_icon.visible = false)

	beaver.pivot_offset = Vector2(beaver.size.x / 2, beaver.size.y)
	var beaver_tween := create_tween()
	beaver_tween.set_trans(Tween.TRANS_ELASTIC)
	beaver_tween.tween_property(beaver, "rotation", deg_to_rad(-3), 0.08)
	beaver_tween.tween_property(beaver, "rotation", deg_to_rad(3), 0.08)
	beaver_tween.tween_property(beaver, "rotation", deg_to_rad(-2), 0.08)
	beaver_tween.tween_property(beaver, "rotation", 0.0, 0.08)

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
	hint_word.visible = false
	tries = 0

func _on_confirm_button_pressed() -> void:
	if forced_draw:
		return
		
	var img: Image = await whiteboard.to_image()
	img = whiteboard.trim_with_padding(img)
	var prediction: Dictionary[String, float] = await cnn_prediction.get_prediction(img)

	if prediction.is_empty():
		PlayerInfo.add_writing(img, { "prediction_error": 0.0 }, current_catalog.kind)
		prediction_failed()
		return

	var word: String = Building.BUILDING_DATA[current_catalog.kind].word.capitalize()
	var result = prediction.get(word)
	
	if result == null:
		PlayerInfo.add_writing(img, { "prediction_error": 0.0 }, current_catalog.kind)
		prediction_failed()
		return
		
	PlayerInfo.add_writing(img, prediction, current_catalog.kind)

	var threshold: float = Building.BUILDING_DATA[current_catalog.kind].confidence_threshold
	if result >= threshold:
		right_anwser()
	else:
		try_again()

func prediction_failed():
	push_warning("Blackboard: prediction failed, auto-accepting answer")
	right_anwser()

func right_anwser():
	current_catalog.unlock_buildings()
	correct.play()
	_show_correct_feedback()
	await get_tree().create_timer(0.7).timeout
	if not is_inside_tree():
		return
	_on_disapear()
	correct_word.emit(current_catalog.kind)


func try_again():
	fail.play()
	whiteboard.clear()
	tries += 1
	if tries >= MAX_TRIES:
		hint_word.visible = true
	_show_question_feedback()


func _on_repeat_button_pressed() -> void:
	if forced_draw:
		return
	whiteboard.clear()
	AudioManager.play_click()


func _on_exit_button_pressed() -> void:
	if forced_draw:
		return
	_on_disapear()
	AudioManager.play_click()
