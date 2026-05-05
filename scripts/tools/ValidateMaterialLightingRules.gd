extends SceneTree

const SCENE_PATH := "res://scenes/mvp/FourRoomMVP.tscn"
const WALL_MATERIAL_PATH := "res://materials/backrooms_wall.tres"
const FLOOR_MATERIAL_PATH := "res://materials/backrooms_floor.tres"
const DOOR_FRAME_MATERIAL_PATH := "res://materials/backrooms_door_frame.tres"
const CEILING_MATERIAL_PATH := "res://materials/backrooms_ceiling.tres"
const GEOMETRY_ROOT_PATH := "LevelRoot/Geometry"
const ContactShadowMaterial = preload("res://scripts/visual/ContactShadowMaterial.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var wall_material := _load_material(WALL_MATERIAL_PATH)
	var floor_material := _load_material(FLOOR_MATERIAL_PATH)
	var door_frame_material := _load_material(DOOR_FRAME_MATERIAL_PATH)
	var ceiling_material := _load_material(CEILING_MATERIAL_PATH)
	if wall_material == null or floor_material == null or door_frame_material == null or ceiling_material == null:
		return

	_validate_material(wall_material, "wall", true, 0.26)
	_validate_material(floor_material, "floor", true, 0.32)
	_validate_material(door_frame_material, "door frame", true, 0.28)
	_validate_material(ceiling_material, "ceiling", false, 0.0)
	_validate_floor_material(floor_material)

	var scene_resource := load(SCENE_PATH) as PackedScene
	if scene_resource == null:
		_fail("Failed to load %s." % SCENE_PATH)
		return

	var scene := scene_resource.instantiate() as Node3D
	scene.set("build_on_ready", false)
	root.add_child(scene)
	current_scene = scene
	await process_frame
	_validate_scene_materials(scene, wall_material, floor_material, door_frame_material, ceiling_material, "baked")

	var builder := scene.get_node_or_null("Systems/SceneBuilder")
	if builder == null or not builder.has_method("build"):
		_fail("SceneBuilder is missing.")
		return
	builder.call("build")
	await process_frame
	_validate_scene_materials(scene, wall_material, floor_material, door_frame_material, ceiling_material, "runtime")

	print("MATERIAL_LIGHTING_RULES_VALIDATION PASS")
	quit(0)

func _load_material(path: String) -> StandardMaterial3D:
	var material := load(path) as StandardMaterial3D
	if material == null:
		_fail("Failed to load StandardMaterial3D: %s." % path)
	return material

func _validate_material(material: StandardMaterial3D, label: String, expects_normal_map: bool, max_normal_scale: float) -> void:
	if material.cull_mode != BaseMaterial3D.CULL_BACK:
		_fail("%s material must use backface culling so walls share one visible-side lighting rule." % label)
		return
	if material.diffuse_mode != BaseMaterial3D.DIFFUSE_LAMBERT_WRAP:
		_fail("%s material must use Lambert Wrap diffuse lighting." % label)
		return
	if expects_normal_map:
		if not material.normal_enabled:
			_fail("%s material must keep its normal map enabled." % label)
			return
		if material.normal_scale > max_normal_scale:
			_fail("%s material normal scale is too strong for unified Mobile lighting: %.3f." % [label, material.normal_scale])
			return

func _validate_floor_material(material: StandardMaterial3D) -> void:
	if material.albedo_color.r < 1.05 or material.albedo_color.g < 1.02 or material.albedo_color.b < 0.96:
		_fail("floor material albedo multiplier is too dark for readable floor projection: %s." % material.albedo_color)
		return
	if absf(material.uv1_scale.x - material.uv1_scale.y) > 0.001:
		_fail("floor material UV scale must be square/uniform: %s." % material.uv1_scale)
		return
	if absf(material.uv1_scale.x - 12.0) > 0.001:
		_fail("floor material UV scale must match the current world UV rule: %s." % material.uv1_scale)
		return
	if material.uv1_offset.length_squared() > 0.000001:
		_fail("floor material UV offset must be zero to avoid shifted tile seams: %s." % material.uv1_offset)
		return

func _validate_scene_materials(
	scene: Node,
	wall_material: Material,
	floor_material: Material,
	door_frame_material: Material,
	ceiling_material: Material,
	pass_name: String
) -> void:
	var wall_meshes := 0
	var floor_meshes := 0
	var door_frame_meshes := 0
	var ceiling_meshes := 0
	var geometry_root := scene.get_node_or_null(GEOMETRY_ROOT_PATH)
	if geometry_root == null:
		_fail("%s scene is missing %s." % [pass_name, GEOMETRY_ROOT_PATH])
		return

	for mesh in _collect_mesh_instances(geometry_root):
		var mesh_instance := mesh as MeshInstance3D
		var owner := mesh_instance.get_parent()
		var owner_name := owner.name if owner != null else mesh_instance.name
		if mesh_instance.is_in_group("floor_visual"):
			floor_meshes += 1
			_expect_override(mesh_instance, floor_material, "%s floor" % pass_name)
		elif mesh_instance.is_in_group("door_frame"):
			door_frame_meshes += 1
			_expect_override(mesh_instance, door_frame_material, "%s door frame" % pass_name)
		elif String(owner_name).begins_with("Wall") or String(mesh_instance.name).begins_with("Wall"):
			wall_meshes += 1
			_expect_override(mesh_instance, wall_material, "%s wall" % pass_name)
		elif String(owner_name).begins_with("Ceiling") or String(mesh_instance.name).begins_with("Ceiling"):
			if not mesh_instance.is_in_group("ceiling_light_panel"):
				ceiling_meshes += 1
				_expect_override(mesh_instance, ceiling_material, "%s ceiling" % pass_name)

	if wall_meshes < 20:
		_fail("%s scene found too few wall meshes: %d." % [pass_name, wall_meshes])
		return
	if floor_meshes != 4:
		_fail("%s scene expected 4 floor visuals, found %d." % [pass_name, floor_meshes])
		return
	if door_frame_meshes != 4:
		_fail("%s scene expected 4 door frames, found %d." % [pass_name, door_frame_meshes])
		return
	if ceiling_meshes != 4:
		_fail("%s scene expected 4 ceilings, found %d." % [pass_name, ceiling_meshes])
		return

func _collect_mesh_instances(root_node: Node) -> Array[MeshInstance3D]:
	var output: Array[MeshInstance3D] = []
	_collect_mesh_instances_recursive(root_node, output)
	return output

func _collect_mesh_instances_recursive(node: Node, output: Array[MeshInstance3D]) -> void:
	var mesh_instance := node as MeshInstance3D
	if mesh_instance != null:
		output.append(mesh_instance)
	for child in node.get_children():
		_collect_mesh_instances_recursive(child, output)

func _expect_override(mesh_instance: MeshInstance3D, expected_material: Material, label: String) -> void:
	if mesh_instance.material_override != expected_material and not ContactShadowMaterial.is_contact_material(mesh_instance.material_override):
		_fail("%s mesh uses a mismatched material override: %s." % [label, mesh_instance.get_path()])

func _fail(message: String) -> void:
	push_error("MATERIAL_LIGHTING_RULES_VALIDATION FAIL: %s" % message)
	quit(1)
