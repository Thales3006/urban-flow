extends Control

@onready var gender_form: GenderForm = $GenderForm
@onready var birthday_form: BirthdayForm = $BirthdayForm
@onready var dimmer: ColorRect = $Dimmer

@onready var sound_button: Button = $SoundButton

@export var icon_on: Texture2D
@export var icon_off: Texture2D


func _ready() -> void:
	gender_form.genderChoosen.connect(_on_gender_decided)
	birthday_form.birthdateChoosen.connect(_on_birthdate_decided)
	if Global.first_time:
		dimmer.modulate.a = 0.0
		dimmer.visible = true
		await get_tree().create_timer(0.5).timeout
		
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(
			dimmer,
			"modulate:a",
			0.6,
			0.6,
		)
		
		gender_form._on_appear()
		Global.first_time = false
	else:
		gender_form.visible = false
		birthday_form.visible = false
		dimmer.visible = false
		
func _on_gender_decided(gender: PlayerInfo.Gender):
	gender_form._on_disapear()
	PlayerInfo.gender = gender
	birthday_form._on_appear()

func _on_birthdate_decided(birthdate: PlayerInfo.Date):
	birthday_form._on_disapear()
	PlayerInfo.birthdate = birthdate
	
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(
		dimmer,
		"modulate:a",
		0.0,
		0.3,
	)
	await tween.finished
	dimmer.visible = false
func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file(Global.level_selector_scene_path)


func _on_exit_button_pressed() -> void:
	get_tree().get_root().close_requested.emit()


func _on_settings_button_pressed() -> void:
	get_tree().change_scene_to_file(Global.level_settings_scene_path)


func _on_button_toggled(toggled_on: bool) -> void:
	AudioServer.set_bus_mute(Global.master_bus, toggled_on)
	if not toggled_on:
		sound_button.icon = icon_on
	else:
		sound_button.icon = icon_off
