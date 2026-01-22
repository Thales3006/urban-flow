extends HBoxContainer


func set_lit(index: int):
	match index:
		0:
			$Star1.set_lit()
		1:
			$Star2.set_lit()
		2:
			$Star3.set_lit()
		3:
			$Star4.set_lit()
		4:
			$Star5.set_lit()

func set_dimmed(index: int):
	match index:
		0:
			$Star1.set_dimmed()
		1:
			$Star2.set_dimmed()
		2:
			$Star3.set_dimmed()
		3:
			$Star4.set_dimmed()
		4:
			$Star5.set_dimmed()
