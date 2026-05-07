extends SceneTree

const MonsterSizeSource = preload("res://scripts/monster/MonsterSizeSource.gd")

const TEMPLATE_ID := "nightmare"
const MAX_COLLISION_ROOT_ERROR := 0.035
const MIN_VISIBLE_BOTTOM := -0.06
const MAX_VISIBLE_BOTTOM := 0.14

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var gameplay := MonsterSizeSource.gameplay_animation_names(TEMPLATE_ID)
	if gameplay.is_empty():
		_fail("missing Nightmare gameplay animation list")
		return

	var checked := 0
	var worst_collision_root_bottom := 0.0
	var worst_visible_floor_bottom := -INF
	var lowest_visible_floor_bottom := INF
	for animation_name in gameplay:
		var stats := await _sample_source_instance(animation_name)
		if stats.has("error"):
			_fail(String(stats["error"]))
			return
		var collision_root_bottom := float(stats["collision_root_bottom"])
		var visible_bottom_min := float(stats["visible_floor_bottom_min"])
		var visible_bottom_max := float(stats["visible_floor_bottom_max"])
		if absf(collision_root_bottom) > MAX_COLLISION_ROOT_ERROR:
			_fail("%s collision bottom is not tied to the runtime root floor: %.3f" % [animation_name, collision_root_bottom])
			return
		if visible_bottom_min < MIN_VISIBLE_BOTTOM:
			_fail("%s sinks below the runtime floor: visible_floor_bottom_min=%.3f" % [animation_name, visible_bottom_min])
			return
		if visible_bottom_min > MAX_VISIBLE_BOTTOM:
			_fail("%s floats above the runtime floor: visible_floor_bottom_min=%.3f" % [animation_name, visible_bottom_min])
			return
		checked += 1
		worst_collision_root_bottom = maxf(worst_collision_root_bottom, absf(collision_root_bottom))
		lowest_visible_floor_bottom = minf(lowest_visible_floor_bottom, visible_bottom_min)
		worst_visible_floor_bottom = maxf(worst_visible_floor_bottom, visible_bottom_max)

	print("MONSTER_RUNTIME_GROUND_SYNC PASS template=%s checked=%d collision_root_error=%.3f visible_floor_bottom_min=%.3f visible_floor_bottom_max=%.3f" % [
		TEMPLATE_ID,
		checked,
		worst_collision_root_bottom,
		lowest_visible_floor_bottom,
		worst_visible_floor_bottom,
	])
	quit(0)

func _sample_source_instance(animation_name: String) -> Dictionary:
	var monster := MonsterSizeSource.instantiate_template(TEMPLATE_ID)
	if monster == null:
		return {"error": "source instance did not instantiate"}
	root.add_child(monster)
	await process_frame
	await process_frame
	_disable_runtime_process(monster)
	var player := _find_animation_player(monster)
	if player == null:
		monster.queue_free()
		return {"error": "missing AnimationPlayer"}
	if not player.has_animation(animation_name):
		monster.queue_free()
		return {"error": "missing animation: %s" % animation_name}
	var animation := player.get_animation(StringName(animation_name))
	if animation == null:
		monster.queue_free()
		return {"error": "null animation: %s" % animation_name}
	MonsterSizeSource.apply_animation_ground_offset(monster, TEMPLATE_ID, animation_name)

	var collision_bottom := _collision_bottom_y(monster)
	if not is_finite(collision_bottom):
		monster.queue_free()
		return {"error": "missing valid collision box"}
	var collision_root_bottom := collision_bottom - monster.global_position.y
	var visible_floor_bottom_min := INF
	var visible_floor_bottom_max := -INF
	var sample_count := maxi(4, ceili(animation.length / 0.12) + 1)
	player.play(animation_name, 0.0, 1.0)
	for index in range(sample_count):
		var t := 0.0
		if sample_count > 1:
			t = animation.length * float(index) / float(sample_count - 1)
		player.seek(t, true)
		player.advance(0.0)
		await process_frame
		var bounds := _combined_bounds(monster)
		if bounds.size == Vector3.ZERO:
			continue
		collision_bottom = _collision_bottom_y(monster)
		var visible_floor_bottom := bounds.position.y - collision_bottom
		visible_floor_bottom_min = minf(visible_floor_bottom_min, visible_floor_bottom)
		visible_floor_bottom_max = maxf(visible_floor_bottom_max, visible_floor_bottom)
	player.stop()
	monster.queue_free()
	await process_frame
	return {
		"collision_root_bottom": collision_root_bottom,
		"visible_floor_bottom_min": visible_floor_bottom_min,
		"visible_floor_bottom_max": visible_floor_bottom_max,
	}

func _disable_runtime_process(monster: Node3D) -> void:
	monster.set_process(false)
	monster.set_physics_process(false)
	monster.set_process_input(false)
	monster.set_process_unhandled_input(false)

func _find_animation_player(node: Node) -> AnimationPlayer:
	var player := node as AnimationPlayer
	if player != null:
		return player
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null

func _collision_bottom_y(monster: Node3D) -> float:
	var collision := _find_collision_shape(monster)
	if collision == null:
		return INF
	var box := collision.shape as BoxShape3D
	if box == null:
		return INF
	return _box_bottom_y(collision.global_transform, box.size)

func _find_collision_shape(node: Node) -> CollisionShape3D:
	if node == null:
		return null
	var collision := node as CollisionShape3D
	if collision != null and collision.shape != null:
		return collision
	for child in node.get_children():
		var found := _find_collision_shape(child)
		if found != null:
			return found
	return null

func _box_bottom_y(transform: Transform3D, size: Vector3) -> float:
	var half := size * 0.5
	var bottom := INF
	var corners := [
		Vector3(-half.x, -half.y, -half.z),
		Vector3(half.x, -half.y, -half.z),
		Vector3(half.x, -half.y, half.z),
		Vector3(-half.x, -half.y, half.z),
		Vector3(-half.x, half.y, -half.z),
		Vector3(half.x, half.y, -half.z),
		Vector3(half.x, half.y, half.z),
		Vector3(-half.x, half.y, half.z),
	]
	for corner in corners:
		bottom = minf(bottom, (transform * corner).y)
	return bottom

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
	push_error("MONSTER_RUNTIME_GROUND_SYNC FAIL %s" % message)
	quit(1)
