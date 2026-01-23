extends Panel


func set_progress(percentage: float):
	if percentage > 100 or percentage < 0:
		return
	$Margin/Margin/ProgressBar.set_value_no_signal(percentage)
	var star_level := percentage / 25 as int	
	for index in 5:
		if index <= star_level:
			$Margin/StarHBox.set_lit(index)
		else:
			$Margin/StarHBox.set_dimmed(index)
