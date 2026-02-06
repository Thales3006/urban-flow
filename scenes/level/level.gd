class_name LevelScene
extends Node

@onready var tutorial: Tutorial = $UILayer/Tutorial
@onready var catalog: Control = $Background/BackUI/SidePanel/PanelContainer/List
@onready var grid: Node2D = $WorldLayer/World/Grid

func _ready() -> void:
	call_deferred("_on_tutorial")

func _on_tutorial():
	tutorial.setup_tutorial(self)
