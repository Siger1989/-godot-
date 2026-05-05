extends SceneTree

const GrimeOverlayBuilder = preload("res://scripts/visual/GrimeOverlayBuilder.gd")

const SOURCE_SCENE_PATH := "res://scenes/mvp/experiments/FourRoomMVP_contact_ao_experiment.tscn"
const EXPERIMENT_SCENE_PATH := "res://scenes/mvp/experiments/FourRoomMVP_grime_experiment.tscn"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_ensure_experiment_dir()

	var packed := load(SOURCE_SCENE_PATH) as PackedScene
	if packed == null:
		_fail("Failed to load %s. Run BakeContactAOExperiment first." % SOURCE_SCENE_PATH)
		return

	var scene := packed.instantiate() as Node3D
	if scene == null:
		_fail("Failed to instantiate %s." % SOURCE_SCENE_PATH)
		return

	scene.name = "FourRoomMVP_GrimeExperiment"
	scene.set("build_on_ready", false)
	root.add_child(scene)
	current_scene = scene
	await process_frame

	var builder := GrimeOverlayBuilder.new()
	var stats := builder.build(scene)
	_add_experiment_marker(scene, stats)
	_assign_owned_generated_nodes(scene)

	var repacked := PackedScene.new()
	var pack_result := repacked.pack(scene)
	if pack_result != OK:
		_fail("PackedScene.pack failed with code %d." % pack_result)
		return
	var save_result := ResourceSaver.save(repacked, EXPERIMENT_SCENE_PATH)
	if save_result != OK:
		_fail("ResourceSaver.save failed with code %d." % save_result)
		return

	print("GRIME_EXPERIMENT_BAKE PASS path=%s ceiling=%d baseboard=%d corner=%d total=%d" % [
		EXPERIMENT_SCENE_PATH,
		int(stats[GrimeOverlayBuilder.TYPE_CEILING_EDGE]),
		int(stats[GrimeOverlayBuilder.TYPE_BASEBOARD]),
		int(stats[GrimeOverlayBuilder.TYPE_CORNER]),
		int(stats["total"]),
	])
	quit(0)

func _add_experiment_marker(scene: Node3D, stats: Dictionary) -> void:
	var level_root := scene.get_node_or_null("LevelRoot") as Node3D
	if level_root == null:
		return
	var old_marker := level_root.get_node_or_null("Experiment_Grime")
	if old_marker != null:
		old_marker.free()
	var marker := Node3D.new()
	marker.name = "Experiment_Grime"
	marker.set_meta("source_scene", SOURCE_SCENE_PATH)
	marker.set_meta("rule", "Global reusable grime overlay experiment. Keep AO/contact darkening separate.")
	marker.set_meta("ceiling_edge_count", int(stats[GrimeOverlayBuilder.TYPE_CEILING_EDGE]))
	marker.set_meta("baseboard_count", int(stats[GrimeOverlayBuilder.TYPE_BASEBOARD]))
	marker.set_meta("corner_count", int(stats[GrimeOverlayBuilder.TYPE_CORNER]))
	marker.set_meta("total_count", int(stats["total"]))
	level_root.add_child(marker)

func _ensure_experiment_dir() -> void:
	var dir := DirAccess.open("res://")
	if dir == null:
		return
	if not dir.dir_exists("scenes/mvp/experiments"):
		dir.make_dir_recursive("scenes/mvp/experiments")

func _assign_owned_generated_nodes(scene: Node) -> void:
	for target_path in [
		"LevelRoot/Geometry/GrimeOverlays",
		"LevelRoot/Experiment_Grime",
	]:
		var target := scene.get_node_or_null(target_path)
		if target != null:
			_assign_owner_recursive(target, scene)

func _assign_owner_recursive(node: Node, owner_root: Node) -> void:
	node.owner = owner_root
	if not node.scene_file_path.is_empty():
		return
	for child in node.get_children():
		_assign_owner_recursive(child, owner_root)

func _fail(message: String) -> void:
	push_error("GRIME_EXPERIMENT_BAKE FAIL: %s" % message)
	quit(1)
