extends SceneTree

const SCENE_PATH := "res://scenes/mvp/FourRoomMVP.tscn"
const MIN_CEILING_LIGHT_ENERGY := 1.0
const MIN_CEILING_LIGHT_RANGE := 5.6
const MAX_CEILING_LIGHT_ATTENUATION := 1.00
const MAX_CEILING_LIGHT_SHADOW_BIAS := 0.025
const MAX_CEILING_LIGHT_SHADOW_NORMAL_BIAS := 0.45
const MIN_CEILING_LIGHT_SHADOW_OPACITY := 0.95
const MIN_WORLD_AMBIENT_ENERGY := 0.05
const MAX_WORLD_AMBIENT_ENERGY := 0.09
const STATIC_GEOMETRY_LAYER := 1 << 0
const ACTOR_LIGHT_LAYER := 1 << 8
const STATIC_LIGHT_MASK := STATIC_GEOMETRY_LAYER | ACTOR_LIGHT_LAYER
const GEOMETRY_ROOT_PATH := "LevelRoot/Geometry"
const ROOM_LIGHT_NAMES := [
	"CeilingLight_Room_A",
	"CeilingLight_Room_B",
	"CeilingLight_Room_C",
	"CeilingLight_Room_D",
]
const FLOOR_VISUAL_NAMES := [
	"Floor_Room_A",
	"Floor_Room_B",
	"Floor_Room_C",
	"Floor_Room_D",
]
const CEILING_MESH_PATHS := [
	"Ceiling_Room_A/Mesh",
	"Ceiling_Room_B/Mesh",
	"Ceiling_Room_C/Mesh",
	"Ceiling_Room_D/Mesh",
]
const PORTAL_VISUAL_PATHS := [
	"WallOpening_P_AB/Mesh",
	"WallOpening_P_BC/Mesh",
	"WallOpening_P_CD/Mesh",
	"WallOpening_P_DA/Mesh",
	"DoorFrame_P_AB",
	"DoorFrame_P_BC",
	"DoorFrame_P_CD",
	"DoorFrame_P_DA",
]

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene_resource := load(SCENE_PATH) as PackedScene
	if scene_resource == null:
		_fail("Failed to load %s." % SCENE_PATH)
		return

	var baked_scene := scene_resource.instantiate() as Node3D
	baked_scene.set("build_on_ready", false)
	root.add_child(baked_scene)
	await process_frame
	await physics_frame
	if not _validate_scene(baked_scene, "baked"):
		return
	baked_scene.queue_free()
	await process_frame

	var runtime_scene := scene_resource.instantiate() as Node3D
	root.add_child(runtime_scene)
	await process_frame
	await physics_frame
	await process_frame
	if not _validate_scene(runtime_scene, "runtime"):
		return

	print("SCENE_SHADOW_VALIDATION PASS baked=true runtime=true")
	quit(0)

