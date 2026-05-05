extends SceneTree

const MODEL_PATH := "res://3D模型/guai1.glb"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var model_scene := load(MODEL_PATH) as PackedScene
	if model_scene == null:
		_fail("Failed to load %s" % MODEL_PATH)
		return

	var model := model_scene.instantiate()
	root.add_child(model)
	await process_frame

	var animation_players: Array[AnimationPlayer] = []
	_collect_animation_players(model, animation_players)
	var mesh_instances: Array[MeshInstance3D] = []
	_collect_mesh_instances(model, mesh_instances)
	var skeleton := _find_skeleton(model)

	print("MONSTER_MODEL_INSPECT PASS path=%s animation_players=%d meshes=%d skeleton=%s" % [
		MODEL_PATH,
		animation_players.size(),
		mesh_instances.size(),
		"yes" if skeleton != null else "no",
	])
	if skeleton != null:
		print("MONSTER_SKELETON bones=%d" % skeleton.get_bone_count())
	for animation_player in animation_players:
		var animation_names := animation_player.get_animation_list()
		print("MONSTER_ANIMATION_PLAYER path=%s animations=%d" % [model.get_path_to(animation_player), animation_names.size()])
		for animation_name in animation_names:
			var animation := animation_player.get_animation(animation_name)
			print("MONSTER_ANIMATION name=%s length=%.3f tracks=%d loop=%d" % [
				animation_name,
				animation.length if animation != null else 0.0,
				animation.get_track_count() if animation != null else 0,
				animation.loop_mode if animation != null else -1,
			])

	var combined_aabb := AABB()
	var has_aabb := false
	for mesh_instance in mesh_instances:
		var aabb := mesh_instance.get_aabb()
		var global_aabb := _to_global_aabb(mesh_instance, aabb)
		if has_aabb:
			combined_aabb = combined_aabb.merge(global_aabb)
		else:
			combined_aabb = global_aabb
			has_aabb = true
	if has_aabb:
		print("MONSTER_AABB position=%s size=%s" % [combined_aabb.position, combined_aabb.size])

	quit(0)

func _collect_animation_players(node: Node, output: Array[AnimationPlayer]) -> void:
	var animation_player := node as AnimationPlayer
	if animation_player != null:
		output.append(animation_player)
	for child in node.get_children():
		_collect_animation_players(child, output)

func _collect_mesh_instances(node: Node, output: Array[MeshInstance3D]) -> void:
	var mesh_instance := node as MeshInstance3D
	if mesh_instance != null:
		output.append(mesh_instance)
	for child in node.get_children():
		_collect_mesh_instances(child, output)

func _find_skeleton(node: Node) -> Skeleton3D:
	var skeleton := node as Skeleton3D
	if skeleton != null:
		return skeleton
	for child in node.get_children():
		var result := _find_skeleton(child)
		if result != null:
			return result
	return null

func _to_global_aabb(node: Node3D, local_aabb: AABB) -> AABB:
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
	var global_aabb := AABB(node.global_transform * corners[0], Vector3.ZERO)
	for corner_index in range(1, corners.size()):
		global_aabb = global_aabb.expand(node.global_transform * corners[corner_index])
	return global_aabb

func _fail(message: String) -> void:
	push_error("MONSTER_MODEL_INSPECT FAIL: %s" % message)
	quit(1)
