extends SceneTree

const IMPORTED_MONSTERS := [
	{
		"id": "NightmareCreature_A",
		"path": "res://assets/backrooms/monsters/NightmareCreature_A.tscn",
		"license": "CC-BY-4.0",
		"min_animations": 18,
		"min_height": 1.05,
		"max_height": 1.55,
		"expected_display_height": 1.29,
		"min_visual_height": 0.5,
		"max_visual_height": 3.0,
		"max_triangles": 9000,
	},
]

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var summaries: Array[String] = []
	for spec in IMPORTED_MONSTERS:
		var packed := load(String(spec["path"])) as PackedScene
		if packed == null:
			_fail("missing imported monster wrapper: %s" % spec["path"])
			return
		var monster := packed.instantiate() as Node3D
		if monster == null:
			_fail("imported monster is not Node3D: %s" % spec["id"])
			return
		root.add_child(monster)
		await process_frame

		if String(monster.get_meta("resource_model_id", "")) != String(spec["id"]):
			_fail("%s resource_model_id metadata mismatch" % spec["id"])
			return
		if String(monster.get_meta("source_license", "")) != String(spec["license"]):
			_fail("%s source_license metadata mismatch" % spec["id"])
			return
		if int(monster.get_meta("approx_triangles", 0)) > int(spec["max_triangles"]):
			_fail("%s triangle count exceeds expected cap" % spec["id"])
			return

		if not _has_visible_mesh(monster):
			_fail("%s has no visible mesh" % spec["id"])
			return
		var visual_bounds := _visual_aabb(monster)
		var visual_height := visual_bounds.size.y
		if visual_height < float(spec["min_visual_height"]) or visual_height > float(spec["max_visual_height"]):
			_fail("%s visual mesh height %.3f is outside expected range %.3f..%.3f" % [
				spec["id"],
				visual_height,
				float(spec["min_visual_height"]),
				float(spec["max_visual_height"]),
			])
			return
		var height := float(monster.get_meta("display_height_meters", 0.0))
		if height < float(spec["min_height"]) or height > float(spec["max_height"]):
			_fail("%s display height %.3f is outside expected range %.3f..%.3f" % [
				spec["id"],
				height,
				float(spec["min_height"]),
				float(spec["max_height"]),
			])
			return
		if absf(height - float(spec["expected_display_height"])) > 0.04:
			_fail("%s display height metadata drifted: %.3f expected %.3f" % [
				spec["id"],
				height,
				float(spec["expected_display_height"]),
			])
			return

		var animation_count := _count_animations(monster)
		if animation_count < int(spec["min_animations"]):
			_fail("%s animation count too low: %d" % [spec["id"], animation_count])
			return

		summaries.append("%s height=%.2f visual=%.2f animations=%d triangles=%d license=%s" % [
			spec["id"],
			height,
			visual_height,
			animation_count,
			int(monster.get_meta("approx_triangles", 0)),
			String(spec["license"]),
		])
		monster.queue_free()
		await process_frame

	print("IMPORTED_MONSTER_ASSETS_VALIDATION PASS %s" % "; ".join(summaries))
	quit(0)

func _has_visible_mesh(root_node: Node) -> bool:
	for node in _all_nodes(root_node):
		var mesh := node as MeshInstance3D
		if mesh != null and mesh.mesh != null:
			return true
	return false

func _collect_meshes(node: Node, output: Array[MeshInstance3D]) -> void:
	var mesh := node as MeshInstance3D
	if mesh != null:
		output.append(mesh)
	for child in node.get_children():
		_collect_meshes(child, output)

func _visual_aabb(root_node: Node3D) -> AABB:
	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(root_node, meshes)
	var has_bounds := false
	var combined := AABB()
	for mesh in meshes:
		if mesh.mesh == null:
			continue
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
		local_aabb.position + Vector3(0.0, local_aabb.size.y, local_aabb.size.z),
		local_aabb.position + Vector3(0.0, 0.0, local_aabb.size.z),
		local_aabb.position + Vector3(local_aabb.size.x, local_aabb.size.y, 0.0),
		local_aabb.position + Vector3(local_aabb.size.x, 0.0, local_aabb.size.z),
		local_aabb.position + Vector3(0.0, local_aabb.size.y, 0.0),
		local_aabb.position + local_aabb.size,
	]
	var converted := AABB(node.global_transform * corners[0], Vector3.ZERO)
	for index in range(1, corners.size()):
		converted = converted.expand(node.global_transform * corners[index])
	return converted

func _count_animations(root_node: Node) -> int:
	var count := 0
	for node in _all_nodes(root_node):
		var player := node as AnimationPlayer
		if player != null:
			count += player.get_animation_list().size()
	return count

func _all_nodes(root_node: Node) -> Array[Node]:
	var result: Array[Node] = [root_node]
	for child in root_node.get_children():
		result.append_array(_all_nodes(child))
	return result

func _fail(message: String) -> void:
	push_error("IMPORTED_MONSTER_ASSETS_VALIDATION FAIL %s" % message)
	quit(1)
