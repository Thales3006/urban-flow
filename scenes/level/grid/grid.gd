extends Area2D

const inset: int = 20
var main_scene: Node2D
var level: LevelData
var cell_instances = []

func _ready() -> void:
	level = global.level
	spawn_cells_from_tilemap()

func spawn_cells_from_tilemap():
	for cell in cell_instances:
		cell.queue_free()
	cell_instances.clear()

	var tile_size = $TileMap.tile_set.tile_size

	for y in range(level.grid_height):
		for x in range(level.grid_width):
			var index = x + y * level.grid_width
			var cell_coord := Vector2i(x, y) - Vector2i(level.grid_width, level.grid_height) / 2
			var world_pos = $TileMap.map_to_local(cell_coord)
			
			match level.grid_layout[index]:
				LevelData.CellType.EMPTY:
					var cell := Cell.create(world_pos)
					add_child(cell)
					cell_instances.append(cell)


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
					var cell_instance = Cell.create(pos)
					add_child(cell_instance)
					cell_instances.append(cell_instance)
				LevelData.CellType.FILLED:
					var cell_instance = Cell.create(pos)
					add_child(cell_instance)
					cell_instances.append(cell_instance)
