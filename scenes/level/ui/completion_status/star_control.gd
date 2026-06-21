extends HBoxContainer


func set_lit(index: int):
	set_star(index, true)

func set_dimmed(index: int):
	set_star(index, false)

func set_star(index: int, lit: bool):
	var stars := [$Star1, $Star2, $Star3, $Star4, $Star5]
	if index < 0 or index >= stars.size():
		return
	if lit:
		stars[index].set_lit()
	else:
		stars[index].set_dimmed()
