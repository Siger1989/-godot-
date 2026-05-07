extends Node

signal online_status_changed(message: String)
signal online_ready

var mode := "single"
var player_name := "Player"
var room_code := ""
var online_requested := false
var service_status := "offline"
var service_message := "Single-player mode"

var _gdsync: Node
var _lobby_request_sent := false
var _online_ready := false

func configure_single(name_text: String) -> void:
	mode = "single"
	player_name = _clean_player_name(name_text)
	room_code = ""
	online_requested = false
	_lobby_request_sent = false
	_online_ready = false
	_set_status("offline", "Single-player mode")

func configure_host(name_text: String, requested_room_code: String) -> void:
	mode = "host"
	player_name = _clean_player_name(name_text)
	room_code = _clean_room_code(requested_room_code)
	if room_code.is_empty():
		room_code = _generate_room_code()
	online_requested = true
	_lobby_request_sent = false
	_online_ready = false
	_set_status("pending_online", "Ready to create online room %s" % room_code)

func configure_join(name_text: String, requested_room_code: String) -> bool:
	var cleaned_room := _clean_room_code(requested_room_code)
	if cleaned_room.is_empty():
		_set_status("missing_room", "Enter a room code to join.")
		return false
	mode = "join"
	player_name = _clean_player_name(name_text)
	room_code = cleaned_room
	online_requested = true
	_lobby_request_sent = false
	_online_ready = false
	_set_status("pending_online", "Ready to join online room %s" % room_code)
	return true

func is_online_mode() -> bool:
	return online_requested

func is_online_ready() -> bool:
	return _online_ready

func start_online_if_needed() -> bool:
	if not online_requested:
		return true
	if _online_ready:
		return true

	var bootstrap := get_node_or_null("/root/GDSyncBootstrap")
	if bootstrap == null:
		_fail_online("GD-Sync bootstrap is not loaded.")
		return false
	if bootstrap.has_method("apply_configuration") and not bool(bootstrap.call("apply_configuration")):
		_fail_online(String(bootstrap.get("status_message")))
		return false

	_gdsync = bootstrap.call("get_or_create_client") as Node
	if _gdsync == null:
		_fail_online(String(bootstrap.get("status_message")))
		return false

	_connect_gdsync_signals(_gdsync)
	if _client_is_connected(_gdsync):
		_begin_lobby_action()
		return false

	if _gdsync.has_method("is_active") and bool(_gdsync.call("is_active")):
		_set_status("connecting_online", "Connecting to GD-Sync...")
		return false

	_set_status("connecting_online", "Connecting to GD-Sync...")
	_gdsync.call("start_multiplayer")
	return false

func get_service_message() -> String:
	return service_message

func _begin_lobby_action() -> void:
	if _gdsync == null or _lobby_request_sent:
		return

	_lobby_request_sent = true
	if _gdsync.has_method("player_set_username"):
		_gdsync.call("player_set_username", player_name)

	if mode == "host":
		_set_status("creating_room", "Creating online room %s..." % room_code)
		_gdsync.call("lobby_create", room_code, "", true, 4)
	elif mode == "join":
		_set_status("joining_room", "Joining online room %s..." % room_code)
		_gdsync.call("lobby_join", room_code, "")
	else:
		_online_ready = true
		emit_signal("online_ready")

func _connect_gdsync_signals(source: Node) -> void:
	_connect_signal_once(source, "connected", "_on_gdsync_connected")
	_connect_signal_once(source, "connection_failed", "_on_gdsync_connection_failed")
	_connect_signal_once(source, "disconnected", "_on_gdsync_disconnected")
	_connect_signal_once(source, "lobby_created", "_on_gdsync_lobby_created")
	_connect_signal_once(source, "lobby_creation_failed", "_on_gdsync_lobby_creation_failed")
	_connect_signal_once(source, "lobby_joined", "_on_gdsync_lobby_joined")
	_connect_signal_once(source, "lobby_join_failed", "_on_gdsync_lobby_join_failed")

func _connect_signal_once(source: Node, signal_name: String, method_name: String) -> void:
	if not source.has_signal(signal_name):
		return
	var callback := Callable(self, method_name)
	if not source.is_connected(signal_name, callback):
		source.connect(signal_name, callback)

func _client_is_connected(source: Node) -> bool:
	return source.has_method("get_client_id") and int(source.call("get_client_id")) >= 0

func _on_gdsync_connected() -> void:
	_begin_lobby_action()

func _on_gdsync_connection_failed(error: int) -> void:
	_fail_online("GD-Sync connection failed: %s" % str(error))

func _on_gdsync_disconnected() -> void:
	if online_requested and not _online_ready:
		_fail_online("Disconnected before the online room was ready.")
	elif online_requested:
		_set_status("online_disconnected", "Online connection closed.")

func _on_gdsync_lobby_created(lobby_name: String) -> void:
	if lobby_name != room_code:
		return
	_mark_online_ready("Online room created: %s" % room_code)

func _on_gdsync_lobby_creation_failed(lobby_name: String, error: int) -> void:
	if lobby_name == room_code:
		_fail_online("Failed to create room %s: %s" % [room_code, str(error)])

func _on_gdsync_lobby_joined(lobby_name: String) -> void:
	if lobby_name != room_code:
		return
	_mark_online_ready("Joined online room: %s" % room_code)

func _on_gdsync_lobby_join_failed(lobby_name: String, error: int) -> void:
	if lobby_name == room_code:
		_fail_online("Failed to join room %s: %s" % [room_code, str(error)])

func _mark_online_ready(message: String) -> void:
	_online_ready = true
	_set_status("online_ready", message)
	emit_signal("online_ready")

func _fail_online(message: String) -> void:
	_lobby_request_sent = false
	_online_ready = false
	_set_status("online_failed", message)

func _set_status(status: String, message: String) -> void:
	service_status = status
	service_message = message
	emit_signal("online_status_changed", service_message)

func _clean_player_name(value: String) -> String:
	var cleaned := value.strip_edges()
	if cleaned.is_empty():
		return "Player"
	return cleaned.substr(0, 18)

func _clean_room_code(value: String) -> String:
	var cleaned := value.strip_edges().to_upper()
	var result := ""
	for index in range(cleaned.length()):
		var code := cleaned.unicode_at(index)
		var is_digit := code >= 48 and code <= 57
		var is_upper := code >= 65 and code <= 90
		if is_digit or is_upper:
			result += cleaned.substr(index, 1)
	return result.substr(0, 8)

func _generate_room_code() -> String:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var alphabet := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
	var result := ""
	for _index in range(6):
		result += alphabet[rng.randi_range(0, alphabet.length() - 1)]
	return result
