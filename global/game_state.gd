extends Node

var level: LevelData
var buildings: Array[Building] = []

func compute_percentage() -> float:
	return compute_score() / level.max_score * 100

func compute_score() -> float:
	var score: float = 0
	for building: Building in buildings:
		if building.current_cell != null:
			score += building.compute_score()
	return score
		

func set_buildings(new: Array[Building]):
	buildings = new

func clear():
	level = null
	buildings.clear()
