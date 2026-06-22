extends Control
class_name ConsentForm

@onready var panel := $FormPanel

signal consentAccepted
signal consentDeclined

func _on_appear():
	var viewport_size := get_viewport().get_visible_rect().size

	panel.position.y = -panel.size.y
	var target_y: float = viewport_size.y / 2 - panel.size.y / 2

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(panel, "position:y", target_y, 0.6)
	visible = true

func _on_disapear():
	var viewport_size := get_viewport().get_visible_rect().size

	var target_y: float = viewport_size.y

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(panel, "position:y", target_y, 0.4)

	await tween.finished
	visible = false


func _on_accept_button_pressed() -> void:
	consentAccepted.emit()
	AudioManager.play_click()

func _on_decline_button_pressed() -> void:
	consentDeclined.emit()
	AudioManager.play_click()
