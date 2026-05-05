extends SceneTree

const SCENE_PATH := "res://scenes/tests/Test_ProcMazeMap.tscn"
const EXPECTED_MONSTER_COUNT := 5
const MonsterSizeSource = preload("res://scripts/monster/MonsterSizeSource.gd")
const TEMPLATE_BY_PROC_MONSTER := {
	"Monster": "normal",
	"Monster_Normal_B": "normal_b",
	"NightmareCreature_A": "nightmare",
	"NightmareCreature_B": "nightmare_b",
	"Monster_Red_Hunter": "red_hunter",
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
	var monsters := _monster_children(monster_root)
	if monsters.size() != EXPECTED_MONSTER_COUNT:
		_fail("unexpected monster count: %d" % monsters.size())
		return

	var red_monster: Node3D = null
	var normal_count := 0
	var nightmare_count := 0
	for monster in monsters:
		var monster_scale := monster.transform.basis.get_scale()
		var template_id := String(TEMPLATE_BY_PROC_MONSTER.get(String(monster.name), "normal"))
		var expected_scale := MonsterSizeSource.template_scale(template_id)
		if not _is_near_vec3(monster_scale, expected_scale, 0.001):
			_fail("monster scale does not match MonsterSizeSource: %s scale=%s expected=%s" % [monster.name, monster_scale, expected_scale])
			return
		var role := String(monster.get_meta("monster_role", "normal"))
		if role == "red":
			red_monster = monster
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
	if red_monster == null:
		_fail("red monster is missing")
		return
	if normal_count != 2:
		_fail("expected two normal monsters, found %d" % normal_count)
		return
	if nightmare_count != 2:
		_fail("expected two nightmare monsters, found %d" % nightmare_count)
		return
	if not red_monster.is_in_group("red_monster"):
		_fail("red monster is not in red_monster group")
		return
	if bool(red_monster.get("attach_escape_key")) or bool(red_monster.get_meta("has_escape_key", false)):
		_fail("red hunter must not carry the escape key")
		return
	if not _has_red_body_material(red_monster):
		_fail("red monster body material is not visibly red")
		return
	if red_monster.get_node_or_null("ChestEscapeKey") != null:
		_fail("red hunter still has a chest key visual")
		return

	print("PROC_MAZE_MONSTER_KEY_VALIDATION PASS monsters=%d normal=%d nightmare=%d red=%s carries_key=false scale=%s" % [
		monsters.size(),
		normal_count,
		nightmare_count,
		red_monster.name,
		MonsterSizeSource.template_scale("normal"),
	])
	quit(0)

func _monster_children(monster_root: Node) -> Array[Node3D]:
	var result: Array[Node3D] = []
	for child in monster_root.get_children():
		var monster := child as Node3D
		if monster != null:
			result.append(monster)
	return result

func _has_red_body_material(root: Node) -> bool:
	for node in _all_nodes(root):
		var mesh := node as MeshInstance3D
		if mesh == null:
			continue
		if not String(mesh.get_path()).contains("ModelRoot"):
			continue
		var material := mesh.material_override as StandardMaterial3D
		if material == null:
			continue
		var color := material.albedo_color
		if color.r > 0.55 and color.g < 0.18 and color.b < 0.16:
			return true
	return false

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
