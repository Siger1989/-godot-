extends SceneTree

const ASSET_ID := "HideLocker_A"
const GLB_PATH := "res://assets/backrooms/props/furniture/HideLocker_A.glb"
const SCENE_PATH := "res://assets/backrooms/props/furniture/HideLocker_A.tscn"
const SHOWCASE_SCENE_PATH := "res://scenes/tests/Test_HideableLockerShowcase.tscn"
const FOUR_ROOM_SCENE_PATH := "res://scenes/mvp/FourRoomMVP.tscn"
const COMPONENT_SCRIPT_PATH := "res://scripts/scene/HideableCabinetComponent.gd"
const FOUR_ROOM_PLACEMENT_NAME := "RoomC_HideLocker_A"
const FOUR_ROOM_PLACEMENT_POSITION := Vector3(8.58, 0.0, 7.32)
const FOUR_ROOM_PLACEMENT_YAW := -PI * 0.5

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	if not _create_wrapper_scene():
		return
	if not _create_showcase_scene():
		return
	if not await _place_locker_in_four_room():
		return
	print("BUILD_HIDEABLE_LOCKER_SCENE PASS asset=%s wrapper=%s showcase=%s four_room=%s" % [ASSET_ID, SCENE_PATH, SHOWCASE_SCENE_PATH, FOUR_ROOM_PLACEMENT_NAME])
	quit(0)

func _create_wrapper_scene() -> bool:
	var packed_glb := load(GLB_PATH) as PackedScene
	if packed_glb == null:
		_fail("Missing GLB PackedScene: %s." % GLB_PATH)
		return false
	var component_script := load(COMPONENT_SCRIPT_PATH) as Script
	if component_script == null:
		_fail("Missing component script: %s." % COMPONENT_SCRIPT_PATH)
		return false

	var root := Node3D.new()
	root.name = ASSET_ID
	root.set_script(component_script)
	root.add_to_group("interactive_hideable", true)
	root.set_meta("natural_prop_id", ASSET_ID)
	root.set_meta("natural_prop_category", "furniture")
	root.set_meta("hideable_prop_id", ASSET_ID)
	root.set_meta("blocks_path", true)
	root.set("front_direction_local", Vector3(0.0, 0.0, 1.0))
	root.set("peek_fov", 34.0)
	root.set("peek_yaw_limit_degrees", 18.0)
	root.set("peek_pitch_limit_degrees", 8.0)

	var model := packed_glb.instantiate() as Node3D
	if model == null:
		_fail("Failed to instantiate GLB.")
		return false
	model.name = "Model"
	root.add_child(model)
	model.owner = root

	var body := StaticBody3D.new()
	body.name = "CollisionBody"
	var shape_node := CollisionShape3D.new()
	shape_node.name = "Collision"
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.80, 1.95, 0.58)
	shape_node.shape = shape
	shape_node.position = Vector3(0.0, 0.975, 0.0)
	body.add_child(shape_node)
	root.add_child(body)
	body.owner = root
	shape_node.owner = root

	var stand_point := Marker3D.new()
	stand_point.name = "HideStandPoint"
	stand_point.position = Vector3(0.0, 0.0, 0.02)
	root.add_child(stand_point)
	stand_point.owner = root

	var camera_anchor := Marker3D.new()
	camera_anchor.name = "HideCameraAnchor"
	camera_anchor.position = Vector3(0.0, 1.58, 0.205)
	root.add_child(camera_anchor)
	camera_anchor.owner = root

	var exit_marker := Marker3D.new()
	exit_marker.name = "ExitMarker"
	exit_marker.position = Vector3(0.0, 0.0, 1.05)
	root.add_child(exit_marker)
	exit_marker.owner = root

	var interaction_marker := Marker3D.new()
	interaction_marker.name = "InteractionPoint"
	interaction_marker.position = Vector3(0.0, 0.85, 0.72)
	root.add_child(interaction_marker)
	interaction_marker.owner = root

	var packed_scene := PackedScene.new()
	var pack_result := packed_scene.pack(root)
	if pack_result != OK:
		_fail("Pack wrapper failed code=%d." % pack_result)
		return false
	var save_result := ResourceSaver.save(packed_scene, SCENE_PATH)
	if save_result != OK:
		_fail("Save wrapper failed code=%d." % save_result)
		return false
	root.free()
	return true

