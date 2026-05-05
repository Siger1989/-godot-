extends SceneTree

const FOUR_ROOM_SCENE_PATH := "res://scenes/mvp/FourRoomMVP.tscn"
const SHOWCASE_SCENE_PATH := "res://scenes/tests/Test_NaturalPropsShowcase.tscn"
const ResourceShowcaseControllerScript = preload("res://scripts/tools/ResourceShowcaseController.gd")
const MonsterSizeSource = preload("res://scripts/monster/MonsterSizeSource.gd")

const PROPS := [
	{"id": "Box_Small_A", "category": "boxes", "collision_size": Vector3.ZERO, "collision_center": Vector3.ZERO, "blocks_path": false},
	{"id": "Box_Medium_A", "category": "boxes", "collision_size": Vector3(0.50, 0.40, 0.40), "collision_center": Vector3(0.0, 0.20, 0.0), "blocks_path": true},
	{"id": "Box_Large_A", "category": "boxes", "collision_size": Vector3(0.70, 0.50, 0.50), "collision_center": Vector3(0.0, 0.25, 0.0), "blocks_path": true},
	{"id": "Box_Stack_2_A", "category": "boxes", "collision_size": Vector3(0.66, 0.70, 0.48), "collision_center": Vector3(0.0, 0.35, 0.0), "blocks_path": true},
	{"id": "Box_Stack_3_A", "category": "boxes", "collision_size": Vector3(0.78, 1.06, 0.56), "collision_center": Vector3(0.0, 0.53, 0.0), "blocks_path": true},
	{"id": "Bucket_A", "category": "cleaning", "collision_size": Vector3(0.42, 0.36, 0.42), "collision_center": Vector3(0.0, 0.18, 0.0), "blocks_path": true},
	{"id": "Mop_A", "category": "cleaning", "collision_size": Vector3(0.24, 1.42, 0.18), "collision_center": Vector3(0.13, 0.71, 0.0), "blocks_path": true},
	{"id": "CleaningClothPile_A", "category": "cleaning", "collision_size": Vector3.ZERO, "collision_center": Vector3.ZERO, "blocks_path": false},
	{"id": "Chair_Old_A", "category": "furniture", "collision_size": Vector3(0.58, 0.86, 0.56), "collision_center": Vector3(0.0, 0.43, 0.04), "blocks_path": true},
	{"id": "SmallCabinet_A", "category": "furniture", "collision_size": Vector3(0.48, 0.80, 0.43), "collision_center": Vector3(0.0, 0.40, 0.0), "blocks_path": true},
	{"id": "MetalShelf_A", "category": "furniture", "collision_size": Vector3(1.04, 1.82, 0.46), "collision_center": Vector3(0.0, 0.91, 0.0), "blocks_path": true},
	{"id": "ElectricBox_A", "category": "industrial", "collision_size": Vector3.ZERO, "collision_center": Vector3.ZERO, "blocks_path": false},
	{"id": "Vent_Wall_A", "category": "industrial", "collision_size": Vector3.ZERO, "collision_center": Vector3.ZERO, "blocks_path": false},
	{"id": "Pipe_Straight_A", "category": "industrial", "collision_size": Vector3.ZERO, "collision_center": Vector3.ZERO, "blocks_path": false},
	{"id": "Pipe_Corner_A", "category": "industrial", "collision_size": Vector3.ZERO, "collision_center": Vector3.ZERO, "blocks_path": false},
]

