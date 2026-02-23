@abstract class_name Hint
extends Resource


func setup_signal(node: Node):
	if node is Button:
		node.pressed.connect(on_hint_executed)
	if node is Cell:
		node.was_filled.connect(on_hint_executed)
	if node is Blackboard:
		node.correct_word.connect(on_hint_executed)
	
func on_hint_executed():
	Signals.hint_executed.emit(self)

func on_use():
	disable_others()
	
@abstract func disable_others()
