extends Node3D

@export_node_path("Camera3D") var camera_path: NodePath = ^"ReviewCamera"
@export var orbit_target := Vector3(0.0, 0.75, 0.9)
@export var orbit_distance := 8.65
@export var orbit_yaw := 0.0
@export var orbit_pitch := 0.56
@export var orbit_sensitivity := 0.006
@export var zoom_step := 0.88
@export var min_distance := 1.2
@export var max_distance := 18.0
@export var scale_step := 1.08
@export var rotate_step_degrees := 15.0

var _camera: Camera3D
var _asset_entries: Array[Dictionary] = []
var _selected_index := -1
var _orbiting := false
var _status_label: Label

func _ready() -> void:
	_camera = get_node_or_null(camera_path) as Camera3D
	_collect_asset_entries()
	_initialize_camera_from_scene()
	_build_viewer_ui()
	if not _asset_entries.is_empty():
		_select_index(0)
	_focus_all()
	_update_status_label()

func _unhandled_input(event: InputEvent) -> void:
	if _camera == null:
		return

	var mouse_button := event as InputEventMouseButton
	if mouse_button != null:
		if mouse_button.button_index == MOUSE_BUTTON_RIGHT:
			_orbiting = mouse_button.pressed
			get_viewport().set_input_as_handled()
			return
		if mouse_button.button_index == MOUSE_BUTTON_LEFT and mouse_button.pressed:
			var hit_index := _pick_asset(mouse_button.position)
			if hit_index >= 0:
				_select_index(hit_index)
				get_viewport().set_input_as_handled()
			return
		if mouse_button.button_index == MOUSE_BUTTON_WHEEL_UP and mouse_button.pressed:
			orbit_distance = maxf(min_distance, orbit_distance * zoom_step)
			_apply_camera()
			get_viewport().set_input_as_handled()
			return
		if mouse_button.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse_button.pressed:
			orbit_distance = minf(max_distance, orbit_distance / zoom_step)
			_apply_camera()
			get_viewport().set_input_as_handled()
			return

	var mouse_motion := event as InputEventMouseMotion
	if mouse_motion != null and _orbiting:
		orbit_yaw -= mouse_motion.relative.x * orbit_sensitivity
		orbit_pitch = clampf(orbit_pitch - mouse_motion.relative.y * orbit_sensitivity, deg_to_rad(8.0), deg_to_rad(78.0))
		_apply_camera()
		get_viewport().set_input_as_handled()
		return

	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo:
		match key.keycode:
			KEY_TAB, KEY_BRACKETRIGHT:
				_select_relative(1)
				get_viewport().set_input_as_handled()
			KEY_BRACKETLEFT:
				_select_relative(-1)
				get_viewport().set_input_as_handled()
			KEY_Q:
				_rotate_selected(-rotate_step_degrees)
				get_viewport().set_input_as_handled()
			KEY_E:
				_rotate_selected(rotate_step_degrees)
				get_viewport().set_input_as_handled()
			KEY_EQUAL, KEY_KP_ADD:
				_scale_selected(scale_step)
				get_viewport().set_input_as_handled()
			KEY_MINUS, KEY_KP_SUBTRACT:
				_scale_selected(1.0 / scale_step)
				get_viewport().set_input_as_handled()
			KEY_R:
				_reset_selected()
				get_viewport().set_input_as_handled()
			KEY_F:
				_focus_selected()
				get_viewport().set_input_as_handled()
			KEY_0, KEY_HOME:
				_focus_all()
				get_viewport().set_input_as_handled()

func _collect_asset_entries() -> void:
	_asset_entries.clear()
	for root_name in ["NaturalProps", "DoorProps", "HideableProps", "Characters"]:
		var category_root := get_node_or_null(root_name)
		if category_root == null:
			continue
		for child in category_root.get_children():
			var asset := child as Node3D
			if asset == null:
				continue
			_asset_entries.append({
				"node": asset,
				"display_name": _asset_display_name(asset),
				"initial_transform": asset.transform,
			})

func _asset_display_name(asset: Node3D) -> String:
	var resource_id := String(asset.get_meta("resource_model_id", ""))
	if not resource_id.is_empty():
		return resource_id
	resource_id = String(asset.get_meta("natural_prop_id", ""))
	if not resource_id.is_empty():
		return resource_id
	return asset.name

func _initialize_camera_from_scene() -> void:
	if _camera == null:
		return
	_camera.current = true
	var offset := _camera.global_position - orbit_target
	if offset.length() > 0.1:
		orbit_distance = offset.length()
		orbit_yaw = atan2(offset.x, offset.z)
		orbit_pitch = asin(clampf(offset.y / orbit_distance, -1.0, 1.0))
		orbit_pitch = clampf(orbit_pitch, deg_to_rad(8.0), deg_to_rad(78.0))

