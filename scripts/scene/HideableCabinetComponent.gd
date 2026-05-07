extends Node3D

@export var front_direction_local := Vector3(0.0, 0.0, 1.0)
@export_node_path("Marker3D") var hide_stand_point_path: NodePath = ^"HideStandPoint"
@export_node_path("Marker3D") var hide_camera_anchor_path: NodePath = ^"HideCameraAnchor"
@export_node_path("Marker3D") var exit_marker_path: NodePath = ^"ExitMarker"
@export var peek_fov := 34.0
@export var peek_yaw_limit_degrees := 18.0
@export var peek_pitch_limit_degrees := 8.0
@export var mouse_sensitivity := 0.0022
@export var keyboard_look_speed_degrees := 42.0
@export var front_interaction_width := 0.96
@export var front_interaction_max_depth := 1.42
@export var front_interaction_facing_dot := 0.18

var _occupant: Node3D
var _camera: Camera3D
var _camera_rig: Node
var _camera_rig_was_physics_processing := false
var _camera_rig_was_processing_unhandled_input := false
var _stored_camera_global_transform := Transform3D.IDENTITY
var _stored_camera_fov := 62.0
var _stored_actor_global_transform := Transform3D.IDENTITY
var _actor_was_visible := true
var _disabled_collision_shapes: Array[Dictionary] = []
var _peek_yaw := 0.0
var _peek_pitch := 0.0
var _previous_mouse_mode := Input.MOUSE_MODE_VISIBLE
var _peek_mask: CanvasLayer
var _exit_button_layer: CanvasLayer
var _exit_button: Button

func _ready() -> void:
	add_to_group("interactive_hideable")

func _process(delta: float) -> void:
	if _occupant == null:
		return
	var look_input := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)
	if look_input.length_squared() <= 0.0001:
		return
	_peek_yaw += deg_to_rad(keyboard_look_speed_degrees) * look_input.x * delta
	_peek_pitch += deg_to_rad(keyboard_look_speed_degrees) * look_input.y * delta
	_clamp_peek_angles()
	_apply_peek_camera_transform()

func _unhandled_input(event: InputEvent) -> void:
	if _occupant == null:
		return
	if event.is_action_pressed("interact"):
		if event is InputEventKey and event.echo:
			return
		_exit_hide()
		get_viewport().set_input_as_handled()
		return
	var mouse_motion := event as InputEventMouseMotion
	if mouse_motion == null or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	apply_peek_mouse_motion(mouse_motion.relative)
	get_viewport().set_input_as_handled()

func interact_from(actor: Node3D, _facing_direction: Vector3) -> bool:
	if actor == null:
		return false
	if _occupant == null:
		return _enter_hide(actor)
	if _occupant == actor:
		_exit_hide()
		return true
	return false

func is_occupied() -> bool:
	return _occupant != null

func apply_peek_mouse_motion(relative_motion: Vector2) -> void:
	if _occupant == null:
		return
	_peek_yaw -= relative_motion.x * mouse_sensitivity
	_peek_pitch -= relative_motion.y * mouse_sensitivity
	_clamp_peek_angles()
	_apply_peek_camera_transform()

func get_interaction_position() -> Vector3:
	var marker := get_node_or_null(exit_marker_path) as Marker3D
	if marker != null:
		return marker.global_position
	return global_position + _get_front_direction() * 0.45

func can_interact_from(actor: Node3D, facing_direction: Vector3, max_distance: float = 1.35) -> bool:
	if actor == null:
		return false
	var front := _get_front_direction()
	var flat_to_actor := actor.global_position - global_position
	flat_to_actor.y = 0.0
	if flat_to_actor.length_squared() <= 0.0001:
		return false
	var front_distance := flat_to_actor.dot(front)
	if front_distance < 0.10 or front_distance > maxf(front_interaction_max_depth, max_distance):
		return false
	var right := front.cross(Vector3.UP).normalized()
	var side_distance := absf(flat_to_actor.dot(right))
	if side_distance > front_interaction_width * 0.5:
		return false
	var flat_facing := facing_direction
	flat_facing.y = 0.0
	if flat_facing.length_squared() <= 0.0001:
		return false
	return flat_facing.normalized().dot(-front) >= front_interaction_facing_dot

