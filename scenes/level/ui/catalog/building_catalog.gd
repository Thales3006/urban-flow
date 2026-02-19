extends Control
class_name BuildingCatalog

@onready var button: Button = $HBoxContainer/VBoxContainer/Button
@onready var buildingHBox: HBoxContainer = $AvailableBuilding

const buildingCatalog = preload("res://scenes/level/ui/catalog/building_catalog.tscn")
const distance = 40

var amount: int
var kind: BuildingData.Kind

var buildings: Array[Building] = []

static func create(new_kind: BuildingData.Kind, n: int) -> BuildingCatalog:
	var new: BuildingCatalog = buildingCatalog.instantiate()
	new.amount = n
	new.kind = new_kind

	return new
	
func _ready() -> void:
	for index in amount:
		_emit_add_building(index)

func _emit_add_building(index: int):
	var building := Building.create(kind, Vector2(50, 0) + generate_position(index))
	building.catalog = self
	building.set_locked()
	buildings.push_back(building)
	
func generate_position(index: int) -> Vector2: 
	var y := sin((index + global_position.y - global_position.x) * 4) * 10
	var x := distance * (index -  (amount / 2 + 1))
	return Vector2(x, y)

func _on_button_pressed() -> void:
	Signals.write_word.emit(kind, self)
	
func unlock_buildings():
	for building: Building in buildings:
		building.set_free()
	$HBoxContainer/VBoxContainer/Button.disabled = true
	$HBoxContainer/VBoxContainer/Button.visible = false