func _validate_scene(scene: Node3D, label: String) -> bool:
	var lights_parent := scene.get_node_or_null("LevelRoot/Lights")
	if lights_parent == null:
		_fail("%s scene is missing LevelRoot/Lights." % label)
		return false

	if not _validate_world_environment(lights_parent, label):
		return false

	var lights: Array[OmniLight3D] = []
	_collect_omni_lights(lights_parent, lights)
	if lights.size() != 4:
		_fail("%s scene expected 4 ceiling OmniLight3D nodes, found %d." % [label, lights.size()])
		return false
	for light in lights:
		if not light.shadow_enabled:
			_fail("%s scene light %s has shadows disabled." % [label, light.name])
			return false
		if light.light_energy < MIN_CEILING_LIGHT_ENERGY:
			_fail("%s scene light %s is too weak for readable room projection: %.3f." % [label, light.name, light.light_energy])
			return false
		if light.omni_range < MIN_CEILING_LIGHT_RANGE:
			_fail("%s scene light %s range is too small for full-room coverage: %.3f." % [label, light.name, light.omni_range])
			return false
		if light.omni_attenuation > MAX_CEILING_LIGHT_ATTENUATION:
			_fail("%s scene light %s attenuation falls off too fast for full-room coverage: %.3f." % [label, light.name, light.omni_attenuation])
			return false
		if light.shadow_bias > MAX_CEILING_LIGHT_SHADOW_BIAS:
			_fail("%s scene light %s shadow bias is too high for contact shadows: %.3f." % [label, light.name, light.shadow_bias])
			return false
		if light.shadow_normal_bias > MAX_CEILING_LIGHT_SHADOW_NORMAL_BIAS:
			_fail("%s scene light %s shadow normal bias is too high for contact shadows: %.3f." % [label, light.name, light.shadow_normal_bias])
			return false
		if light.shadow_opacity < MIN_CEILING_LIGHT_SHADOW_OPACITY:
			_fail("%s scene light %s shadow opacity is too low: %.3f." % [label, light.name, light.shadow_opacity])
			return false
		if not ROOM_LIGHT_NAMES.has(String(light.name)):
			_fail("%s scene has unexpected ceiling light name: %s." % [label, light.name])
			return false
		if light.light_cull_mask != STATIC_LIGHT_MASK:
			_fail("%s scene light %s has wrong light_cull_mask: %d expected %d." % [label, light.name, light.light_cull_mask, STATIC_LIGHT_MASK])
			return false
		if light.shadow_caster_mask != STATIC_LIGHT_MASK:
			_fail("%s scene light %s has wrong shadow_caster_mask: %d expected %d." % [label, light.name, light.shadow_caster_mask, STATIC_LIGHT_MASK])
			return false

	var panels: Array[MeshInstance3D] = []
	_collect_group_meshes(scene, "ceiling_light_panel", panels)
	if panels.size() != 4:
		_fail("%s scene expected 4 ceiling light panels, found %d." % [label, panels.size()])
		return false
	for panel in panels:
		if panel.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			_fail("%s scene panel %s should not cast its own light shadow." % [label, panel.name])
			return false
		if not _validate_panel_layer(panel, label):
			return false

	if not _validate_static_light_layers(scene, label):
		return false

	if not _validate_actor_meshes(scene, "PlayerRoot/Player/ModelRoot", "player", label):
		return false
	if not _validate_actor_meshes(scene, "MonsterRoot/Monster/ModelRoot", "monster", label):
		return false
	return true

func _validate_world_environment(lights_parent: Node, label: String) -> bool:
	var environments: Array[WorldEnvironment] = []
	_collect_world_environments(lights_parent, environments)
	if environments.size() != 1:
		_fail("%s scene expected one WorldEnvironment under LevelRoot/Lights, found %d." % [label, environments.size()])
		return false
	var world_environment := environments[0]
	if world_environment.environment == null:
		_fail("%s scene WorldEnvironment has no Environment resource." % label)
		return false
	var environment := world_environment.environment
	if environment.ambient_light_source != Environment.AMBIENT_SOURCE_COLOR:
		_fail("%s scene WorldEnvironment must use color ambient source." % label)
		return false
	if environment.ambient_light_energy < MIN_WORLD_AMBIENT_ENERGY or environment.ambient_light_energy > MAX_WORLD_AMBIENT_ENERGY:
		_fail("%s scene WorldEnvironment ambient energy is outside visual-unification range: %.3f." % [label, environment.ambient_light_energy])
		return false
	if environment.ambient_light_sky_contribution != 0.0:
		_fail("%s scene WorldEnvironment ambient sky contribution must stay disabled." % label)
		return false
	return true

func _validate_actor_meshes(scene: Node3D, node_path: String, actor_name: String, label: String) -> bool:
	var actor_root := scene.get_node_or_null(NodePath(node_path))
	if actor_root == null:
		_fail("%s scene is missing %s model root." % [label, actor_name])
		return false
	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(actor_root, meshes)
	if meshes.is_empty():
		_fail("%s scene %s has no MeshInstance3D shadow caster." % [label, actor_name])
		return false
	for mesh_instance in meshes:
		if mesh_instance.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			_fail("%s scene %s mesh %s has cast_shadow disabled." % [label, actor_name, mesh_instance.name])
			return false
		if mesh_instance.layers != ACTOR_LIGHT_LAYER:
			_fail("%s scene %s mesh %s must use actor light layer %d, got %d." % [label, actor_name, mesh_instance.name, ACTOR_LIGHT_LAYER, mesh_instance.layers])
			return false
	return true

