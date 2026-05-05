extends SceneTree

const SCENE_PATH := "res://scenes/debug/BaseResourceGallery.tscn"
const GeneratedMeshRules = preload("res://scripts/scene/GeneratedMeshRules.gd")
const WallOpeningBodyScript = preload("res://scripts/scene/WallOpeningBody.gd")
const DoorFrameVisualScript = preload("res://scripts/scene/DoorFrameVisual.gd")
const DebugMaterial = preload("res://materials/debug/uv_direction_debug.tres")
const WallMaterial = preload("res://materials/backrooms_wall.tres")
const FloorMaterial = preload("res://materials/backrooms_floor.tres")
const CeilingMaterial = preload("res://materials/backrooms_ceiling.tres")
const DoorFrameMaterial = preload("res://materials/backrooms_door_frame.tres")

const WALL_HEIGHT := 2.55
const WALL_THICKNESS := 0.2
const WALL_SPAN := 2.4
const WALL_OPENING_SPAN := 3.2
const DOOR_WIDTH := 1.15
const DOOR_HEIGHT := 2.16

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := Node3D.new()
	scene.name = "BaseResourceGallery"
	root.add_child(scene)
	current_scene = scene

	_create_world(scene)
	_create_lighting(scene)
	_create_camera(scene)

	var debug_root := Node3D.new()
	debug_root.name = "UV_Debug_Row"
	scene.add_child(debug_root)

	var style_root := Node3D.new()
	style_root.name = "Backrooms_Material_Row"
	style_root.position = Vector3(0.0, 0.0, -3.2)
	scene.add_child(style_root)

	var x := -13.5
	var spacing := 2.7
	_add_wall_box(debug_root, "Wall_Visible_PosZ", Vector3(x, WALL_HEIGHT * 0.5, 0.0), 0.0, DebugMaterial)
	_add_label(debug_root, "Wall +Z", Vector3(x, WALL_HEIGHT + 0.45, 0.0))
	x += spacing
	_add_wall_box(debug_root, "Wall_Visible_NegZ", Vector3(x, WALL_HEIGHT * 0.5, 0.0), PI, DebugMaterial)
	_add_label(debug_root, "Wall -Z", Vector3(x, WALL_HEIGHT + 0.45, 0.0))
	x += spacing
	_add_wall_box(debug_root, "Wall_Visible_PosX", Vector3(x, WALL_HEIGHT * 0.5, 0.0), -PI * 0.5, DebugMaterial)
	_add_label(debug_root, "Wall +X", Vector3(x, WALL_HEIGHT + 0.45, 0.0))
	x += spacing
	_add_wall_box(debug_root, "Wall_Visible_NegX", Vector3(x, WALL_HEIGHT * 0.5, 0.0), PI * 0.5, DebugMaterial)
	_add_label(debug_root, "Wall -X", Vector3(x, WALL_HEIGHT + 0.45, 0.0))
	x += spacing
	_add_wall_joint(debug_root, "WallJoint_Box", Vector3(x, WALL_HEIGHT * 0.5, 0.0), DebugMaterial)
	_add_label(debug_root, "Joint Box", Vector3(x, WALL_HEIGHT + 0.45, 0.0))
	x += spacing
	_add_opening(debug_root, "WallOpening_Local_Z", Vector3(x, 0.0, 0.0), "z", DebugMaterial)
	_add_label(debug_root, "Opening Z", Vector3(x, WALL_HEIGHT + 0.45, 0.0))
	x += spacing
	_add_opening(debug_root, "WallOpening_Rotated_X", Vector3(x, 0.0, 0.0), "x", DebugMaterial)
	_add_label(debug_root, "Opening X", Vector3(x, WALL_HEIGHT + 0.45, 0.0))
	x += spacing
	_add_door_frame(debug_root, "DoorFrame_Z", Vector3(x, 0.0, 0.0), "z", DebugMaterial)
	_add_label(debug_root, "Frame Z", Vector3(x, WALL_HEIGHT + 0.45, 0.0))
	x += spacing
	_add_door_frame(debug_root, "DoorFrame_X", Vector3(x, 0.0, 0.0), "x", DebugMaterial)
	_add_label(debug_root, "Frame X", Vector3(x, WALL_HEIGHT + 0.45, 0.0))
	x += spacing
	_add_floor_panel(debug_root, "Floor_Panel", Vector3(x, 0.0, 0.0), DebugMaterial)
	_add_label(debug_root, "Floor", Vector3(x, WALL_HEIGHT + 0.45, 0.0))
	x += spacing
	_add_ceiling_panel(debug_root, "Ceiling_Panel", Vector3(x, WALL_HEIGHT * 0.5, 0.0), DebugMaterial)
	_add_label(debug_root, "Ceiling", Vector3(x, WALL_HEIGHT + 0.45, 0.0))

	_create_style_reference_row(style_root)

	await process_frame
	_assign_owner_recursive(scene, scene)

	var packed := PackedScene.new()
	var pack_result := packed.pack(scene)
	if pack_result != OK:
		_fail("PackedScene.pack failed with code %d." % pack_result)
		return
	var save_result := ResourceSaver.save(packed, SCENE_PATH)
	if save_result != OK:
		_fail("ResourceSaver.save failed with code %d." % save_result)
		return

	print("BASE_RESOURCE_GALLERY_BAKE PASS path=%s" % SCENE_PATH)
	quit(0)

