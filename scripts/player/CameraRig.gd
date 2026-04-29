extends Node3D
class_name CameraRig

@export var target_path: NodePath
@export var follow_lerp := 9.0
@export var mouse_yaw_sensitivity := 0.006
@export var mouse_zoom_sensitivity := 0.015

var yaw_index := 0
var zoom_index := 1
var zooms := [
	{"distance": 6.4, "height": 4.9},
	{"distance": 7.8, "height": 5.7},
	{"distance": 10.2, "height": 7.0},
]
var target_yaw := deg_to_rad(45.0)
var current_yaw := deg_to_rad(45.0)
var target_zoom := 1.0
var current_zoom := 1.0
var middle_dragging := false
var target: Node3D
var camera: Camera3D


func _ready() -> void:
	add_to_group("camera_rig")
	top_level = true
	target = get_node_or_null(target_path) as Node3D
	if not target:
		target = get_parent() as Node3D
	camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.fov = 50.0
	camera.current = true
	add_child(camera)
	global_position = target.global_position if target else Vector3.ZERO


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_MIDDLE:
			middle_dragging = mouse_button.pressed
			get_viewport().set_input_as_handled()
		elif mouse_button.button_index == MOUSE_BUTTON_WHEEL_UP and mouse_button.pressed:
			target_zoom = clamp(target_zoom - 0.34, 0.0, float(zooms.size() - 1))
			get_viewport().set_input_as_handled()
		elif mouse_button.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse_button.pressed:
			target_zoom = clamp(target_zoom + 0.34, 0.0, float(zooms.size() - 1))
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and middle_dragging:
		var motion := event as InputEventMouseMotion
		target_yaw -= motion.relative.x * mouse_yaw_sensitivity
		target_zoom = clamp(target_zoom + motion.relative.y * mouse_zoom_sensitivity, 0.0, float(zooms.size() - 1))
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not target:
		return
	if Input.is_action_just_pressed("rotate_camera_left"):
		yaw_index -= 1
		target_yaw -= deg_to_rad(90.0)
	if Input.is_action_just_pressed("rotate_camera_right"):
		yaw_index += 1
		target_yaw += deg_to_rad(90.0)
	if Input.is_action_just_pressed("zoom_camera"):
		zoom_index = (int(round(target_zoom)) + 1) % zooms.size()
		target_zoom = float(zoom_index)

	global_position = global_position.lerp(target.global_position, 1.0 - exp(-follow_lerp * delta))
	current_yaw = lerp_angle(current_yaw, target_yaw, 1.0 - exp(-10.0 * delta))
	current_zoom = lerp(current_zoom, target_zoom, 1.0 - exp(-9.0 * delta))
	var zoom := _sample_zoom(current_zoom)
	var distance: float = zoom.x
	var height: float = zoom.y
	var offset := Vector3(sin(current_yaw) * distance, height, cos(current_yaw) * distance)
	camera.global_position = global_position + offset
	camera.look_at(global_position + Vector3(0.0, 1.0, 0.0), Vector3.UP)


func _sample_zoom(value: float) -> Vector2:
	var lower: int = int(floor(value))
	var upper: int = min(lower + 1, zooms.size() - 1)
	var blend: float = clamp(value - float(lower), 0.0, 1.0)
	var zoom_a: Dictionary = zooms[lower]
	var zoom_b: Dictionary = zooms[upper]
	var distance: float = lerp(float(zoom_a["distance"]), float(zoom_b["distance"]), blend)
	var height: float = lerp(float(zoom_a["height"]), float(zoom_b["height"]), blend)
	return Vector2(distance, height)
