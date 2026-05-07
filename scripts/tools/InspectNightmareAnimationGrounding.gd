extends SceneTree

const NIGHTMARE_MONSTER_PATH := "res://assets/backrooms/monsters/NightmareCreature_Monster.tscn"
const MonsterSizeSource = preload("res://scripts/monster/MonsterSizeSource.gd")
const RECOMMENDED := {
	"Creature_armature|idle": "idle",
	"Creature_armature|walk": "walk",
	"Creature_armature|Run": "run",
	"Creature_armature|attack_1": "attack",
	"Creature_armature|death_1": "death",
	"Creature_armature|hit_1": "optional_hit",
	"Creature_armature|roar": "optional_roar",
}

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
	var player := _find_animation_player(monster)
	if player == null:
		_fail("missing AnimationPlayer")
		return
	var model_root := monster.get_node_or_null("ModelRoot") as Node3D
	if model_root == null:
		_fail("missing ModelRoot")
		return

	print("NIGHTMARE_ANIMATION_GROUNDING_BEGIN animations=%d model_root_y=%.3f" % [
		player.get_animation_list().size(),
		model_root.position.y,
	])
	for animation_name_variant in player.get_animation_list():
		var animation_name := String(animation_name_variant)
		var animation := player.get_animation(StringName(animation_name))
		if animation == null:
			continue
		var stats := await _sample_animation(monster, player, animation_name, animation.length)
		var role := String(RECOMMENDED.get(animation_name, "unused"))
		print("ANIM name=\"%s\" role=%s length=%.3f bottom_min=%.3f bottom_max=%.3f height_min=%.3f height_max=%.3f suggested_offset=%.3f" % [
			animation_name,
			role,
			animation.length,
			float(stats["bottom_min"]),
			float(stats["bottom_max"]),
			float(stats["height_min"]),
			float(stats["height_max"]),
			-float(stats["bottom_min"]),
		])
	print("NIGHTMARE_ANIMATION_GROUNDING_END")
	quit(0)

func _sample_animation(monster: Node3D, player: AnimationPlayer, animation_name: String, length: float) -> Dictionary:
	MonsterSizeSource.apply_animation_ground_offset(monster, "nightmare", animation_name)
	var bottom_min := INF
	var bottom_max := -INF
	var height_min := INF
	var height_max := -INF
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
		var bottom := bounds.position.y
		var height := bounds.size.y
		bottom_min = minf(bottom_min, bottom)
		bottom_max = maxf(bottom_max, bottom)
		height_min = minf(height_min, height)
		height_max = maxf(height_max, height)
	player.stop()
	return {
		"bottom_min": bottom_min,
		"bottom_max": bottom_max,
		"height_min": height_min,
		"height_max": height_max,
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
	push_error("NIGHTMARE_ANIMATION_GROUNDING_FAIL %s" % message)
	quit(1)