func _create_world(scene: Node3D) -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.02, 0.02, 0.018)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.9, 0.84, 0.7)
	environment.ambient_light_energy = 0.45
	var world := WorldEnvironment.new()
	world.name = "WorldEnvironment"
	world.environment = environment
	scene.add_child(world)

func _create_lighting(scene: Node3D) -> void:
	var light := DirectionalLight3D.new()
	light.name = "DirectionalLight"
	light.rotation_degrees = Vector3(-45.0, -25.0, 0.0)
	light.light_energy = 1.1
	scene.add_child(light)

func _create_camera(scene: Node3D) -> void:
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.position = Vector3(0.0, 3.0, 8.0)
	camera.rotation_degrees = Vector3(-12.0, 0.0, 0.0)
	camera.fov = 58.0
	camera.current = true
	scene.add_child(camera)

func _create_style_reference_row(parent: Node3D) -> void:
	var x := -13.5
	var spacing := 2.7
	_add_wall_box(parent, "Wall_Style_PosZ", Vector3(x, WALL_HEIGHT * 0.5, 0.0), 0.0, WallMaterial)
	x += spacing
	_add_wall_box(parent, "Wall_Style_NegZ", Vector3(x, WALL_HEIGHT * 0.5, 0.0), PI, WallMaterial)
	x += spacing
	_add_wall_box(parent, "Wall_Style_PosX", Vector3(x, WALL_HEIGHT * 0.5, 0.0), -PI * 0.5, WallMaterial)
	x += spacing
	_add_wall_box(parent, "Wall_Style_NegX", Vector3(x, WALL_HEIGHT * 0.5, 0.0), PI * 0.5, WallMaterial)
	x += spacing
	_add_wall_joint(parent, "WallJoint_Style_Box", Vector3(x, WALL_HEIGHT * 0.5, 0.0), WallMaterial)
	x += spacing
	_add_opening(parent, "WallOpening_Style_Z", Vector3(x, 0.0, 0.0), "z", WallMaterial)
	x += spacing
	_add_opening(parent, "WallOpening_Style_X", Vector3(x, 0.0, 0.0), "x", WallMaterial)
	x += spacing
	_add_door_frame(parent, "DoorFrame_Style_Z", Vector3(x, 0.0, 0.0), "z", DoorFrameMaterial)
	x += spacing
	_add_door_frame(parent, "DoorFrame_Style_X", Vector3(x, 0.0, 0.0), "x", DoorFrameMaterial)
	x += spacing
	_add_floor_panel(parent, "Floor_Style_Panel", Vector3(x, 0.0, 0.0), FloorMaterial)
	x += spacing
	_add_ceiling_panel(parent, "Ceiling_Style_Panel", Vector3(x, WALL_HEIGHT * 0.5, 0.0), CeilingMaterial)

