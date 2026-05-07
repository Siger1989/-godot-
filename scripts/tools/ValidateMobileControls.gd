extends SceneTree

const PLAYER_SCENE_PATH := "res://scenes/modules/PlayerModule.tscn"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	if OS.get_environment("FORCE_MOBILE_CONTROLS") != "1":
		_fail("run with FORCE_MOBILE_CONTROLS=1 so desktop validation uses the phone UI path")
		return
	get_root().size = Vector2i(1280, 720)
	var packed := load(PLAYER_SCENE_PATH) as PackedScene
	if packed == null:
		_fail("missing player scene")
		return

	var scene := Node3D.new()
	scene.name = "MobileControlsValidationRoot"
	get_root().add_child(scene)

	var player_root := Node3D.new()
	player_root.name = "PlayerRoot"
	scene.add_child(player_root)

	var camera_rig := Node3D.new()
	camera_rig.name = "CameraRig"
	scene.add_child(camera_rig)
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera_rig.add_child(camera)

	var player := packed.instantiate() as CharacterBody3D
	if player == null:
		_fail("player scene did not instantiate as CharacterBody3D")
		return
	player.name = "Player"
	player_root.add_child(player)

	await process_frame
	await process_frame

	if not player.has_method("debug_mobile_controls_visible"):
		_fail("player does not expose mobile-controls validation hooks")
		return
	if not bool(player.call("debug_mobile_controls_visible")):
		_fail("mobile controls are not visible when forced")
		return
	if not player.has_method("debug_mobile_sprint_button_visible"):
		_fail("player does not expose mobile sprint-button validation hook")
		return
	if not bool(player.call("debug_mobile_sprint_button_visible")):
		_fail("mobile sprint button is not visible when phone controls are forced")
		return
	if not player.has_method("debug_mobile_crouch_button_visible"):
		_fail("player does not expose mobile crouch-button validation hook")
		return
	if not bool(player.call("debug_mobile_crouch_button_visible")):
		_fail("mobile crouch button is not visible when phone controls are forced")
		return
	if not player.has_method("debug_mobile_settings_button_visible") or not bool(player.call("debug_mobile_settings_button_visible")):
		_fail("mobile settings button is not visible when phone controls are forced")
		return
	if not player.has_method("debug_has_stamina_bar") or not bool(player.call("debug_has_stamina_bar")):
		_fail("player stamina bar is missing")
		return
	var viewport_size := get_root().get_visible_rect().size
	var sprint_rect := player.call("debug_get_mobile_sprint_button_rect") as Rect2
	var crouch_rect := player.call("debug_get_mobile_crouch_button_rect") as Rect2
	var settings_rect := player.call("debug_get_mobile_settings_button_rect") as Rect2
	if sprint_rect.size.x < 150.0 or sprint_rect.size.y < 88.0:
		_fail("mobile sprint button is still too small: %s" % str(sprint_rect))
		return
	if crouch_rect.size.x < 150.0 or crouch_rect.size.y < 88.0:
		_fail("mobile crouch button is still too small: %s" % str(crouch_rect))
		return
	if viewport_size.x - sprint_rect.end.x < 120.0 or viewport_size.x - crouch_rect.end.x < 120.0:
		_fail("mobile action buttons are too close to the right edge: sprint=%s crouch=%s viewport=%s" % [str(sprint_rect), str(crouch_rect), str(viewport_size)])
		return
	if settings_rect.position.x < viewport_size.x * 0.58:
		_fail("mobile settings button is not in the right-side thumb/top area: %s" % str(settings_rect))
		return
	if not player.has_method("debug_mobile_touch_handled") or not player.has_method("debug_is_mobile_sprint_pressed"):
		_fail("player does not expose sprint touch passthrough validation hooks")
		return
	var sprint_touch := InputEventScreenTouch.new()
	sprint_touch.index = 7
	sprint_touch.position = sprint_rect.get_center()
	sprint_touch.pressed = true
	var sprint_press_handled := bool(player.call("debug_mobile_touch_handled", sprint_touch))
	if sprint_press_handled:
		_fail("mobile sprint press should not consume the touch, so camera dragging can continue")
		return
	if not bool(player.call("debug_is_mobile_sprint_pressed")):
		_fail("mobile sprint press did not latch sprint state")
		return
	var sprint_drag := InputEventScreenDrag.new()
	sprint_drag.index = 7
	sprint_drag.position = sprint_rect.get_center() + Vector2(-80.0, -10.0)
	sprint_drag.relative = Vector2(-80.0, -10.0)
	if bool(player.call("debug_mobile_touch_handled", sprint_drag)):
		_fail("mobile sprint drag should pass through to camera view control")
		return
	sprint_touch.pressed = false
	player.call("debug_mobile_touch_handled", sprint_touch)
	if bool(player.call("debug_is_mobile_sprint_pressed")):
		_fail("mobile sprint state did not release")
		return
	if not player.has_method("debug_get_mobile_stick_center") or not player.has_method("debug_get_mobile_joystick_radius"):
		_fail("player does not expose mobile joystick layout validation hooks")
		return
	var stick_center := player.call("debug_get_mobile_stick_center") as Vector2
	var stick_radius := float(player.call("debug_get_mobile_joystick_radius"))
	if stick_center.x < stick_radius * 2.25:
		_fail("mobile joystick is too close to the left edge: center=%s radius=%s" % [str(stick_center), str(stick_radius)])
		return
	if viewport_size.y - stick_center.y < stick_radius * 2.25:
		_fail("mobile joystick is too close to the bottom edge: center=%s viewport=%s radius=%s" % [str(stick_center), str(viewport_size), str(stick_radius)])
		return
	if not bool(player.call("debug_mobile_stick_accepts_start", stick_center + Vector2(stick_radius * 2.65, 0.0))):
		_fail("mobile joystick relaxed start area does not accept a comfortable thumb start")
		return
	for angle_index in range(8):
		var angle := TAU * float(angle_index) / 8.0
		var screen_direction := Vector2(cos(angle), sin(angle))
		var drag_position := stick_center + screen_direction * stick_radius
		var input_direction := player.call("debug_simulate_mobile_touch_path", stick_center, drag_position) as Vector2
		var expected_direction := Vector2(screen_direction.x, -screen_direction.y)
		if input_direction.distance_to(expected_direction) > 0.08:
			_fail("mobile joystick angle %d did not map correctly: got=%s expected=%s" % [angle_index, str(input_direction), str(expected_direction)])
			return
	var left_screen_drag := player.call("debug_simulate_mobile_touch_path", stick_center, stick_center + Vector2(-stick_radius, 0.0)) as Vector2
	if left_screen_drag.x > -0.92 or absf(left_screen_drag.y) > 0.08:
		_fail("mobile joystick full-left drag is not reliable: %s" % str(left_screen_drag))
		return

	player.call("debug_set_mobile_move_vector", Vector2(0.55, 0.80))
	var input_value: Variant = player.call("debug_get_input_vector")
	if not (input_value is Vector2):
		_fail("debug input vector did not return Vector2")
		return
	var input_vector := input_value as Vector2
	if input_vector.x < 0.50 or input_vector.y < 0.70:
		_fail("mobile joystick vector is not contributing to movement: %s" % str(input_vector))
		return
	var stamina_before := float(player.call("debug_get_stamina"))
	player.call("debug_update_stamina", 1.0, true)
	var stamina_after_sprint := float(player.call("debug_get_stamina"))
	if stamina_after_sprint >= stamina_before - 10.0:
		_fail("sprint stamina did not drain enough: before=%s after=%s" % [str(stamina_before), str(stamina_after_sprint)])
		return
	player.call("debug_update_stamina", 2.0, false)
	var stamina_after_recover := float(player.call("debug_get_stamina"))
	if stamina_after_recover <= stamina_after_sprint:
		_fail("stamina did not recover while not sprinting: sprint=%s recover=%s" % [str(stamina_after_sprint), str(stamina_after_recover)])
		return
	player.call("debug_set_stamina", 0.0)
	if not player.has_method("debug_update_stamina"):
		_fail("missing stamina validation hook")
		return
	if not player.has_method("debug_set_mobile_crouch") or not player.has_method("debug_is_crouching"):
		_fail("player does not expose crouch validation hooks")
		return
	player.call("debug_set_mobile_crouch", true)
	if not bool(player.call("debug_is_crouching")):
		_fail("mobile crouch toggle did not set crouching state")
		return
	if player.has_method("get_footstep_noise_radius") and float(player.call("get_footstep_noise_radius")) > 0.0:
		_fail("crouch walk should be silent to hearing AI")
		return
	if player.has_method("get_detection_target_height"):
		var crouch_height := float(player.call("get_detection_target_height"))
		player.call("debug_set_mobile_crouch", false)
		var stand_height := float(player.call("get_detection_target_height"))
		if crouch_height >= stand_height:
			_fail("crouch detection height was not lower than standing height: crouch=%s stand=%s" % [str(crouch_height), str(stand_height)])
			return

	print("MOBILE_CONTROLS_VALIDATION PASS input=%s sprint_button=true crouch_button=true" % str(input_vector))
	quit(0)

func _fail(message: String) -> void:
	push_error("MOBILE_CONTROLS_VALIDATION FAIL %s" % message)
	quit(1)
