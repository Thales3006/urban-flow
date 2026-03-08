extends Node

@onready var _player := AudioStreamPlayer.new()

@export var click_sound: AudioStream = preload("res://sounds/button_click2.mp3")
@export var volume_db: float = -16.0

func _ready() -> void:
	add_child(_player)
	_player.volume_db = -8.0

func play(stream: AudioStream, volume: float = -16.0) -> void:
	_player.stream = stream
	_player.volume_db = volume
	_player.play()

func play_click():
	play(click_sound, volume_db)
