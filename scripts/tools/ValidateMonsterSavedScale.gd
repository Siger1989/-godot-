extends SceneTree

const SCENE_PATH := "res://scenes/mvp/FourRoomMVP.tscn"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene_resource := load(SCENE_PATH) as PackedScene
	if scene_resource == null:
		_fail("Failed to load %s." % SCENE_PATH)
		return

	var scene := scene_resource.instantiate() as Node3D
	var monster_root := scene.get_node_or_null("MonsterRoot") as Node3D
	if monster_root == null:
		_fail("MonsterRoot is missing before scene enters tree.")
		return
	if not monster_root.scene_file_path.is_empty():
		_fail("MonsterRoot must be a direct editable node before scene enters tree.")
		return
	if not bool(monster_root.get_meta("mvp_editable_monster_root", false)):
		_fail("MonsterRoot is not marked as the direct editable MVP monster root.")
		return
	var saved_monster := scene.get_node_or_null("MonsterRoot/Monster") as Node3D
	if saved_monster == null:
		_fail("Monster node is missing before scene enters tree.")
		return
	var saved_scale := saved_monster.transform.basis.get_scale()

	root.add_child(scene)
	await process_frame

	var runtime_monster := scene.get_node_or_null("MonsterRoot/Monster") as Node3D
	var spawn := scene.get_node_or_null("LevelRoot/Markers/Spawn_Monster_D") as Node3D
	if runtime_monster == null or spawn == null:
		_fail("Monster or monster spawn is missing after scene startup.")
		return
	runtime_monster.set_physics_process(false)

	var runtime_scale := runtime_monster.transform.basis.get_scale()
	if not _is_near_vec3(runtime_scale, saved_scale, 0.001):
		_fail("Runtime monster scale changed from saved scene scale. saved=%s runtime=%s." % [saved_scale, runtime_scale])
		return
	if runtime_monster.global_position.distance_to(spawn.global_position) > 0.05:
		_fail("Monster was not placed at spawn after preserving scale.")
		return

	print("MONSTER_SAVED_SCALE_VALIDATION PASS saved_scale=%s runtime_scale=%s" % [saved_scale, runtime_scale])
	quit(0)

func _is_near_vec3(a: Vector3, b: Vector3, tolerance: float) -> bool:
	return (
		absf(a.x - b.x) <= tolerance
		and absf(a.y - b.y) <= tolerance
		and absf(a.z - b.z) <= tolerance
	)

func _fail(message: String) -> void:
	push_error("MONSTER_SAVED_SCALE_VALIDATION FAIL: %s" % message)
	quit(1)
