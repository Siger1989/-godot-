extends SceneTree

const SCENE_PATH := "res://scenes/mvp/FourRoomMVP.tscn"
const SEAM_MATERIAL_PATH := "res://materials/backrooms_seam_grime.tres"
const SEAM_TEXTURE_PATH := "res://materials/textures/backrooms_seam_grime_albedo.png"

const FORBIDDEN_GROUPS := [
	&"seam_grime",
	&"wall_seam_grime",
	&"ceiling_seam_grime",
	&"door_seam_grime",
]

const FORBIDDEN_NODE_NAMES := [
	"WallSeamGrime",
	"CeilingSeamGrime",
	"DoorSeamGrime",
	"DoorFrameSeamGrime",
]

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene_resource := load(SCENE_PATH) as PackedScene
	if scene_resource == null:
		_fail("Failed to load %s." % SCENE_PATH)
		return

	var scene := scene_resource.instantiate() as Node3D
	scene.set("build_on_ready", false)
	root.add_child(scene)
	current_scene = scene
	await process_frame

	var builder := scene.get_node_or_null("Systems/SceneBuilder")
	if builder == null or not builder.has_method("build"):
		_fail("SceneBuilder is missing.")
		return
	builder.call("build")
	await process_frame
	await physics_frame
	await process_frame

	for group_name in FORBIDDEN_GROUPS:
		var nodes := get_nodes_in_group(group_name)
		if not nodes.is_empty():
			_fail("Removed seam/detail group still has %d nodes: %s." % [nodes.size(), group_name])
			return

	var forbidden_node := _find_forbidden_node(scene)
	if forbidden_node != null:
		_fail("Removed seam/detail node still exists: %s." % forbidden_node.get_path())
		return

	if ResourceLoader.exists(SEAM_MATERIAL_PATH):
		_fail("Unused seam grime material should be removed: %s." % SEAM_MATERIAL_PATH)
		return
	if ResourceLoader.exists(SEAM_TEXTURE_PATH):
		_fail("Unused seam grime texture should be removed: %s." % SEAM_TEXTURE_PATH)
		return

	print("SEAM_GRIME_REMOVAL_VALIDATION PASS")
	quit(0)

func _find_forbidden_node(node: Node) -> Node:
	if FORBIDDEN_NODE_NAMES.has(node.name):
		return node
	for child in node.get_children():
		var found := _find_forbidden_node(child)
		if found != null:
			return found
	return null

func _fail(message: String) -> void:
	push_error("SEAM_GRIME_REMOVAL_VALIDATION FAIL: %s" % message)
	quit(1)
