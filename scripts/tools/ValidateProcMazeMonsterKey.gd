extends SceneTree

const SCENE_PATH := "res://scenes/tests/Test_ProcMazeMap.tscn"
const EXPECTED_MONSTER_COUNT := 6
const MonsterSizeSource = preload("res://scripts/monster/MonsterSizeSource.gd")
const TEMPLATE_BY_PROC_MONSTER := {
	"NightmareCreature_A": "nightmare",
	"NightmareCreature_B": "nightmare_b",
	"NightmareCreature_C": "nightmare",
	"NightmareCreature_D": "nightmare_b",
	"Monster_Red_Hunter_A": "red_hunter",
	"Monster_Red_Hunter_B": "red_hunter",
}

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load(SCENE_PATH) as PackedScene
	if packed == null:
		_fail("missing scene: %s" % SCENE_PATH)
		return
	var root := packed.instantiate() as Node3D
	if root == null:
		_fail("scene root is not Node3D")
		return
	get_root().add_child(root)
	if root.has_method("rebuild"):
		var result: Dictionary = root.rebuild()
		if not bool(result.get("ok", false)):
			_fail("proc maze rebuild failed before monster key validation")
			return
	await process_frame
	await physics_frame

	var monster_root := root.get_node_or_null("MonsterRoot") as Node3D
	if monster_root == null:
		_fail("MonsterRoot is missing")
		return
	var player := root.get_node_or_null("PlayerRoot/Player") as Node3D
	if player == null:
		_fail("PlayerRoot/Player is missing")
		return
	var monsters := _monster_children(monster_root)
	if monsters.size() != EXPECTED_MONSTER_COUNT:
		_fail("unexpected monster count: %d" % monsters.size())
		return

	var red_monsters: Array[Node3D] = []
	var normal_count := 0
	var nightmare_count := 0
	var max_monster_speed := 0.0
	for monster in monsters:
		var monster_scale := monster.transform.basis.get_scale()
		if not TEMPLATE_BY_PROC_MONSTER.has(String(monster.name)):
			_fail("unexpected proc-maze monster name: %s" % monster.name)
			return
		var template_id := String(TEMPLATE_BY_PROC_MONSTER[String(monster.name)])
		var expected_scale := MonsterSizeSource.template_scale(template_id)
		if not _is_near_vec3(monster_scale, expected_scale, 0.001):
			_fail("monster scale does not match MonsterSizeSource: %s scale=%s expected=%s" % [monster.name, monster_scale, expected_scale])
			return
		if not bool(monster.get("wander_cross_room_enabled")):
			_fail("monster cross-room patrol is disabled: %s" % monster.name)
			return
		max_monster_speed = maxf(max_monster_speed, float(monster.get("flee_speed")))
		max_monster_speed = maxf(max_monster_speed, float(monster.get("chase_speed")))
		max_monster_speed = maxf(max_monster_speed, float(monster.get("nightmare_locked_investigate_speed")))
		var role := String(monster.get_meta("monster_role", "normal"))
		if role == "red":
			red_monsters.append(monster)
		elif role == "nightmare":
			nightmare_count += 1
			if not monster.is_in_group("nightmare_monster"):
				_fail("nightmare monster is missing nightmare_monster group: %s" % monster.name)
				return
			if monster.get_node_or_null("NightmareSonarAudio") == null:
				_fail("nightmare monster is missing sonar audio: %s" % monster.name)
				return
			if bool(monster.call("debug_can_see_player")):
				_fail("nightmare monster should not use vision: %s" % monster.name)
				return
		else:
			normal_count += 1
	if red_monsters.size() != 2:
		_fail("expected two red vision monsters, found %d" % red_monsters.size())
		return
	if normal_count != 0:
		_fail("expected zero normal filler monsters in proc maze pressure test, found %d" % normal_count)
		return
	if nightmare_count != 4:
		_fail("expected four nightmare monsters, found %d" % nightmare_count)
		return
	for red_monster in red_monsters:
		if not red_monster.is_in_group("red_monster"):
			_fail("red monster is not in red_monster group: %s" % red_monster.name)
			return
		if bool(red_monster.get("attach_escape_key")) or bool(red_monster.get_meta("has_escape_key", false)):
			_fail("red hunter must not carry the escape key: %s" % red_monster.name)
			return
		if red_monster.get_node_or_null("ChestEscapeKey") != null:
			_fail("red hunter still has a chest key visual: %s" % red_monster.name)
			return
		if not _is_near_vec3(red_monster.transform.basis.get_scale(), MonsterSizeSource.template_scale("normal"), 0.001):
			_fail("red hunter no longer uses normal monster model scale: %s" % red_monster.name)
			return

	var player_sprint_speed := float(player.get("move_speed")) * float(player.get("sprint_multiplier"))
	if player_sprint_speed <= max_monster_speed + 0.25:
		_fail("player sprint speed must clearly exceed all monster speeds: player=%.2f monster=%.2f" % [player_sprint_speed, max_monster_speed])
		return

	print("PROC_MAZE_MONSTER_KEY_VALIDATION PASS monsters=%d normal=%d nightmare=%d red=%d carries_key=false red_model=normal player_sprint=%.2f max_monster=%.2f" % [
		monsters.size(),
		normal_count,
		nightmare_count,
		red_monsters.size(),
		player_sprint_speed,
		max_monster_speed,
	])
	quit(0)

func _monster_children(monster_root: Node) -> Array[Node3D]:
	var result: Array[Node3D] = []
	for child in monster_root.get_children():
		var monster := child as Node3D
		if monster != null:
			result.append(monster)
	return result

func _gold_key_mesh_count(root: Node) -> int:
	var count := 0
	for node in _all_nodes(root):
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

func _all_nodes(root: Node) -> Array:
	var result := [root]
	for child in root.get_children():
		result.append_array(_all_nodes(child))
	return result

func _is_near_vec3(a: Vector3, b: Vector3, tolerance: float) -> bool:
	return (
		absf(a.x - b.x) <= tolerance
		and absf(a.y - b.y) <= tolerance
		and absf(a.z - b.z) <= tolerance
	)

func _fail(message: String) -> void:
	push_error("PROC_MAZE_MONSTER_KEY_VALIDATION FAIL %s" % message)
	quit(1)
