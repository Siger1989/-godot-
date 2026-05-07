extends SceneTree

const SCENE_PATH := "res://scenes/mvp/FourRoomMVP.tscn"
const EXPECTED_MONSTER_NAMES := [
	"Monster",
	"Monster_Red_KeyBearer_MVP",
	"NightmareCreature_A_MVP",
]
const EXPECTED_ALL_MONSTER_NODES := [
	"Monster",
	"Monster_Red_KeyBearer_MVP",
	"NightmareCreature_A_MVP",
]
const FORBIDDEN_MONSTER_NODES := [
	"Monster_Normal_B",
	"NightmareCreature_B_MVP",
	"CreatureZombie_A_MVP",
]
const ROOM_MIN := Vector2(-2.45, -2.45)
const ROOM_MAX := Vector2(8.45, 8.45)
const DOOR_CENTERS := [
	Vector2(3.0, 0.0),
	Vector2(6.0, 3.0),
	Vector2(3.0, 6.0),
	Vector2(0.0, 3.0),
]

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene_resource := load(SCENE_PATH) as PackedScene
	if scene_resource == null:
		_fail("Failed to load %s." % SCENE_PATH)
		return

	var scene := scene_resource.instantiate() as Node3D
	if scene == null:
		_fail("Scene root is not Node3D.")
		return
	root.add_child(scene)
	await process_frame
	await physics_frame
	await process_frame

	var player := scene.get_node_or_null("PlayerRoot/Player") as CharacterBody3D
	if player == null:
		_fail("MVP player is missing.")
		return
	if not bool(scene.get_meta("mvp_player_immortal", false)):
		_fail("MVP scene is not marked as an immortal-player test room.")
		return
	if not bool(player.get_meta("mvp_player_immortal", false)):
		_fail("MVP player is not marked immortal for monster-mechanic testing.")
		return

	var monster_root := scene.get_node_or_null("MonsterRoot") as Node3D
	if monster_root == null:
		_fail("MonsterRoot is missing.")
		return
	if not monster_root.scene_file_path.is_empty():
		_fail("MonsterRoot must be a direct editable node in FourRoomMVP, got scene_file_path=%s." % monster_root.scene_file_path)
		return
	if not bool(monster_root.get_meta("mvp_editable_monster_root", false)):
		_fail("MonsterRoot is not marked as the direct editable MVP monster root.")
		return
	for monster_name in FORBIDDEN_MONSTER_NODES:
		if monster_root.get_node_or_null(monster_name) != null:
			_fail("MVP must keep one source per monster type, but found duplicate/removed node: %s." % monster_name)
			return
	for monster_name in EXPECTED_ALL_MONSTER_NODES:
		var monster_node := monster_root.get_node_or_null(monster_name) as Node3D
		if monster_node == null:
			_fail("Missing MVP monster source node: %s." % monster_name)
			return
		if not bool(monster_node.get_meta("mvp_test_monster", false)):
			_fail("%s is not tagged as an MVP test monster." % monster_name)
			return
		if not _has_mesh(monster_node):
			_fail("%s has no visible mesh." % monster_name)
			return
		if not _is_inside_mvp_rooms(monster_node.global_position):
			_fail("%s is outside the FourRoomMVP room bounds at %s." % [monster_name, monster_node.global_position])
			return
		if _is_on_door_center(monster_node.global_position):
			_fail("%s is too close to a doorway center at %s." % [monster_name, monster_node.global_position])
			return

	var monsters := _monster_children(monster_root)
	if monsters.size() != 3:
		_fail("Expected one controller-backed MVP test monster per type, found %d." % monsters.size())
		return

	for monster_name in EXPECTED_MONSTER_NAMES:
		if monster_root.get_node_or_null(monster_name) == null:
			_fail("Missing MVP test monster: %s." % monster_name)
			return

	var normal_count := 0
	var nightmare_count := 0
	var nightmare_monsters: Array[CharacterBody3D] = []
	var red_monster: CharacterBody3D = null
	for monster in monsters:
		var role := String(monster.get_meta("monster_role", monster.get("monster_role")))
		if role == "red":
			red_monster = monster
		elif role == "nightmare":
			nightmare_count += 1
			nightmare_monsters.append(monster)
		else:
			normal_count += 1
		if not bool(monster.get_meta("mvp_test_monster", false)):
			_fail("%s is not tagged as an MVP test monster." % monster.name)
			return
		if not _has_positive_scale(monster):
			_fail("%s scale is invalid: %s." % [monster.name, monster.transform.basis.get_scale()])
			return
		if not _is_inside_mvp_rooms(monster.global_position):
			_fail("%s is outside the FourRoomMVP room bounds at %s." % [monster.name, monster.global_position])
			return
		if _is_on_door_center(monster.global_position):
			_fail("%s is too close to a doorway center at %s." % [monster.name, monster.global_position])
			return

	if normal_count != 1:
		_fail("Expected one normal MVP test monster, found %d." % normal_count)
		return
	if red_monster == null:
		_fail("MVP red hunter monster is missing.")
		return
	if nightmare_count != 1:
		_fail("Expected one MVP Nightmare hearing monster, found %d." % nightmare_count)
		return
	for nightmare_monster in nightmare_monsters:
		if not nightmare_monster.is_in_group("nightmare_monster"):
			_fail("%s is not in nightmare_monster group." % nightmare_monster.name)
			return
		if not bool(nightmare_monster.get_meta("mvp_runtime_hearing_monster", false)):
			_fail("%s is not tagged as the MVP runtime hearing monster." % nightmare_monster.name)
			return
		if bool(nightmare_monster.call("debug_can_see_player")):
			_fail("%s must not use vision against the player." % nightmare_monster.name)
			return
		if nightmare_monster.get_node_or_null("NightmareSonarAudio") == null:
			_fail("%s is missing NightmareSonarAudio." % nightmare_monster.name)
			return
	if not red_monster.is_in_group("red_monster"):
		_fail("MVP red monster is not in red_monster group.")
		return
	if bool(red_monster.get("attach_escape_key")):
		_fail("MVP red monster must not be configured to carry the escape key.")
		return
	if bool(red_monster.get_meta("has_escape_key", false)):
		_fail("MVP red monster still exposes has_escape_key metadata.")
		return
	if red_monster.get_node_or_null("ChestEscapeKey") != null:
		_fail("MVP red monster still has a ChestEscapeKey visual.")
		return

	var visible_prey := _first_monster_except(monsters, red_monster)
	if visible_prey == null:
		_fail("No living monster prey is available for red hunter targeting.")
		return
	red_monster.set_physics_process(false)
	visible_prey.set_physics_process(false)
	red_monster.global_position = Vector3(6.2, 0.05, 7.0)
	visible_prey.global_position = Vector3(6.2, 0.05, 6.38)
	red_monster.rotation.y = 0.0
	red_monster.set("_attack_timer", 0.0)
	await physics_frame
	var red_health_before_prey_attack := float(red_monster.call("debug_get_health"))
	var prey_health_before := float(visible_prey.call("debug_get_health"))
	red_monster.call("_update_red_state", 0.016)
	if String(red_monster.call("debug_get_chase_target_name")) != visible_prey.name:
		_fail("Red hunter did not target the visible living monster prey.")
		return
	var prey_health_after := float(visible_prey.call("debug_get_health"))
	if prey_health_after >= prey_health_before:
		_fail("Red hunter did not damage the visible living monster prey.")
		return
	if float(red_monster.call("debug_get_health")) < red_health_before_prey_attack:
		_fail("Red hunter should not auto-counter-damage itself when it attacks visible prey.")
		return
	if _forward_dot_to(red_monster, visible_prey) < 0.94:
		_fail("Red hunter is not facing the prey during attack.")
		return

	player.set_meta("red_monster_hit_count", 0)
	player.set_meta("mvp_red_attack_was_nonlethal", false)
	player.set_meta("dead", false)
	red_monster.set("_chase_target", player)
	red_monster.call("_perform_attack")
	if int(player.get_meta("red_monster_hit_count", 0)) < 1:
		_fail("Red monster attack did not register a nonlethal MVP player hit.")
		return
	if bool(player.get_meta("dead", false)):
		_fail("MVP player was marked dead by red monster attack.")
		return
	if not bool(player.get_meta("mvp_red_attack_was_nonlethal", false)):
		_fail("MVP red monster attack did not use the nonlethal immortal-player path.")
		return

	var cabinet := scene.get_node_or_null("LevelRoot/Props/RoomB_Maintenance_Cabinet") as Node3D
	var cabinet_key := scene.get_node_or_null("LevelRoot/Props/CabinetTop_EscapeKey") as Node3D
	if cabinet == null or cabinet_key == null:
		_fail("MVP cabinet or cabinet-top escape key is missing.")
		return
	if not cabinet_key.is_in_group("escape_key_pickup"):
		_fail("CabinetTop_EscapeKey is not in escape_key_pickup group.")
		return
	if cabinet_key.global_position.y <= cabinet.global_position.y + 0.75:
		_fail("CabinetTop_EscapeKey is not placed on top of the cabinet.")
		return
	var key_parts := _gold_key_mesh_count(cabinet_key)
	if key_parts < 7:
		_fail("CabinetTop_EscapeKey is not visually complete.")
		return
	player.call("debug_set_escape_key", false)
	player.call("collect_escape_key", cabinet_key)
	if not bool(player.call("has_escape_key")):
		_fail("Player did not receive the escape key from the cabinet pickup.")
		return

	if scene.get_node_or_null("LevelRoot/Geometry/WallOpening_Exit_C_North") == null:
		_fail("Outer-wall exit opening is missing.")
		return
	if scene.get_node_or_null("LevelRoot/Geometry/DoorFrame_Exit_C_North") == null:
		_fail("Outer-wall exit door frame is missing.")
		return
	var exit_door := scene.get_node_or_null("LevelRoot/Doors/Door_Exit_C_North_Keyed") as Node3D
	if exit_door == null:
		_fail("Keyed outer exit door is missing.")
		return
	if not bool(exit_door.get("requires_escape_key")):
		_fail("Outer exit door is not configured to require the escape key.")
		return
	player.call("debug_set_escape_key", false)
	var opened_without_key := bool(exit_door.call("interact_from", player, Vector3.FORWARD))
	if opened_without_key or bool(exit_door.call("is_open")):
		_fail("Outer exit door opened without the escape key.")
		return
	if int(exit_door.get_meta("locked_attempt_count", 0)) < 1:
		_fail("Outer exit door did not record a locked interaction attempt.")
		return
	player.call("debug_set_escape_key", true)
	var opened_with_key := bool(exit_door.call("interact_from", player, Vector3.FORWARD))
	if not opened_with_key or not bool(exit_door.call("is_open")):
		_fail("Outer exit door did not open with the escape key.")
		return

	print("FOUR_ROOM_MVP_MONSTER_SET_VALIDATION PASS monsters=%d normal=%d nightmares=%d red=%s cabinet_key_parts=%d keyed_exit=true" % [
		monsters.size(),
		normal_count,
		nightmare_count,
		red_monster.name,
		key_parts,
	])
	quit(0)

