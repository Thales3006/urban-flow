class_name LevelButton
extends Button

@onready var lock: TextureRect = $Lock
var locked: bool = false

func set_lock():
	lock.visible = true
	locked = true
	
func set_unlock():
	lock.visible = false
	locked = false
