extends Node

const LOCAL_PLAYER_PATH := NodePath("../../PlayerRoot/Player")
const SEND_INTERVAL := 0.08

var _session: Node
var _gdsync: Node
var _local_player: Node3D
var _remote_root: Node3D
var _remote_players := {}
var _send_timer := 0.0
var _local_client_id := -1

func _ready() -> void:
	call_deferred("_initialize")

func _process(delta: float) -> void:
	if _gdsync == null or _local_player == null:
		return
	_send_timer -= delta
	if _send_timer > 0.0:
		return
	_send_timer = SEND_INTERVAL
	_send_local_player_state()

func _initialize() -> void:
	_session = get_node_or_null("/root/GameSession")
	if _session == null or not _session.has_method("is_online_mode") or not bool(_session.call("is_online_mode")):
		set_process(false)
		return
	if _session.has_method("is_online_ready") and not bool(_session.call("is_online_ready")):
		set_process(false)
		return

	_gdsync = get_node_or_null("/root/GDSync")
	if _gdsync == null:
		set_process(false)
		return
	_local_player = get_node_or_null(LOCAL_PLAYER_PATH) as Node3D
	if _local_player == null:
		set_process(false)
		return

	_remote_root = _get_or_create_remote_root()
	_connect_signal_once(_gdsync, "client_left", "_on_gdsync_client_left")
	if _gdsync.has_method("expose_func"):
		_gdsync.call("expose_func", Callable(self, "_remote_player_state"))
	if _gdsync.has_method("get_client_id"):
		_local_client_id = int(_gdsync.call("get_client_id"))
	set_process(true)

func _send_local_player_state() -> void:
	if not _gdsync.has_method("call_func_unreliable"):
		return
	if _local_client_id < 0 and _gdsync.has_method("get_client_id"):
		_local_client_id = int(_gdsync.call("get_client_id"))
	if _local_client_id < 0:
		return
	var health := 100.0
	if _local_player.has_method("debug_get_health"):
		health = float(_local_player.call("debug_get_health"))
	elif _local_player.has_method("get_health"):
		health = float(_local_player.call("get_health"))
	_gdsync.call(
		"call_func_unreliable",
		Callable(self, "_remote_player_state"),
		_local_client_id,
		_local_player.global_position,
		_local_player.global_rotation.y,
		health
	)

func _remote_player_state(client_id: int, position: Vector3, yaw: float, health: float) -> void:
	if client_id == _local_client_id:
		return
	var remote := _get_or_create_remote_player(client_id)
	remote.global_position = position
	remote.global_rotation.y = yaw
	remote.set_meta("remote_health", health)

func _get_or_create_remote_player(client_id: int) -> Node3D:
	if _remote_players.has(client_id) and is_instance_valid(_remote_players[client_id]):
		return _remote_players[client_id]

	var marker := Node3D.new()
	marker.name = "RemotePlayer_%s" % str(client_id)

	var body := MeshInstance3D.new()
	body.name = "Body"
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.28
	mesh.height = 1.6
	body.mesh = mesh
	body.position.y = 0.8
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.8, 1.0, 0.72)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	body.material_override = material
	marker.add_child(body)

	var label := Label3D.new()
	label.name = "NameLabel"
	label.text = "P%s" % str(client_id)
	label.position.y = 1.85
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(0.7, 0.95, 1.0, 1.0)
	marker.add_child(label)

	_remote_root.add_child(marker)
	_remote_players[client_id] = marker
	return marker

func _get_or_create_remote_root() -> Node3D:
	var scene_root := get_parent().get_parent() as Node3D
	var existing := scene_root.get_node_or_null("RemotePlayers") as Node3D
	if existing != null:
		return existing
	var created := Node3D.new()
	created.name = "RemotePlayers"
	scene_root.add_child(created)
	return created

func _on_gdsync_client_left(client_id: int) -> void:
	if not _remote_players.has(client_id):
		return
	var remote: Node = _remote_players[client_id]
	if is_instance_valid(remote):
		remote.queue_free()
	_remote_players.erase(client_id)

func _connect_signal_once(source: Node, signal_name: String, method_name: String) -> void:
	if not source.has_signal(signal_name):
		return
	var callback := Callable(self, method_name)
	if not source.is_connected(signal_name, callback):
		source.connect(signal_name, callback)
