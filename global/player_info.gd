extends Node

enum Gender {
	Male,
	Female,
	None
}

var gender: Gender = Gender.None:
	set(value):
		gender = value
		_update_profile_fields()

var birthdate: PlayerDate = PlayerDate.new():
	set(value):
		birthdate = value
		_update_profile_fields()

var session_id: String = ""
var device_id: String = ""
var absolute_start_time: float = 0.0

var db: SQLite = null
const DB_PATH := "user://player_info.db"
const DEVICE_ID_PATH := "user://device_id.txt"

var _drag_start_pos: Vector2
var _drag_start_time: float
var _drag_node: Node

var _current_scene_name: String = ""
var _current_scene_start: float = 0.0
var _current_scene_row_id: int = -1

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
	absolute_start_time = Time.get_unix_time_from_system()
	get_tree().set_auto_accept_quit(false)
	get_tree().node_added.connect(_on_node_added)

	_open_database()
	device_id = _load_or_create_device_id()
	session_id = _generate_session_id()
	_insert_session_row()
	track_scene(String(get_tree().current_scene.name))

var _finalize_timer: float = 0.0
const FINALIZE_INTERVAL: float = 15.0

func _process(delta: float) -> void:
	_finalize_timer += delta
	if _finalize_timer >= FINALIZE_INTERVAL:
		_finalize_timer = 0.0
		finalize_session()

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_WM_GO_BACK_REQUEST:
			track_scene(_current_scene_name)
			finalize_session()
			if db != null:
				db.close_db()
			get_tree().quit()
		NOTIFICATION_APPLICATION_RESUMED:
			finalize_session()

func _on_node_added(node: Node) -> void:
	if node.get_parent() == get_tree().get_root() and node != self:
		if GameState.level != null:
			track_scene(String(node.name) + "_" + str(GameState.level.level))
		else:
			track_scene(String(node.name))

# ============================================
# DATABASE SETUP

func _open_database() -> void:
	db = SQLite.new()
	db.path = DB_PATH
	db.foreign_keys = true
	if not db.open_db():
		push_error("PlayerInfo: failed to open local database at " + DB_PATH)
		return
	_ensure_schema()

func _ensure_schema() -> void:
	db.create_table("sessions", {
		"session_id": {"data_type": "text", "primary_key": true, "not_null": true},
		"device_id": {"data_type": "text"},
		"absolute_start_time": {"data_type": "real"},
		"total_duration": {"data_type": "real", "default": 0.0},
		"gender": {"data_type": "text"},
		"birth_day": {"data_type": "int"},
		"birth_month": {"data_type": "int"},
		"birth_year": {"data_type": "int"},
		# "dirty"/"synced_at" exist for the future remote-sync stage: a row
		# stays dirty until a sync clears it, so nothing is built here yet
		# that actively clears them.
		"dirty": {"data_type": "int", "default": 1},
		"synced_at": {"data_type": "real"},
	})
	db.create_table("scenes", {
		"id": {"data_type": "int", "primary_key": true, "not_null": true, "auto_increment": true},
		"session_id": {"data_type": "text", "not_null": true, "foreign_key": "sessions.session_id"},
		"scene": {"data_type": "text"},
		"time": {"data_type": "real"},
		"duration": {"data_type": "real"},
	})
	db.create_table("interactions", {
		"id": {"data_type": "int", "primary_key": true, "not_null": true, "auto_increment": true},
		"session_id": {"data_type": "text", "not_null": true, "foreign_key": "sessions.session_id"},
		"type": {"data_type": "text"},
		"time": {"data_type": "real"},
		"duration": {"data_type": "real"},
		"root_scene": {"data_type": "text"},
		"level": {"data_type": "int"},
		"position_x": {"data_type": "real"},
		"position_y": {"data_type": "real"},
		"start_x": {"data_type": "real"},
		"start_y": {"data_type": "real"},
		"end_x": {"data_type": "real"},
		"end_y": {"data_type": "real"},
		"clicked": {"data_type": "text"},
		"drag": {"data_type": "text"},
		"drop_target": {"data_type": "text"},
	})
	db.create_table("writings", {
		"id": {"data_type": "int", "primary_key": true, "not_null": true, "auto_increment": true},
		"session_id": {"data_type": "text", "not_null": true, "foreign_key": "sessions.session_id"},
		"kind": {"data_type": "text"},
		"image": {"data_type": "blob"},
		"prediction_json": {"data_type": "text"},
	})

func _load_or_create_device_id() -> String:
	if FileAccess.file_exists(DEVICE_ID_PATH):
		var read_file := FileAccess.open(DEVICE_ID_PATH, FileAccess.READ)
		var existing := read_file.get_as_text().strip_edges()
		read_file.close()
		if not existing.is_empty():
			return existing

	var new_id := _generate_uuid_v4()
	var write_file := FileAccess.open(DEVICE_ID_PATH, FileAccess.WRITE)
	write_file.store_string(new_id)
	write_file.close()
	return new_id

