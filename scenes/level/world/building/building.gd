extends Node2D
class_name Building

const DRAG_Z := 1000
const NORMAL_Z := 0

const building = preload("res://scenes/level/world/building/building.tscn")
const BUILDING_DATA: Dictionary[BuildingData.Kind, BuildingData] = {
	BuildingData.Kind.HOUSE: preload("res://buildings/house.tres"),
	BuildingData.Kind.HOSPITAL: preload("res://buildings/hospital.tres"),
	BuildingData.Kind.RECYCLING: preload("res://buildings/recycling.tres"),
	BuildingData.Kind.WATER: preload("res://buildings/water.tres"),
}

enum State {
	LOCKED,
	FIXED,
	FREE,
}

var dragging: bool = false:
	set(value):
		if value:
			z_index = DRAG_Z
		else:
			z_index = NORMAL_Z
		dragging = value
var current_cell: Cell = null
var state: State = State.FREE
var will_affect = []
var affecting = []

@onready var sprite: Sprite2D = $Sprite2D
@onready var recycling_balloon: Sprite2D = $RecyclingBalloon
@onready var happy_emote: Sprite2D = $Happy
@onready var water_balloon: Sprite2D = $WaterBalloon

@onready var grabed_sound := $GrabedSound
@onready var droped_sound := $DropedSound
@onready var drag_area: Area2D = $Drag
@onready var effect_area: Area2D = $EffectArea
@export var data: BuildingData
@export var catalog: BuildingCatalog

var initialPos: Vector2
var initialScale: Vector2
var is_disabled: bool

static func create(kind: BuildingData.Kind, pos: Vector2) -> Building:
	var new : Building = building.instantiate()
	new.initialPos = pos
	new.data = BUILDING_DATA[kind]
	return new

func _ready() -> void:
	if data == null:
		push_error("Building sem tipo!")
		return
	sprite.texture = data.sprite
	sprite.scale *= data.sprite_scale
	initialScale = sprite.scale
	var shape = $EffectArea/Shape.shape.duplicate()
	if shape is RectangleShape2D:
			shape.size = Vector2.ONE * data.radius * 180
	if shape is CircleShape2D:
			shape.radius = data.radius * 100
	$EffectArea/Shape.shape = shape
	get_viewport().size_changed.connect(_on_window_resized)
	Signals.disable_others.connect(_on_disable_others)
	Signals.enable_all.connect(func(): is_disabled = false)
	
	call_deferred("_post_ready")

func _post_ready():
	_on_window_resized()
	
func _on_disable_others(nodes: Array[Node]):
	is_disabled = not nodes.has(self)

func _input(event: InputEvent) -> void:
	if is_disabled:
		return
	if event is InputEventMouseMotion and dragging:
		global_position = get_global_mouse_position()
		var closest_cell: Cell = get_closest_overlapping_cell()
		if closest_cell != null:
			effect_area.global_position = closest_cell.global_position
		else:
			effect_area.global_position = global_position
		
	if event is InputEventMouseButton:
		if not event.pressed and dragging:
			# Droped =====================================
			dragging = false
			Global.is_dragging = false
			
			var tween = get_tree().create_tween()
			var closest_cell: Cell = get_closest_overlapping_cell()
			if closest_cell and not closest_cell.is_filled and not closest_cell.is_disabled:
				closest_cell.is_filled = true
				current_cell = closest_cell
				current_cell.was_filled.emit()
				push_affect_all()
				tween.tween_property(self, "global_position", closest_cell.global_position, 0.2).set_ease(Tween.EASE_OUT)
			else:
				current_cell = null
				tween.tween_property(self, "global_position", get_world_catalog_pos() + initialPos, 0.5).set_ease(Tween.EASE_OUT)
			for cell in will_affect:
				remove_affect_feedback(cell)
			will_affect.clear()
			effect_area.position = Vector2.ZERO
				
			droped_sound.play()
			Signals.building_placed.emit()
			

func compute_score() -> float:
	recycling_balloon.visible = false
	water_balloon.visible = false
	happy_emote.visible = false
	
	if current_cell == null:
		return 0

	var has_water := false
	var needs_recycling := false
	var is_happy := false
	
	var score := data.score
	
	if current_cell.has_water():
		has_water = true
	else:
		score /= 2
		
	if current_cell.is_trashed and not current_cell.is_recycled():
		needs_recycling = true
		score /= 2
		
	if current_cell.has_hospital() and data.kind == BuildingData.Kind.HOUSE:
		is_happy = true
		score *= BUILDING_DATA[BuildingData.Kind.HOSPITAL].effect
		
	if not has_water:
		water_balloon.visible = true
		return score
	
	if needs_recycling:
		recycling_balloon.visible = true
		return score
		
	if is_happy:
		happy_emote.visible = true
		return score

	return score
	
# =============================
# Overlaping cells
# =============================

