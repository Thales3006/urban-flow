extends Node2D

var cell_size: int = 100
const inset: int = 10
var main_scene: Control
var level: LevelData
var cell_instances = []

func _ready() -> void:
	level = global.level
	create_cells()

func _draw():
	if not level:
		return
	draw_grid_lines()

func draw_grid_lines():
	for x in range(level.grid_width + 1):
		var start = Vector2(x * (cell_size + inset) - 50, -50)
		var end = Vector2(x * (cell_size + inset)- 50, level.grid_height * (cell_size + inset)-50)
		draw_line(start, end, Color(0.3, 0.8, 0.3, 1), 2.0)
	
	for y in range(level.grid_height + 1):
		var start = Vector2(0- 50, y * (cell_size + inset)- 50)
		var end = Vector2(level.grid_width * (cell_size + inset)- 50, y * (cell_size + inset)-50)
		draw_line(start, end, Color(0.3, 0.8, 0.3, 1), 2.0)

func create_cells():
	for cell in cell_instances:
		cell.queue_free()
	cell_instances.clear()
	
	for y in range(level.grid_height):
		for x in range(level.grid_width):
			var index = y * level.grid_width + x
			var cell_type = level.grid_layout[index]
			
			var pos = Vector2(inset+x * (cell_size + inset), inset+y * (cell_size + inset))
			
			match cell_type:
				LevelData.CellType.EMPTY:
					var cell_instance = Cell.create(pos)
					add_child(cell_instance)
					cell_instances.append(cell_instance)
				LevelData.CellType.FILLED:
					var cell_instance = Cell.create(pos)
					add_child(cell_instance)
					cell_instances.append(cell_instance)
