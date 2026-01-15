extends Resource
class_name BuildingData

enum Kind {
	HOUSE,
	HOSPITAL
}

@export var kind: Kind
@export var sprite: Texture2D
@export var sprite_scale: float
@export var radius: float