const FOUR_ROOM_PLACEMENTS := [
	{"name": "RoomA_Corner_BoxStack", "id": "Box_Stack_2_A", "pos": Vector3(-2.28, 0.0, -2.18), "rot_y": 0.24, "room": "Room_A", "group": "boxes_corner"},
	{"name": "RoomA_Low_Box", "id": "Box_Medium_A", "pos": Vector3(-1.72, 0.0, -2.30), "rot_y": -0.18, "room": "Room_A", "group": "boxes_corner"},
	{"name": "RoomB_Maintenance_Cabinet", "id": "SmallCabinet_A", "pos": Vector3(8.47, 0.0, -1.55), "rot_y": -PI * 0.5, "room": "Room_B", "group": "maintenance_wall"},
	{"name": "RoomB_Bucket", "id": "Bucket_A", "pos": Vector3(8.24, 0.0, -2.35), "rot_y": -0.55, "room": "Room_B", "group": "cleaning_corner"},
	{"name": "RoomB_Mop_Leaning", "id": "Mop_A", "pos": Vector3(8.50, 0.0, -2.16), "rot_y": -PI * 0.5 - 0.12, "room": "Room_B", "group": "cleaning_corner"},
	{"name": "RoomB_ElectricBox", "id": "ElectricBox_A", "pos": Vector3(8.89, 1.18, 1.35), "rot_y": -PI * 0.5, "room": "Room_B", "group": "wall_maintenance"},
	{"name": "RoomB_Pipe_Straight", "id": "Pipe_Straight_A", "pos": Vector3(8.87, 1.76, 1.35), "rot_y": -PI * 0.5, "room": "Room_B", "group": "wall_maintenance"},
	{"name": "RoomC_MetalShelf", "id": "MetalShelf_A", "pos": Vector3(8.35, 0.0, 5.42), "rot_y": -PI * 0.5 + 0.06, "room": "Room_C", "group": "storage_side"},
	{"name": "RoomC_BoxStack_3", "id": "Box_Stack_3_A", "pos": Vector3(7.33, 0.0, 4.60), "rot_y": 0.38, "room": "Room_C", "group": "storage_side"},
	{"name": "RoomC_Small_Box", "id": "Box_Small_A", "pos": Vector3(7.92, 0.0, 4.35), "rot_y": -0.34, "room": "Room_C", "group": "storage_side"},
	{"name": "RoomC_OldChair", "id": "Chair_Old_A", "pos": Vector3(5.00, 0.0, 7.88), "rot_y": PI - 0.30, "room": "Room_C", "group": "old_office_edge"},
	{"name": "RoomC_WallVent", "id": "Vent_Wall_A", "pos": Vector3(6.82, 2.05, 8.89), "rot_y": PI, "room": "Room_C", "group": "upper_wall_detail"},
	{"name": "RoomD_WallVent", "id": "Vent_Wall_A", "pos": Vector3(-2.89, 2.02, 7.35), "rot_y": PI * 0.5, "room": "Room_D", "group": "upper_wall_detail"},
	{"name": "RoomD_NorthPipe", "id": "Pipe_Straight_A", "pos": Vector3(0.95, 2.12, 8.88), "rot_y": 0.0, "room": "Room_D", "group": "pipe_edge"},
	{"name": "RoomD_PipeCorner", "id": "Pipe_Corner_A", "pos": Vector3(-2.60, 2.03, 8.68), "rot_y": PI * 0.15, "room": "Room_D", "group": "pipe_edge"},
	{"name": "RoomD_ClothPile", "id": "CleaningClothPile_A", "pos": Vector3(-2.23, 0.0, 7.85), "rot_y": 0.40, "room": "Room_D", "group": "low_cleaning_detail"},
]

var _prop_by_id: Dictionary = {}

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_index_props()
	if not _create_wrapper_scenes():
		quit(1)
		return
	if not _create_showcase_scene():
		quit(1)
		return
	var placed_four_room := await _place_props_in_four_room()
	if not placed_four_room:
		quit(1)
		return
	print("BUILD_NATURAL_PROP_SCENES PASS wrappers=%d placements=%d showcase=%s" % [PROPS.size(), FOUR_ROOM_PLACEMENTS.size(), SHOWCASE_SCENE_PATH])
	quit(0)

func _index_props() -> void:
	for prop in PROPS:
		_prop_by_id[prop["id"]] = prop

func _prop_glb_path(prop: Dictionary) -> String:
	return "res://assets/backrooms/props/%s/%s.glb" % [prop["category"], prop["id"]]

func _prop_scene_path(prop: Dictionary) -> String:
	return "res://assets/backrooms/props/%s/%s.tscn" % [prop["category"], prop["id"]]

func _create_wrapper_scenes() -> bool:
	for prop in PROPS:
		var packed := load(_prop_glb_path(prop)) as PackedScene
		if packed == null:
			_fail("Missing GLB PackedScene for %s." % prop["id"])
			return false

		var root := Node3D.new()
		root.name = prop["id"]
		root.set_meta("natural_prop_id", prop["id"])
		root.set_meta("natural_prop_category", prop["category"])
		root.set_meta("blocks_path", bool(prop["blocks_path"]))

		var model := packed.instantiate() as Node3D
		if model == null:
			_fail("Failed to instantiate GLB for %s." % prop["id"])
			return false
		model.name = "Model"
		root.add_child(model)
		model.owner = root

		var collision_size: Vector3 = prop["collision_size"]
		if collision_size != Vector3.ZERO:
			var body := StaticBody3D.new()
			body.name = "CollisionBody"
			var shape_node := CollisionShape3D.new()
			shape_node.name = "Collision"
			var shape := BoxShape3D.new()
			shape.size = collision_size
			shape_node.shape = shape
			shape_node.position = prop["collision_center"]
			body.add_child(shape_node)
			root.add_child(body)
			body.owner = root
			shape_node.owner = root

		var packed_scene := PackedScene.new()
		var pack_result := packed_scene.pack(root)
		if pack_result != OK:
			_fail("Pack wrapper failed for %s code=%d." % [prop["id"], pack_result])
			return false
		var save_result := ResourceSaver.save(packed_scene, _prop_scene_path(prop))
		if save_result != OK:
			_fail("Save wrapper failed for %s code=%d." % [prop["id"], save_result])
			return false
		root.free()
	return true

