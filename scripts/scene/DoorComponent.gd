extends Node3D

signal state_changed(open: bool)

const LOCKED_DOOR_RATTLE_PATH := "res://assets/audio/locked_door_rattle.wav"
const EXIT_DOOR_UNLOCK_OPEN_PATH := "res://assets/audio/exit_door_unlock_open.wav"

@export var door_id := ""
@export var starts_open := false
@export var open_angle_degrees := 90.0
@export var open_speed_degrees := 360.0
@export var requires_escape_key := false
@export var locked_prompt_text := "E Need key"
@export var unlock_prompt_text := "E Use key"
@export var open_prompt_text := "E Open door"
@export var close_prompt_text := "E Close door"
@export var locked_rattle_cooldown := 0.45
@export_node_path("Node3D") var hinge_pivot_path: NodePath = ^"HingePivot"
@export var closed_leaf_center_offset := Vector3(-0.49, 0.0, 0.0)

var _open := false
var _target_angle := 0.0
var _locked_audio: AudioStreamPlayer3D
var _unlock_audio: AudioStreamPlayer3D
var _last_locked_rattle_time := -999.0

func _ready() -> void:
	add_to_group("interactive_door", true)
	set_meta("requires_escape_key", requires_escape_key)
	_open = starts_open
	_target_angle = deg_to_rad(open_angle_degrees) if _open else 0.0
	var pivot := _hinge_pivot()
	if pivot != null:
		pivot.rotation.y = _target_angle
	_create_lock_audio()

func is_open() -> bool:
	return _open

func open() -> void:
	set_open(true)

func open_toward_direction(world_direction: Vector3) -> void:
	var direction := world_direction
	direction.y = 0.0
	if direction.length_squared() > 0.0001:
		_target_angle = _choose_open_angle(direction.normalized())
	set_open(true)

func close() -> void:
	set_open(false)

func toggle() -> void:
	set_open(not _open)

func interact_from(actor: Node3D, facing_direction: Vector3) -> bool:
	if _open:
		close()
		return true
	if requires_escape_key and not _actor_has_escape_key(actor):
		_register_locked_attempt()
		return false
	if requires_escape_key:
		set_meta("unlocked_with_escape_key", true)
		_play_one_shot(_unlock_audio)
	open_toward_direction(facing_direction)
	return true

func get_interaction_text_for_actor(actor: Node3D) -> String:
	if _open:
		return close_prompt_text
	if requires_escape_key:
		return unlock_prompt_text if _actor_has_escape_key(actor) else locked_prompt_text
	return open_prompt_text

func set_open(value: bool) -> void:
	if _open == value:
		return
	_open = value
	if not _open:
		_target_angle = 0.0
	elif absf(_target_angle) <= 0.0001:
		_target_angle = deg_to_rad(open_angle_degrees)
	state_changed.emit(_open)

func get_target_angle_degrees() -> float:
	return rad_to_deg(_target_angle)

func _physics_process(delta: float) -> void:
	var pivot := _hinge_pivot()
	if pivot == null:
		return
	var max_step := deg_to_rad(open_speed_degrees) * delta
	pivot.rotation.y = move_toward(pivot.rotation.y, _target_angle, max_step)

func _hinge_pivot() -> Node3D:
	return get_node_or_null(hinge_pivot_path) as Node3D

func _choose_open_angle(facing_direction: Vector3) -> float:
	var positive_angle := deg_to_rad(absf(open_angle_degrees))
	var negative_angle := -positive_angle
	var positive_direction := _leaf_direction_for_angle(positive_angle)
	var negative_direction := _leaf_direction_for_angle(negative_angle)
	if positive_direction.dot(facing_direction) >= negative_direction.dot(facing_direction):
		return positive_angle
	return negative_angle

func _leaf_direction_for_angle(angle: float) -> Vector3:
	var local_offset := Basis(Vector3.UP, angle) * closed_leaf_center_offset
	var world_offset := global_transform.basis * local_offset
	world_offset.y = 0.0
	if world_offset.length_squared() <= 0.0001:
		return Vector3.FORWARD
	return world_offset.normalized()

func _actor_has_escape_key(actor: Node3D) -> bool:
	if actor == null:
		return false
	if actor.has_method("has_escape_key"):
		return bool(actor.call("has_escape_key"))
	return bool(actor.get_meta("has_escape_key", false))

func _register_locked_attempt() -> void:
	set_meta("locked_attempt_count", int(get_meta("locked_attempt_count", 0)) + 1)
	var now := Time.get_ticks_msec() * 0.001
	if now - _last_locked_rattle_time < locked_rattle_cooldown:
		return
	_last_locked_rattle_time = now
	_play_one_shot(_locked_audio)

func _create_lock_audio() -> void:
	_locked_audio = AudioStreamPlayer3D.new()
	_locked_audio.name = "LockedDoorRattleAudio"
	_locked_audio.stream = _load_audio_stream(LOCKED_DOOR_RATTLE_PATH)
	_locked_audio.volume_db = -9.0
	_locked_audio.max_distance = 8.0
	add_child(_locked_audio)

	_unlock_audio = AudioStreamPlayer3D.new()
	_unlock_audio.name = "UnlockDoorAudio"
	_unlock_audio.stream = _load_audio_stream(EXIT_DOOR_UNLOCK_OPEN_PATH)
	_unlock_audio.volume_db = -8.0
	_unlock_audio.max_distance = 9.0
	add_child(_unlock_audio)

func _play_one_shot(player: Node) -> void:
	var audio3d := player as AudioStreamPlayer3D
	if audio3d != null and audio3d.stream != null:
		audio3d.stop()
		audio3d.play()

func _load_audio_stream(path: String) -> AudioStream:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as AudioStream
