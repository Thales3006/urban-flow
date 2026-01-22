extends Panel


func set_progress(percentage: float):
	if percentage > 100 or percentage < 0:
		return
	$Margin/Margin/ProgressBar.set_value_no_signal(percentage)
	var star_level := percentage / 20 as int
	
	for index in star_level:
		$Margin/StarHBox.set_lit(index)