func _create_showcase_scene() -> bool:
	var scene := Node3D.new()
	scene.name = "Test_NaturalPropsShowcase"
	scene.set_script(ResourceShowcaseControllerScript)
	_create_showcase_environment(scene)

	var props_root := Node3D.new()
	props_root.name = "NaturalProps"
	scene.add_child(props_root)
	props_root.owner = scene

	var spacing_x := 1.45
	var spacing_z := 1.35
	for index in range(PROPS.size()):
		var prop: Dictionary = PROPS[index]
		var row := index / 5
		var column := index % 5
		var position := Vector3((column - 2) * spacing_x, 0.0, (row - 1) * spacing_z)
		var instance := _instantiate_prop(prop["id"], "%s_Showcase" % prop["id"], position, (index % 3 - 1) * 0.18)
		if instance == null:
			return false
		props_root.add_child(instance)
		_assign_owner_recursive(instance, scene)
	if not _add_unified_showcase_resources(scene):
		return false

	var packed_scene := PackedScene.new()
	var pack_result := packed_scene.pack(scene)
	if pack_result != OK:
		_fail("Pack showcase failed code=%d." % pack_result)
		return false
	var save_result := ResourceSaver.save(packed_scene, SHOWCASE_SCENE_PATH)
	if save_result != OK:
		_fail("Save showcase failed code=%d." % save_result)
		return false
	scene.free()
	return true

func _create_showcase_environment(scene: Node3D) -> void:
	var world := WorldEnvironment.new()
	world.name = "WorldEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.015, 0.014, 0.012)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(1.0, 0.92, 0.74)
	environment.ambient_light_energy = 0.28
	world.environment = environment
	scene.add_child(world)
	world.owner = scene

	var floor := MeshInstance3D.new()
	floor.name = "ScaleCheckFloor"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(16.8, 0.04, 9.8)
	floor.mesh = mesh
	floor.position = Vector3(1.4, -0.02, 0.45)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.54, 0.49, 0.36)
	material.roughness = 0.9
	floor.material_override = material
	scene.add_child(floor)
	floor.owner = scene

	var light := DirectionalLight3D.new()
	light.name = "SoftReviewLight"
	light.light_energy = 1.7
	light.rotation_degrees = Vector3(-46.0, -35.0, 0.0)
	scene.add_child(light)
	light.owner = scene

	var camera := Camera3D.new()
	camera.name = "ReviewCamera"
	camera.fov = 50.0
	camera.look_at_from_position(Vector3(0.0, 5.35, 8.25), Vector3(0.0, 0.75, 0.9), Vector3.UP)
	camera.current = true
	scene.add_child(camera)
	camera.owner = scene

func _add_unified_showcase_resources(scene: Node3D) -> bool:
	var door_root := Node3D.new()
	door_root.name = "DoorProps"
	door_root.set_meta("showcase_category", "doors")
	scene.add_child(door_root)
	door_root.owner = scene
	if not _add_showcase_scene_instance(
		door_root,
		scene,
		"res://assets/backrooms/props/doors/OldOfficeDoor_A.tscn",
		"OldOfficeDoor_A_Showcase",
		Vector3(-4.65, 0.0, 3.05),
		0.22,
		"OldOfficeDoor_A",
		"doors"
	):
		return false

	var hideable_root := Node3D.new()
	hideable_root.name = "HideableProps"
	hideable_root.set_meta("showcase_category", "hideables")
	scene.add_child(hideable_root)
	hideable_root.owner = scene
	if not _add_showcase_scene_instance(
		hideable_root,
		scene,
		"res://assets/backrooms/props/furniture/HideLocker_A.tscn",
		"HideLocker_A_Showcase",
		Vector3(-2.45, 0.0, 3.0),
		-0.18,
		"HideLocker_A",
		"furniture"
	):
		return false

	var characters_root := Node3D.new()
	characters_root.name = "Characters"
	characters_root.set_meta("showcase_category", "characters")
	scene.add_child(characters_root)
	characters_root.owner = scene
	if not _add_showcase_scene_instance(
		characters_root,
		scene,
		"res://scenes/modules/PlayerModule.tscn",
		"Player_Showcase",
		Vector3(0.15, 0.0, 3.0),
		-0.3,
		"PlayerModule",
		"characters",
		true
	):
		return false
	if not _add_showcase_scene_instance(
		characters_root,
		scene,
		"res://scenes/modules/MonsterModule.tscn",
		"Monster_Default_Showcase",
		Vector3(2.3, 0.05, 3.0),
		0.25,
		"MonsterModule",
		"characters",
		true
	):
		return false
	_apply_monster_size_source(characters_root, "Monster_Default_Showcase", "normal")
	var red_monster := _add_showcase_scene_instance(
		characters_root,
		scene,
		"res://scenes/modules/MonsterModule.tscn",
		"Monster_Red_KeyBearer_Showcase",
		Vector3(4.35, 0.05, 3.0),
		-0.22,
		"MonsterModule_Red_KeyBearer",
		"characters",
		true
	)
	if not red_monster:
		return false
	var red_node := characters_root.get_node_or_null("Monster_Red_KeyBearer_Showcase")
	if red_node != null:
		_apply_monster_size_source(characters_root, "Monster_Red_KeyBearer_Showcase", "red_hunter")
		red_node.add_to_group("red_monster", true)
		red_node.set("monster_role", "red")
		red_node.set("attach_escape_key", false)
		red_node.remove_meta("has_escape_key")
	if not _add_showcase_scene_instance(
		characters_root,
		scene,
		"res://assets/backrooms/monsters/NightmareCreature_Monster.tscn",
		"NightmareCreature_A_Showcase",
		Vector3(6.35, 0.05, 3.0),
		-0.16,
		"NightmareCreature_A",
		"monsters",
		true
	):
		return false
	_apply_monster_size_source(characters_root, "NightmareCreature_A_Showcase", "nightmare")
	return true

