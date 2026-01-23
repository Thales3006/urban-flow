extends Node2D

const CELL_KIND_DROPABLE := "dropable"

var main_scene: Node2D
var level: LevelData
var cell_instances = []
var tile_map: TileMapLayer

func _ready() -> void:
	level = GameState.level
	tile_map = level.tilemap_scene.instantiate()
	add_child(tile_map)
	spawn_cells_from_tilemap()

func spawn_cells_from_tilemap():
	for cell_pos: Vector2i in tile_map.get_used_cells():
		var tile_data := tile_map.get_cell_tile_data(cell_pos)
		if tile_data == null:
			continue

		var kind: String = tile_data.get_custom_data("cell_kind")
		if kind != CELL_KIND_DROPABLE:
			continue

		var cell := Cell.create(tile_map.map_to_local(cell_pos), cell_pos)
		add_child(cell)
		
func get_tilemap_world_rect() -> Rect2:
	var used := tile_map.get_used_rect() # in cells
	var cell_size := tile_map.tile_set.tile_size

	var world_pos := tile_map.map_to_local(used.position)
	var world_size := used.size * cell_size

	return Rect2(world_pos, world_size)