func _enter_hide(actor: Node3D) -> bool:
	var camera := _find_current_camera()
	var anchor := get_node_or_null(hide_camera_anchor_path) as Marker3D
	var stand_point := get_node_or_null(hide_stand_point_path) as Marker3D
	if camera == null or anchor == null or stand_point == null:
		return false

	_occupant = actor
	_camera = camera
	_camera_rig = _camera.get_parent()
	_stored_actor_global_transform = actor.global_transform
	_actor_was_visible = actor.visible
	_stored_camera_global_transform = _camera.global_transform
	_stored_camera_fov = _camera.fov
	_previous_mouse_mode = Input.mouse_mode
	_peek_yaw = 0.0
	_peek_pitch = 0.0

	if actor.has_method("set_interaction_locked"):
		actor.call("set_interaction_locked", true)
	if actor.has_method("set_hidden_in_hideable"):
		actor.call("set_hidden_in_hideable", true, self)
	_store_and_disable_collision_shapes(actor)
	actor.global_position = stand_point.global_position
	actor.visible = false

	if _camera_rig != null:
		_camera_rig_was_physics_processing = _camera_rig.is_physics_processing()
		_camera_rig_was_processing_unhandled_input = _camera_rig.is_processing_unhandled_input()
		_camera_rig.set_physics_process(false)
		_camera_rig.set_process_unhandled_input(false)
	_camera.fov = peek_fov
	_apply_peek_camera_transform()
	_create_peek_mask()
	_create_exit_button()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	return true

func _exit_hide() -> void:
	var actor := _occupant
	if actor == null:
		return
	_remove_exit_button()
	_remove_peek_mask()

	var exit_marker := get_node_or_null(exit_marker_path) as Marker3D
	if exit_marker != null:
		actor.global_position = exit_marker.global_position
	else:
		actor.global_transform = _stored_actor_global_transform
	actor.visible = _actor_was_visible
	_restore_collision_shapes()
	if actor.has_method("set_interaction_locked"):
		actor.call("set_interaction_locked", false)
	if actor.has_method("set_hidden_in_hideable"):
		actor.call("set_hidden_in_hideable", false, self)

	if _camera != null:
		_camera.global_transform = _stored_camera_global_transform
		_camera.fov = _stored_camera_fov
	if _camera_rig != null:
		_camera_rig.set_physics_process(_camera_rig_was_physics_processing)
		_camera_rig.set_process_unhandled_input(_camera_rig_was_processing_unhandled_input)
	Input.mouse_mode = _previous_mouse_mode

	_occupant = null
	_camera = null
	_camera_rig = null

func _clamp_peek_angles() -> void:
	_peek_yaw = clampf(_peek_yaw, -deg_to_rad(peek_yaw_limit_degrees), deg_to_rad(peek_yaw_limit_degrees))
	_peek_pitch = clampf(_peek_pitch, -deg_to_rad(peek_pitch_limit_degrees), deg_to_rad(peek_pitch_limit_degrees))

func _apply_peek_camera_transform() -> void:
	if _camera == null:
		return
	var anchor := get_node_or_null(hide_camera_anchor_path) as Marker3D
	if anchor == null:
		return
	var front := _get_front_direction()
	var basis := Basis.looking_at(front, Vector3.UP)
	basis = Basis(Vector3.UP, _peek_yaw) * basis
	basis = Basis(basis.x.normalized(), _peek_pitch) * basis
	_camera.global_transform = Transform3D(basis.orthonormalized(), anchor.global_position)

func _get_front_direction() -> Vector3:
	var front := global_transform.basis * front_direction_local
	front.y = 0.0
	if front.length_squared() <= 0.0001:
		return Vector3.FORWARD
	return front.normalized()

func _find_current_camera() -> Camera3D:
	var viewport := get_viewport()
	if viewport != null:
		var current_camera := viewport.get_camera_3d()
		if current_camera != null:
			return current_camera
	return _find_camera_recursive(get_tree().root)

func _find_camera_recursive(node: Node) -> Camera3D:
	var camera := node as Camera3D
	if camera != null and camera.current:
		return camera
	for child in node.get_children():
		var result := _find_camera_recursive(child)
		if result != null:
			return result
	return null

func _store_and_disable_collision_shapes(node: Node) -> void:
	_disabled_collision_shapes.clear()
	_store_and_disable_collision_shapes_recursive(node)

func _store_and_disable_collision_shapes_recursive(node: Node) -> void:
	var shape := node as CollisionShape3D
	if shape != null:
		_disabled_collision_shapes.append({"shape": shape, "disabled": shape.disabled})
		shape.disabled = true
	for child in node.get_children():
		_store_and_disable_collision_shapes_recursive(child)

func _restore_collision_shapes() -> void:
	for entry in _disabled_collision_shapes:
		var shape := entry["shape"] as CollisionShape3D
		if shape != null:
			shape.disabled = bool(entry["disabled"])
	_disabled_collision_shapes.clear()

