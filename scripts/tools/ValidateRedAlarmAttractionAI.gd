extends SceneTree

const SCENE_PATH := "res://scenes/tests/Test_ProcMazeMap.tscn"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load(SCENE_PATH) as PackedScene
	if packed == null:
		_fail("missing scene")
		return
	var root := packed.instantiate() as Node3D
	if root == null:
		_fail("scene root is not Node3D")
		return
	get_root().add_child(root)
	if root.has_method("rebuild"):
		var result: Dictionary = root.rebuild()
		if not bool(result.get("ok", false)):
			_fail("proc maze rebuild failed")
			return
	await process_frame
	await physics_frame

	var attractor := _find_red_alarm_attractor(root, "W47")
	var monster := _first_monster(root)
	var player := root.get_node_or_null("PlayerRoot/Player") as CharacterBody3D
	var monster_start := root.get_node_or_null("LevelRoot/Areas/Area_W42") as Node3D
	if attractor == null or monster == null or player == null or monster_start == null:
		_fail("missing attractor, monster, player, or W42 area")
		return
	if not attractor.has_method("debug_has_alarm_audio") or not bool(attractor.call("debug_has_alarm_audio")):
		_fail("red alarm attractor is missing a generated 3D alarm sound")
		return
	if not attractor.has_method("debug_linked_alarm_light_count") or int(attractor.call("debug_linked_alarm_light_count")) <= 0:
		_fail("red alarm attractor has no linked room light")
		return
	if bool(attractor.call("debug_any_alarm_light_visible")):
		_fail("red alarm light is visible before the player activates it")
		return
	player.global_position = Vector3(80.0, 0.05, 80.0)
	player.velocity = Vector3.ZERO
	player.set_physics_process(false)
	monster.global_position = monster_start.global_position + Vector3(0.0, 0.05, 0.0)
	monster.velocity = Vector3.ZERO
	attractor.call("activate")
	if not bool(attractor.call("debug_is_alarm_audio_playing")):
		_fail("red alarm audio did not start when alarm activated")
		return
	if not bool(attractor.call("debug_any_alarm_light_visible")):
		_fail("red alarm light did not turn on when alarm activated")
		return
	if float(attractor.call("debug_first_alarm_light_energy")) < 1.4:
		_fail("active red alarm light is too dim to light the room")
		return
	if float(attractor.call("debug_first_alarm_light_range")) < 6.0:
		_fail("active red alarm light range is too small for a room-scale alarm glow")
		return
	monster.call("_update_red_alarm_attraction_state", 0.4)
	monster.call("_update_investigate", 0.016)

	if not bool(monster.call("debug_has_alarm_target")):
		_fail("monster did not accept active red alarm target")
		return
	if not bool(monster.call("debug_has_alarm_route")):
		_fail("monster did not build a portal route toward the red alarm")
		return
	var route_target := monster.call("debug_get_alarm_route_target") as Vector3
	var alarm_position := attractor.call("get_attract_position") as Vector3
	if route_target.distance_to(alarm_position) < 0.75:
		_fail("alarm route target is still the direct alarm point, not a portal waypoint")
		return

	var same_area := root.get_node_or_null("LevelRoot/Areas/Area_W47") as Node3D
	var internal_waypoint := _find_internal_waypoint(root, "W47")
	if same_area == null or internal_waypoint == null:
		_fail("missing W47 same-area internal alarm waypoint")
		return
	monster.global_position = same_area.global_position + Vector3(3.6, 0.05, 2.9)
	monster.velocity = Vector3.ZERO
	monster.set("_has_alarm_route", false)
	monster.set("_alarm_repath_timer", 0.0)
	monster.call("_update_red_alarm_attraction_state", 0.4)
	var same_area_target := monster.call("debug_get_alarm_navigation_target") as Vector3
	if same_area_target.distance_to(alarm_position) < 0.75:
		_fail("same-area alarm navigation still targets the alarm directly through an internal wall")
		return
	if same_area_target.distance_to(internal_waypoint.global_position) > 0.85:
		_fail("same-area alarm navigation did not use the internal doorway waypoint: target=%s waypoint=%s" % [same_area_target, internal_waypoint.global_position])
		return

	monster.set("_has_alarm_route", true)
	monster.set("_has_last_alarm_position", true)
	monster.set("_last_alarm_position", monster.global_position)
	monster.set("_alarm_stuck_timer", 0.0)
	monster.call("_update_alarm_stuck", float(monster.get("alarm_stuck_repath_time")) + 0.05)
	if bool(monster.call("debug_has_alarm_route")):
		_fail("alarm stuck recovery did not clear the stale alarm route")
		return

	monster.global_position = same_area.global_position + Vector3(0.0, 0.05, -2.5)
	monster.velocity = Vector3.ZERO
	player.global_position = monster.global_position + Vector3(0.0, 0.0, -2.0)
	monster.look_at(player.global_position, Vector3.UP)
	monster.call("_update_red_alarm_attraction_state", 0.016)
	var chase_state := String(monster.call("debug_get_state_name"))
	if chase_state != "CHASE" and chase_state != "ATTACK":
		_fail("monster did not prioritize a visible player while responding to alarm: %s" % chase_state)
		return

	attractor.call("_on_body_entered", player)
	if not bool(attractor.call("is_active")):
		_fail("alarm did not activate when player entered")
		return
	attractor.call("_on_body_exited", player)
	attractor.call("_process", float(attractor.get("linger_after_player_exit")) + 0.25)
	if bool(attractor.call("is_active")):
		_fail("alarm did not stop after player left and linger elapsed")
		return
	if bool(attractor.call("debug_is_alarm_audio_playing")):
		_fail("red alarm audio did not stop when alarm deactivated")
		return
	if bool(attractor.call("debug_any_alarm_light_visible")):
		_fail("red alarm light stayed on after alarm deactivated")
		return

	print("RED_ALARM_ATTRACTION_AI_VALIDATION PASS route_target=%s same_area_target=%s alarm=%s chase_state=%s" % [
		str(route_target),
		str(same_area_target),
		str(alarm_position),
		chase_state,
	])
	quit(0)

func _find_red_alarm_attractor(root: Node, owner_id: String) -> Node:
	for node in _nodes_in_group(root, "red_alarm_attractor"):
		if String(node.get_meta("owner_module_id", "")) == owner_id:
			return node
	return null

func _find_internal_waypoint(root: Node, owner_id: String) -> Node3D:
	for node in _nodes_in_group(root, "proc_internal_navigation_waypoint"):
		var waypoint := node as Node3D
		if waypoint != null and String(waypoint.get_meta("owner_module_id", "")) == owner_id:
			return waypoint
	return null

func _first_monster(root: Node) -> CharacterBody3D:
	var monster_root := root.get_node_or_null("MonsterRoot")
	if monster_root == null:
		return null
	for child in monster_root.get_children():
		var monster := child as CharacterBody3D
		if monster != null:
			return monster
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
	push_error("RED_ALARM_ATTRACTION_AI_VALIDATION FAIL %s" % message)
	quit(1)
