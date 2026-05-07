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
	player.call("set_hidden_in_hideable", true, null)
	if bool(nightmare.call("debug_can_hear_player")):
		_fail("Nightmare still hears a player marked hidden inside a locker.")
		return
	player.call("set_hidden_in_hideable", false, null)
	player.velocity = Vector3(1.2, 0.0, 0.0)
	nightmare.call("_update_nightmare_state", 0.016)
	nightmare.call("_update_hearing_pause", 0.016)
	var active_state := String(nightmare.call("debug_get_state_name"))
	if active_state != "HEARING_ALERT":
		_fail("Nightmare did not enter HEARING_ALERT after the first footstep; state=%s." % active_state)
		return

	player.velocity = Vector3.ZERO
	nightmare.call("_update_hearing_pause", float(nightmare.get("nightmare_hearing_alert_time")) + 0.05)
	var single_sound_confirm_state := String(nightmare.call("debug_get_state_name"))
	if single_sound_confirm_state != "HEARING_CONFIRM":
		_fail("Nightmare did not leave single-sound HEARING_ALERT for HEARING_CONFIRM; state=%s." % single_sound_confirm_state)
		return
	nightmare.call("_update_hearing_pause", float(nightmare.get("nightmare_hearing_confirm_time")) + 0.05)
	var single_sound_lock_state := String(nightmare.call("debug_get_state_name"))
	if single_sound_lock_state != "CHASE" and single_sound_lock_state != "INVESTIGATE":
		_fail("Nightmare did not act on a single heard point after the alert window; state=%s." % single_sound_lock_state)
		return

	nightmare.call("_choose_wander")
	nightmare.global_position = Vector3(1.25, 0.05, 5.9)
	player.global_position = Vector3(1.25, 0.05, 4.2)
	player.velocity = Vector3(1.2, 0.0, 0.0)
	nightmare.call("_update_nightmare_state", 0.016)
	nightmare.call("_update_hearing_pause", 0.016)
	active_state = String(nightmare.call("debug_get_state_name"))
	if active_state != "HEARING_ALERT":
		_fail("Nightmare did not re-enter HEARING_ALERT after reset; state=%s." % active_state)
		return

	player.global_position += Vector3(0.24, 0.0, 0.0)
	nightmare.call("_update_nightmare_state", 0.016)
	nightmare.call("_update_hearing_pause", 0.016)
	var confirm_state := String(nightmare.call("debug_get_state_name"))
	if confirm_state != "HEARING_CONFIRM":
		_fail("Nightmare did not enter HEARING_CONFIRM after a second footstep; state=%s." % confirm_state)
		return

	nightmare.call("_update_hearing_pause", float(nightmare.get("nightmare_hearing_confirm_time")) + 0.05)
	var locked_state := String(nightmare.call("debug_get_state_name"))
	if locked_state != "CHASE":
		_fail("Nightmare did not lock and chase the player when the player stayed near the heard point; state=%s." % locked_state)
		return

	player.velocity = Vector3(1.2, 0.0, 0.0)
	player.global_position += Vector3(0.18, 0.0, 0.0)
	nightmare.call("_update_nightmare_state", 0.016)
	var sustained_chase_state := String(nightmare.call("debug_get_state_name"))
	if sustained_chase_state == "HEARING_ALERT" or sustained_chase_state == "HEARING_CONFIRM":
		_fail("Nightmare reset to a hearing pause while already chasing continuous movement; state=%s." % sustained_chase_state)
		return
	if sustained_chase_state != "CHASE":
		_fail("Nightmare left CHASE unexpectedly during continuous movement; state=%s." % sustained_chase_state)
		return

	nightmare.call("_update_nightmare_ceiling_ambush", 0.18)
	if not bool(nightmare.get_meta("nightmare_ceiling_ambush_active", false)):
		_fail("Nightmare did not enter the ceiling ambush visual phase during close sound-locked chase.")
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
	if quiet_state != "INVESTIGATE":
		_fail("Nightmare did not move into INVESTIGATE after the chased target went silent; state=%s." % quiet_state)
		return

	player.velocity = Vector3(1.2, 0.0, 0.0)
	for i in range(90):
		player.global_position += Vector3(0.02, 0.0, 0.0)
		nightmare.call("_update_nightmare_state", 0.016)
		var moving_investigate_state := String(nightmare.call("debug_get_state_name"))
		if moving_investigate_state == "HEARING_ALERT" or moving_investigate_state == "HEARING_CONFIRM":
			_fail("Nightmare reset to a hearing pause while investigating repeated movement; state=%s frame=%d." % [moving_investigate_state, i])
			return
		if moving_investigate_state != "INVESTIGATE":
			_fail("Nightmare left INVESTIGATE unexpectedly during repeated movement; state=%s frame=%d." % [moving_investigate_state, i])
			return

	player.velocity = Vector3.ZERO
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
		"%s->%s->%s" % [active_state, confirm_state, locked_state],
		"%s->%s" % [quiet_state, lost_target_state],
		int(player.get_meta("nightmare_monster_hit_count", 0)),
	])
	quit(0)

func _fail(message: String) -> void:
	push_error("NIGHTMARE_HEARING_AI_VALIDATION FAIL %s" % message)
	quit(1)
