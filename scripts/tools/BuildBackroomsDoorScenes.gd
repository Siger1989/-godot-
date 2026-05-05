extends SceneTree

const FOUR_ROOM_SCENE_PATH := "res://scenes/mvp/FourRoomMVP.tscn"
const DoorComponentScript = preload("res://scripts/scene/DoorComponent.gd")

const DOORS := [
	{
		"id": "OldOfficeDoor_A",
		"category": "doors",
		"hinge_x": 0.49,
		"collision_size": Vector3(1.02, 2.09, 0.08),
		"collision_center": Vector3(0.0, 1.045, 0.0),
	},
]

const FOUR_ROOM_DOOR_PLACEMENTS := [
	{"name": "Door_P_BC_OldOffice_A", "id": "OldOfficeDoor_A", "pos": Vector3(6.0, 0.0, 3.0), "rot_y": 0.0, "portal": "P_BC"},
]

var _door_by_id: Dictionary = {}

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_index_doors()
	if not _create_wrapper_scenes():
		quit(1)
		return
	var placed := await _place_doors_in_four_room()
	if not placed:
		quit(1)
		return
	print("BUILD_BACKROOMS_DOOR_SCENES PASS wrappers=%d placements=%d" % [DOORS.size(), FOUR_ROOM_DOOR_PLACEMENTS.size()])
	quit(0)

func _index_doors() -> void:
	for door in DOORS:
		_door_by_id[door["id"]] = door

func _door_glb_path(door: Dictionary) -> String:
	return "res://assets/backrooms/props/%s/%s.glb" % [door["category"], door["id"]]

func _door_scene_path(door: Dictionary) -> String:
	return "res://assets/backrooms/props/%s/%s.tscn" % [door["category"], door["id"]]

func _create_wrapper_scenes() -> bool:
	for door in DOORS:
		var packed := load(_door_glb_path(door)) as PackedScene
		if packed == null:
			_fail("Missing GLB PackedScene for %s." % door["id"])
			return false

		var root := Node3D.new()
		root.name = door["id"]
		root.set_script(DoorComponentScript)
		root.set("door_id", door["id"])
		root.set("starts_open", false)
		root.set("hinge_pivot_path", NodePath("HingePivot"))
		root.set("closed_leaf_center_offset", Vector3(-float(door["hinge_x"]), 0.0, 0.0))
		root.set_meta("backrooms_door_id", door["id"])
		root.set_meta("backrooms_door_category", door["category"])
		root.set_meta("blocks_path", true)

		var hinge := Node3D.new()
		hinge.name = "HingePivot"
		hinge.position = Vector3(float(door["hinge_x"]), 0.0, 0.0)
		root.add_child(hinge)
		hinge.owner = root

		var model := packed.instantiate() as Node3D
		if model == null:
			_fail("Failed to instantiate GLB for %s." % door["id"])
			return false
		model.name = "Model"
		model.position = Vector3(-float(door["hinge_x"]), 0.0, 0.0)
		hinge.add_child(model)
		model.owner = root

		var body := StaticBody3D.new()
		body.name = "CollisionBody"
		body.position = Vector3(-float(door["hinge_x"]), 0.0, 0.0)
		var shape_node := CollisionShape3D.new()
		shape_node.name = "Collision"
		var shape := BoxShape3D.new()
		shape.size = door["collision_size"]
		shape_node.shape = shape
		shape_node.position = door["collision_center"]
		body.add_child(shape_node)
		hinge.add_child(body)
		body.owner = root
		shape_node.owner = root

		var packed_scene := PackedScene.new()
		var pack_result := packed_scene.pack(root)
		if pack_result != OK:
			_fail("Pack wrapper failed for %s code=%d." % [door["id"], pack_result])
			return false
		var save_result := ResourceSaver.save(packed_scene, _door_scene_path(door))
		if save_result != OK:
			_fail("Save wrapper failed for %s code=%d." % [door["id"], save_result])
			return false
		root.free()
	return true

func _place_doors_in_four_room() -> bool:
	var packed := load(FOUR_ROOM_SCENE_PATH) as PackedScene
	if packed == null:
		_fail("Missing FourRoomMVP scene.")
		return false
	var scene := packed.instantiate() as Node3D
	if scene == null:
		_fail("Failed to instantiate FourRoomMVP.")
		return false
	scene.set("build_on_ready", false)
	root.add_child(scene)
	current_scene = scene
	await process_frame

	var builder := scene.get_node_or_null("Systems/SceneBuilder")
	if builder != null and builder.has_method("build"):
		builder.call("build")
		await process_frame

	var level_root := scene.get_node_or_null("LevelRoot") as Node3D
	if level_root == null:
		_fail("FourRoomMVP missing LevelRoot.")
		return false
	var doors_root := level_root.get_node_or_null("Doors") as Node3D
	if doors_root == null:
		doors_root = Node3D.new()
		doors_root.name = "Doors"
		level_root.add_child(doors_root)
	for child in doors_root.get_children():
		child.free()

	for placement in FOUR_ROOM_DOOR_PLACEMENTS:
		var instance := _instantiate_door(placement["id"], placement["name"], placement["pos"], float(placement["rot_y"]))
		if instance == null:
			return false
		instance.set_meta("portal_id", placement["portal"])
		instance.set_meta("placement_group", "selected_door_frame")
		doors_root.add_child(instance)
		var portal := scene.get_node_or_null("LevelRoot/Portals/%s" % placement["portal"])
		if portal != null:
			portal.set("door_node_path", NodePath("../../Doors/%s" % placement["name"]))

	scene.set("build_on_ready", true)
	_assign_owned_level_nodes(scene)

	var repacked := PackedScene.new()
	var pack_result := repacked.pack(scene)
	if pack_result != OK:
		_fail("Pack FourRoomMVP failed code=%d." % pack_result)
		return false
	var save_result := ResourceSaver.save(repacked, FOUR_ROOM_SCENE_PATH)
	if save_result != OK:
		_fail("Save FourRoomMVP failed code=%d." % save_result)
		return false
	root.remove_child(scene)
	scene.free()
	return true

func _instantiate_door(door_id: String, node_name: String, position: Vector3, rot_y: float) -> Node3D:
	var door: Dictionary = _door_by_id.get(door_id, {})
	if door.is_empty():
		_fail("Unknown door id %s." % door_id)
		return null
	var packed := load(_door_scene_path(door)) as PackedScene
	if packed == null:
		_fail("Missing door wrapper scene for %s." % door_id)
		return null
	var instance := packed.instantiate() as Node3D
	if instance == null:
		_fail("Failed to instantiate door wrapper for %s." % door_id)
		return null
	instance.name = node_name
	instance.position = position
	instance.rotation.y = rot_y
	instance.set_meta("backrooms_door_id", door_id)
	instance.set_meta("blocks_path", true)
	return instance

func _assign_owned_level_nodes(scene: Node) -> void:
	for target_path in [
		"LevelRoot/Geometry",
		"LevelRoot/Areas",
		"LevelRoot/Portals",
		"LevelRoot/Markers",
		"LevelRoot/Lights",
		"LevelRoot/Props",
		"LevelRoot/Doors",
	]:
		var target := scene.get_node_or_null(target_path)
		if target != null:
			_assign_owner_recursive(target, scene)

func _assign_owner_recursive(node: Node, owner: Node) -> void:
	node.owner = owner
	for child in node.get_children():
		_assign_owner_recursive(child, owner)

func _fail(message: String) -> void:
	push_error("BUILD_BACKROOMS_DOOR_SCENES FAIL: %s" % message)
