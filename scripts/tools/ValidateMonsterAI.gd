extends SceneTree

const SCENE_PATH := "res://scenes/mvp/FourRoomMVP.tscn"
const IDLE_ANIMATION := "road_creature_reference_skeleton|Idle"
const WALK_ANIMATION := "road_creature_reference_skeleton|Walk"
const RUN_ANIMATION := "road_creature_reference_skeleton|Run"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene_resource := load(SCENE_PATH) as PackedScene
	if scene_resource == null:
		_fail("Failed to load %s." % SCENE_PATH)
		return

	var scene := scene_resource.instantiate() as Node3D
	root.add_child(scene)
	await process_frame
	await physics_frame
	await process_frame

	var player := scene.get_node_or_null("PlayerRoot/Player") as CharacterBody3D
	var monster := scene.get_node_or_null("MonsterRoot/Monster") as CharacterBody3D
	var monster_spawn := scene.get_node_or_null("LevelRoot/Markers/Spawn_Monster_D") as Node3D
	var animation_player := scene.get_node_or_null("MonsterRoot/Monster/ModelRoot/guai1/AnimationPlayer") as AnimationPlayer
	var portal_cd := scene.get_node_or_null("LevelRoot/Portals/P_CD") as Node3D
	var portal_da := scene.get_node_or_null("LevelRoot/Portals/P_DA") as Node3D
	if player == null or monster == null or monster_spawn == null or animation_player == null or portal_cd == null or portal_da == null:
		_fail("Required player, monster, spawn, or monster AnimationPlayer node is missing.")
		return
	_isolate_primary_monster(scene, monster)

	if monster.global_position.distance_to(monster_spawn.global_position) > 0.2:
		_fail("Monster was not placed at Spawn_Monster_D.")
		return

	for animation_name in [IDLE_ANIMATION, WALK_ANIMATION, RUN_ANIMATION]:
		if not animation_player.has_animation(animation_name):
			_fail("Monster animation %s is missing." % animation_name)
			return
		var animation := animation_player.get_animation(animation_name)
		if animation == null:
			_fail("Monster animation %s is null." % animation_name)
			return
		if _has_enabled_position_track(animation):
			_fail("Monster animation %s still has an enabled POSITION track." % animation_name)
			return

	monster.rotation = Vector3.ZERO
	var forward_speed := float(monster.call("debug_test_locomotion_animation_speed", Vector3(0.0, 0.0, -1.0)))
	if forward_speed <= 0.0:
		_fail("Monster forward locomotion animation did not play forward: speed=%.3f." % forward_speed)
		return
	var reverse_speed := float(monster.call("debug_test_locomotion_animation_speed", Vector3(0.0, 0.0, 1.0)))
	if reverse_speed >= 0.0:
		_fail("Monster backward locomotion animation did not reverse: speed=%.3f." % reverse_speed)
		return

	player.set_physics_process(false)
	player.velocity = Vector3.ZERO
	player.global_position = Vector3(0.0, 0.05, 1.8)
	monster.global_position = Vector3(0.0, 0.05, 0.0)
	monster.rotation = Vector3.ZERO
	monster.velocity = Vector3.ZERO
	await physics_frame

	var panic_detected := bool(monster.call("debug_can_see_player"))
	if not panic_detected:
		_fail("Monster did not panic-detect a nearby player behind it.")
		return

	await _wait_physics_frames(3)
	var panic_state := String(monster.call("debug_get_state_name"))
	if panic_state != "FLEE":
		_fail("Monster did not immediately enter FLEE from nearby panic; current state is %s." % panic_state)
		return
	var panic_speed := Vector2(monster.velocity.x, monster.velocity.z).length()
	if panic_speed < 1.4:
		_fail("Monster panic flee did not get an immediate start impulse: speed=%.3f." % panic_speed)
		return

	monster.call("_choose_wander")
	player.set_physics_process(false)
	player.velocity = Vector3.ZERO
	player.global_position = Vector3(0.0, 0.05, -2.2)
	monster.global_position = Vector3(0.0, 0.05, 0.0)
	monster.rotation = Vector3.ZERO
	await physics_frame

	var can_see := bool(monster.call("debug_can_see_player"))
	if not can_see:
		_fail("Monster forward vision did not detect the player in front.")
		return

	var initial_flee_distance := _flat_distance(monster.global_position, player.global_position)
	await _wait_physics_frames(25)
	var flee_state := String(monster.call("debug_get_state_name"))
	if flee_state != "FLEE":
		_fail("Monster did not enter FLEE after seeing the player; current state is %s." % flee_state)
		return
	var current_flee_distance := _flat_distance(monster.global_position, player.global_position)
	if current_flee_distance <= initial_flee_distance + 0.4:
		_fail("Monster did not open distance from the player while fleeing: initial=%.3f current=%.3f." % [initial_flee_distance, current_flee_distance])
		return
	if animation_player.current_animation != RUN_ANIMATION:
		_fail("Monster did not play Run while fleeing.")
		return

	player.global_position = Vector3(-1.1, 0.05, 5.0)
	monster.global_position = Vector3(-1.1, 0.05, 7.0)
	monster.rotation = Vector3.ZERO
	monster.velocity = Vector3.ZERO
	await physics_frame
	if not bool(monster.call("debug_can_see_player")):
		_fail("Monster did not see the player during the Room_D escape-route test.")
		return

	var initial_portal_distance := minf(
		_flat_distance(monster.global_position, portal_cd.global_position),
		_flat_distance(monster.global_position, portal_da.global_position)
	)
	await _wait_physics_frames(70)
	var routed_flee_state := String(monster.call("debug_get_state_name"))
	if routed_flee_state != "FLEE":
		_fail("Monster left FLEE during the Room_D escape-route test; current state is %s." % routed_flee_state)
		return
	if not bool(monster.call("debug_has_flee_route")):
		_fail("Monster did not select a portal escape route while fleeing in Room_D.")
		return
	var current_portal_distance := minf(
		_flat_distance(monster.global_position, portal_cd.global_position),
		_flat_distance(monster.global_position, portal_da.global_position)
	)
	if current_portal_distance >= initial_portal_distance - 0.5:
		_fail("Monster did not make progress toward a room-exit portal while fleeing.")
		return
	if monster.global_position.z > 7.6:
		_fail("Monster fled into the north wall instead of routing toward another room.")
		return

	player.global_position = Vector3(12.0, 0.05, 12.0)
	await _wait_physics_frames(180)
	var non_flee_state := String(monster.call("debug_get_state_name"))
	if non_flee_state == "FLEE":
		_fail("Monster remained in FLEE after the player left vision.")
		return

	print(
		"MONSTER_AI_VALIDATION PASS state=%s flee_z=%.3f animation=%s"
		% [non_flee_state, monster.global_position.z, animation_player.current_animation]
	)
	quit(0)

func _wait_physics_frames(frame_count: int) -> void:
	for _frame_index in range(frame_count):
		await physics_frame

func _isolate_primary_monster(scene: Node, primary_monster: CharacterBody3D) -> void:
	var monster_root := scene.get_node_or_null("MonsterRoot")
	if monster_root == null:
		return
	for child in monster_root.get_children():
		var monster := child as CharacterBody3D
		if monster == null or monster == primary_monster:
			continue
		monster.set_meta("dead", true)
		monster.set_physics_process(false)
		monster.global_position = Vector3(80.0, 0.05, 80.0)

func _has_enabled_position_track(animation: Animation) -> bool:
	for track_index in range(animation.get_track_count()):
		if animation.track_get_type(track_index) == Animation.TYPE_POSITION_3D and animation.track_is_enabled(track_index):
			return true
	return false

func _flat_distance(a: Vector3, b: Vector3) -> float:
	var flat_a := Vector3(a.x, 0.0, a.z)
	var flat_b := Vector3(b.x, 0.0, b.z)
	return flat_a.distance_to(flat_b)

func _fail(message: String) -> void:
	push_error("MONSTER_AI_VALIDATION FAIL: %s" % message)
	quit(1)
