extends Node3D

@export_node_path("Node3D") var target_path: NodePath
@export var distance := 1.8
@export var target_height := 1.0
@export var look_ahead := 0.85
@export var initial_yaw_degrees := 90.0
@export var pitch_degrees := 3.0
@export var min_pitch_degrees := -5.0
@export var max_pitch_degrees := 12.0
@export var shoulder_offset := 0.0
@export var follow_smoothing := 18.0
@export var mouse_sensitivity := 0.003
@export var touch_sensitivity := 0.004
@export var capture_mouse_on_click := true

var _yaw := 0.0
var _pitch := 0.0

func _ready() -> void:
	_yaw = deg_to_rad(initial_yaw_degrees)
	_pitch = deg_to_rad(pitch_degrees)
	snap_to_target()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton and event.pressed and capture_mouse_on_click:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			get_viewport().set_input_as_handled()
			return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_rotate_view(event.relative, mouse_sensitivity)
		get_viewport().set_input_as_handled()
		return

	if event is InputEventScreenDrag:
		_rotate_view(event.relative, touch_sensitivity)
		get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
	_follow_target(delta)

func snap_to_target() -> void:
	var target := get_node_or_null(target_path) as Node3D
	if target == null:
		return
	var desired_position := _get_desired_position(target)
	global_position = desired_position
	_look_at_target(target)

func _follow_target(delta: float) -> void:
	var target := get_node_or_null(target_path) as Node3D
	if target == null:
		return
	var desired_position := _get_desired_position(target)
	global_position = global_position.lerp(desired_position, clampf(delta * follow_smoothing, 0.0, 1.0))
	_look_at_target(target)

func _rotate_view(relative_motion: Vector2, sensitivity: float) -> void:
	_yaw = wrapf(_yaw - relative_motion.x * sensitivity, -PI, PI)
	_pitch += relative_motion.y * sensitivity
	_pitch = clampf(_pitch, deg_to_rad(min_pitch_degrees), deg_to_rad(max_pitch_degrees))

func _get_desired_position(target: Node3D) -> Vector3:
	var focus := _get_focus_position(target)
	var flat_forward := _get_flat_forward()
	var right := _get_flat_right(flat_forward)
	var horizontal_distance := cos(_pitch) * distance
	var height := sin(_pitch) * distance
	return focus - flat_forward * horizontal_distance + right * shoulder_offset + Vector3.UP * height

func _look_at_target(target: Node3D) -> void:
	var focus := _get_focus_position(target)
	var look_target := focus + _get_flat_forward() * look_ahead
	look_at(look_target, Vector3.UP)

func _get_focus_position(target: Node3D) -> Vector3:
	return target.global_position + Vector3.UP * target_height

func get_flat_forward() -> Vector3:
	return _get_flat_forward()

func _get_flat_forward() -> Vector3:
	return Vector3(sin(_yaw), 0.0, cos(_yaw)).normalized()

func _get_flat_right(forward: Vector3) -> Vector3:
	return Vector3(forward.z, 0.0, -forward.x).normalized()
