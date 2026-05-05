@tool
extends Node3D

const ModuleRegistry = preload("res://scripts/proc_maze/ModuleRegistry.gd")
const MapGraphGenerator = preload("res://scripts/proc_maze/MapGraphGenerator.gd")
const MapValidator = preload("res://scripts/proc_maze/MapValidator.gd")
const ProcMazeSceneBuilder = preload("res://scripts/proc_maze/ProcMazeSceneBuilder.gd")
const SceneValidator = preload("res://scripts/proc_maze/SceneValidator.gd")
const DebugView = preload("res://scripts/proc_maze/DebugView.gd")
const PlayerScene = preload("res://scenes/modules/PlayerModule.tscn")
const MonsterScene = preload("res://scenes/modules/MonsterModule.tscn")
const MonsterSizeSource = preload("res://scripts/monster/MonsterSizeSource.gd")
const CameraControllerScript = preload("res://scripts/camera/CameraController.gd")
const LightingControllerScript = preload("res://scripts/lighting/LightingController.gd")
const LightingTuningPanelScript = preload("res://scripts/lighting/LightingTuningPanel.gd")
const ForegroundOcclusionScript = preload("res://scripts/camera/ForegroundOcclusion.gd")

const PREVIEW_CELL_SIZE := 2.5

@export var registry_path = "res://data/proc_maze/module_registry.json"
@export var seed = 2026050401
@export var max_seed_retries = 20
@export var enable_playable_test := true
@export var preview_without_ceiling := false
@export var preview_keep_ceiling_lights := true
@export var preview_full_map_camera := false
@export var last_result = {}

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if enable_playable_test:
		call_deferred("_setup_playable_test")

func rebuild() -> Dictionary:
	var registry = ModuleRegistry.new()
	if not registry.load_from_path(registry_path):
		last_result = {
			"ok": false,
			"stage": "ModuleRegistry",
			"issues": registry.errors,
		}
		_print_result(last_result)
		return last_result

	var generator = MapGraphGenerator.new(registry)
	var map_validator = MapValidator.new()
	var graph = {}
	var map_validation = {}
	var selected_seed = seed
	var attempts = []

	for attempt in range(max_seed_retries):
		selected_seed = seed + attempt
		graph = generator.generate_fixed(selected_seed)
		map_validation = map_validator.validate(graph, registry)
		attempts.append({"seed": selected_seed, "ok": bool(map_validation["ok"]), "issues": map_validation.get("issues", [])})
		if bool(map_validation["ok"]):
			break

	if graph.is_empty() or not bool(map_validation.get("ok", false)):
		last_result = {
			"ok": false,
			"stage": "MapValidator",
			"seed": selected_seed,
			"generator_version": MapGraphGenerator.GENERATOR_VERSION,
			"attempts": attempts,
			"issues": map_validation.get("issues", []),
		}
		_print_result(last_result)
		return last_result

	var builder = ProcMazeSceneBuilder.new()
	builder.include_ceilings = not preview_without_ceiling
	builder.include_ceiling_lights = true
	if preview_without_ceiling:
		builder.include_ceiling_lights = preview_keep_ceiling_lights
	var build_summary = builder.build(self, graph, registry)
	var scene_validator = SceneValidator.new()
	var scene_validation = scene_validator.validate(self, graph, map_validation)
	DebugView.new().build(self, graph, scene_validation)
	if enable_playable_test:
		_setup_playable_test()
	else:
		_remove_playable_test_nodes()
	if preview_full_map_camera:
		_configure_full_map_preview_camera(graph)

	var metrics: Dictionary = map_validation.get("metrics", {})
	var scene_metrics: Dictionary = scene_validation.get("metrics", {})
	last_result = {
		"ok": bool(scene_validation.get("ok", false)),
		"stage": "SceneValidator" if not bool(scene_validation.get("ok", false)) else "PASS",
		"seed": selected_seed,
		"generator_version": MapGraphGenerator.GENERATOR_VERSION,
		"total_rooms": int(metrics.get("total_nodes", 0)),
		"main_path_length": int(metrics.get("main_path_length", 0)),
		"branch_count": int(metrics.get("branch_count", 0)),
		"loop_count": int(metrics.get("loop_count", 0)),
		"macro_loop_count": int(metrics.get("macro_loop_count", 0)),
		"macro_cycle_length": int(metrics.get("macro_cycle_length", 0)),
		"largest_simple_cycle_length": int(metrics.get("largest_simple_cycle_length", 0)),
		"macro_route_a_length": int(metrics.get("macro_route_a_length", 0)),
		"macro_route_b_length": int(metrics.get("macro_route_b_length", 0)),
		"small_loop_count": int(metrics.get("small_loop_count", 0)),
		"dead_end_count": int(metrics.get("dead_end_count", 0)),
		"large_room_count": int(metrics.get("large_room_count", 0)),
		"long_corridor_count": int(metrics.get("long_corridor_count", 0)),
		"l_turn_count": int(metrics.get("l_turn_count", 0)),
		"l_room_count": int(metrics.get("l_room_count", 0)),
		"internal_large_count": int(metrics.get("internal_large_count", 0)),
		"hub_count": int(metrics.get("hub_count", 0)),
		"plain_rect_count": int(metrics.get("plain_rect_count", 0)),
		"special_count": int(metrics.get("special_count", 0)),
		"narrow_corridor_count": int(metrics.get("narrow_corridor_count", 0)),
		"normal_corridor_count": int(metrics.get("normal_corridor_count", 0)),
		"normal_room_count": int(metrics.get("normal_room_count", 0)),
		"large_width_count": int(metrics.get("large_width_count", 0)),
		"hub_width_count": int(metrics.get("hub_width_count", 0)),
		"entrance_to_exit_reachable": true,
		"has_overlap": bool(scene_metrics.get("has_overlap", false)),
		"has_door_to_wall": bool(scene_metrics.get("has_door_to_wall", false)),
		"has_door_reveal_blocker": bool(scene_metrics.get("has_door_reveal_blocker", false)),
		"fps": float(scene_metrics.get("fps", 0.0)),
		"draw_calls": int(scene_metrics.get("draw_calls", 0)),
		"active_light_count": int(scene_metrics.get("active_light_count", 0)),
		"active_light_fixture_count": int(scene_metrics.get("active_light_fixture_count", scene_metrics.get("active_light_count", 0))),
		"active_light_source_count": int(scene_metrics.get("active_light_source_count", scene_metrics.get("active_light_count", 0))),
		"preview_without_ceiling": preview_without_ceiling,
		"preview_full_map_camera": preview_full_map_camera,
		"issues": scene_validation.get("issues", []),
		"build_summary": build_summary,
		"attempts": attempts,
	}
	set_meta("proc_maze_last_result", last_result)
	_print_result(last_result)
	return last_result

