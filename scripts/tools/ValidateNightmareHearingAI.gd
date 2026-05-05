extends SceneTree

const SCENE_PATH := "res://scenes/mvp/FourRoomMVP.tscn"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load(SCENE_PATH) as PackedScene
	if packed == null:
		_fail("Missing scene: %s." % SCENE_PATH)
		return
	var scene := packed.instantiate() as Node3D
	if scene == null:
		_fail("MVP scene root is not Node3D.")
		return
	root.add_child(scene)
	await process_frame
	await physics_frame

	var player := scene.get_node_or_null("PlayerRoot/Player") as CharacterBody3D
	var nightmare := scene.get_node_or_null("MonsterRoot/NightmareCreature_A_MVP") as CharacterBody3D
	if player == null:
		_fail("MVP player is missing.")
		return
	if nightmare == null:
		_fail("NightmareCreature_A_MVP is not an active CharacterBody3D.")
		return
	if String(nightmare.get("monster_role")) != "nightmare":
		_fail("NightmareCreature_A_MVP role is not nightmare.")
		return
	if not nightmare.is_in_group("nightmare_monster"):
		_fail("NightmareCreature_A_MVP is missing nightmare_monster group.")
		return
	if scene.get_node_or_null("MonsterRoot/NightmareCreature_B_MVP") != null:
		_fail("MVP monster-size room should keep only one Nightmare source.")
		return
	if nightmare.get_node_or_null("NightmareSonarAudio") == null:
		_fail("Nightmare monster must have NightmareSonarAudio.")
		return

	player.set_physics_process(false)
	nightmare.global_position = Vector3(1.25, 0.05, 5.9)
	player.global_position = Vector3(1.25, 0.05, 4.2)
	player.velocity = Vector3.ZERO
	await physics_frame

	if bool(nightmare.call("debug_can_see_player")):
		_fail("Nightmare should not see the player even at close range.")
		return
	if bool(nightmare.call("debug_can_hear_player")):
		_fail("Nightmare heard a stationary player.")
		return

	player.velocity = Vector3(1.2, 0.0, 0.0)
	if not bool(nightmare.call("debug_can_hear_player")):
		_fail("Nightmare did not hear a nearby walking player.")
		return
	nightmare.call("_update_nightmare_state", 0.016)
	var active_state := String(nightmare.call("debug_get_state_name"))
	if active_state != "CHASE" and active_state != "ATTACK":
		_fail("Nightmare did not enter CHASE/ATTACK after hearing footsteps; state=%s." % active_state)
		return
	if String(nightmare.call("debug_get_chase_target_name")) != player.name:
		_fail("Nightmare did not target the player after hearing footsteps.")
		return

	player.velocity = Vector3.ZERO
	nightmare.call("_update_nightmare_state", 0.016)
	if bool(nightmare.call("debug_can_hear_player")):
		_fail("Nightmare still hears the player after the player stops.")
		return
	var quiet_state := String(nightmare.call("debug_get_state_name"))
	if quiet_state == "CHASE":
		_fail("Nightmare kept chasing the silent player instead of investigating the last heard point.")
		return
	nightmare.call("_update_nightmare_state", float(nightmare.get("nightmare_hearing_memory_time")) + 0.25)
	var lost_target_state := String(nightmare.call("debug_get_state_name"))
	if lost_target_state != "WANDER":
		_fail("Nightmare did not wander after losing the silent target; state=%s." % lost_target_state)
		return

	nightmare.global_position = player.global_position + Vector3(0.0, 0.0, 0.28)
	player.velocity = Vector3(1.0, 0.0, 0.0)
	player.set_meta("nightmare_monster_hit_count", 0)
	player.set_meta("mvp_nightmare_attack_was_nonlethal", false)
	nightmare.set("_attack_timer", 0.0)
	nightmare.call("_update_nightmare_state", 0.016)
	if int(player.get_meta("nightmare_monster_hit_count", 0)) < 1:
		_fail("Nightmare attack did not register a nonlethal MVP player hit.")
		return
	if bool(player.get_meta("dead", false)):
		_fail("Nightmare attack marked the immortal MVP player dead.")
		return
	if not bool(player.get_meta("mvp_nightmare_attack_was_nonlethal", false)):
		_fail("Nightmare attack did not use the nonlethal immortal-player path.")
		return

	print("NIGHTMARE_HEARING_AI_VALIDATION PASS state=%s quiet_state=%s nonlethal_hits=%d" % [
		active_state,
		"%s->%s" % [quiet_state, lost_target_state],
		int(player.get_meta("nightmare_monster_hit_count", 0)),
	])
	quit(0)

func _fail(message: String) -> void:
	push_error("NIGHTMARE_HEARING_AI_VALIDATION FAIL %s" % message)
	quit(1)
