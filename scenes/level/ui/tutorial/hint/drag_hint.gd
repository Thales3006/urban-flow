class_name DragHint
extends Hint

@export var initial_node_path: String
@export var end_node_path: String

var initial_node: Node
var end_node: Node

func disable_others():
	Signals.disable_others.emit([initial_node, end_node] as Array[Node])
