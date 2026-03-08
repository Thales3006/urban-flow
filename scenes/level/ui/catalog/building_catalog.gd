extends Control
class_name BuildingCatalog

@onready var button: Button = $HBoxContainer/VBoxContainer/CatalogButton
@onready var buildingHBox: HBoxContainer = $AvailableBuilding
@onready var card: PanelContainer = $"."

const buildingCatalog = preload("res://scenes/level/ui/catalog/building_catalog.tscn")
const distance = 40

var front_button: Button = null
var amount: int
var kind: BuildingData.Kind
var amount_educated: int

var buildings: Array[Building] = []

static func create(new_kind: BuildingData.Kind, n: int, educated: int = 0) -> BuildingCatalog:
	if new_kind == BuildingData.Kind.HOUSE and educated > n:
		return null
	
	var new: BuildingCatalog = buildingCatalog.instantiate()
	new.amount = n
	new.kind = new_kind
	if new_kind == BuildingData.Kind.HOUSE:
		new.amount_educated = educated
	else:
		new.amount_educated = 0
	return new
		
func _ready() -> void:

	for index in amount:
		var should_educate: bool = index < amount_educated
		add_building(index, should_educate)

func add_building(index: int, educated: bool = false):
	var building := Building.create(kind, Vector2(50, 0) + generate_position(index), educated)
	building.catalog = self
	building.set_locked()
	buildings.push_back(building)
	
func generate_position(index: int) -> Vector2: 
	var y := sin((index + global_position.y - global_position.x) * 4) * 10
	var x := distance * (index -  (amount as float / 2 + 1))
	return Vector2(x, y)

func _on_button_pressed() -> void:
	Signals.write_word.emit(kind, self)
	
func unlock_buildings():
	for building: Building in buildings:
		building.set_free()
		
	button.disabled = true
	button.visible = false
	
	front_button.disabled = true
	front_button.visible = false
