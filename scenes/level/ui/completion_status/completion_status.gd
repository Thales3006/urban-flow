class_name CompletionStatus
extends PanelContainer

@onready var progress_bar := $HBox/VBoxContainer/ProgressBar
@onready var star_HBox := $VBoxContainer/StarHBox

func _ready() -> void:
	Signals.progress_state_changed.connect(_on_progress_changed)

func _on_progress_changed(percentage: float):
	set_progress(percentage)
	if percentage >= 100:
		Signals.level_won.emit()

func set_progress(percentage: float):
	if percentage > 100 or percentage < 0:
		return
	progress_bar.set_value_no_signal(percentage)
	var star_level := percentage / 25 as int
	for index in 5:
		if index <= star_level:
			star_HBox.set_lit(index)
		else:
			star_HBox.set_dimmed(index)
