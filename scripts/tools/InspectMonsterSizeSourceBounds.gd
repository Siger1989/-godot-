extends SceneTree

const SOURCE_SCENE_PATH := "res://scenes/mvp/FourRoomMVP.tscn"
const TARGETS := [
	"MonsterRoot/Monster",
	"MonsterRoot/Monster_Red_KeyBearer_MVP",
	"MonsterRoot/NightmareCreature_A_MVP",
]

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load(SOURCE_SCENE_PATH) as PackedScene
	if packed == null:
		push_error("missing source scene")
		quit(1)
		return
	var scene := packed.instantiate() as Node3D
	root.add_child(scene)
	await process_frame
	for target_path in TARGETS:
		var node := scene.get_node_or_null(NodePath(target_path)) as Node3D
		if node == null:
			print("%s missing" % target_path)
			continue
		var meshes: Array[MeshInstance3D] = []
		_collect_meshes(node, meshes)
		var bounds := _combined_bounds(meshes)
		print("%s pos=%s scale=%s meshes=%d bounds_pos=%s bounds_size=%s" % [
			target_path,
			node.global_position,
			node.transform.basis.get_scale(),
			meshes.size(),
			bounds.position,
			bounds.size,
		])
	quit(0)

func _collect_meshes(node: Node, output: Array[MeshInstance3D]) -> void:
	var mesh := node as MeshInstance3D
	if mesh != null and mesh.mesh != null and mesh.visible:
		output.append(mesh)
	for child in node.get_children():
		_collect_meshes(child, output)

func _combined_bounds(meshes: Array[MeshInstance3D]) -> AABB:
	var has_bounds := false
	var combined := AABB()
	for mesh in meshes:
		var bounds := _aabb_to_global(mesh, mesh.get_aabb())
		if has_bounds:
			combined = combined.merge(bounds)
		else:
			combined = bounds
			has_bounds = true
	return combined

func _aabb_to_global(node: Node3D, local_aabb: AABB) -> AABB:
	var corners := [
		local_aabb.position,
		local_aabb.position + Vector3(local_aabb.size.x, 0.0, 0.0),
		local_aabb.position + Vector3(0.0, local_aabb.size.y, 0.0),
		local_aabb.position + Vector3(0.0, 0.0, local_aabb.size.z),
		local_aabb.position + Vector3(local_aabb.size.x, local_aabb.size.y, 0.0),
		local_aabb.position + Vector3(local_aabb.size.x, 0.0, local_aabb.size.z),
		local_aabb.position + Vector3(0.0, local_aabb.size.y, local_aabb.size.z),
		local_aabb.position + local_aabb.size,
	]
	var converted := AABB(node.global_transform * corners[0], Vector3.ZERO)
	for index in range(1, corners.size()):
		converted = converted.expand(node.global_transform * corners[index])
	return converted
