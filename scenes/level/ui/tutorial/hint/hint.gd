class_name Hint
extends Resource


func setup_signal(node: Node):
	if node is Button:
		node.pressed.connect(func(): Signals.hint_executed.emit(self))
	
