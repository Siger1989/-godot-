extends SceneTree

const PLAYER_SCENE_PATH := "res://scenes/modules/PlayerModule.tscn"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load(PLAYER_SCENE_PATH) as PackedScene
	if packed == null:
		_fail("missing player scene")
		return
	var root_node := Node3D.new()
	root.add_child(root_node)
	var player := packed.instantiate() as CharacterBody3D
	if player == null:
		_fail("player scene did not instantiate as CharacterBody3D")
		return
	root_node.add_child(player)
	await process_frame
	await process_frame
	if not bool(player.call("debug_has_health_bar")):
		_fail("player health bar was not created")
		return
	if float(player.call("debug_get_health")) != float(player.call("debug_get_max_health")):
		_fail("player health did not start full")
		return
	player.call("receive_damage", 25.0, null)
	await process_frame
	if absf(float(player.call("debug_get_health")) - 75.0) > 0.01:
		_fail("player health did not decrease after damage")
		return
	player.call("heal", 10.0)
	await process_frame
	if absf(float(player.call("debug_get_health")) - 85.0) > 0.01:
		_fail("player health did not increase after healing")
		return
	player.call("receive_damage", 200.0, null)
	await process_frame
	if not bool(player.call("is_dead")):
		_fail("player did not enter dead state at zero health")
		return
	if not bool(player.call("debug_has_game_over")):
		_fail("player did not show game over UI at zero health")
		return
	print("PLAYER_HEALTH_BAR_VALIDATION PASS health=%.0f" % float(player.call("debug_get_health")))
	quit(0)

func _fail(message: String) -> void:
	push_error("PLAYER_HEALTH_BAR_VALIDATION FAIL %s" % message)
	quit(1)