# A real UUIDv4 collision between independently-generated IDs (many
# devices, no coordinator) is astronomically unlikely -- but for
# irreplaceable research data, "unlikely" isn't "safe to ignore if it
# happens anyway". This check makes a collision loud and recoverable
# instead of silently merging two different sessions into one row.
func _generate_session_id() -> String:
	var new_id := _generate_uuid_v4()
	while not db.select_rows("sessions", "session_id = '%s'" % new_id, ["session_id"]).is_empty():
		push_warning("PlayerInfo: session_id collision detected, regenerating")
		new_id = _generate_uuid_v4()
	return new_id

func _generate_uuid_v4() -> String:
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var bytes := PackedByteArray()
	bytes.resize(16)
	for i in range(16):
		bytes[i] = rng.randi() % 256

	# Set the RFC 4122 version (4) and variant (10) bits.
	bytes[6] = (bytes[6] & 0x0F) | 0x40
	bytes[8] = (bytes[8] & 0x3F) | 0x80

	var hex := bytes.hex_encode()
	return "%s-%s-%s-%s-%s" % [
		hex.substr(0, 8),
		hex.substr(8, 4),
		hex.substr(12, 4),
		hex.substr(16, 4),
		hex.substr(20, 12),
	]

func _insert_session_row() -> void:
	db.insert_row("sessions", {
		"session_id": session_id,
		"device_id": device_id,
		"absolute_start_time": absolute_start_time,
		"total_duration": 0.0,
		"gender": Gender.keys()[gender],
		"birth_day": birthdate.day,
		"birth_month": birthdate.month,
		"birth_year": birthdate.year,
		"dirty": 1,
	})

func _update_profile_fields() -> void:
	if db == null or session_id == "":
		return
	db.update_rows("sessions", "session_id = '%s'" % session_id, {
		"gender": Gender.keys()[gender],
		"birth_day": birthdate.day,
		"birth_month": birthdate.month,
		"birth_year": birthdate.year,
		"dirty": 1,
	})

func finalize_session() -> void:
	if db == null or session_id == "":
		return
	var total_duration := Time.get_unix_time_from_system() - absolute_start_time
	db.update_rows("sessions", "session_id = '%s'" % session_id, {
		"total_duration": total_duration,
		"dirty": 1,
	})

# ============================================
# INPUT TRACKING

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
	var controls := []
	_collect_controls(get_viewport(), pos, controls)
	for i in range(controls.size() - 1, -1, -1):
		if not _is_ignored(controls[i]):
			return controls[i]

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
		if current == get_tree().current_scene:
			break
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

# ============================================
# RECORDING

func track_scene(scene_name: String) -> void:
	var now := Time.get_ticks_msec() / 1000.0

	if _current_scene_row_id != -1 and _current_scene_name == scene_name:
		db.update_rows("scenes", "id = %d" % _current_scene_row_id, {"duration": now - _current_scene_start})
		return

	if _current_scene_row_id != -1:
		db.update_rows("scenes", "id = %d" % _current_scene_row_id, {"duration": now - _current_scene_start})

	db.insert_row("scenes", {
		"session_id": session_id,
		"scene": scene_name,
		"time": now,
		"duration": 0.0,
	})
	_current_scene_row_id = db.last_insert_rowid

	_current_scene_name = scene_name
	_current_scene_start = now

func add_click(root: Node, lvl: int, t: float, dur: float, pos: Vector2, clicked_node: Node) -> void:
	db.insert_row("interactions", {
		"session_id": session_id,
		"type": "click",
		"time": t,
		"duration": dur,
		"root_scene": root.name,
		"level": lvl,
		"position_x": pos.x,
		"position_y": pos.y,
		"clicked": clicked_node.name,
	})

func add_drag(root: Node, lvl: int, t: float, dur: float, start: Vector2, end: Vector2, drag_node: Node, drop_node: Node) -> void:
	db.insert_row("interactions", {
		"session_id": session_id,
		"type": "drag",
		"time": t,
		"duration": dur,
		"root_scene": root.name,
		"level": lvl,
		"start_x": start.x,
		"start_y": start.y,
		"end_x": end.x,
		"end_y": end.y,
		"drag": drag_node.name if drag_node != null else "",
		"drop_target": drop_node.name if drop_node != null else "",
	})

func add_writing(img: Image, pred: Dictionary[String, float], k: BuildingData.Kind) -> void:
	var png_bytes: PackedByteArray = img.save_png_to_buffer()
	db.insert_row("writings", {
		"session_id": session_id,
		"kind": BuildingData.Kind.keys()[k],
		"image": png_bytes,
		"prediction_json": JSON.stringify(pred),
	})
