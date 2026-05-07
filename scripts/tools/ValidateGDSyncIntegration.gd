extends SceneTree

const BOOTSTRAP_SCRIPT := "res://scripts/gameplay/GDSyncBootstrap.gd"
const SESSION_SCRIPT := "res://scripts/gameplay/GameSession.gd"
const BRIDGE_SCRIPT := "res://scripts/gameplay/OnlineGameBridge.gd"
const CLIENT_SCRIPT := "res://addons/GD-Sync/MultiplayerClient.gd"
const KEY_EXAMPLE := "res://local_gdsync_keys.example.cfg"
const PROJECT_SCENE_SCRIPT := "res://scripts/proc_maze/TestProcMazeMap.gd"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	if String(ProjectSettings.get_setting("autoload/GDSyncBootstrap", "")) != "*%s" % BOOTSTRAP_SCRIPT:
		_fail("GDSyncBootstrap autoload is missing")
		return
	for path in [BOOTSTRAP_SCRIPT, SESSION_SCRIPT, BRIDGE_SCRIPT, CLIENT_SCRIPT, KEY_EXAMPLE]:
		if not FileAccess.file_exists(path):
			_fail("missing online integration file: %s" % path)
			return

	var project_text := FileAccess.get_file_as_string("res://project.godot")
	if project_text.contains("2e3238d14fddbd65") or project_text.contains("1d49331a4433ac47"):
		_fail("GD-Sync key values must not be committed into project.godot")
		return
	var ignore_text := FileAccess.get_file_as_string("res://.gitignore")
	if not ignore_text.contains("local_gdsync_keys.cfg"):
		_fail("local GD-Sync key file is not ignored")
		return

	var session_script := load(SESSION_SCRIPT) as Script
	if session_script == null:
		_fail("GameSession script failed to load")
		return
	var session := session_script.new() as Node
	root.add_child(session)
	session.call("configure_host", "Tester", "")
	if bool(session.call("is_online_ready")):
		_fail("GameSession should wait for GD-Sync lobby before reporting online ready")
		return
	if not session.has_method("start_online_if_needed"):
		_fail("GameSession has no online startup method")
		return

	ProjectSettings.set_setting("GD-Sync/publicKey", "TEST_PUBLIC")
	ProjectSettings.set_setting("GD-Sync/privateKey", "TEST_PRIVATE")
	var bootstrap := root.get_node_or_null("GDSyncBootstrap")
	if bootstrap == null or not bootstrap.has_method("get_or_create_client"):
		_fail("GDSyncBootstrap cannot create the runtime client")
		return
	var client := bootstrap.call("get_or_create_client") as Node
	if client == null or root.get_node_or_null("GDSync") == null:
		_fail("GD-Sync runtime client could not be created after keys were configured")
		return

	var proc_script := FileAccess.get_file_as_string(PROJECT_SCENE_SCRIPT)
	if not proc_script.contains("OnlineGameBridgeScript") or not proc_script.contains("OnlineGameBridge"):
		_fail("formal proc-maze scene does not install OnlineGameBridge")
		return

	print("GDSYNC_INTEGRATION_VALIDATION PASS addon=true bootstrap=true bridge=true key_policy=local_or_env")
	quit(0)

func _fail(message: String) -> void:
	push_error("GDSYNC_INTEGRATION_VALIDATION FAIL %s" % message)
	quit(1)