func _add_wall_box(parent: Node3D, node_name: String, position: Vector3, yaw: float, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = GeneratedMeshRules.build_box_mesh(Vector3(WALL_SPAN, WALL_HEIGHT, WALL_THICKNESS), material, 6.0, false, false)
	instance.material_override = material
	instance.position = position
	instance.rotation.y = yaw
	parent.add_child(instance)
	return instance

func _add_wall_joint(parent: Node3D, node_name: String, position: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = GeneratedMeshRules.build_box_mesh(Vector3(0.6, WALL_HEIGHT, 0.6), material, 6.0, false, false)
	instance.material_override = material
	instance.position = position
	instance.rotation.y = PI * 0.25
	parent.add_child(instance)
	return instance

func _add_opening(parent: Node3D, node_name: String, position: Vector3, span_axis: String, material: Material) -> StaticBody3D:
	var opening := StaticBody3D.new()
	opening.name = node_name
	opening.set_script(WallOpeningBodyScript)
	opening.span_axis = span_axis
	opening.span_length = WALL_OPENING_SPAN
	opening.opening_width = DOOR_WIDTH
	opening.opening_height = DOOR_HEIGHT
	opening.wall_height = WALL_HEIGHT
	opening.wall_thickness = WALL_THICKNESS
	opening.visual_material = material
	opening.position = position
	parent.add_child(opening)
	opening.call("_rebuild_body")
	return opening

func _add_door_frame(parent: Node3D, node_name: String, position: Vector3, span_axis: String, material: Material) -> MeshInstance3D:
	var frame := MeshInstance3D.new()
	frame.name = node_name
	frame.set_script(DoorFrameVisualScript)
	frame.span_axis = span_axis
	frame.opening_width = DOOR_WIDTH
	frame.outer_height = 2.18
	frame.trim_width = 0.15
	frame.frame_depth = 0.22
	frame.visual_material = material
	frame.position = position
	parent.add_child(frame)
	frame.call("_rebuild_mesh")
	return frame

func _add_floor_panel(parent: Node3D, node_name: String, position: Vector3, material: Material) -> MeshInstance3D:
	var half := Vector2(1.1, 1.1)
	var vertices := PackedVector3Array([
		Vector3(-half.x, 0.0, -half.y),
		Vector3(half.x, 0.0, -half.y),
		Vector3(half.x, 0.0, half.y),
		Vector3(-half.x, 0.0, -half.y),
		Vector3(half.x, 0.0, half.y),
		Vector3(-half.x, 0.0, half.y),
	])
	var normals := PackedVector3Array([Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP])
	var uvs := PackedVector2Array([
		Vector2(-half.x, -half.y) / 6.0,
		Vector2(half.x, -half.y) / 6.0,
		Vector2(half.x, half.y) / 6.0,
		Vector2(-half.x, -half.y) / 6.0,
		Vector2(half.x, half.y) / 6.0,
		Vector2(-half.x, half.y) / 6.0,
	])
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = GeneratedMeshRules.build_array_mesh(vertices, normals, uvs, material)
	instance.material_override = material
	instance.position = position
	parent.add_child(instance)
	return instance

func _add_ceiling_panel(parent: Node3D, node_name: String, position: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = GeneratedMeshRules.build_box_mesh(Vector3(2.2, 0.1, 2.2), material, 6.0, true, true)
	instance.material_override = material
	instance.position = position + Vector3(0.0, 1.15, 0.0)
	parent.add_child(instance)
	return instance

func _add_label(parent: Node3D, text: String, position: Vector3) -> void:
	var label := Label3D.new()
	label.name = "Label_%s" % text.replace(" ", "_").replace("+", "Pos").replace("-", "Neg")
	label.text = text
	label.font_size = 48
	label.pixel_size = 0.012
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(1.0, 0.92, 0.72)
	label.position = position
	parent.add_child(label)

func _assign_owner_recursive(node: Node, owner_root: Node) -> void:
	if node != owner_root:
		node.owner = owner_root
	for child in node.get_children():
		_assign_owner_recursive(child, owner_root)

func _fail(message: String) -> void:
	push_error("BASE_RESOURCE_GALLERY_BAKE FAIL: %s" % message)
	quit(1)