func get_closest_overlapping_cell():
	if not drag_area:
		return null
	var overlapping_bodies = drag_area.get_overlapping_bodies()
	var dropable_cells = []
	for body in overlapping_bodies:
		if body.is_in_group('dropable'):
			dropable_cells.append(body)
			
	var closest_cell = null
	var min_distance = INF
	for cell in dropable_cells:
		var distance = global_position.distance_to(cell.global_position)
		if distance < min_distance:
			min_distance = distance
			closest_cell = cell
	if closest_cell != null:
		return closest_cell.get_parent()
	else:
		return null

func get_overlapping_cells() -> Array[Cell]: 
	var cells: Array[Cell]
	for body in $EffectArea.get_overlapping_bodies():
		var cell = body.get_parent()
		if cell is Cell:
			cells.push_back(cell)
	return cells

# VISUAL FEEDBACK =========================

func set_free():
	state = State.FREE
	$Sprite2D.modulate = Color(1, 1, 1, 1)

func set_locked():
	state = State.LOCKED
	$Sprite2D.modulate = Color(0.1, 0.1, 0.1, 1.0)

func set_fixed():
	state = State.FIXED
	$Sprite2D.modulate = Color(1, 1, 1, 1)


func set_affect_feedback(cell: Cell):

	match data.kind:
		BuildingData.Kind.HOUSE:
			pass
		BuildingData.Kind.HOSPITAL:
			cell.set_positive()
		BuildingData.Kind.RECYCLING:
			cell.set_clean()
		BuildingData.Kind.WATER:
			cell.set_water()
			
	
func remove_affect_feedback(cell: Cell):
	cell.set_no_effect()
	
	
func push_affect_all():
	for cell: Cell in will_affect:
		if data.kind == BuildingData.Kind.RECYCLING:
			cell.trash.modulate.a = 0.3
		cell.affecting.push_back(self)
		affecting.push_back(cell)

func remove_affect_all():
	for cell: Cell in affecting:
		if data.kind == BuildingData.Kind.RECYCLING:
			cell.trash.modulate.a = 1
		cell.affecting.erase(self)


# =============================
#  Signals
# =============================

func _on_area_2d_body_entered(body) -> void:
	if not Global.is_dragging:
		return
	var cell = body.get_parent()
	if cell is Cell:
		if cell.is_disabled:
			return
		get_tree().create_tween().tween_property(cell, "scale", Vector2(1.1,1.1), 0.2).set_ease(Tween.EASE_OUT)
		
func _on_area_2d_body_exited(body) -> void:
	if not Global.is_dragging:
		return
	var cell = body.get_parent()
	if cell is Cell:
		get_tree().create_tween().tween_property(cell, "scale", Vector2(1,1), 0.2).set_ease(Tween.EASE_OUT)
		
func _on_area_2d_mouse_entered() -> void:
	if not is_disabled and not Global.is_dragging and state == State.FREE:
		get_tree().create_tween().tween_property(sprite, "scale", initialScale * 1.05, 0.05).set_ease(Tween.EASE_OUT)

func _on_area_2d_mouse_exited() -> void:
		get_tree().create_tween().tween_property(sprite, "scale", initialScale, 0.05).set_ease(Tween.EASE_OUT)
	
func _on_effect_area_entered(body) -> void:
	if not Global.is_dragging and state != Building.State.FIXED:
		return
		
	var cell = body.get_parent()
	
	if cell is Cell:
		if state != Building.State.FIXED:
			will_affect.push_back(cell)
			set_affect_feedback(cell)
		else:
			will_affect.push_back(cell)
			push_affect_all()
			will_affect.clear()

func _on_effect_area_exited(body) -> void:
	var cell = body.get_parent()
	if cell is Cell:
		will_affect.erase(cell)
		remove_affect_feedback(cell)


func _on_drag_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if is_disabled or state != State.FREE:
		return
	if event is InputEventMouseButton:
		# Grabbed building ======================
		if event.pressed and not Global.is_dragging:
			dragging = true
			Global.is_dragging = true
			if current_cell != null:
				current_cell.is_filled = false
				current_cell = null
			for cell: Cell in get_overlapping_cells(): 
				will_affect.push_back(cell)
				set_affect_feedback(cell)
			remove_affect_all()
			global_position = get_global_mouse_position()
			
			grabed_sound.play()
			Signals.building_placed.emit()

func _on_window_resized():
	if state == Building.State.LOCKED:
		global_position = get_world_catalog_pos() + initialPos
		
func update_cells_in_area():
	for cell: Cell in get_overlapping_cells():
		_on_effect_area_entered(cell.body)
	
func get_world_catalog_pos() -> Vector2:
	var viewport := get_viewport()
	var screen_pos: Vector2 = catalog.get_global_rect().position
	return viewport.get_canvas_transform().affine_inverse() * screen_pos
