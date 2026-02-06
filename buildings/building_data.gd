extends Resource
class_name BuildingData

enum Kind {
	HOUSE,
	HOSPITAL,
	RECYCLING,
}

@export var word: String
@export var kind: Kind
@export var sprite: Texture2D
@export var sprite_scale: float
@export var radius: float
@export var score: float
@export var effect: float = 1.0
@export var hints: Array[Hint] = []
