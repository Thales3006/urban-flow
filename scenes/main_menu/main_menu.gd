extends Control

@onready var gender_form: GenderForm = $GenderForm
@onready var birthday_form: BirthdayForm = $BirthdayForm
@onready var consent_form: ConsentForm = $ConsentForm
@onready var dimmer: ColorRect = $Dimmer

@onready var sound_button: Button = $SoundButton

@export var icon_on: Texture2D
@export var icon_off: Texture2D


func _ready() -> void:
	consent_form.consentAccepted.connect(_on_consent_accepted)
	consent_form.consentDeclined.connect(_on_consent_declined)
	gender_form.genderChoosen.connect(_on_gender_decided)
	birthday_form.birthdateChoosen.connect(_on_birthdate_decided)
	if Global.first_time:
		dimmer.modulate.a = 0.0
		dimmer.visible = true
		await get_tree().create_timer(0.5).timeout
		# get_tree().create_timer() isn't bound to this node's lifetime like
		# create_tween() is -- if the scene changed (e.g. the player tapped
		# something that navigates away) while this was pending, resuming
		# here would touch a freed node. Bail out instead.
		if not is_inside_tree():
			return

		var tween := create_tween()
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(
			dimmer,
			"modulate:a",
			0.6,
			0.6,
		)

		consent_form._on_appear()
		Global.first_time = false
	else:
		consent_form.visible = false
		gender_form.visible = false
		birthday_form.visible = false
		dimmer.visible = false

func _on_consent_accepted() -> void:
	consent_form._on_disapear()
	gender_form._on_appear()

func _on_consent_declined() -> void:
	PlayerInfo.discard_session()
	get_tree().quit()

func _on_gender_decided(gender: PlayerInfo.Gender):
	gender_form._on_disapear()
	PlayerInfo.gender = gender
	birthday_form._on_appear()

func _on_birthdate_decided(birthdate: PlayerDate):
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
	AudioManager.play_click()
	get_tree().change_scene_to_file(Global.level_selector_scene_path)


func _on_exit_button_pressed() -> void:
	AudioManager.play_click()
	PlayerInfo.finalize_session()
	get_tree().quit()


func _on_settings_button_pressed() -> void:
	AudioManager.play_click()
	get_tree().change_scene_to_file(Global.level_settings_scene_path)


func _on_button_toggled(toggled_on: bool) -> void:
	AudioManager.play_click()
	AudioServer.set_bus_mute(Global.master_bus, toggled_on)
	if not toggled_on:
		sound_button.icon = icon_on
	else:
		sound_button.icon = icon_off
