class_name DrawHint
extends Hint

var node: Node

func disable_others():
	Signals.disable_others.emit([node] as Array[Node])
	
func setup_signal(whiteboard: Node):
	whiteboard.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and not event.pressed:
			on_hint_executed()
	)
