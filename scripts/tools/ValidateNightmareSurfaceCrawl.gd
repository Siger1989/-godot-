extends SceneTree

const NIGHTMARE_MONSTER_PATH := "res://assets/backrooms/monsters/NightmareCreature_Monster.tscn"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load(NIGHTMARE_MONSTER_PATH) as PackedScene
	if packed == null:
		_fail("Missing Nightmare monster scene.")
		return

	var scene_root := Node3D.new()
	root.add_child(scene_root)
	_add_static_box(scene_root, "Ceiling", Vector3(0.0, 2.55, 0.0), Vector3(5.0, 0.12, 5.0))
	_add_static_box(scene_root, "Wall_X", Vector3(0.72, 1.25, 0.0), Vector3(0.12, 2.5, 5.0))

	var player := CharacterBody3D.new()
	player.name = "Player"
	player.add_to_group("player", true)
	scene_root.add_child(player)
	player.global_position = Vector3(0.0, 0.05, 3.0)
	player.velocity = Vector3(1.2, 0.0, 0.0)

	var monster := packed.instantiate() as CharacterBody3D
	if monster == null:
		_fail("Nightmare monster did not instantiate as CharacterBody3D.")
		return
	scene_root.add_child(monster)
	monster.global_position = Vector3.ZERO
	await process_frame
	await physics_frame

	var animation_player := _find_animation_player(monster)
	if animation_player == null:
		_fail("Nightmare is missing AnimationPlayer.")
		return
	if not animation_player.has_animation("Creature_armature|crawl"):
		_fail("Nightmare must have the crawl animation for wall/ceiling surface movement.")
		return

	monster.set("_chase_target", player)
	monster.call("_record_heard_sound", player.global_position)
	monster.call("_start_chase")
	monster.call("_update_nightmare_ceiling_ambush", 0.18)
	var ceiling_mode := String(monster.call("debug_get_nightmare_surface_mode"))
	var ceiling_up := monster.call("debug_get_nightmare_model_up") as Vector3
	var ceiling_animation := String(monster.call("debug_get_current_animation"))
	if ceiling_mode != "CEILING":
		_fail("Nightmare did not enter CEILING crawl mode; mode=%s." % ceiling_mode)
		return
	if ceiling_up.dot(Vector3.DOWN) < 0.55:
		_fail("Nightmare ceiling mode is not inverted enough; model_up=%s." % str(ceiling_up))
		return
	if ceiling_animation != "Creature_armature|crawl":
		_fail("Nightmare ceiling mode must use crawl animation; animation=%s." % ceiling_animation)
		return

	monster.call("_clear_nightmare_surface_crawl")
	monster.set("nightmare_ceiling_ambush_enabled", false)
	monster.global_position = Vector3.ZERO
	monster.velocity = Vector3(1.2, 0.0, 0.0)
	monster.set("_chase_target", player)
	monster.call("_start_chase")
	monster.call("_update_nightmare_ceiling_ambush", 0.18)
	var wall_mode := String(monster.call("debug_get_nightmare_surface_mode"))
	var wall_up := monster.call("debug_get_nightmare_model_up") as Vector3
	var wall_animation := String(monster.call("debug_get_current_animation"))
	if wall_mode != "WALL":
		_fail("Nightmare did not enter WALL crawl mode; mode=%s." % wall_mode)
		return
	if wall_up.dot(Vector3.LEFT) < 0.55:
		_fail("Nightmare wall mode is not perpendicular to the wall; model_up=%s." % str(wall_up))
		return
	if wall_animation != "Creature_armature|crawl":
		_fail("Nightmare wall mode must use crawl animation; animation=%s." % wall_animation)
		return

	print("NIGHTMARE_SURFACE_CRAWL_VALIDATION PASS ceiling_up=%s wall_up=%s animation=%s" % [
		str(ceiling_up),
		str(wall_up),
		wall_animation,
	])
	quit(0)

func _add_static_box(parent: Node3D, node_name: String, position: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	parent.add_child(body)
	body.global_position = position
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	collision.shape = shape
	body.add_child(collision)

func _find_animation_player(node: Node) -> AnimationPlayer:
	var player := node as AnimationPlayer
	if player != null:
		return player
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null

func _fail(message: String) -> void:
	push_error("NIGHTMARE_SURFACE_CRAWL_VALIDATION FAIL %s" % message)
	quit(1)
