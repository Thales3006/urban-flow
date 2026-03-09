extends Node

class Date:
	var day: int = 0
	var month: int = 0
	var year: int = 0

enum Gender {
	Male,
	Female,
	None
}

class Writing:
	var image: Image
	var prediction: float
	var kind: BuildingData.Kind

@abstract class Interaction:
	var root_scene: String
	var level: int
	var time: float
	var duration: float

class Click extends Interaction:
	var position: Vector2
	var clicked: String

class Drag extends Interaction:
	var start_position: Vector2
	var end_position: Vector2
	var drag: String
	var drop: String

var absolute_start_time: float
var gender: Gender = Gender.None
var birthdate: Date = Date.new()
var interactions: Array[Interaction] = []
var writings: Array[Writing] = []

var _drag_start_pos: Vector2
var _drag_start_time: float
var _drag_node: Node

var scenes: Array[Dictionary] = []
var _current_scene_name: String = ""
var _current_scene_start: float = 0.0

var ignored_node_names: Array[String] = [
		"Tutorial", 
		"Beaver", 
		"Dimmer", 
		"UI", 
		"DateBars",
		"drag",
		"click",
		"Spacer",
		"HBoxContainer",
		"VBoxContainer",
		"Hbox",
		"Spacer1",
		"Spacer2",
		"Word",
		"WordHint",
	]
	
func _ready() -> void:
	absolute_start_time = Time.get_ticks_msec() / 1000.0
	get_tree().set_auto_accept_quit(false)
	get_tree().get_root().close_requested.connect(_on_close)
	get_tree().node_added.connect(_on_node_added)
	track_scene(String(get_tree().current_scene.name))

func _on_node_added(node: Node) -> void:
	if node.get_parent() == get_tree().get_root() and node != self:
		track_scene(String(node.name))

func _on_close() -> void:
	append_to_json()
	get_tree().quit()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var e := event as InputEventMouseButton
		var viewport_rect := get_viewport().get_visible_rect()
		if not viewport_rect.has_point(e.position):
			return
	
	var current_scene := get_tree().current_scene
	var lvl := 0
	if GameState.level != null and GameState.level.level != null:
		lvl = GameState.level.level

	if event is InputEventMouseButton:
		var e := event as InputEventMouseButton
		if e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				_drag_start_pos = e.position
				_drag_start_time = Time.get_ticks_msec() / 1000.0
				_drag_node = _get_node_at(e.position)
			else:
				var release_time := Time.get_ticks_msec() / 1000.0
				var duration := release_time - _drag_start_time
				var moved := e.position.distance_to(_drag_start_pos)

				if moved < 10.0:
					var clicked := _get_node_at(e.position)
					if _is_ignored(clicked):
						return
					add_click(current_scene, lvl, _drag_start_time, duration, e.position, clicked)
				else:
					var drop := _get_node_at(e.position)
					if _is_ignored(_drag_node) and _is_ignored(drop):
						return
					add_drag(current_scene, lvl, _drag_start_time, duration, _drag_start_pos, e.position, _drag_node, drop)

func _is_ignored(node: Node) -> bool:
	if node == null:
		return true
	if node.name in ignored_node_names:
		return true
	if node is CanvasItem and not (node as CanvasItem).is_visible_in_tree():
		return true
	return false
	
func _get_node_at(pos: Vector2) -> Node:
	# 1. Control nodes (UI)
	var controls := []
	_collect_controls(get_viewport(), pos, controls)
	for i in range(controls.size() - 1, -1, -1):
		if not _is_ignored(controls[i]):
			return controls[i]

	# 2. World 2D
	var space := get_viewport().find_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.position = get_viewport().get_canvas_transform().affine_inverse() * pos
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.max_results = 32
	var results := space.intersect_point(query)
	for result in results:
		var node := _get_meaningful_parent(result["collider"] as Node)
		if not _is_ignored(node):
			return node

	return null

func _get_meaningful_parent(node: Node) -> Node:
	var current := node
	while current != null:
		# para ao chegar na raiz da cena
		if current == get_tree().current_scene:
			break
		# sobe se for um CollisionShape ou nó puramente técnico
		if current is CollisionShape2D or current is CollisionPolygon2D:
			current = current.get_parent()
			continue
		if not _is_ignored(current):
			return current
		current = current.get_parent()
	return node

