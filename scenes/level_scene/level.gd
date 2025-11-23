extends Control

func _ready():
	add_child(Building.create(Vector2(100,100)))
