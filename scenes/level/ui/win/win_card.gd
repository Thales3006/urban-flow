extends Control

@onready var stars :CompletionStatus = $PanelContainer/VBoxContainer/CompletionStatus

func _ready() -> void:
	stars.set_progress(GameState.compute_percentage())