func _print_result(result: Dictionary) -> void:
	print("PROC_MAZE_RESULT_BEGIN")
	for key in [
		"ok",
		"stage",
		"seed",
		"generator_version",
		"total_rooms",
		"main_path_length",
		"branch_count",
		"loop_count",
		"macro_loop_count",
		"macro_cycle_length",
		"largest_simple_cycle_length",
		"macro_route_a_length",
		"macro_route_b_length",
		"small_loop_count",
		"dead_end_count",
		"large_room_count",
		"long_corridor_count",
		"l_turn_count",
		"l_room_count",
		"internal_large_count",
		"hub_count",
		"plain_rect_count",
		"special_count",
		"narrow_corridor_count",
		"normal_corridor_count",
		"normal_room_count",
		"large_width_count",
		"hub_width_count",
		"entrance_to_exit_reachable",
		"has_overlap",
		"has_door_to_wall",
		"has_door_reveal_blocker",
		"fps",
		"draw_calls",
		"active_light_count",
		"active_light_source_count",
	]:
		if result.has(key):
			print("%s=%s" % [key, str(result[key])])
	var issues: Array = result.get("issues", [])
	print("issue_count=%d" % issues.size())
	for issue in issues:
		print("issue=%s" % issue)
	print("PROC_MAZE_RESULT_END")

func _remove_playable_test_nodes() -> void:
	for child_name in ["Systems", "PlayerRoot", "CameraRig", "MonsterRoot"]:
		var child = get_node_or_null(child_name)
		if child != null:
			child.free()

func _configure_full_map_preview_camera(graph: Dictionary) -> void:
	var camera = get_node_or_null("Camera3D") as Camera3D
	if camera == null:
		camera = Camera3D.new()
		camera.name = "Camera3D"
		add_child(camera)
	var bounds = _graph_world_bounds(graph.get("nodes", []))
	var center = Vector3(
		(bounds.position.x + bounds.end.x) * 0.5,
		0.0,
		(bounds.position.y + bounds.end.y) * 0.5
	)
	var max_size = maxf(bounds.size.x, bounds.size.y)
	var height = maxf(38.0, max_size * 0.95)
	var backward = maxf(28.0, max_size * 0.55)
	camera.current = true
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = max_size * 1.18
	camera.far = 220.0
	camera.near = 0.05
	camera.position = center + Vector3(0.0, height, backward)
	camera.look_at_from_position(camera.position, center + Vector3(0.0, 0.4, 0.0), Vector3.UP)
	camera.set_meta("preview_camera", true)
	camera.set_meta("preview_camera_mode", "no_ceiling_full_map")
	camera.set_meta("preview_bounds", bounds)

