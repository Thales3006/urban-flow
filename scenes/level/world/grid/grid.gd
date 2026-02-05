extends Node2D

const CELL_KIND_DROPABLE := "dropable"
const CELL_KIND_TRASHED := "trashed"

@onready var buildings: Node2D = $Buildings
@onready var cells: Node2D = $Cells

var main_scene: Node2D
var cell_instances = []
var tile_map: TileMapLayer
var terrain_map: TileMapLayer

func _ready() -> void:
	Signals.add_building.connect(_on_add_building)
	
	var layout = GameState.level.layout.instantiate()
	tile_map = layout.get_node("Placement")
	terrain_map = layout.get_node("Terrain")
	tile_map.visible = false
	add_child(layout)
	move_child(layout, 0)
	spawn_cells_from_tilemap()

func spawn_cells_from_tilemap():
	for cell_pos: Vector2i in tile_map.get_used_cells():
		var tile_data := tile_map.get_cell_tile_data(cell_pos)
		if tile_data == null:
			continue

		var kind: String = tile_data.get_custom_data("placement")
		match kind:
			CELL_KIND_DROPABLE:
				var cell := Cell.create(tile_map.map_to_local(cell_pos), cell_pos)
				cells.add_child(cell)
			CELL_KIND_TRASHED:
				var cell := Cell.create(tile_map.map_to_local(cell_pos), cell_pos)
				cells.add_child(cell)
				cell.set_trashed()

		
		
func get_tilemap_world_rect() -> Rect2:
	var used := tile_map.get_used_rect()
	var cell_size := tile_map.tile_set.tile_size

	var world_pos := tile_map.map_to_local(used.position)
	var world_size := used.size * cell_size

	return Rect2(world_pos, world_size)
	
func _on_add_building(building: Building):
	buildings.add_child(building)
	building.global_position = building.initialPos
