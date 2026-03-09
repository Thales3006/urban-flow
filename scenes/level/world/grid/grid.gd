class_name Grid
extends Node2D

const CELL_KIND_DROPABLE := "dropable"
const CELL_KIND_TRASHED := "trashed"
const CELL_KIND_HOUSE := "house"
const CELL_KIND_HOSPITAL := "hospital"
const CELL_KIND_RECYCLING := "recycling"
const CELL_KIND_WATER := "water"
const CELL_KIND_SCHOOL := "school"

@onready var buildings: Node2D = $Buildings
@onready var cells: Node2D = $Cells

var main_scene: Node2D
var cell_instances = []
var tile_map: TileMapLayer
var terrain_map: TileMapLayer

func _ready() -> void:
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
			CELL_KIND_WATER:
				var building := Building.create(BuildingData.Kind.WATER, tile_map.map_to_local(cell_pos))
				building.set_fixed()
				buildings.add_child(building)
				building.position = tile_map.map_to_local(cell_pos)
			CELL_KIND_HOUSE:
				var building := Building.create(BuildingData.Kind.HOUSE, tile_map.map_to_local(cell_pos))
				building.set_fixed()
				buildings.add_child(building)
				building.position = tile_map.map_to_local(cell_pos)
			CELL_KIND_HOSPITAL:
				var building := Building.create(BuildingData.Kind.HOSPITAL, tile_map.map_to_local(cell_pos))
				building.set_fixed()
				buildings.add_child(building)
				building.position = tile_map.map_to_local(cell_pos)
			CELL_KIND_RECYCLING:
				var building := Building.create(BuildingData.Kind.RECYCLING, tile_map.map_to_local(cell_pos))
				building.set_fixed()
				buildings.add_child(building)
				building.position = tile_map.map_to_local(cell_pos)
			CELL_KIND_SCHOOL:
				var building := Building.create(BuildingData.Kind.SCHOOL, tile_map.map_to_local(cell_pos))
				building.set_fixed()
				buildings.add_child(building)
				building.position = tile_map.map_to_local(cell_pos)
				
func set_cell(building: Building, cell: Cell):
	cell.is_filled = true
	building.current_cell = cell
	building.current_cell.was_filled.emit()
	building.push_affect_all()
	cell.visible = true

func get_tilemap_world_rect() -> Rect2:
	var used := tile_map.get_used_rect()
	var cell_size := tile_map.tile_set.tile_size

	var world_pos := tile_map.map_to_local(used.position)
	var world_size := used.size * cell_size

	return Rect2(world_pos, world_size)
	
func set_buildings(new_buildings: Array[Building]):
	for building: Building in new_buildings:
		buildings.add_child(building)
		building.global_position = building.initialPos
	
func get_cell(pos: Vector2i) -> Cell:
	for child: Cell in cells.get_children():
		if child.tile == pos:
			return child
	return null
	
func get_building(kind: BuildingData.Kind, index: int) -> Building:
	var iter: int = 0
	for child: Building in buildings.get_children():
		if child.data.kind == kind:
			if iter == index:
				return child
			else:
				iter += 1
	return null
