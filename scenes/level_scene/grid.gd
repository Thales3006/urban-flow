extends Area2D

const inset: int = 20
var main_scene: Control
var level: LevelData
var cell_instances = []

signal resized(cell_size: Vector2)

func _ready() -> void:
	level = global.level
	create_cells()
	get_parent().connect("resized", Callable(self, "on_resize"))
	
func on_resize():
	update_scale()
	center_in_parent()
	
func update_scale():
	var parent = get_parent()
	var base_size: Vector2 = $CollisionShape2D.shape.size
	var scale_factor = min(
		parent.size.x / base_size.x,
		parent.size.y / base_size.y
	)
	scale = Vector2(scale_factor, scale_factor)

func center_in_parent():
	var parent = get_parent()
	var parent_size: Vector2
	parent_size = parent.size
	var base_size: Vector2 = $CollisionShape2D.shape.size * scale
	position = parent_size * 0.5 - base_size * 0.5

func _draw():
	if not level:
		return
	draw_grid_lines()

func draw_grid_lines():
	var cell_size = $CollisionShape2D.shape.size / Vector2(level.grid_width,level.grid_height)
	
	for x in range(level.grid_width + 1):
		var start = Vector2(x, 0) * cell_size
		var end = Vector2(x, level.grid_height) * cell_size
		draw_line(start, end, Color(0.3, 0.8, 0.3, 1), 2.0)
	
	for y in range(level.grid_height + 1):
		var start = Vector2(0, y) * cell_size
		var end = Vector2(level.grid_width, y)* cell_size
		draw_line(start, end, Color(0.3, 0.8, 0.3, 1), 2.0)

func create_cells():
	for cell in cell_instances:
		cell.queue_free()
	cell_instances.clear()
	
	var cell_size = $CollisionShape2D.shape.size / Vector2(level.grid_width,level.grid_height) - Vector2(inset,inset)
	
	for y in range(level.grid_height):
		for x in range(level.grid_width):
			var index = y * level.grid_width + x
			var cell_type = level.grid_layout[index]
			
			var pos = Vector2(x, y) * (cell_size  + Vector2(inset,inset)) + cell_size/2 + Vector2(inset,inset)/2
			
			match cell_type:
				LevelData.CellType.EMPTY:
					var cell_instance = Cell.create(pos,cell_size)
					add_child(cell_instance)
					cell_instances.append(cell_instance)
				LevelData.CellType.FILLED:
					var cell_instance = Cell.create(pos,cell_size)
					add_child(cell_instance)
					cell_instances.append(cell_instance)
