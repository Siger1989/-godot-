extends SceneTree

const MENU_SCENE := "res://scenes/ui/LoginMenu.tscn"
const PLAYER_SCENE := "res://scenes/modules/PlayerModule.tscn"
const PROC_MAZE_SCENE := "res://scenes/tests/Test_ProcMazeMap.tscn"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)

	if String(ProjectSettings.get_setting("application/run/main_scene", "")) != MENU_SCENE:
		_fail("main scene is not LoginMenu")
		return

	var packed := load(MENU_SCENE) as PackedScene
	if packed == null:
		_fail("missing LoginMenu scene")
		return
	var menu := packed.instantiate() as Control
	if menu == null:
		_fail("LoginMenu root is not Control")
		return
	root.add_child(menu)
	await process_frame
	await process_frame

	if not menu.has_method("debug_has_login_controls") or not bool(menu.call("debug_has_login_controls")):
		_fail("LoginMenu does not expose required login/mode controls")
		return
	if (
		not menu.has_method("debug_get_input_minimum_size")
		or not menu.has_method("debug_get_input_runtime_size")
		or not menu.has_method("debug_get_input_font_size")
		or not menu.has_method("debug_get_button_minimum_size")
		or not menu.has_method("debug_get_button_font_size")
		or not menu.has_method("debug_get_host_button_minimum_size")
		or not menu.has_method("debug_get_control_global_rect")
		or not menu.has_method("debug_focus_room_code")
		or not menu.has_method("debug_is_any_input_focused")
		or not menu.has_method("debug_set_skip_online_start")
	):
		_fail("LoginMenu does not expose input layout validation hooks")
		return
	menu.call("debug_set_skip_online_start", true)
	var input_size := menu.call("debug_get_input_minimum_size") as Vector2
	var input_runtime_size := menu.call("debug_get_input_runtime_size") as Vector2
	var input_font_size := int(menu.call("debug_get_input_font_size"))
	var button_size := menu.call("debug_get_button_minimum_size") as Vector2
	var host_button_size := menu.call("debug_get_host_button_minimum_size") as Vector2
	var button_font_size := int(menu.call("debug_get_button_font_size"))
	if input_size.x > 340.0 or input_size.y < 72.0:
		_fail("LoginMenu input fields are still too wide or too short for phone notch/safe area: %s" % str(input_size))
		return
	if input_runtime_size.x > 360.0 or input_runtime_size.y < 72.0:
		_fail("LoginMenu runtime input fields are not compact/tall enough: %s" % str(input_runtime_size))
		return
	if input_font_size < 32:
		_fail("LoginMenu input font is still too small: %d" % input_font_size)
		return
	if button_size.x < 300.0 or button_size.y < 70.0 or host_button_size.x < 150.0 or host_button_size.y < 70.0 or button_font_size < 23:
		_fail("LoginMenu mode buttons are still too small: single=%s host=%s font=%d" % [str(button_size), str(host_button_size), button_font_size])
		return
	var status_text := String(menu.call("debug_get_status_text"))
	if not status_text.contains("C") or (not status_text.contains("手机") and not status_text.contains("Mobile")):
		_fail("LoginMenu status does not mention PC C crouch and mobile button")
		return
	if String(menu.get("game_scene_path")) != PROC_MAZE_SCENE:
		_fail("LoginMenu does not enter the formal proc-maze scene")
		return

	var session := root.get_node_or_null("GameSession")
	if session == null:
		_fail("GameSession autoload is missing")
		return
	if root.get_node_or_null("GDSyncBootstrap") == null:
		_fail("GDSyncBootstrap autoload is missing")
		return
	session.call("configure_host", "Tester", "")
	if String(session.get("mode")) != "host" or String(session.get("room_code")).length() < 4:
		_fail("GameSession did not configure host room state")
		return
	if bool(session.call("is_online_ready")):
		_fail("host configuration should not mark online ready before GD-Sync lobby creation")
		return
	if not bool(session.call("configure_join", "Tester", "ab12")):
		_fail("GameSession did not accept valid join room code")
		return
	if String(session.get("room_code")) != "AB12":
		_fail("GameSession did not normalize room code")
		return

	var player_rect := menu.call("debug_get_control_global_rect", "RootMargin/Layout/Form/PlayerNameInput") as Rect2
	var room_rect := menu.call("debug_get_control_global_rect", "RootMargin/Layout/Form/RoomCodeInput") as Rect2
	var host_rect := menu.call("debug_get_control_global_rect", "RootMargin/Layout/Form/ModeButtons/HostButton") as Rect2
	var join_rect := menu.call("debug_get_control_global_rect", "RootMargin/Layout/Form/ModeButtons/JoinButton") as Rect2
	if _rects_intersect(player_rect, host_rect) or _rects_intersect(room_rect, host_rect):
		_fail("Host button overlaps an input field: player=%s room=%s host=%s" % [str(player_rect), str(room_rect), str(host_rect)])
		return
	if _rects_intersect(player_rect, join_rect) or _rects_intersect(room_rect, join_rect):
		_fail("Join button overlaps an input field: player=%s room=%s join=%s" % [str(player_rect), str(room_rect), str(join_rect)])
		return

	session.call("configure_single", "Tester")
	menu.call("debug_focus_room_code")
	if not bool(menu.call("debug_is_any_input_focused")):
		_fail("Room code input did not focus before touch-flow validation")
		return
	await _tap_control(menu.get_node("RootMargin/Layout/Form/ModeButtons/HostButton") as Control)
	await process_frame
	if bool(menu.call("debug_is_any_input_focused")):
		_fail("Host button did not release input focus / virtual keyboard ownership")
		return
	if String(session.get("mode")) != "host" or String(session.get("room_code")).length() < 4:
		_fail("Tapping host button did not configure host room state")
		return

	menu.call("debug_set_room_code", "")
	menu.call("debug_focus_room_code")
	await _tap_control(menu.get_node("RootMargin/Layout/Form/ModeButtons/JoinButton") as Control)
	await process_frame
	if bool(menu.call("debug_is_any_input_focused")):
		_fail("Join button without code did not release input focus / virtual keyboard ownership")
		return
	if String(session.get("service_status")) != "missing_room":
		_fail("Tapping join without room code should show missing-room status, got %s" % String(session.get("service_status")))
		return

	menu.call("debug_set_room_code", "ab12")
	menu.call("debug_focus_room_code")
	await _tap_control(menu.get_node("RootMargin/Layout/Form/ModeButtons/JoinButton") as Control)
	await process_frame
	if bool(menu.call("debug_is_any_input_focused")):
		_fail("Join button with code did not release input focus / virtual keyboard ownership")
		return
	if String(session.get("mode")) != "join" or String(session.get("room_code")) != "AB12":
		_fail("Tapping join button did not configure normalized join room state")
		return

	var player_packed := load(PLAYER_SCENE) as PackedScene
	if player_packed == null:
		_fail("missing player scene")
		return
	var player_root := Node3D.new()
	player_root.name = "PlayerRoot"
	root.add_child(player_root)
	var player := player_packed.instantiate() as CharacterBody3D
	if player == null:
		_fail("player scene did not instantiate")
		return
	player_root.add_child(player)
	await process_frame

	var crouch_events := InputMap.action_get_events("crouch")
	if crouch_events.size() != 1:
		_fail("crouch should have exactly one keyboard binding, found %d" % crouch_events.size())
		return
	var key_event := crouch_events[0] as InputEventKey
	if key_event == null or key_event.physical_keycode != KEY_C:
		_fail("crouch keyboard binding must be C only")
		return

	print("LOGIN_MENU_VALIDATION PASS main_scene=%s room=%s game_scene=%s crouch=C" % [MENU_SCENE, String(session.get("room_code")), PROC_MAZE_SCENE])
	quit(0)

func _tap_control(control: Control) -> void:
	var center := control.get_global_rect().get_center()
	var press := InputEventMouseButton.new()
	press.position = center
	press.global_position = center
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	root.push_input(press)
	await process_frame
	var release := InputEventMouseButton.new()
	release.position = center
	release.global_position = center
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	root.push_input(release)
	await process_frame

func _rects_intersect(a: Rect2, b: Rect2) -> bool:
	return a.intersects(b, true)

func _fail(message: String) -> void:
	push_error("LOGIN_MENU_VALIDATION FAIL %s" % message)
	quit(1)
