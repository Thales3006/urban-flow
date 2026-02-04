extends Control

const KIND_TO_STRING := {
	BuildingData.Kind.HOUSE: "moradia",
	BuildingData.Kind.HOSPITAL: "hospital",
	BuildingData.Kind.RECYCLING: "reciclagem",
}

@onready var dimmer := $Dimmer
@onready var card := $Card
@onready var label_word := $Card/VBoxContainer/WhiteBoard/Word

var current_catalog: BuildingCatalog = null 

func _ready() -> void:
	Signals.write_word.connect(_on_appear)

func _on_appear(kind: BuildingData.Kind, catalog: BuildingCatalog):
	label_word.text = KIND_TO_STRING[kind]
	current_catalog = catalog
	visible = true

func _on_button_pressed() -> void:
	visible = false
	current_catalog.unlock_buildings()
	