func _monster_children(monster_root: Node) -> Array[CharacterBody3D]:
	var result: Array[CharacterBody3D] = []
	for child in monster_root.get_children():
		var monster := child as CharacterBody3D
		if monster != null:
			result.append(monster)
	return result

func _first_monster_except(monsters: Array[CharacterBody3D], excluded: CharacterBody3D) -> CharacterBody3D:
	for monster in monsters:
		if monster != excluded and not bool(monster.call("debug_is_dead")):
			return monster
	return null

func _forward_dot_to(source: Node3D, target: Node3D) -> float:
	var forward := -source.global_transform.basis.z
	forward.y = 0.0
	var to_target := target.global_position - source.global_position
	to_target.y = 0.0
	if forward.length_squared() <= 0.0001 or to_target.length_squared() <= 0.0001:
		return -1.0
	return forward.normalized().dot(to_target.normalized())

func _has_mesh(node: Node) -> bool:
	var mesh := node as MeshInstance3D
	if mesh != null and mesh.mesh != null:
		return true
	for child in node.get_children():
		if _has_mesh(child):
			return true
	return false

func _has_positive_scale(node: Node3D) -> bool:
	var scale := node.transform.basis.get_scale()
	return scale.x > 0.0 and scale.y > 0.0 and scale.z > 0.0