func _validate_panel_layer(panel: MeshInstance3D, label: String) -> bool:
	var expected_names := [
		"CeilingLightPanel_Room_A",
		"CeilingLightPanel_Room_B",
		"CeilingLightPanel_Room_C",
		"CeilingLightPanel_Room_D",
	]
	if not expected_names.has(String(panel.name)):
		_fail("%s scene has unexpected ceiling light panel name: %s." % [label, panel.name])
		return false
	if panel.layers != STATIC_GEOMETRY_LAYER:
		_fail("%s scene panel %s has wrong light layer: %d expected %d." % [label, panel.name, panel.layers, STATIC_GEOMETRY_LAYER])
		return false
	return true

func _validate_static_light_layers(scene: Node3D, label: String) -> bool:
	for node_name in FLOOR_VISUAL_NAMES:
		var mesh := scene.get_node_or_null("%s/%s" % [GEOMETRY_ROOT_PATH, node_name]) as MeshInstance3D
		if mesh == null:
			_fail("%s scene is missing floor visual %s." % [label, node_name])
			return false
		if mesh.layers != STATIC_GEOMETRY_LAYER:
			_fail("%s scene floor %s has wrong light layer: %d expected %d." % [label, node_name, mesh.layers, STATIC_GEOMETRY_LAYER])
			return false
	for node_path in CEILING_MESH_PATHS:
		var ceiling_mesh := scene.get_node_or_null("%s/%s" % [GEOMETRY_ROOT_PATH, node_path]) as MeshInstance3D
		if ceiling_mesh == null:
			_fail("%s scene is missing ceiling mesh %s." % [label, node_path])
			return false
		if ceiling_mesh.layers != STATIC_GEOMETRY_LAYER:
			_fail("%s scene ceiling %s has wrong light layer: %d expected %d." % [label, node_path, ceiling_mesh.layers, STATIC_GEOMETRY_LAYER])
			return false
	for node_path in PORTAL_VISUAL_PATHS:
		var portal_mesh := scene.get_node_or_null("%s/%s" % [GEOMETRY_ROOT_PATH, node_path]) as MeshInstance3D
		if portal_mesh == null:
			_fail("%s scene is missing portal visual %s." % [label, node_path])
			return false
		if portal_mesh.layers != STATIC_GEOMETRY_LAYER:
			_fail("%s scene portal visual %s has wrong light layer: %d expected %d." % [label, node_path, portal_mesh.layers, STATIC_GEOMETRY_LAYER])
			return false
	return true

func _collect_omni_lights(node: Node, output: Array[OmniLight3D]) -> void:
	var light := node as OmniLight3D
	if light != null:
		output.append(light)
	for child in node.get_children():
		_collect_omni_lights(child, output)

func _collect_world_environments(node: Node, output: Array[WorldEnvironment]) -> void:
	var world_environment := node as WorldEnvironment
	if world_environment != null:
		output.append(world_environment)
	for child in node.get_children():
		_collect_world_environments(child, output)

func _collect_group_meshes(node: Node, group_name: StringName, output: Array[MeshInstance3D]) -> void:
	var mesh_instance := node as MeshInstance3D
	if mesh_instance != null and mesh_instance.is_in_group(group_name):
		output.append(mesh_instance)
	for child in node.get_children():
		_collect_group_meshes(child, group_name, output)

func _collect_meshes(node: Node, output: Array[MeshInstance3D]) -> void:
	var mesh_instance := node as MeshInstance3D
	if mesh_instance != null:
		output.append(mesh_instance)
	for child in node.get_children():
		_collect_meshes(child, output)

func _fail(message: String) -> void:
	push_error("SCENE_SHADOW_VALIDATION FAIL: %s" % message)
	quit(1)