func _create_showcase_scene() -> bool:
	var packed_locker := load(SCENE_PATH) as PackedScene
	if packed_locker == null:
		_fail("Missing wrapper scene before showcase.")
		return false
	var scene := Node3D.new()
	scene.name = "Test_HideableLockerShowcase"
	_create_environment(scene)

	var props_root := Node3D.new()
	props_root.name = "HideableProps"
	scene.add_child(props_root)
	props_root.owner = scene

	var locker := packed_locker.instantiate() as Node3D
	if locker == null:
		_fail("Failed to instantiate wrapper for showcase.")
		return false
	locker.name = "HideLocker_A_Showcase"
	locker.position = Vector3(0.0, 0.0, 0.0)
	props_root.add_child(locker)
	_assign_owner_recursive(locker, scene)

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

func _place_locker_in_four_room() -> bool:
	var packed := load(FOUR_ROOM_SCENE_PATH) as PackedScene
	if packed == null:
		_fail("Missing FourRoomMVP scene.")
		return false
	var packed_locker := load(SCENE_PATH) as PackedScene
	if packed_locker == null:
		_fail("Missing locker wrapper scene.")
		return false

	var scene := packed.instantiate() as Node3D
	if scene == null:
		_fail("Failed to instantiate FourRoomMVP.")
		return false
	scene.set("build_on_ready", false)
	root.add_child(scene)
	current_scene = scene
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
		var prop := child as Node3D
		if prop == null:
			continue
		if prop.name == FOUR_ROOM_PLACEMENT_NAME or String(prop.get_meta("hideable_prop_id", "")) == ASSET_ID:
			child.free()
	await process_frame

	var locker := packed_locker.instantiate() as Node3D
	if locker == null:
		_fail("Failed to instantiate locker wrapper for FourRoomMVP.")
		return false
	locker.name = FOUR_ROOM_PLACEMENT_NAME
	locker.position = FOUR_ROOM_PLACEMENT_POSITION
	locker.rotation.y = FOUR_ROOM_PLACEMENT_YAW
	locker.set_meta("room_id", "Room_C")
	locker.set_meta("placement_group", "hideable_wall")
	locker.set_meta("mvp_placement", true)
	props_root.add_child(locker)
	_assign_owner_recursive(locker, scene)

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

func _create_environment(scene: Node3D) -> void:
	var world := WorldEnvironment.new()
	world.name = "WorldEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.020, 0.019, 0.016)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(1.0, 0.91, 0.72)
	environment.ambient_light_energy = 0.24
	world.environment = environment
	scene.add_child(world)
	world.owner = scene

	var floor := MeshInstance3D.new()
	floor.name = "ScaleCheckFloor"
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(4.2, 0.04, 4.0)
	floor.mesh = floor_mesh
	floor.position = Vector3(0.0, -0.02, 0.90)
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.52, 0.48, 0.35)
	floor_material.roughness = 0.92
	floor.material_override = floor_material
	scene.add_child(floor)
	floor.owner = scene

	var wall := MeshInstance3D.new()
	wall.name = "BackroomsWallBackdrop"
	var wall_mesh := BoxMesh.new()
	wall_mesh.size = Vector3(4.2, 2.55, 0.08)
	wall.mesh = wall_mesh
	wall.position = Vector3(0.0, 1.275, -0.365)
	var wall_material := StandardMaterial3D.new()
	wall_material.albedo_color = Color(0.55, 0.47, 0.26)
	wall_material.roughness = 0.94
	wall.material_override = wall_material
	scene.add_child(wall)
	wall.owner = scene

	var light := OmniLight3D.new()
	light.name = "SoftLockerReviewLight"
	light.position = Vector3(0.0, 2.25, 1.25)
	light.light_color = Color(1.0, 0.86, 0.62)
	light.light_energy = 1.6
	light.omni_range = 4.0
	scene.add_child(light)
	light.owner = scene

	var camera := Camera3D.new()
	camera.name = "ReviewCamera"
	camera.fov = 48.0
	camera.look_at_from_position(Vector3(1.35, 1.38, 3.15), Vector3(0.0, 0.98, 0.06), Vector3.UP)
	camera.current = true
	scene.add_child(camera)
	camera.owner = scene

func _assign_owner_recursive(node: Node, owner_root: Node) -> void:
	node.owner = owner_root
	if not node.scene_file_path.is_empty():
		return
	for child in node.get_children():
		_assign_owner_recursive(child, owner_root)

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

func _fail(message: String) -> void:
	push_error("BUILD_HIDEABLE_LOCKER_SCENE FAIL: %s" % message)
	quit(1)