func _setup_playable_test() -> void:
	_ensure_runtime_systems()
	var player = _ensure_player()
	var camera_rig = _ensure_camera_rig()
	_place_player_at_entrance(player)
	_ensure_proc_maze_monsters()
	_configure_gameplay_cameras(camera_rig)
	_snap_camera_to_player(camera_rig)

func _ensure_runtime_systems() -> void:
	var systems = _get_or_create_node(self, "Systems")
	var lighting = systems.get_node_or_null("LightingController")
	if lighting == null:
		lighting = Node.new()
		lighting.name = "LightingController"
		systems.add_child(lighting)
	lighting.set_script(LightingControllerScript)

	var tuning_panel = systems.get_node_or_null("LightingTuningPanel")
	if tuning_panel == null:
		tuning_panel = CanvasLayer.new()
		tuning_panel.name = "LightingTuningPanel"
		systems.add_child(tuning_panel)
	tuning_panel.set_script(LightingTuningPanelScript)

	var occlusion = systems.get_node_or_null("ForegroundOcclusion")
	if occlusion == null:
		occlusion = Node.new()
		occlusion.name = "ForegroundOcclusion"
		systems.add_child(occlusion)
	occlusion.process_priority = 100
	occlusion.set_script(ForegroundOcclusionScript)
	occlusion.set("camera_path", NodePath("../../CameraRig/Camera3D"))
	occlusion.set("target_path", NodePath("../../PlayerRoot/Player"))

func _ensure_player() -> Node3D:
	var player_root = _get_or_create_node3d(self, "PlayerRoot")
	var player = player_root.get_node_or_null("Player") as Node3D
	if player != null:
		return player
	player = PlayerScene.instantiate() as Node3D
	player.name = "Player"
	player_root.add_child(player)
	return player

func _ensure_camera_rig() -> Node3D:
	var camera_rig = _get_or_create_node3d(self, "CameraRig")
	camera_rig.set_script(CameraControllerScript)
	camera_rig.set("target_path", NodePath("../PlayerRoot/Player"))
	camera_rig.set("distance", 1.8)
	camera_rig.set("target_height", 1.0)
	camera_rig.set("look_ahead", 0.85)
	camera_rig.set("initial_yaw_degrees", 90.0)
	camera_rig.set("pitch_degrees", 3.0)
	camera_rig.set("min_pitch_degrees", -5.0)
	camera_rig.set("max_pitch_degrees", 12.0)
	camera_rig.set("follow_smoothing", 18.0)
	camera_rig.set("_yaw", deg_to_rad(90.0))
	camera_rig.set("_pitch", deg_to_rad(3.0))

	var camera = camera_rig.get_node_or_null("Camera3D") as Camera3D
	if camera == null:
		camera = Camera3D.new()
		camera.name = "Camera3D"
		camera_rig.add_child(camera)
	camera.current = true
	camera.fov = 62.0
	return camera_rig

func _place_player_at_entrance(player: Node3D) -> void:
	if player == null:
		return
	var marker = _find_marker_by_type("Entrance")
	if marker == null:
		return
	var player_parent = player.get_parent() as Node3D
	var spawn_position = _get_root_relative_position(marker)
	spawn_position.y = maxf(spawn_position.y, 0.05)
	if player_parent != null:
		player.position = spawn_position - _get_root_relative_position(player_parent)
	else:
		player.position = spawn_position