func _collect_controls(node: Node, pos: Vector2, hits: Array) -> void:
	for child in node.get_children():
		if child is Control:
			var c := child as Control
			if c.visible and c.get_global_rect().has_point(pos):
				hits.append(c)
		_collect_controls(child, pos, hits)

func track_scene(scene_name: String) -> void:
	# fecha a cena anterior
	if _current_scene_name != "":
		scenes.append({
			"scene": _current_scene_name,
			"duration": Time.get_ticks_msec() / 1000.0 - _current_scene_start,
			"time": _current_scene_start,
		})
	_current_scene_name = scene_name
	_current_scene_start = Time.get_ticks_msec() / 1000.0

func add_click(root: Node, lvl: int, t: float, dur: float, pos: Vector2, clicked_node: Node) -> void:
	var click := Click.new()
	click.root_scene = root.name
	click.level = lvl
	click.time = t
	click.duration = dur
	click.position = pos
	click.clicked = clicked_node.name
	interactions.append(click)

func add_drag(root: Node, lvl: int, t: float, dur: float, start: Vector2, end: Vector2, drag_node: Node, drop_node: Node) -> void:
	var drag := Drag.new()
	drag.root_scene = root.name
	drag.level = lvl
	drag.time = t
	drag.duration = dur
	drag.start_position = start
	drag.end_position = end
	drag.drag = drag_node.name
	if drop_node != null:
		drag.drop = drop_node.name
	else:
		drag.drop = ""
	interactions.append(drag)
	
func add_writing(img: Image, pred: float, k: BuildingData.Kind) -> void:
	var w := Writing.new()
	w.image = img
	w.prediction = pred
	w.kind = k
	writings.append(w)

func to_json() -> Dictionary:
	var current_time := Time.get_ticks_msec() / 1000.0
	
	if _current_scene_name != "":
		track_scene("end")
	
	var data := {
		"absolute_start_time": absolute_start_time,
		"total_duration": current_time - absolute_start_time,
		"gender": Gender.keys()[gender],
		"birthdate": {
			"day": birthdate.day,
			"month": birthdate.month,
			"year": birthdate.year
		},
		"scenes": scenes,
		"interactions": []
	}
	data["writings"] = []
	for w in writings:
		var png_bytes: PackedByteArray = w.image.save_png_to_buffer()
		var b64: String = Marshalls.raw_to_base64(png_bytes)
		data["writings"].append({
			"image": b64,
			"prediction": w.prediction,
			"kind": BuildingData.Kind.keys()[w.kind]
		})

	for interaction in interactions:
		var root_scene_name: String = ""
		if interaction.root_scene:
			root_scene_name = interaction.root_scene
			
		var entry := {
			"level": interaction.level,
			"time": interaction.time,
			"duration": interaction.duration,
			"root_scene": root_scene_name
		}

		if interaction is Click:
			entry["type"] = "click"
			entry["position"] = {
				"x": interaction.position.x,
				"y": interaction.position.y
			}
			entry["clicked"] = interaction.clicked

		elif interaction is Drag:
			entry["type"] = "drag"
			entry["start_position"] = {
				"x": interaction.start_position.x,
				"y": interaction.start_position.y
			}
			entry["end_position"] = {
				"x": interaction.end_position.x,
				"y": interaction.end_position.y
			}
			entry["drag"] = interaction.drag
			entry["drop"] = interaction.drop

		data["interactions"].append(entry)

	return data

func append_to_json(path: String = "user://player_info.json") -> void:
	var existing_data: Array = []

	if FileAccess.file_exists(path):
		var read_file := FileAccess.open(path, FileAccess.READ)
		if read_file == null:
			push_error("PlayerInfo: failed to open file for reading: %s" % path)
			return
		var json_string := read_file.get_as_text()
		read_file.close()

		var parsed = JSON.parse_string(json_string)
		if parsed is Array:
			existing_data = parsed
		elif parsed is Dictionary:
			existing_data = [parsed]
		else:
			push_error("PlayerInfo: invalid JSON format in file: %s" % path)
			return

	existing_data.append(to_json())

	var write_file := FileAccess.open(path, FileAccess.WRITE)
	if write_file == null:
		push_error("PlayerInfo: failed to open file for writing: %s" % path)
		return

	write_file.store_string(JSON.stringify(existing_data, "\t"))
	write_file.close()
