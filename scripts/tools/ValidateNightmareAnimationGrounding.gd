extends SceneTree

const NIGHTMARE_MONSTER_PATH := "res://assets/backrooms/monsters/NightmareCreature_Monster.tscn"
const MonsterSizeSource = preload("res://scripts/monster/MonsterSizeSource.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load(NIGHTMARE_MONSTER_PATH) as PackedScene
	if packed == null:
		_fail("missing Nightmare monster scene")
		return
	var monster := packed.instantiate() as Node3D
	if monster == null:
		_fail("Nightmare monster did not instantiate")
		return
	root.add_child(monster)
	await process_frame
	await process_frame
	_disable_runtime_process(monster)
	var player := _find_animation_player(monster)
	if player == null:
		_fail("missing AnimationPlayer")
		return

	var available_names := {}
	for animation_name_variant in player.get_animation_list():
		available_names[String(animation_name_variant)] = true
	var imported_count := available_names.size()
	var gameplay := MonsterSizeSource.gameplay_animation_names("nightmare")
	if gameplay.is_empty():
		_fail("missing gameplay animation list.")
		return
	monster.queue_free()
	await process_frame

	var checked := 0
	var worst_min := INF
	var worst_max := -INF
	for animation_name in gameplay:
		if not available_names.has(animation_name):
			_fail("missing gameplay animation: %s." % animation_name)
			return
		var stats := await _sample_animation(packed, animation_name)
		if stats.has("error"):
			_fail(String(stats["error"]))
			return
		var bottom_min := float(stats["bottom_min"])
		var bottom_max := float(stats["bottom_max"])
		worst_min = minf(worst_min, bottom_min)
		worst_max = maxf(worst_max, bottom_max)
		if bottom_min < -0.04:
			_fail("%s sinks below floor after grounding: bottom_min=%.3f." % [animation_name, bottom_min])
			return
		if bottom_min > 0.05:
			_fail("%s never touches the floor after grounding: bottom_min=%.3f." % [animation_name, bottom_min])
			return
		if bottom_max > 0.24:
			_fail("%s floats too high after grounding: bottom_max=%.3f." % [animation_name, bottom_max])
			return
		checked += 1

	print("NIGHTMARE_ANIMATION_GROUNDING_VALIDATION PASS imported=%d checked=%d gameplay=%d bottom_min=%.3f bottom_max=%.3f" % [
		imported_count,
		checked,
		gameplay.size(),
		worst_min,
		worst_max,
	])
	quit(0)

func _sample_animation(packed: PackedScene, animation_name: String) -> Dictionary:
	var monster := packed.instantiate() as Node3D
	if monster == null:
		return {"error": "Nightmare monster sample did not instantiate for %s." % animation_name}
	root.add_child(monster)
	await process_frame
	await process_frame
	var player := _find_animation_player(monster)
	if player == null:
		monster.queue_free()
		return {"error": "missing AnimationPlayer in sample for %s." % animation_name}
	if not player.has_animation(animation_name):
		monster.queue_free()
		return {"error": "missing sample animation: %s." % animation_name}
	var animation := player.get_animation(StringName(animation_name))
	if animation == null:
		monster.queue_free()
		return {"error": "null sample animation: %s." % animation_name}

	MonsterSizeSource.apply_animation_ground_offset(monster, "nightmare", animation_name)
	var bottom_min := INF
	var bottom_max := -INF
	var length := animation.length
	var sample_count := maxi(4, ceili(length / 0.12) + 1)
	player.play(animation_name, 0.0, 1.0)
	for index in range(sample_count):
		var t := 0.0
		if sample_count > 1:
			t = length * float(index) / float(sample_count - 1)
		player.seek(t, true)
		player.advance(0.0)
		await process_frame
		var bounds := _combined_bounds(monster)
		if bounds.size == Vector3.ZERO:
			continue
		bottom_min = minf(bottom_min, bounds.position.y)
		bottom_max = maxf(bottom_max, bounds.position.y)
	player.stop()
	monster.queue_free()
	await process_frame
	return {
		"bottom_min": bottom_min,
		"bottom_max": bottom_max,
	}

func _find_animation_player(node: Node) -> AnimationPlayer:
	var player := node as AnimationPlayer
	if player != null:
		return player
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null

func _disable_runtime_process(monster: Node3D) -> void:
	monster.set_process(false)
	monster.set_physics_process(false)
	monster.set_process_input(false)
	monster.set_process_unhandled_input(false)

func _combined_bounds(node: Node) -> AABB:
	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(node, meshes)
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

func _collect_meshes(node: Node, output: Array[MeshInstance3D]) -> void:
	var mesh := node as MeshInstance3D
	if mesh != null and mesh.mesh != null and mesh.visible:
		output.append(mesh)
	for child in node.get_children():
		_collect_meshes(child, output)

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

func _fail(message: String) -> void:
	push_error("NIGHTMARE_ANIMATION_GROUNDING_VALIDATION FAIL %s" % message)
	quit(1)
