extends CanvasLayer

static var a = 1
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	$UI/VBox/CompletionStatus.set_progress(GameState.compute_percentage())
