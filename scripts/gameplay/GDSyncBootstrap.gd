extends Node

const CLIENT_PATH := "res://addons/GD-Sync/MultiplayerClient.gd"
const ENUMS_PATH := "res://addons/GD-Sync/Scripts/Enums/Enums.gd"
const LOCAL_CONFIG_RES := "res://local_gdsync_keys.cfg"
const LOCAL_CONFIG_USER := "user://gdsync_keys.cfg"

var configured := false
var status_message := "GD-Sync keys are not configured."

func _ready() -> void:
	apply_configuration()

func apply_configuration() -> bool:
	var keys := _read_project_keys()
	if not _keys_are_valid(keys):
		keys = _load_keys_from_environment()
	if not _keys_are_valid(keys):
		keys = _load_keys_from_file(LOCAL_CONFIG_RES)
	if not _keys_are_valid(keys):
		keys = _load_keys_from_file(LOCAL_CONFIG_USER)

	configured = _keys_are_valid(keys)
	if not configured:
		status_message = "Online is unavailable: missing GD-Sync keys."
		return false

	ProjectSettings.set_setting("GD-Sync/publicKey", String(keys["public_key"]))
	ProjectSettings.set_setting("GD-Sync/privateKey", String(keys["private_key"]))
	ProjectSettings.set_setting("GD-Sync/protectedMode", true)
	ProjectSettings.set_setting("GD-Sync/uniqueUsername", false)
	ProjectSettings.set_setting("GD-Sync/useSenderID", false)
	status_message = "GD-Sync keys configured."
	return true

func get_or_create_client() -> Node:
	if not apply_configuration():
		return null

	var existing := get_node_or_null("/root/GDSync")
	if existing != null:
		return existing

	if not ResourceLoader.exists(CLIENT_PATH):
		status_message = "Online is unavailable: GD-Sync addon is missing."
		return null
	load(ENUMS_PATH)

	var script := load(CLIENT_PATH) as Script
	if script == null:
		status_message = "Online is unavailable: GD-Sync client script failed to load."
		return null

	var client := script.new() as Node
	if client == null:
		status_message = "Online is unavailable: GD-Sync client failed to instantiate."
		return null
	client.name = "GDSync"
	get_tree().root.add_child(client)
	return client

func _read_project_keys() -> Dictionary:
	return {
		"public_key": String(ProjectSettings.get_setting("GD-Sync/publicKey", "")),
		"private_key": String(ProjectSettings.get_setting("GD-Sync/privateKey", "")),
	}

func _load_keys_from_environment() -> Dictionary:
	return {
		"public_key": OS.get_environment("GDSYNC_PUBLIC_KEY").strip_edges(),
		"private_key": OS.get_environment("GDSYNC_PRIVATE_KEY").strip_edges(),
	}

func _load_keys_from_file(path: String) -> Dictionary:
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return {}
	return {
		"public_key": String(config.get_value("gdsync", "public_key", "")).strip_edges(),
		"private_key": String(config.get_value("gdsync", "private_key", "")).strip_edges(),
	}

func _keys_are_valid(keys: Dictionary) -> bool:
	return (
		keys.has("public_key")
		and keys.has("private_key")
		and not String(keys["public_key"]).strip_edges().is_empty()
		and not String(keys["private_key"]).strip_edges().is_empty()
	)