func _create_peek_mask() -> void:
	_remove_peek_mask()
	_peek_mask = CanvasLayer.new()
	_peek_mask.name = "HideLockerPeekSlitMask"
	_peek_mask.layer = 80
	add_child(_peek_mask)

	var root_control := Control.new()
	root_control.name = "MaskRoot"
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	_peek_mask.add_child(root_control)

	var left_edge := 0.16
	var right_edge := 0.84
	var top_edge := 0.285
	var bottom_edge := 0.600
	var bar_height := 0.016

	_add_mask_rect(root_control, 0.0, 0.0, 1.0, top_edge)
	_add_mask_rect(root_control, 0.0, bottom_edge, 1.0, 1.0)
	_add_mask_rect(root_control, 0.0, top_edge, left_edge, bottom_edge)
	_add_mask_rect(root_control, right_edge, top_edge, 1.0, bottom_edge)
	for y in [0.326, 0.385, 0.444, 0.503, 0.562]:
		_add_mask_rect(root_control, left_edge, y, right_edge, y + bar_height)
		_add_soft_mask_edge(root_control, left_edge, y - 0.010, right_edge, y, 0.32)
		_add_soft_mask_edge(root_control, left_edge, y + bar_height, right_edge, y + bar_height + 0.010, 0.32)
	_add_soft_mask_edge(root_control, left_edge, top_edge, right_edge, top_edge + 0.020, 0.36)
	_add_soft_mask_edge(root_control, left_edge, bottom_edge - 0.020, right_edge, bottom_edge, 0.36)
	_add_soft_mask_edge(root_control, left_edge, top_edge, left_edge + 0.020, bottom_edge, 0.28)
	_add_soft_mask_edge(root_control, right_edge - 0.020, top_edge, right_edge, bottom_edge, 0.28)

func _add_mask_rect(parent: Control, left: float, top: float, right: float, bottom: float) -> void:
	_add_mask_rect_with_opacity(parent, left, top, right, bottom, 1.0, "OpaqueMaskRect")

func _add_soft_mask_edge(parent: Control, left: float, top: float, right: float, bottom: float, opacity: float) -> void:
	_add_mask_rect_with_opacity(parent, left, top, right, bottom, opacity, "SoftMaskEdge")

func _add_mask_rect_with_opacity(parent: Control, left: float, top: float, right: float, bottom: float, opacity: float, node_name: String) -> void:
	var rect := ColorRect.new()
	rect.name = "%s_%02d" % [node_name, parent.get_child_count()]
	rect.color = Color(0.0, 0.0, 0.0, opacity)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.anchor_left = left
	rect.anchor_top = top
	rect.anchor_right = right
	rect.anchor_bottom = bottom
	rect.offset_left = 0.0
	rect.offset_top = 0.0
	rect.offset_right = 0.0
	rect.offset_bottom = 0.0
	parent.add_child(rect)

func _remove_peek_mask() -> void:
	if _peek_mask != null:
		_peek_mask.queue_free()
		_peek_mask = null

func _create_exit_button() -> void:
	_remove_exit_button()
	_exit_button_layer = CanvasLayer.new()
	_exit_button_layer.name = "HideLockerExitButtonLayer"
	_exit_button_layer.layer = 95
	add_child(_exit_button_layer)

	_exit_button = Button.new()
	_exit_button.name = "ExitHideButton"
	_exit_button.text = "E 出来"
	_exit_button.focus_mode = Control.FOCUS_NONE
	_exit_button.custom_minimum_size = Vector2(144.0, 58.0)
	_exit_button.anchor_left = 0.5
	_exit_button.anchor_top = 1.0
	_exit_button.anchor_right = 0.5
	_exit_button.anchor_bottom = 1.0
	_exit_button.offset_left = -72.0
	_exit_button.offset_top = -96.0
	_exit_button.offset_right = 72.0
	_exit_button.offset_bottom = -38.0
	_exit_button.add_theme_font_size_override("font_size", 22)
	_exit_button.add_theme_color_override("font_color", Color(0.96, 0.90, 0.72, 1.0))
	_exit_button.add_theme_color_override("font_pressed_color", Color(1.0, 0.88, 0.52, 1.0))
	_exit_button.add_theme_stylebox_override("normal", _make_exit_button_style(Color(0.055, 0.052, 0.040, 0.92), Color(0.62, 0.53, 0.28, 0.92)))
	_exit_button.add_theme_stylebox_override("hover", _make_exit_button_style(Color(0.090, 0.082, 0.055, 0.96), Color(0.78, 0.66, 0.34, 1.0)))
	_exit_button.add_theme_stylebox_override("pressed", _make_exit_button_style(Color(0.135, 0.102, 0.048, 0.98), Color(0.92, 0.73, 0.28, 1.0)))
	_exit_button.pressed.connect(_exit_hide)
	_exit_button_layer.add_child(_exit_button)

func _make_exit_button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style

func _remove_exit_button() -> void:
	if _exit_button_layer != null:
		_exit_button_layer.queue_free()
		_exit_button_layer = null
	_exit_button = null