func _build_viewer_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "ResourceShowcaseUI"
	add_child(layer)

	var panel := PanelContainer.new()
	panel.name = "ControlsPanel"
	panel.position = Vector2(14.0, 14.0)
	panel.custom_minimum_size = Vector2(440.0, 0.0)
	layer.add_child(panel)

	var box := VBoxContainer.new()
	panel.add_child(box)

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_status_label)

	var row_a := HBoxContainer.new()
	box.add_child(row_a)
	_add_button(row_a, "上一个", _select_previous)
	_add_button(row_a, "下一个", _select_next)
	_add_button(row_a, "看选中", _focus_selected)
	_add_button(row_a, "看全场", _focus_all)

	var row_b := HBoxContainer.new()
	box.add_child(row_b)
	_add_button(row_b, "左旋", func() -> void: _rotate_selected(-rotate_step_degrees))
	_add_button(row_b, "右旋", func() -> void: _rotate_selected(rotate_step_degrees))
	_add_button(row_b, "缩小", func() -> void: _scale_selected(1.0 / scale_step))
	_add_button(row_b, "放大", func() -> void: _scale_selected(scale_step))
	_add_button(row_b, "重置", _reset_selected)

func _add_button(parent: Control, text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(callback)
	parent.add_child(button)

func _select_previous() -> void:
	_select_relative(-1)

func _select_next() -> void:
	_select_relative(1)

func _select_relative(delta: int) -> void:
	if _asset_entries.is_empty():
		return
	var next_index := _selected_index + delta
	if next_index < 0:
		next_index = _asset_entries.size() - 1
	elif next_index >= _asset_entries.size():
		next_index = 0
	_select_index(next_index)

func _select_index(index: int) -> void:
	if index < 0 or index >= _asset_entries.size():
		return
	_selected_index = index
	_update_status_label()

func _selected_node() -> Node3D:
	if _selected_index < 0 or _selected_index >= _asset_entries.size():
		return null
	return _asset_entries[_selected_index].get("node") as Node3D

func _rotate_selected(degrees: float) -> void:
	var selected := _selected_node()
	if selected == null:
		return
	selected.rotation.y += deg_to_rad(degrees)
	_update_status_label()

func _scale_selected(factor: float) -> void:
	var selected := _selected_node()
	if selected == null:
		return
	var next_scale := selected.scale * factor
	var max_axis := maxf(absf(next_scale.x), maxf(absf(next_scale.y), absf(next_scale.z)))
	var min_axis := minf(absf(next_scale.x), minf(absf(next_scale.y), absf(next_scale.z)))
	if max_axis > 4.0 or min_axis < 0.04:
		return
	selected.scale = next_scale
	_update_status_label()

func _reset_selected() -> void:
	if _selected_index < 0 or _selected_index >= _asset_entries.size():
		return
	var selected := _selected_node()
	if selected == null:
		return
	selected.transform = _asset_entries[_selected_index].get("initial_transform", selected.transform)
	_update_status_label()

func _focus_selected() -> void:
	var selected := _selected_node()
	if selected == null:
		return
	var bounds := _asset_world_aabb(selected)
	if bounds.size == Vector3.ZERO:
		return
	orbit_target = _aabb_center(bounds)
	orbit_distance = clampf(maxf(bounds.size.length() * 1.9, 1.6), min_distance, max_distance)
	_apply_camera()
	_update_status_label()

func _focus_all() -> void:
	var bounds := _all_assets_world_aabb()
	if bounds.size == Vector3.ZERO:
		return
	orbit_target = _aabb_center(bounds)
	orbit_distance = clampf(maxf(bounds.size.length() * 0.78, 7.0), min_distance, max_distance)
	_apply_camera()
	_update_status_label()

func _apply_camera() -> void:
	if _camera == null:
		return
	var horizontal := cos(orbit_pitch) * orbit_distance
	var offset := Vector3(
		sin(orbit_yaw) * horizontal,
		sin(orbit_pitch) * orbit_distance,
		cos(orbit_yaw) * horizontal
	)
	_camera.look_at_from_position(orbit_target + offset, orbit_target, Vector3.UP)

func _update_status_label() -> void:
	if _status_label == null:
		return
	var selected := _selected_node()
	var selected_text := "无"
	var scale_text := "-"
	if selected != null:
		selected_text = String(_asset_entries[_selected_index].get("display_name", selected.name))
		scale_text = "(%.3f, %.3f, %.3f)" % [selected.scale.x, selected.scale.y, selected.scale.z]
	_status_label.text = "资源查看器\n选中：%s\n当前缩放：%s\n右键拖动旋转视角，滚轮拉近/拉远。左键点模型可选中。\nTab 或 [ ] 切换资源，Q/E 旋转选中资源，+/- 调整大小，R 重置，F 看选中，0 看全场。\n这里的大小调整只用于预览，不会保存到资源文件。" % [selected_text, scale_text]

func _pick_asset(screen_position: Vector2) -> int:
	var ray_origin := _camera.project_ray_origin(screen_position)
	var ray_direction := _camera.project_ray_normal(screen_position).normalized()
	var best_index := -1
	var best_distance := INF
	for index in range(_asset_entries.size()):
		var asset := _asset_entries[index].get("node") as Node3D
		if asset == null:
			continue
		var bounds := _asset_world_aabb(asset)
		if bounds.size == Vector3.ZERO:
			continue
		var distance := _ray_aabb_distance(ray_origin, ray_direction, bounds.grow(0.08))
		if distance >= 0.0 and distance < best_distance:
			best_distance = distance
			best_index = index
	return best_index

func _asset_world_aabb(asset: Node3D) -> AABB:
	var meshes: Array[MeshInstance3D] = []
	_collect_mesh_instances(asset, meshes)
	var has_bounds := false
	var combined := AABB()
	for mesh_instance in meshes:
		var mesh_bounds := _aabb_to_global(mesh_instance, mesh_instance.get_aabb())
		if has_bounds:
			combined = combined.merge(mesh_bounds)
		else:
			combined = mesh_bounds
			has_bounds = true
	if not has_bounds:
		return AABB()
	return combined

func _all_assets_world_aabb() -> AABB:
	var has_bounds := false
	var combined := AABB()
	for entry in _asset_entries:
		var asset := entry.get("node") as Node3D
		if asset == null:
			continue
		var bounds := _asset_world_aabb(asset)
		if bounds.size == Vector3.ZERO:
			continue
		if has_bounds:
			combined = combined.merge(bounds)
		else:
			combined = bounds
			has_bounds = true
	if not has_bounds:
		return AABB()
	return combined

func _collect_mesh_instances(node: Node, output: Array[MeshInstance3D]) -> void:
	var mesh_instance := node as MeshInstance3D
	if mesh_instance != null and mesh_instance.mesh != null:
		output.append(mesh_instance)
	for child in node.get_children():
		_collect_mesh_instances(child, output)

func _aabb_to_global(node: Node3D, local_aabb: AABB) -> AABB:
	var corners := [
		local_aabb.position,
		local_aabb.position + Vector3(local_aabb.size.x, 0.0, 0.0),
		local_aabb.position + Vector3(0.0, local_aabb.size.y, 0.0),
		local_aabb.position + Vector3(0.0, 0.0, local_aabb.size.z),
		local_aabb.position + Vector3(local_aabb.size.x, local_aabb.size.y, 0.0),
		local_aabb.position + Vector3(local_aabb.size.x, 0.0, local_aabb.size.z),
		local_aabb.position + Vector3(0.0, local_aabb.size.y, local_aabb.size.z),
		local_aabb.position + local_aabb.size,
	]
	var converted := AABB(node.global_transform * corners[0], Vector3.ZERO)
	for index in range(1, corners.size()):
		converted = converted.expand(node.global_transform * corners[index])
	return converted

func _aabb_center(bounds: AABB) -> Vector3:
	return bounds.position + bounds.size * 0.5

func _ray_aabb_distance(origin: Vector3, direction: Vector3, bounds: AABB) -> float:
	var origin_values := [origin.x, origin.y, origin.z]
	var direction_values := [direction.x, direction.y, direction.z]
	var min_values := [bounds.position.x, bounds.position.y, bounds.position.z]
	var max_values := [bounds.end.x, bounds.end.y, bounds.end.z]
	var near_distance := -INF
	var far_distance := INF
	for axis in range(3):
		var axis_direction: float = direction_values[axis]
		var axis_origin: float = origin_values[axis]
		if absf(axis_direction) < 0.00001:
			if axis_origin < min_values[axis] or axis_origin > max_values[axis]:
				return -1.0
			continue
		var t1: float = (min_values[axis] - axis_origin) / axis_direction
		var t2: float = (max_values[axis] - axis_origin) / axis_direction
		if t1 > t2:
			var swapped := t1
			t1 = t2
			t2 = swapped
		near_distance = maxf(near_distance, t1)
		far_distance = minf(far_distance, t2)
		if near_distance > far_distance:
			return -1.0
	if far_distance < 0.0:
		return -1.0
	return maxf(near_distance, 0.0)