func _ensure_proc_maze_monsters() -> void:
	var monster_root := _get_or_create_node3d(self, "MonsterRoot")
	_clear_children(monster_root)
	var spawn_specs := _choose_proc_maze_monster_spawns()
	for spec in spawn_specs:
		var template_id := String(spec.get("template_id", "normal"))
		var monster := MonsterSizeSource.instantiate_template(template_id)
		if monster == null:
			monster = MonsterScene.instantiate() as Node3D
		if monster == null:
			continue
		var role := String(spec.get("role", "normal"))
		var spawn_position: Vector3 = spec.get("position", Vector3.ZERO)
		var character := monster as CharacterBody3D
		if character != null:
			character.velocity = Vector3.ZERO
		monster.name = String(spec.get("name", "Monster"))
		monster.set("monster_role", role)
		monster.set("attach_escape_key", bool(spec.get("attach_escape_key", false)))
		monster.set_meta("monster_role", role)
		monster.set_meta("proc_maze_spawn_id", String(spec.get("source_module_id", "")))
		if role == "red":
			monster.add_to_group("red_monster", true)
			if bool(spec.get("attach_escape_key", false)):
				monster.set_meta("has_escape_key", true)
			elif monster.has_meta("has_escape_key"):
				monster.remove_meta("has_escape_key")
		elif role == "nightmare":
			monster.add_to_group("nightmare_monster", true)
		monster.position = spawn_position - _get_root_relative_position(monster_root)
		monster.rotation.y = float(spec.get("yaw", 0.0))
		monster.set_meta("default_size_source", MonsterSizeSource.template_source_reference(template_id))
		monster_root.add_child(monster)

func _choose_proc_maze_monster_spawns() -> Array[Dictionary]:
	var candidates := _collect_monster_spawn_candidates()
	if candidates.is_empty():
		return []
	var entrance_position := _marker_position("Entrance")
	var red_candidate: Dictionary = candidates[0]
	var normal_a: Dictionary = candidates[min(1, candidates.size() - 1)]
	var normal_b: Dictionary = candidates[min(2, candidates.size() - 1)]
	var nightmare_a: Dictionary = candidates[min(3, candidates.size() - 1)]
	var nightmare_b: Dictionary = candidates[min(4, candidates.size() - 1)]
	var normal_a_position := _monster_spawn_position(normal_a, 0)
	var normal_b_position := _monster_spawn_position(normal_b, 1)
	var nightmare_a_position := _monster_spawn_position(nightmare_a, 2)
	var nightmare_b_position := _monster_spawn_position(nightmare_b, 3)
	var red_position := _monster_spawn_position(red_candidate, 4)
	return [
		{
			"name": "Monster",
			"template_id": "normal",
			"role": "normal",
			"attach_escape_key": false,
			"position": normal_a_position,
			"yaw": _yaw_facing_toward(normal_a_position, entrance_position),
			"source_module_id": String(normal_a.get("id", "")),
		},
		{
			"name": "Monster_Normal_B",
			"template_id": "normal_b",
			"role": "normal",
			"attach_escape_key": false,
			"position": normal_b_position,
			"yaw": _yaw_facing_toward(normal_b_position, entrance_position),
			"source_module_id": String(normal_b.get("id", "")),
		},
		{
			"name": "NightmareCreature_A",
			"template_id": "nightmare",
			"role": "nightmare",
			"attach_escape_key": false,
			"position": nightmare_a_position,
			"yaw": _yaw_facing_toward(nightmare_a_position, entrance_position),
			"source_module_id": String(nightmare_a.get("id", "")),
		},
		{
			"name": "NightmareCreature_B",
			"template_id": "nightmare_b",
			"role": "nightmare",
			"attach_escape_key": false,
			"position": nightmare_b_position,
			"yaw": _yaw_facing_toward(nightmare_b_position, entrance_position),
			"source_module_id": String(nightmare_b.get("id", "")),
		},
		{
			"name": "Monster_Red_Hunter",
			"template_id": "red_hunter",
			"role": "red",
			"attach_escape_key": false,
			"position": red_position,
			"yaw": _yaw_facing_toward(red_position, entrance_position),
			"source_module_id": String(red_candidate.get("id", "")),
		},
	]

func _collect_monster_spawn_candidates() -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	var modules_root := get_node_or_null("LevelRoot/Geometry/Modules") as Node3D
	if modules_root == null:
		return candidates
	var entrance_marker := _find_marker_by_type("Entrance")
	var exit_marker := _find_marker_by_type("Exit")
	var entrance_id := String(entrance_marker.get("room_id")) if entrance_marker != null else ""
	var exit_id := String(exit_marker.get("room_id")) if exit_marker != null else ""
	var entrance_position := _get_root_relative_position(entrance_marker) if entrance_marker != null else Vector3.ZERO
	for child in modules_root.get_children():
		var module := child as Node3D
		if module == null:
			continue
		var module_id := String(module.get_meta("id", ""))
		if module_id.is_empty() or module_id == entrance_id or module_id == exit_id:
			continue
		var kind := String(module.get_meta("space_kind", ""))
		if kind in ["narrow_corridor", "long_corridor", "l_turn", "junction", "offset_corridor"]:
			continue
		var module_position := _get_root_relative_position(module)
		var score := module_position.distance_to(entrance_position)
		if kind == "special":
			score += 40.0
		elif kind == "large_internal" or kind == "hub":
			score += 28.0
		elif String(module.get_meta("type", "")) == "room":
			score += 12.0
		if bool(module.get_meta("is_dead_end", false)):
			score += 6.0
		candidates.append({
			"id": module_id,
			"position": module_position,
			"score": score,
			"space_kind": kind,
		})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("score", 0.0)) > float(b.get("score", 0.0))
	)
	return candidates

