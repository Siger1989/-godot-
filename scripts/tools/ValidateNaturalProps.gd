extends SceneTree

const FOUR_ROOM_SCENE_PATH := "res://scenes/mvp/FourRoomMVP.tscn"
const SHOWCASE_SCENE_PATH := "res://scenes/tests/Test_NaturalPropsShowcase.tscn"
const ROOM_SIZE := 6.0
const DOOR_CLEAR_RADIUS := 0.95
const CENTER_CLEAR_RADIUS := 0.95

const PROPS := [
	{"id": "Box_Small_A", "category": "boxes", "collision": false},
	{"id": "Box_Medium_A", "category": "boxes", "collision": true},
	{"id": "Box_Large_A", "category": "boxes", "collision": true},
	{"id": "Box_Stack_2_A", "category": "boxes", "collision": true},
	{"id": "Box_Stack_3_A", "category": "boxes", "collision": true},
	{"id": "Bucket_A", "category": "cleaning", "collision": true},
	{"id": "Mop_A", "category": "cleaning", "collision": true},
	{"id": "CleaningClothPile_A", "category": "cleaning", "collision": false},
	{"id": "Chair_Old_A", "category": "furniture", "collision": true},
	{"id": "SmallCabinet_A", "category": "furniture", "collision": true},
	{"id": "MetalShelf_A", "category": "furniture", "collision": true},
	{"id": "ElectricBox_A", "category": "industrial", "collision": false},
	{"id": "Vent_Wall_A", "category": "industrial", "collision": false},
	{"id": "Pipe_Straight_A", "category": "industrial", "collision": false},
	{"id": "Pipe_Corner_A", "category": "industrial", "collision": false},
]

const ROOM_CENTERS := {
	"Room_A": Vector3(0.0, 0.0, 0.0),
	"Room_B": Vector3(6.0, 0.0, 0.0),
	"Room_C": Vector3(6.0, 0.0, 6.0),
	"Room_D": Vector3(0.0, 0.0, 6.0),
}

const EXPECTED_ROOM_PROP_COUNTS := {
	"Room_A": 2,
	"Room_B": 5,
	"Room_C": 5,
	"Room_D": 4,
}

const DOOR_CENTERS := [
	Vector3(3.0, 0.0, 0.0),
	Vector3(6.0, 0.0, 3.0),
	Vector3(3.0, 0.0, 6.0),
	Vector3(0.0, 0.0, 3.0),
]

const WALL_PROP_IDS := {
	"ElectricBox_A": true,
	"Vent_Wall_A": true,
	"Pipe_Straight_A": true,
	"Pipe_Corner_A": true,
}

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	if not _validate_prop_resources():
		return
	if not _validate_showcase_scene():
		return
	var four_room_valid := await _validate_four_room_scene()
	if not four_room_valid:
		return
	print("NATURAL_PROPS_VALIDATION PASS props=%d placements=16" % PROPS.size())
	quit(0)

func _validate_prop_resources() -> bool:
	for prop in PROPS:
		var glb_path := _prop_glb_path(prop)
		var scene_path := _prop_scene_path(prop)
		if not ResourceLoader.exists(glb_path):
			_fail("Missing GLB resource: %s." % glb_path)
			return false
		if not ResourceLoader.exists(scene_path):
			_fail("Missing wrapper scene: %s." % scene_path)
			return false

		var packed := load(scene_path) as PackedScene
		if packed == null:
			_fail("Wrapper scene failed to load: %s." % scene_path)
			return false
		var instance := packed.instantiate() as Node3D
		if instance == null:
			_fail("Wrapper scene failed to instantiate: %s." % scene_path)
			return false
		if instance.name != String(prop["id"]):
			_fail("Wrapper root name mismatch for %s." % prop["id"])
			instance.free()
			return false
		if instance.get_node_or_null("Model") == null:
			_fail("Wrapper missing Model child: %s." % prop["id"])
			instance.free()
			return false
		if _count_mesh_instances(instance) <= 0:
			_fail("Wrapper has no MeshInstance3D descendants: %s." % prop["id"])
			instance.free()
			return false
		var has_collision := instance.get_node_or_null("CollisionBody/Collision") is CollisionShape3D
		if has_collision != bool(prop["collision"]):
			_fail("Wrapper collision expectation mismatch for %s." % prop["id"])
			instance.free()
			return false
		instance.free()
	return true