func _is_inside_mvp_rooms(position: Vector3) -> bool:
	var flat := Vector2(position.x, position.z)
	return flat.x >= ROOM_MIN.x and flat.x <= ROOM_MAX.x and flat.y >= ROOM_MIN.y and flat.y <= ROOM_MAX.y

func _is_on_door_center(position: Vector3) -> bool:
	var flat := Vector2(position.x, position.z)
	for door_center in DOOR_CENTERS:
		if flat.distance_to(door_center) < 0.82:
			return true
	return false

func _gold_key_mesh_count(root_node: Node) -> int:
	var count := 0
	for node in _all_nodes(root_node):
		var mesh := node as MeshInstance3D
		if mesh == null:
			continue
		var material := mesh.material_override as StandardMaterial3D
		if material == null:
			material = mesh.get_surface_override_material(0) as StandardMaterial3D
		if material == null:
			continue
		var color := material.albedo_color
		if color.r > 0.85 and color.g > 0.45 and color.b < 0.28:
			count += 1
	return count

func _all_nodes(root_node: Node) -> Array:
	var result := [root_node]
	for child in root_node.get_children():
		result.append_array(_all_nodes(child))
	return result

func _is_near_vec3(a: Vector3, b: Vector3, tolerance: float) -> bool:
	return (
		absf(a.x - b.x) <= tolerance
		and absf(a.y - b.y) <= tolerance
		and absf(a.z - b.z) <= tolerance
	)

func _fail(message: String) -> void:
	push_error("FOUR_ROOM_MVP_MONSTER_SET_VALIDATION FAIL: %s" % message)
	quit(1)