func _monster_spawn_position(candidate: Dictionary, offset_index: int) -> Vector3:
	var position: Vector3 = candidate.get("position", Vector3.ZERO)
	var offsets := [
		Vector3(0.46, 0.0, 0.38),
		Vector3(-0.48, 0.0, 0.34),
		Vector3(0.18, 0.0, -0.48),
		Vector3(-0.24, 0.0, -0.42),
		Vector3(0.0, 0.0, 0.0),
	]
	position += offsets[offset_index % offsets.size()]
	position.y = 0.05
	return position

func _marker_position(marker_type: String) -> Vector3:
	var marker := _find_marker_by_type(marker_type)
	if marker == null:
		return Vector3.ZERO
	return _get_root_relative_position(marker)

func _yaw_facing_toward(from_position: Vector3, to_position: Vector3) -> float:
	var direction := to_position - from_position
	direction.y = 0.0
	if direction.length_squared() <= 0.0001:
		return 0.0
	direction = direction.normalized()
	return atan2(-direction.x, -direction.z)

func _find_marker_by_type(marker_type: String) -> Node3D:
	var markers = get_node_or_null("LevelRoot/Markers")
	if markers == null:
		return null
	for marker in markers.get_children():
		var marker_node = marker as Node3D
		if marker_node == null:
			continue
		if String(marker_node.get("marker_type")) == marker_type:
			return marker_node
	return null

func _configure_gameplay_cameras(camera_rig: Node3D) -> void:
	var overview_camera = get_node_or_null("Camera3D") as Camera3D
	if overview_camera != null:
		overview_camera.current = false
	var gameplay_camera = camera_rig.get_node_or_null("Camera3D") as Camera3D
	if gameplay_camera != null:
		gameplay_camera.current = true

func _snap_camera_to_player(camera_rig: Node3D) -> void:
	if camera_rig != null and camera_rig.is_inside_tree() and camera_rig.has_method("snap_to_target"):
		camera_rig.snap_to_target()

func _get_root_relative_position(node: Node3D) -> Vector3:
	var chain: Array[Node3D] = []
	var current: Node = node
	while current != null and current != self:
		var current_node3d = current as Node3D
		if current_node3d != null:
			chain.push_front(current_node3d)
		current = current.get_parent()

	var transform = Transform3D.IDENTITY
	for item in chain:
		transform *= item.transform
	return transform.origin

func _graph_world_bounds(nodes: Array) -> Rect2:
	var initialized = false
	var min_x = 0.0
	var min_z = 0.0
	var max_x = 0.0
	var max_z = 0.0
	for node in nodes:
		var footprint: Dictionary = node.get("footprint", {})
		var x0 = float(int(footprint.get("x", 0))) * PREVIEW_CELL_SIZE
		var z0 = float(int(footprint.get("z", 0))) * PREVIEW_CELL_SIZE
		var x1 = float(int(footprint.get("x", 0)) + int(footprint.get("w", 1))) * PREVIEW_CELL_SIZE
		var z1 = float(int(footprint.get("z", 0)) + int(footprint.get("h", 1))) * PREVIEW_CELL_SIZE
		if not initialized:
			min_x = x0
			min_z = z0
			max_x = x1
			max_z = z1
			initialized = true
		else:
			min_x = minf(min_x, x0)
			min_z = minf(min_z, z0)
			max_x = maxf(max_x, x1)
			max_z = maxf(max_z, z1)
	return Rect2(Vector2(min_x, min_z), Vector2(max_x - min_x, max_z - min_z))

func _get_or_create_node(parent: Node, child_name: String) -> Node:
	var existing = parent.get_node_or_null(child_name)
	if existing != null:
		return existing
	var created = Node.new()
	created.name = child_name
	parent.add_child(created)
	return created

func _get_or_create_node3d(parent: Node, child_name: String) -> Node3D:
	var existing = parent.get_node_or_null(child_name) as Node3D
	if existing != null:
		return existing
	var created = Node3D.new()
	created.name = child_name
	parent.add_child(created)
	return created

func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.free()
