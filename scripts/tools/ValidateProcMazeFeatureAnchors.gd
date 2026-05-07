extends SceneTree

const SCENE_PATH := "res://scenes/tests/Test_ProcMazeMap.tscn"
const MIN_FEATURE_ANCHORS := 4
const MAX_FEATURE_ANCHORS := 7
const MIN_DARK_ZONES := 4
const MAX_AMBIENT_ENERGY := 0.04
const REQUIRED_FEATURES := [
	"pillar_hall",
	"low_wall_maze_hall",
	"box_heap_hall",
	"dark_doorway_room",
	"split_hall",
	"side_chamber_hall",
	"red_alarm_hall",
]
const REQUIRED_DARK_ZONES := [
	"Dark_Doorway_Interior",
	"Dark_Corridor_End",
	"Dark_Turn_Corner",
	"Dark_BackRoom",
	"NoLight_Room",
]

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
	var result := {}
	if root.has_method("rebuild"):
		result = root.rebuild()
	if not bool(result.get("ok", false)):
		_fail("proc maze rebuild failed before feature-anchor validation")
		return
	await process_frame
	await physics_frame

	var feature_modules := _nodes_in_group(root, "proc_feature_anchor")
	var dark_modules := _nodes_in_group(root, "proc_dark_zone")
	var pillars := _nodes_in_group(root, "proc_feature_pillar")
	var low_walls := _nodes_in_group(root, "proc_feature_low_wall")
	var feature_props := _nodes_in_group(root, "proc_feature_prop")
	var red_lights := _nodes_in_group(root, "proc_red_alarm_light")
	var red_attractors := _nodes_in_group(root, "proc_red_alarm_attractor")
	var panels_by_owner := _nodes_by_owner(root, "ceiling_light_panel")
	var lights_by_owner := _nodes_by_owner(root, "ceiling_light")
	var feature_counts := _metadata_counts(feature_modules, "feature_template")
	var dark_counts := _metadata_counts(dark_modules, "dark_zone")

	if feature_modules.size() < MIN_FEATURE_ANCHORS or feature_modules.size() > MAX_FEATURE_ANCHORS:
		_fail("feature anchor count out of range: %d" % feature_modules.size())
		return
	for required_feature in REQUIRED_FEATURES:
		if int(feature_counts.get(required_feature, 0)) < 1:
			_fail("missing required feature room: %s" % required_feature)
			return
	if dark_modules.size() < MIN_DARK_ZONES:
		_fail("dark zone count too low: %d" % dark_modules.size())
		return
	for required_dark_zone in REQUIRED_DARK_ZONES:
		if int(dark_counts.get(required_dark_zone, 0)) < 1:
			_fail("missing required dark zone: %s" % required_dark_zone)
			return
	if pillars.size() < 4 or pillars.size() > 9:
		_fail("pillar_hall pillar count out of range: %d" % pillars.size())
		return
	if low_walls.size() < 4 or low_walls.size() > 8:
		_fail("low_wall_maze_hall half-wall count out of range: %d" % low_walls.size())
		return
	if red_lights.size() != 3:
		_fail("red alarm light count mismatch: %d" % red_lights.size())
		return
	if red_attractors.size() != 3:
		_fail("red alarm attractor count mismatch: %d" % red_attractors.size())
		return

	var box_props := []
	for prop in feature_props:
		var prop3d := prop as Node3D
		if prop3d != null and String(prop3d.get_meta("feature_template", "")) == "box_heap_hall":
			box_props.append(prop3d)
	if box_props.size() < 3 or box_props.size() > 7:
		_fail("box_heap_hall box count out of range: %d" % box_props.size())
		return
	if _props_are_row_aligned(box_props):
		_fail("box_heap_hall boxes are too row-aligned")
		return

	for module in dark_modules:
		var module3d := module as Node3D
		if module3d == null:
			continue
		var owner_id := String(module3d.get_meta("id", ""))
		if panels_by_owner.has(owner_id) or lights_by_owner.has(owner_id):
			_fail("dark zone has local ceiling light: %s" % owner_id)
			return

	var ambient_energy := _ambient_energy(root)
	if ambient_energy > MAX_AMBIENT_ENERGY:
		_fail("ambient energy too high: %.3f" % ambient_energy)
		return

	print("PROC_MAZE_FEATURE_ANCHOR_VALIDATION PASS features=%d dark_zones=%d pillars=%d low_walls=%d red_lights=%d red_attractors=%d feature_props=%d box_props=%d ambient=%.3f" % [
		feature_modules.size(),
		dark_modules.size(),
		pillars.size(),
		low_walls.size(),
		red_lights.size(),
		red_attractors.size(),
		feature_props.size(),
		box_props.size(),
		ambient_energy,
	])
	quit(0)

func _metadata_counts(nodes: Array, meta_name: String) -> Dictionary:
	var result := {}
	for node in nodes:
		var node3d := node as Node3D
		if node3d == null:
			continue
		var value := String(node3d.get_meta(meta_name, ""))
		if value.is_empty():
			continue
		result[value] = int(result.get(value, 0)) + 1
	return result

func _nodes_by_owner(root: Node, group_name: String) -> Dictionary:
	var result := {}
	for node in _nodes_in_group(root, group_name):
		var node3d := node as Node3D
		if node3d == null:
			continue
		var owner_id := String(node3d.get_meta("owner_module_id", ""))
		if owner_id.is_empty():
			continue
		result[owner_id] = true
	return result

func _props_are_row_aligned(props: Array) -> bool:
	if props.size() < 3:
		return false
	var min_x := INF
	var max_x := -INF
	var min_z := INF
	var max_z := -INF
	for prop in props:
		var prop3d := prop as Node3D
		if prop3d == null:
			continue
		var position := prop3d.global_position
		min_x = minf(min_x, position.x)
		max_x = maxf(max_x, position.x)
		min_z = minf(min_z, position.z)
		max_z = maxf(max_z, position.z)
	return max_x - min_x < 0.35 or max_z - min_z < 0.35

func _ambient_energy(root: Node) -> float:
	var world_environment := _find_world_environment(root)
	if world_environment == null or world_environment.environment == null:
		return INF
	return world_environment.environment.ambient_light_energy

func _find_world_environment(root: Node) -> WorldEnvironment:
	var world_environment := root as WorldEnvironment
	if world_environment != null:
		return world_environment
	for child in root.get_children():
		var found := _find_world_environment(child)
		if found != null:
			return found
	return null

func _nodes_in_group(root: Node, group_name: String) -> Array:
	var result := []
	_collect_nodes_in_group(root, group_name, result)
	return result

func _collect_nodes_in_group(node: Node, group_name: String, result: Array) -> void:
	if node.is_in_group(group_name):
		result.append(node)
	for child in node.get_children():
		_collect_nodes_in_group(child, group_name, result)

func _fail(message: String) -> void:
	push_error("PROC_MAZE_FEATURE_ANCHOR_VALIDATION FAIL %s" % message)
	quit(1)