func _apply_monster_size_source(parent: Node, node_name: String, template_id: String) -> void:
	var node := parent.get_node_or_null(node_name) as Node3D
	if node == null:
		return
	node.scale = MonsterSizeSource.template_scale(template_id)
	node.set_meta("default_size_source", MonsterSizeSource.template_source_reference(template_id))

func _add_showcase_scene_instance(
	parent: Node3D,
	owner: Node,
	scene_path: String,
	node_name: String,
	position: Vector3,
	yaw: float,
	resource_id: String,
	category: String,
	disable_process := false
) -> bool:
	var packed := load(scene_path) as PackedScene
	if packed == null:
		_fail("Missing showcase resource scene: %s." % scene_path)
		return false
	var instance := packed.instantiate() as Node3D
	if instance == null:
		_fail("Failed to instantiate showcase resource: %s." % scene_path)
		return false
	instance.name = node_name
	instance.position = position
	instance.rotation.y = yaw
	instance.set_meta("resource_model_id", resource_id)
	instance.set_meta("resource_model_category", category)
	if disable_process:
		instance.process_mode = Node.PROCESS_MODE_DISABLED
	parent.add_child(instance)
	_assign_owner_recursive(instance, owner)
	return true

func _place_props_in_four_room() -> bool:
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
	var props_root := level_root.get_node_or_null("Props") as Node3D
	if props_root == null:
		props_root = Node3D.new()
		props_root.name = "Props"
		level_root.add_child(props_root)
	for child in props_root.get_children():
		if String(child.get_meta("hideable_prop_id", "")).is_empty():
			child.free()

	for placement in FOUR_ROOM_PLACEMENTS:
		var instance := _instantiate_prop(placement["id"], placement["name"], placement["pos"], float(placement["rot_y"]))
		if instance == null:
			return false
		instance.set_meta("room_id", placement["room"])
		instance.set_meta("placement_group", placement["group"])
		props_root.add_child(instance)

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

func _assign_owned_level_nodes(scene: Node) -> void:
	for target_path in [
		"LevelRoot/Geometry",
		"LevelRoot/Areas",
		"LevelRoot/Portals",
		"LevelRoot/Markers",
		"LevelRoot/Lights",
		"LevelRoot/Props",
	]:
		var target := scene.get_node_or_null(target_path)
		if target != null:
			_assign_owner_recursive(target, scene)

func _instantiate_prop(prop_id: String, node_name: String, position: Vector3, yaw: float) -> Node3D:
	if not _prop_by_id.has(prop_id):
		_fail("Unknown prop id %s." % prop_id)
		return null
	var prop: Dictionary = _prop_by_id[prop_id]
	var packed := load(_prop_scene_path(prop)) as PackedScene
	if packed == null:
		_fail("Missing wrapper scene for %s." % prop_id)
		return null
	var instance := packed.instantiate() as Node3D
	if instance == null:
		_fail("Failed to instantiate wrapper scene for %s." % prop_id)
		return null
	instance.name = node_name
	instance.position = position
	instance.rotation.y = yaw
	return instance

func _assign_owner_recursive(node: Node, owner_root: Node) -> void:
	node.owner = owner_root
	if not node.scene_file_path.is_empty():
		return
	for child in node.get_children():
		_assign_owner_recursive(child, owner_root)

func _fail(message: String) -> void:
	push_error("BUILD_NATURAL_PROP_SCENES FAIL: %s" % message)
	quit(1)