func _validate_showcase_scene() -> bool:
	var packed := load(SHOWCASE_SCENE_PATH) as PackedScene
	if packed == null:
		_fail("Missing showcase scene.")
		return false
	var scene := packed.instantiate() as Node3D
	if scene == null:
		_fail("Showcase scene failed to instantiate.")
		return false
	var props_root := scene.get_node_or_null("NaturalProps")
	if props_root == null or props_root.get_child_count() != PROPS.size():
		_fail("Showcase must contain exactly %d natural prop instances." % PROPS.size())
		scene.free()
		return false
	scene.free()
	return true

func _validate_four_room_scene() -> bool:
	var packed := load(FOUR_ROOM_SCENE_PATH) as PackedScene
	if packed == null:
		_fail("Missing FourRoomMVP scene.")
		return false
	var scene := packed.instantiate() as Node3D
	if scene == null:
		_fail("FourRoomMVP failed to instantiate.")
		return false
	scene.set("build_on_ready", false)
	root.add_child(scene)
	current_scene = scene
	await process_frame

	var props_root := scene.get_node_or_null("LevelRoot/Props") as Node3D
	if props_root == null:
		_fail("FourRoomMVP missing LevelRoot/Props.")
		return false
	var natural_prop_count := 0

	var room_counts := {}
	for room_id in EXPECTED_ROOM_PROP_COUNTS.keys():
		room_counts[room_id] = 0

	for child in props_root.get_children():
		var prop := child as Node3D
		if prop == null:
			_fail("A prop placement is not Node3D.")
			return false
		if not String(prop.get_meta("hideable_prop_id", "")).is_empty():
			continue
		natural_prop_count += 1
		var prop_id := String(prop.get_meta("natural_prop_id", ""))
		var room_id := String(prop.get_meta("room_id", ""))
		if prop_id.is_empty() or room_id.is_empty():
			_fail("Prop placement is missing metadata: %s." % prop.name)
			return false
		if not ROOM_CENTERS.has(room_id):
			_fail("Prop placement has unknown room metadata: %s." % prop.name)
			return false
		room_counts[room_id] = int(room_counts[room_id]) + 1

		if not _is_inside_room(prop.global_position, ROOM_CENTERS[room_id]):
			_fail("Prop placement falls outside its room bounds: %s at %s." % [prop.name, prop.global_position])
			return false
		if bool(prop.get_meta("blocks_path", false)) and _is_near_any_door(prop.global_position):
			_fail("Blocking prop is too close to a door opening: %s." % prop.name)
			return false
		if bool(prop.get_meta("blocks_path", false)) and _is_near_any_room_center(prop.global_position):
			_fail("Blocking prop is too close to the walkable center of a room: %s." % prop.name)
			return false
		if WALL_PROP_IDS.has(prop_id) and prop.global_position.y < 0.9:
			_fail("Wall/pipe prop is too low: %s at %.2f." % [prop.name, prop.global_position.y])
			return false
		if not WALL_PROP_IDS.has(prop_id) and prop.global_position.y < -0.02:
			_fail("Floor prop is below floor level: %s at %.2f." % [prop.name, prop.global_position.y])
			return false

	for room_id in EXPECTED_ROOM_PROP_COUNTS.keys():
		if int(room_counts[room_id]) != int(EXPECTED_ROOM_PROP_COUNTS[room_id]):
			_fail("Room prop count mismatch for %s." % room_id)
			return false
	if natural_prop_count != 16:
		_fail("FourRoomMVP expected 16 natural prop placements; found %d." % natural_prop_count)
		return false

	root.remove_child(scene)
	scene.free()
	return true

func _is_inside_room(position: Vector3, center: Vector3) -> bool:
	var half := ROOM_SIZE * 0.5
	return position.x >= center.x - half and position.x <= center.x + half and position.z >= center.z - half and position.z <= center.z + half

func _is_near_any_door(position: Vector3) -> bool:
	for door_center in DOOR_CENTERS:
		if _xz_distance(position, door_center) < DOOR_CLEAR_RADIUS:
			return true
	return false

func _is_near_any_room_center(position: Vector3) -> bool:
	for room_center in ROOM_CENTERS.values():
		if _xz_distance(position, room_center) < CENTER_CLEAR_RADIUS:
			return true
	return false

func _xz_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))

func _count_mesh_instances(node: Node) -> int:
	var count := 1 if node is MeshInstance3D else 0
	for child in node.get_children():
		count += _count_mesh_instances(child)
	return count

func _prop_glb_path(prop: Dictionary) -> String:
	return "res://assets/backrooms/props/%s/%s.glb" % [prop["category"], prop["id"]]

func _prop_scene_path(prop: Dictionary) -> String:
	return "res://assets/backrooms/props/%s/%s.tscn" % [prop["category"], prop["id"]]

func _fail(message: String) -> void:
	push_error("NATURAL_PROPS_VALIDATION FAIL: %s" % message)
	quit(1)
