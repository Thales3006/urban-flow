extends Control

var lit = load("res://images/star_lit.png")
var dimmed = load("res://images/star_dimmed.png")

func set_lit():
	$".".texture = lit
	
func set_dimmed():
	$".".texture = dimmed
