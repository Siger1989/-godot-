extends Node3D

const MonsterSizeSource = preload("res://scripts/monster/MonsterSizeSource.gd")
const TransformStore = preload("res://scripts/tools/MonsterSourceTransformStore.gd")
const DoorReferenceScene = preload("res://assets/backrooms/props/doors/OldOfficeDoor_A.tscn")

const PREVIEW_CENTER := Vector3.ZERO
const TARGET_FORWARD := Vector3(0.0, 0.0, -1.0)

@export var camera_distance := 5.2
@export var camera_yaw := deg_to_rad(38.0)
@export var camera_pitch := deg_to_rad(28.0)
@export var camera_min_distance := 1.2
@export var camera_max_distance := 14.0
@export var orbit_sensitivity := 0.006

var _entries: Array[Dictionary] = []
var _selected_index := -1
var _preview_root: Node3D
var _preview_monster: Node3D
var _door_reference: Node3D
var _camera: Camera3D
var _orbit_target := Vector3(0.0, 0.9, 0.0)
var _orbiting := false
var _updating_controls := false

var _monster_picker: OptionButton
var _animation_picker: OptionButton
var _status_label: Label
var _front_help_label: Label
var _direction_label: Label
var _bounds_label: Label
var _save_label: Label
var _lock_scale_check: CheckBox
var _pos_x: SpinBox
var _pos_y: SpinBox
var _pos_z: SpinBox
var _rot_pitch: SpinBox
var _rot_yaw: SpinBox
var _rot_roll: SpinBox
var _visual_yaw: SpinBox
var _scale_uniform: SpinBox
var _scale_x: SpinBox
var _scale_y: SpinBox
var _scale_z: SpinBox
var _collision_pos_x: SpinBox
var _collision_pos_y: SpinBox
var _collision_pos_z: SpinBox
var _collision_size_x: SpinBox
var _collision_size_y: SpinBox
var _collision_size_z: SpinBox
var _animation_speed: SpinBox
var _target_forward_line: MeshInstance3D
var _target_forward_label: Label3D
var _forward_line: MeshInstance3D
var _forward_label: Label3D
var _model_forward_line: MeshInstance3D
var _model_forward_label: Label3D
var _collision_wire: MeshInstance3D
var _collision_label: Label3D

func _ready() -> void:
	_entries = TransformStore.monster_entries()
	_build_stage()
	_build_ui()
	if not _entries.is_empty():
		_select_monster(0)
	_update_camera()

func _unhandled_input(event: InputEvent) -> void:
	var mouse_button := event as InputEventMouseButton
	if mouse_button != null:
		if mouse_button.button_index == MOUSE_BUTTON_RIGHT:
			_orbiting = mouse_button.pressed
			get_viewport().set_input_as_handled()
			return
		if mouse_button.button_index == MOUSE_BUTTON_WHEEL_UP and mouse_button.pressed:
			camera_distance = maxf(camera_min_distance, camera_distance * 0.88)
			_update_camera()
			get_viewport().set_input_as_handled()
			return
		if mouse_button.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse_button.pressed:
			camera_distance = minf(camera_max_distance, camera_distance / 0.88)
			_update_camera()
			get_viewport().set_input_as_handled()
			return

	var mouse_motion := event as InputEventMouseMotion
	if mouse_motion != null and _orbiting:
		camera_yaw -= mouse_motion.relative.x * orbit_sensitivity
		camera_pitch = clampf(camera_pitch - mouse_motion.relative.y * orbit_sensitivity, deg_to_rad(8.0), deg_to_rad(78.0))
		_update_camera()
		get_viewport().set_input_as_handled()
		return

	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo:
		match key.keycode:
			KEY_BRACKETLEFT:
				_select_relative(-1)
				get_viewport().set_input_as_handled()
			KEY_BRACKETRIGHT, KEY_TAB:
				_select_relative(1)
				get_viewport().set_input_as_handled()
			KEY_Q:
				_nudge_yaw(-15.0)
				get_viewport().set_input_as_handled()
			KEY_E:
				_nudge_yaw(15.0)
				get_viewport().set_input_as_handled()
			KEY_F:
				_focus_preview()
				get_viewport().set_input_as_handled()
			KEY_G:
				_snap_to_ground()
				get_viewport().set_input_as_handled()
			KEY_SPACE:
				_play_selected_animation()
				get_viewport().set_input_as_handled()

func debug_get_entry_count() -> int:
	return _entries.size()

func debug_select_index(index: int) -> void:
	_select_monster(index)

func debug_get_selected_animation_count() -> int:
	if _animation_picker == null:
		return 0
	return _animation_picker.item_count

func debug_has_preview_monster() -> bool:
	return _preview_monster != null

func debug_has_reference_door() -> bool:
	return _door_reference != null

func debug_has_collision_controls() -> bool:
	return _collision_size_x != null and _collision_wire != null

func debug_is_preview_centered() -> bool:
	if _preview_monster == null:
		return false
	return absf(_preview_monster.position.x) < 0.001 and absf(_preview_monster.position.z) < 0.001

func debug_get_collision_size() -> Vector3:
	var collision := _find_collision_shape(_preview_monster)
	if collision == null:
		return Vector3.ZERO
	var box := collision.shape as BoxShape3D
	if box == null:
		return Vector3.ZERO
	return box.size

func debug_get_visible_bottom_y() -> float:
	if _preview_monster == null:
		return INF
	var bounds := _combined_bounds(_preview_monster)
	if bounds.size == Vector3.ZERO:
		return INF
	return bounds.position.y

func debug_get_collision_bottom_y() -> float:
	return _collision_bottom_y(_preview_monster)

func debug_get_collision_root_bottom_y() -> float:
	if _preview_monster == null:
		return INF
	return _collision_bottom_y(_preview_monster) - _preview_monster.global_position.y

func debug_get_game_floor_visible_bottom_y() -> float:
	if _preview_monster == null:
		return INF
	var bounds := _combined_bounds(_preview_monster)
	if bounds.size == Vector3.ZERO:
		return INF
	var collision_bottom := _collision_bottom_y(_preview_monster)
	if not is_finite(collision_bottom):
		return bounds.position.y
	return bounds.position.y - collision_bottom

func debug_has_visual_yaw_control() -> bool:
	return _visual_yaw != null and _model_forward_line != null

func debug_get_visual_yaw_degrees() -> float:
	return float(_visual_yaw.value) if _visual_yaw != null else 0.0

func debug_set_visual_yaw_degrees(value: float) -> void:
	if _visual_yaw == null:
		return
	_visual_yaw.value = value
	_apply_visual_yaw_to_preview()
	_capture_preview_transform()
	_refresh_readouts()

func debug_get_controller_forward_yaw() -> float:
	return _flat_yaw_degrees(_controller_forward())

func debug_get_model_forward_yaw() -> float:
	return _flat_yaw_degrees(_model_visual_forward())

func debug_get_animation_names() -> Array[String]:
	var names: Array[String] = []
	if _animation_picker == null:
		return names
	for index in range(_animation_picker.item_count):
		names.append(_animation_picker.get_item_text(index))
	return names

func _build_stage() -> void:
	_preview_root = Node3D.new()
	_preview_root.name = "PreviewRoot"
	add_child(_preview_root)

	var environment := WorldEnvironment.new()
	environment.name = "WorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.055, 0.057, 0.052)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.8, 0.76, 0.62)
	env.ambient_light_energy = 0.45
	environment.environment = env
	add_child(environment)

	var floor := MeshInstance3D.new()
	floor.name = "GroundPlane"
	var plane := PlaneMesh.new()
	plane.size = Vector2(12.0, 12.0)
	floor.mesh = plane
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.34, 0.32, 0.24)
	floor_material.roughness = 0.9
	floor.material_override = floor_material
	add_child(floor)

	_add_grid()
	_add_axis_line("WorldXLine", Vector3.ZERO, Vector3(2.2, 0.01, 0.0), Color(0.95, 0.18, 0.14))
	_add_axis_line("WorldZLine", Vector3.ZERO, Vector3(0.0, 0.01, 2.2), Color(0.2, 0.65, 1.0))
	_add_label3d("世界 +X", Vector3(2.35, 0.08, 0.0), Color(0.95, 0.18, 0.14))
	_add_label3d("世界 +Z", Vector3(0.0, 0.08, 2.35), Color(0.2, 0.65, 1.0))
	_target_forward_line = _add_axis_line("TargetForwardLine", Vector3.ZERO, Vector3(0.0, 0.03, -2.2), Color(0.25, 0.95, 0.32))
	_target_forward_label = _add_label3d("校准目标\n世界-Z", Vector3(0.0, 0.20, -2.35), Color(0.25, 0.95, 0.32))
	_forward_line = _add_axis_line("ControllerForwardLine", Vector3.ZERO, Vector3(0.0, 0.055, -1.8), Color(1.0, 0.66, 0.12))
	_forward_label = _add_label3d("游戏正面\nAI移动/攻击", Vector3(0.0, 0.18, -1.95), Color(1.0, 0.66, 0.12))
	_model_forward_line = _add_axis_line("ModelVisualForwardLine", Vector3.ZERO, Vector3(0.0, 0.085, -1.55), Color(0.25, 0.92, 1.0))
	_model_forward_label = _add_label3d("模型脸朝向\n只影响外观", Vector3(0.0, 0.30, -1.7), Color(0.25, 0.92, 1.0))

	_collision_wire = MeshInstance3D.new()
	_collision_wire.name = "CollisionBoxWire"
	add_child(_collision_wire)
	_collision_label = _add_label3d("碰撞盒", Vector3(0.0, 1.2, 0.0), Color(0.3, 1.0, 0.45))
	_add_reference_door()

	var key := DirectionalLight3D.new()
	key.name = "KeyLight"
	key.rotation_degrees = Vector3(-52.0, -32.0, 0.0)
	key.light_energy = 1.65
	key.shadow_enabled = true
	add_child(key)

	var fill := OmniLight3D.new()
	fill.name = "FillLight"
	fill.position = Vector3(-2.4, 2.4, 2.2)
	fill.light_energy = 0.9
	fill.omni_range = 7.0
	add_child(fill)

	_camera = Camera3D.new()
	_camera.name = "ReviewCamera"
	_camera.current = true
	_camera.fov = 58.0
	add_child(_camera)

func _add_reference_door() -> void:
	_door_reference = DoorReferenceScene.instantiate() as Node3D
	if _door_reference == null:
		return
	_door_reference.name = "ReferenceDoor_Actual"
	_door_reference.position = Vector3(2.05, 0.0, 0.15)
	add_child(_door_reference)
	_door_reference.remove_from_group("interactive_door")
	_disable_runtime_behaviour(_door_reference)
	_add_label3d("实际门 2.09m", _door_reference.position + Vector3(0.0, 2.22, 0.0), Color(0.82, 0.9, 1.0))

func _add_grid() -> void:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.54, 0.50, 0.38, 0.72)
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	for i in range(-6, 7):
		mesh.surface_add_vertex(Vector3(float(i), 0.012, -6.0))
		mesh.surface_add_vertex(Vector3(float(i), 0.012, 6.0))
		mesh.surface_add_vertex(Vector3(-6.0, 0.012, float(i)))
		mesh.surface_add_vertex(Vector3(6.0, 0.012, float(i)))
	mesh.surface_end()
	var grid := MeshInstance3D.new()
	grid.name = "GroundGrid"
	grid.mesh = mesh
	add_child(grid)

func _add_axis_line(node_name: String, from: Vector3, to: Vector3, color: Color) -> MeshInstance3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	mesh.surface_add_vertex(from)
	mesh.surface_add_vertex(to)
	mesh.surface_end()
	var line := MeshInstance3D.new()
	line.name = node_name
	line.mesh = mesh
	add_child(line)
	return line

func _add_label3d(text: String, position: Vector3, color: Color) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.position = position
	label.modulate = color
	label.font_size = 26
	add_child(label)
	return label

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "MonsterShowcaseUI"
	add_child(layer)

	var panel := PanelContainer.new()
	panel.name = "ControlsPanel"
	panel.position = Vector2(14.0, 14.0)
	panel.custom_minimum_size = Vector2(640.0, 0.0)
	layer.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	margin.add_child(box)

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_status_label)

	_front_help_label = Label.new()
	_front_help_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_front_help_label.text = "游戏里的正面是橙色：游戏正面/AI移动攻击方向。蓝色只代表模型脸朝哪边；把蓝色调到橙色/绿色上，怪物看起来才会朝正确方向走。"
	box.add_child(_front_help_label)

	var pick_row := HBoxContainer.new()
	box.add_child(pick_row)
	_monster_picker = OptionButton.new()
	_monster_picker.custom_minimum_size = Vector2(190.0, 0.0)
	for entry in _entries:
		_monster_picker.add_item(String(entry["display_name"]))
	_monster_picker.item_selected.connect(func(index: int) -> void: _select_monster(index))
	pick_row.add_child(_monster_picker)
	_add_button(pick_row, "上一个", func() -> void: _select_relative(-1))
	_add_button(pick_row, "下一个", func() -> void: _select_relative(1))
	_add_button(pick_row, "看当前", _focus_preview)

	_add_separator(box)
	_add_transform_rows(box)
	_add_separator(box)
	_add_collision_rows(box)
	_add_separator(box)
	_add_animation_rows(box)
	_add_separator(box)

	var save_row := HBoxContainer.new()
	box.add_child(save_row)
	_add_button(save_row, "保存当前到全局", _save_selected_global)
	_add_button(save_row, "保存全部到全局", _save_all_global)
	_add_button(save_row, "重读全局", _reload_all)

	_direction_label = Label.new()
	_direction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_direction_label)
	_bounds_label = Label.new()
	_bounds_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_bounds_label)
	_save_label = Label.new()
	_save_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_save_label)

func _add_transform_rows(box: VBoxContainer) -> void:
	var row_pos := HBoxContainer.new()
	box.add_child(row_pos)
	_pos_x = _add_spin(row_pos, "X", -20.0, 20.0, 0.01, _on_transform_spin_changed)
	_pos_y = _add_spin(row_pos, "离地Y", -5.0, 8.0, 0.005, _on_transform_spin_changed)
	_pos_z = _add_spin(row_pos, "Z", -20.0, 20.0, 0.01, _on_transform_spin_changed)
	_add_button(row_pos, "贴地", _snap_to_ground)

	var row_rot := HBoxContainer.new()
	box.add_child(row_rot)
	_rot_pitch = _add_spin(row_rot, "俯仰X", -180.0, 180.0, 1.0, _on_transform_spin_changed)
	_rot_yaw = _add_spin(row_rot, "整体朝向Y", -360.0, 360.0, 1.0, _on_transform_spin_changed)
	_rot_roll = _add_spin(row_rot, "侧倾Z", -180.0, 180.0, 1.0, _on_transform_spin_changed)
	_add_button(row_rot, "左15", func() -> void: _nudge_yaw(-15.0))
	_add_button(row_rot, "右15", func() -> void: _nudge_yaw(15.0))

	var row_visual := HBoxContainer.new()
	box.add_child(row_visual)
	_visual_yaw = _add_spin(row_visual, "模型前方Y", -360.0, 360.0, 1.0, _on_visual_yaw_changed)
	_add_button(row_visual, "模型左15", func() -> void: _nudge_visual_yaw(-15.0))
	_add_button(row_visual, "模型右15", func() -> void: _nudge_visual_yaw(15.0))
	_add_button(row_visual, "模型归零", _zero_visual_yaw)

	var row_scale := HBoxContainer.new()
	box.add_child(row_scale)
	_lock_scale_check = CheckBox.new()
	_lock_scale_check.text = "锁定XYZ"
	_lock_scale_check.button_pressed = false
	_lock_scale_check.toggled.connect(func(_pressed: bool) -> void: _on_transform_spin_changed(0.0))
	row_scale.add_child(_lock_scale_check)
	_scale_uniform = _add_spin(row_scale, "整体", 0.02, 6.0, 0.01, _on_uniform_scale_changed)
	_scale_x = _add_spin(row_scale, "宽X", 0.02, 6.0, 0.01, _on_axis_scale_changed)
	_scale_y = _add_spin(row_scale, "高Y", 0.02, 6.0, 0.01, _on_axis_scale_changed)
	_scale_z = _add_spin(row_scale, "深Z", 0.02, 6.0, 0.01, _on_axis_scale_changed)

	var row_reset := HBoxContainer.new()
	box.add_child(row_reset)
	_add_button(row_reset, "重置当前", _reset_selected_from_source)
	_add_button(row_reset, "位置归零", _zero_position)
	_add_button(row_reset, "朝向归零", _zero_rotation)

func _add_collision_rows(box: VBoxContainer) -> void:
	var title := Label.new()
	title.text = "碰撞体积（绿色线框，保存后全局生效）"
	box.add_child(title)

	var row_pos := HBoxContainer.new()
	box.add_child(row_pos)
	_collision_pos_x = _add_spin(row_pos, "碰撞X", -3.0, 3.0, 0.01, _on_collision_spin_changed)
	_collision_pos_y = _add_spin(row_pos, "碰撞Y", -3.0, 5.0, 0.01, _on_collision_spin_changed)
	_collision_pos_z = _add_spin(row_pos, "碰撞Z", -3.0, 3.0, 0.01, _on_collision_spin_changed)
	_add_button(row_pos, "碰撞贴地", _snap_collision_to_ground)

	var row_size := HBoxContainer.new()
	box.add_child(row_size)
	_collision_size_x = _add_spin(row_size, "宽X", 0.05, 6.0, 0.01, _on_collision_spin_changed)
	_collision_size_y = _add_spin(row_size, "高Y", 0.05, 6.0, 0.01, _on_collision_spin_changed)
	_collision_size_z = _add_spin(row_size, "深Z", 0.05, 6.0, 0.01, _on_collision_spin_changed)
	_add_button(row_size, "读当前碰撞", _sync_collision_controls_from_preview)

func _add_animation_rows(box: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	box.add_child(row)
	_animation_picker = OptionButton.new()
	_animation_picker.custom_minimum_size = Vector2(250.0, 0.0)
	row.add_child(_animation_picker)
	_add_button(row, "播放动作", _play_selected_animation)
	_add_button(row, "停止", _stop_animation)
	_animation_speed = _add_spin(row, "速度", 0.05, 3.0, 0.05, _on_animation_speed_changed)
	_animation_speed.value = 1.0

func _add_button(parent: Control, text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(callback)
	parent.add_child(button)

func _add_spin(parent: Control, label_text: String, min_value: float, max_value: float, step: float, callback: Callable) -> SpinBox:
	var label := Label.new()
	label.text = label_text
	parent.add_child(label)
	var spin := SpinBox.new()
	spin.min_value = min_value
	spin.max_value = max_value
	spin.step = step
	spin.custom_minimum_size = Vector2(82.0, 0.0)
	spin.value_changed.connect(func(value: float) -> void:
		if not _updating_controls:
			callback.call(value)
	)
	parent.add_child(spin)
	return spin

func _add_separator(parent: Control) -> void:
	var separator := HSeparator.new()
	parent.add_child(separator)

func _select_relative(delta: int) -> void:
	if _entries.is_empty():
		return
	var next_index := _selected_index + delta
	if next_index < 0:
		next_index = _entries.size() - 1
	elif next_index >= _entries.size():
		next_index = 0
	_select_monster(next_index)

func _select_monster(index: int) -> void:
	if index < 0 or index >= _entries.size():
		return
	_capture_preview_transform()
	_selected_index = index
	_save_label.text = ""
	if _monster_picker != null:
		_updating_controls = true
		_monster_picker.select(index)
		_updating_controls = false
	_rebuild_preview()

func _rebuild_preview() -> void:
	if _preview_monster != null:
		_preview_monster.queue_free()
		_preview_monster = null
	var entry := _entries[_selected_index]
	var template_id := String(entry["template_id"])
	_preview_monster = MonsterSizeSource.instantiate_template(template_id)
	if _preview_monster == null:
		return
	_preview_monster.name = "Preview_%s" % String(entry["source_id"])
	var source_transform: Transform3D = entry.get("transform", Transform3D.IDENTITY)
	_preview_monster.transform = _display_transform(source_transform)
	_preview_root.add_child(_preview_monster)
	_disable_runtime_behaviour(_preview_monster)
	_apply_entry_visual_yaw_to_preview(entry)
	var loaded_collision: Dictionary = entry.get("collision_config", {})
	if not loaded_collision.is_empty():
		var collision_config := loaded_collision
		MonsterSizeSource.apply_collision_config(_preview_monster, collision_config["size"], collision_config["position"])
	_update_controls_from_transform(source_transform)
	_update_visual_yaw_control_from_entry(entry)
	_sync_collision_controls_from_preview()
	_refresh_animation_picker()
	if _animation_picker != null and _animation_picker.item_count > 0:
		_apply_animation_ground_offset(_animation_picker.get_item_text(_animation_picker.selected))
	_focus_preview()
	_refresh_readouts()

func _disable_runtime_behaviour(node: Node) -> void:
	node.set_process(false)
	node.set_physics_process(false)
	node.set_process_input(false)
	node.set_process_unhandled_input(false)
	var audio := node as AudioStreamPlayer3D
	if audio != null:
		audio.stop()
	for child in node.get_children():
		_disable_runtime_behaviour(child)

func _display_transform(source_transform: Transform3D) -> Transform3D:
	var display := source_transform
	display.origin = Vector3(PREVIEW_CENTER.x, source_transform.origin.y, PREVIEW_CENTER.z)
	return display

func _source_transform_from_controls() -> Transform3D:
	var position := Vector3(float(_pos_x.value), float(_pos_y.value), float(_pos_z.value))
	var rotation_degrees := Vector3(float(_rot_pitch.value), float(_rot_yaw.value), float(_rot_roll.value))
	var scale := Vector3(float(_scale_x.value), float(_scale_y.value), float(_scale_z.value))
	return TransformStore.build_transform(position, rotation_degrees, scale)

func _update_controls_from_transform(transform: Transform3D) -> void:
	var data := TransformStore.decompose_transform(transform)
	var position: Vector3 = data["position"]
	var rotation: Vector3 = data["rotation_degrees"]
	var scale: Vector3 = data["scale"]
	_updating_controls = true
	_pos_x.value = position.x
	_pos_y.value = position.y
	_pos_z.value = position.z
	_rot_pitch.value = rotation.x
	_rot_yaw.value = rotation.y
	_rot_roll.value = rotation.z
	_scale_x.value = scale.x
	_scale_y.value = scale.y
	_scale_z.value = scale.z
	_scale_uniform.value = (scale.x + scale.y + scale.z) / 3.0
	_updating_controls = false

func _update_visual_yaw_control_from_entry(entry: Dictionary) -> void:
	if _visual_yaw == null:
		return
	_updating_controls = true
	_visual_yaw.value = float(entry.get("visual_yaw_degrees", 0.0))
	_updating_controls = false

func _on_transform_spin_changed(_value: float) -> void:
	_apply_controls_to_preview()

func _on_visual_yaw_changed(_value: float) -> void:
	_apply_visual_yaw_to_preview()
	_capture_preview_transform()
	_refresh_readouts()

func _on_uniform_scale_changed(value: float) -> void:
	if _updating_controls:
		return
	_updating_controls = true
	_scale_x.value = value
	_scale_y.value = value
	_scale_z.value = value
	_updating_controls = false
	_apply_controls_to_preview()

func _on_axis_scale_changed(value: float) -> void:
	if _updating_controls:
		return
	if _lock_scale_check != null and _lock_scale_check.button_pressed:
		_updating_controls = true
		_scale_x.value = value
		_scale_y.value = value
		_scale_z.value = value
		_scale_uniform.value = value
		_updating_controls = false
	else:
		_updating_controls = true
		_scale_uniform.value = (_scale_x.value + _scale_y.value + _scale_z.value) / 3.0
		_updating_controls = false
	_apply_controls_to_preview()

func _apply_controls_to_preview() -> void:
	if _preview_monster == null:
		return
	var source_transform := _source_transform_from_controls()
	_preview_monster.transform = _display_transform(source_transform)
	_apply_visual_yaw_to_preview()
	_apply_collision_controls_to_preview()
	_capture_preview_transform()
	_refresh_readouts()

func _apply_entry_visual_yaw_to_preview(entry: Dictionary) -> void:
	if _preview_monster == null:
		return
	MonsterSizeSource.apply_visual_yaw_offset(_preview_monster, float(entry.get("visual_yaw_degrees", 0.0)))

func _apply_visual_yaw_to_preview() -> void:
	if _preview_monster == null or _visual_yaw == null:
		return
	MonsterSizeSource.apply_visual_yaw_offset(_preview_monster, float(_visual_yaw.value))

func _capture_preview_transform() -> void:
	if _preview_monster == null or _selected_index < 0 or _selected_index >= _entries.size():
		return
	_entries[_selected_index]["transform"] = _source_transform_from_controls()
	if _visual_yaw != null:
		_entries[_selected_index]["visual_yaw_degrees"] = float(_visual_yaw.value)
	_capture_collision_config()

func _on_collision_spin_changed(_value: float) -> void:
	_apply_collision_controls_to_preview()
	_capture_collision_config()
	_refresh_readouts()

func _collision_config_from_controls() -> Dictionary:
	if _collision_size_x == null:
		return {}
	return {
		"position": Vector3(float(_collision_pos_x.value), float(_collision_pos_y.value), float(_collision_pos_z.value)),
		"size": Vector3(float(_collision_size_x.value), float(_collision_size_y.value), float(_collision_size_z.value)),
	}

func _apply_collision_controls_to_preview() -> void:
	if _preview_monster == null or _collision_size_x == null:
		return
	var config := _collision_config_from_controls()
	if config.is_empty():
		return
	MonsterSizeSource.apply_collision_config(_preview_monster, config["size"], config["position"])
	_update_collision_wire()

func _capture_collision_config() -> void:
	if _selected_index < 0 or _selected_index >= _entries.size():
		return
	var config := _collision_config_from_controls()
	if not config.is_empty():
		_entries[_selected_index]["collision_config"] = config

func _sync_collision_controls_from_preview() -> void:
	if _preview_monster == null or _collision_size_x == null:
		return
	var collision := _find_collision_shape(_preview_monster)
	if collision == null:
		return
	var box := collision.shape as BoxShape3D
	if box == null:
		return
	_updating_controls = true
	_collision_pos_x.value = collision.position.x
	_collision_pos_y.value = collision.position.y
	_collision_pos_z.value = collision.position.z
	_collision_size_x.value = box.size.x
	_collision_size_y.value = box.size.y
	_collision_size_z.value = box.size.z
	_updating_controls = false
	_capture_collision_config()
	_update_collision_wire()

func _set_collision_bottom_to_root_floor() -> void:
	if _collision_size_y == null or _collision_pos_y == null:
		return
	_collision_pos_y.value = float(_collision_size_y.value) * 0.5

func _snap_collision_to_ground() -> void:
	if _collision_size_y == null:
		return
	_set_collision_bottom_to_root_floor()
	_apply_collision_controls_to_preview()
	_capture_collision_config()
	_refresh_readouts()

func _nudge_yaw(delta_degrees: float) -> void:
	if _rot_yaw == null:
		return
	_rot_yaw.value = float(_rot_yaw.value) + delta_degrees
	_apply_controls_to_preview()

func _nudge_visual_yaw(delta_degrees: float) -> void:
	if _visual_yaw == null:
		return
	_visual_yaw.value = float(_visual_yaw.value) + delta_degrees
	_apply_visual_yaw_to_preview()
	_capture_preview_transform()
	_refresh_readouts()

func _zero_position() -> void:
	_pos_x.value = 0.0
	_pos_z.value = 0.0
	_apply_controls_to_preview()

func _zero_rotation() -> void:
	_rot_pitch.value = 0.0
	_rot_yaw.value = 0.0
	_rot_roll.value = 0.0
	_apply_controls_to_preview()

func _zero_visual_yaw() -> void:
	if _visual_yaw == null:
		return
	_visual_yaw.value = 0.0
	_apply_visual_yaw_to_preview()
	_capture_preview_transform()
	_refresh_readouts()

func _snap_to_ground() -> void:
	if _preview_monster == null:
		return
	_set_collision_bottom_to_root_floor()
	_apply_collision_controls_to_preview()
	_capture_collision_config()
	var bounds := _combined_bounds(_preview_monster)
	if bounds.size == Vector3.ZERO:
		return
	_pos_y.value = float(_pos_y.value) - bounds.position.y
	_apply_controls_to_preview()

func _reset_selected_from_source() -> void:
	if _selected_index < 0:
		return
	var source_id := String(_entries[_selected_index]["source_id"])
	_entries[_selected_index]["transform"] = TransformStore.load_transform(source_id)
	_entries[_selected_index]["collision_config"] = TransformStore.load_collision_config(source_id)
	_entries[_selected_index]["visual_yaw_degrees"] = TransformStore.load_visual_yaw_degrees(source_id)
	_rebuild_preview()

func _reload_all() -> void:
	_entries = TransformStore.monster_entries()
	var index := clampi(_selected_index, 0, max(0, _entries.size() - 1))
	_selected_index = -1
	_select_monster(index)
	_save_label.text = "已从 FourRoomMVP 重新读取全局怪物设置。"

func _save_selected_global() -> void:
	_capture_preview_transform()
	if _selected_index < 0:
		return
	var entry := _entries[_selected_index]
	var err := TransformStore.save_transform(String(entry["source_id"]), entry["transform"])
	var collision_err := _save_entry_collision(entry)
	var visual_err := TransformStore.save_visual_yaw_degrees(String(entry["source_id"]), float(entry.get("visual_yaw_degrees", 0.0)))
	if err == OK and collision_err == OK and visual_err == OK:
		_save_label.text = "当前怪物尺寸、整体朝向、模型前方、离地和碰撞体积已保存到全局。"
	else:
		_save_label.text = "保存失败：transform=%d visual=%d collision=%d" % [err, visual_err, collision_err]

func _save_all_global() -> void:
	_capture_preview_transform()
	var errors: Array[String] = []
	for entry in _entries:
		var err := TransformStore.save_transform(String(entry["source_id"]), entry["transform"])
		if err != OK:
			errors.append("%s:transform:%d" % [String(entry["source_id"]), err])
		var visual_err := TransformStore.save_visual_yaw_degrees(String(entry["source_id"]), float(entry.get("visual_yaw_degrees", 0.0)))
		if visual_err != OK:
			errors.append("%s:visual:%d" % [String(entry["source_id"]), visual_err])
		var collision_err := _save_entry_collision(entry)
		if collision_err != OK:
			errors.append("%s:collision:%d" % [String(entry["source_id"]), collision_err])
	if errors.is_empty():
		_save_label.text = "全部怪物尺寸、整体朝向、模型前方和碰撞设置已保存到 FourRoomMVP 全局来源。"
	else:
		_save_label.text = "保存失败：" + ", ".join(errors)

func _save_entry_collision(entry: Dictionary) -> int:
	var config: Dictionary = entry.get("collision_config", {})
	if config.is_empty():
		return OK
	return TransformStore.save_collision_config(String(entry["source_id"]), config["size"], config["position"])

func _refresh_animation_picker() -> void:
	_animation_picker.clear()
	var player := _find_animation_player(_preview_monster)
	if player == null:
		_animation_picker.add_item("无 AnimationPlayer")
		return
	var names := _filtered_animation_names(player)
	for animation_name in names:
		_animation_picker.add_item(animation_name)
	if _animation_picker.item_count == 0:
		_animation_picker.add_item("无动作")

func _play_selected_animation() -> void:
	var player := _find_animation_player(_preview_monster)
	if player == null or _animation_picker == null or _animation_picker.item_count <= 0:
		return
	var animation_name := _animation_picker.get_item_text(_animation_picker.selected)
	if player.has_animation(animation_name):
		_apply_animation_ground_offset(animation_name)
		player.play(animation_name, 0.0, float(_animation_speed.value))
		_save_label.text = "正在播放动作：%s（已应用该动作地面偏移）" % animation_name

func _filtered_animation_names(player: AnimationPlayer) -> Array[String]:
	var all_names: Array[String] = []
	for animation_name_variant in player.get_animation_list():
		all_names.append(String(animation_name_variant))
	if _selected_index < 0 or _selected_index >= _entries.size():
		return all_names
	var entry := _entries[_selected_index]
	var recommended := MonsterSizeSource.gameplay_animation_names(String(entry.get("template_id", "")), false)
	if recommended.is_empty():
		return all_names
	var result: Array[String] = []
	for animation_name in recommended:
		if player.has_animation(animation_name):
			result.append(animation_name)
	return result

func _apply_animation_ground_offset(animation_name: String) -> void:
	if _preview_monster == null or _selected_index < 0 or _selected_index >= _entries.size():
		return
	var entry := _entries[_selected_index]
	MonsterSizeSource.apply_animation_ground_offset(_preview_monster, String(entry.get("template_id", "")), animation_name)
	_update_collision_wire()

func _stop_animation() -> void:
	var player := _find_animation_player(_preview_monster)
	if player != null:
		player.stop()
		_save_label.text = "动作已停止。"

func _on_animation_speed_changed(value: float) -> void:
	var player := _find_animation_player(_preview_monster)
	if player != null:
		player.speed_scale = value

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node == null:
		return null
	var player := node as AnimationPlayer
	if player != null:
		return player
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null

func _focus_preview() -> void:
	if _preview_monster == null:
		return
	var bounds := _combined_bounds_for_nodes([_preview_monster, _door_reference])
	if bounds.size != Vector3.ZERO:
		_orbit_target = bounds.get_center()
		camera_distance = clampf(maxf(bounds.size.length() * 1.35, 2.3), camera_min_distance, camera_max_distance)
	else:
		_orbit_target = PREVIEW_CENTER + Vector3.UP
	_update_camera()

func _update_camera() -> void:
	if _camera == null:
		return
	var horizontal := cos(camera_pitch) * camera_distance
	var offset := Vector3(
		sin(camera_yaw) * horizontal,
		sin(camera_pitch) * camera_distance,
		cos(camera_yaw) * horizontal
	)
	_camera.global_position = _orbit_target + offset
	_camera.look_at(_orbit_target, Vector3.UP)

func _refresh_readouts() -> void:
	if _preview_monster == null or _selected_index < 0:
		return
	var entry := _entries[_selected_index]
	var scale := _preview_monster.transform.basis.get_scale()
	var controller_forward := _controller_forward()
	var model_forward := _model_visual_forward()
	var controller_yaw := _flat_yaw_degrees(controller_forward)
	var model_yaw := _flat_yaw_degrees(model_forward)
	var bounds := _combined_bounds(_preview_monster)
	var bottom := bounds.position.y
	var top := bounds.position.y + bounds.size.y
	_status_label.text = "%s | source=%s | 保存目标：%s" % [
		String(entry["display_name"]),
		String(entry["source_id"]),
		TransformStore.SOURCE_SCENE_PATH,
	]
	_direction_label.text = "游戏正面=-global_basis.z：forward=(%.3f, %.3f)，Yaw=%.1f°。这是怪物移动、追人、攻击使用的方向。" % [controller_forward.x, controller_forward.z, controller_yaw]
	_bounds_label.text = "尺寸scale=(%.3f, %.3f, %.3f) | 可见底部Y=%.3f | 顶部Y=%.3f | 高度=%.3f | 动作数=%d" % [
		scale.x, scale.y, scale.z, bottom, top, bounds.size.y, _animation_picker.item_count if _animation_picker != null else 0
	]
	var target_yaw := _flat_yaw_degrees(TARGET_FORWARD)
	var controller_delta := _angle_delta_degrees(controller_yaw - target_yaw)
	var model_delta := _angle_delta_degrees(model_yaw - target_yaw)
	var visual_yaw := float(entry.get("visual_yaw_degrees", 0.0))
	var source_transform: Transform3D = entry.get("transform", Transform3D.IDENTITY)
	var source_position := source_transform.origin
	var collision := _find_collision_shape(_preview_monster)
	var collision_text := "无碰撞盒"
	if collision != null:
		var box := collision.shape as BoxShape3D
		if box != null:
			collision_text = "碰撞size=(%.3f, %.3f, %.3f) center=(%.3f, %.3f, %.3f)" % [
				box.size.x, box.size.y, box.size.z,
				collision.position.x, collision.position.y, collision.position.z,
			]
	_status_label.text = "%s | source=%s | 展示固定在地面中心，源位置=(%.2f, %.2f, %.2f) | 保存目标：%s" % [
		String(entry["display_name"]),
		String(entry["source_id"]),
		source_position.x,
		source_position.y,
		source_position.z,
		TransformStore.SOURCE_SCENE_PATH,
	]
	_direction_label.text = "橙色=游戏正面/AI移动攻击 Yaw=%.1f° 偏差=%.1f° | 蓝色=模型脸朝向/只影响外观 Yaw=%.1f° 偏差=%.1f° | 绿色=校准目标世界-Z | 模型前方Y=%.1f°" % [
		controller_yaw,
		controller_delta,
		model_yaw,
		model_delta,
		visual_yaw,
	]
	_bounds_label.text = "尺寸scale=(%.3f, %.3f, %.3f) | 可见底部Y=%.3f | 顶部Y=%.3f | 高度=%.3f | %s | 动作数=%d" % [
		scale.x, scale.y, scale.z, bottom, top, bounds.size.y, collision_text, _animation_picker.item_count if _animation_picker != null else 0
	]
	_update_direction_markers(controller_forward, model_forward)
	_update_collision_wire()

func _update_direction_markers(controller_forward: Vector3, model_forward: Vector3) -> void:
	if _forward_line == null or controller_forward.length_squared() <= 0.0001:
		return
	var origin := Vector3(PREVIEW_CENTER.x, 0.055, PREVIEW_CENTER.z)
	var target_end := origin + TARGET_FORWARD * 2.25
	if _target_forward_line != null:
		_target_forward_line.mesh = _line_mesh(origin, target_end, Color(0.25, 0.95, 0.32))
	if _target_forward_label != null:
		_target_forward_label.position = target_end + Vector3.UP * 0.16
	var end := origin + controller_forward * 2.0
	_forward_line.mesh = _line_mesh(origin, end, Color(1.0, 0.66, 0.12))
	if _forward_label != null:
		_forward_label.position = end + Vector3.UP * 0.16
		_forward_label.text = "游戏正面\nAI移动/攻击"
	if _model_forward_line == null or model_forward.length_squared() <= 0.0001:
		return
	var model_origin := origin + Vector3.UP * 0.045
	var model_end := model_origin + model_forward * 1.72
	_model_forward_line.mesh = _line_mesh(model_origin, model_end, Color(0.25, 0.92, 1.0))
	if _model_forward_label != null:
		_model_forward_label.position = model_end + Vector3.UP * 0.16
		_model_forward_label.text = "模型脸朝向\n只影响外观"

func _controller_forward() -> Vector3:
	if _preview_monster == null:
		return TARGET_FORWARD
	return _flat_direction(-_preview_monster.global_transform.basis.z)

func _model_visual_forward() -> Vector3:
	var model_root := _find_model_root(_preview_monster)
	if model_root == null:
		return _controller_forward()
	return _flat_direction(-model_root.global_transform.basis.z)

func _flat_direction(direction: Vector3) -> Vector3:
	var flat := Vector3(direction.x, 0.0, direction.z)
	if flat.length_squared() <= 0.0001:
		return Vector3.ZERO
	return flat.normalized()

func _find_model_root(node: Node) -> Node3D:
	if node == null:
		return null
	var direct := node.get_node_or_null("ModelRoot") as Node3D
	if direct != null:
		return direct
	for child in node.get_children():
		var found := _find_model_root(child)
		if found != null:
			return found
	return null

func _flat_yaw_degrees(direction: Vector3) -> float:
	var flat := Vector3(direction.x, 0.0, direction.z)
	if flat.length_squared() <= 0.0001:
		return 0.0
	flat = flat.normalized()
	return rad_to_deg(atan2(-flat.x, -flat.z))

func _angle_delta_degrees(value: float) -> float:
	var wrapped := fmod(value + 180.0, 360.0)
	if wrapped < 0.0:
		wrapped += 360.0
	return wrapped - 180.0

func _line_mesh(from: Vector3, to: Vector3, color: Color) -> ImmediateMesh:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	mesh.surface_add_vertex(from)
	mesh.surface_add_vertex(to)
	mesh.surface_end()
	return mesh

func _update_collision_wire() -> void:
	if _collision_wire == null or _preview_monster == null:
		return
	var collision := _find_collision_shape(_preview_monster)
	if collision == null:
		_collision_wire.mesh = null
		return
	var box := collision.shape as BoxShape3D
	if box == null:
		_collision_wire.mesh = null
		return
	_collision_wire.mesh = _box_wire_mesh(collision.global_transform, box.size, Color(0.3, 1.0, 0.45))
	if _collision_label != null:
		_collision_label.position = collision.global_transform.origin + Vector3.UP * (box.size.y * 0.5 + 0.16)

func _box_wire_mesh(transform: Transform3D, size: Vector3, color: Color) -> ImmediateMesh:
	var half := size * 0.5
	var corners := [
		Vector3(-half.x, -half.y, -half.z),
		Vector3(half.x, -half.y, -half.z),
		Vector3(half.x, -half.y, half.z),
		Vector3(-half.x, -half.y, half.z),
		Vector3(-half.x, half.y, -half.z),
		Vector3(half.x, half.y, -half.z),
		Vector3(half.x, half.y, half.z),
		Vector3(-half.x, half.y, half.z),
	]
	var edges := [
		[0, 1], [1, 2], [2, 3], [3, 0],
		[4, 5], [5, 6], [6, 7], [7, 4],
		[0, 4], [1, 5], [2, 6], [3, 7],
	]
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	for edge in edges:
		mesh.surface_add_vertex(transform * corners[int(edge[0])])
		mesh.surface_add_vertex(transform * corners[int(edge[1])])
	mesh.surface_end()
	return mesh

func _find_collision_shape(node: Node) -> CollisionShape3D:
	if node == null:
		return null
	var collision := node as CollisionShape3D
	if collision != null and collision.shape != null:
		return collision
	for child in node.get_children():
		var found := _find_collision_shape(child)
		if found != null:
			return found
	return null

func _collision_bottom_y(monster: Node3D) -> float:
	var collision := _find_collision_shape(monster)
	if collision == null:
		return INF
	var box := collision.shape as BoxShape3D
	if box == null:
		return INF
	return _box_bottom_y(collision.global_transform, box.size)

func _box_bottom_y(transform: Transform3D, size: Vector3) -> float:
	var half := size * 0.5
	var bottom := INF
	var corners := [
		Vector3(-half.x, -half.y, -half.z),
		Vector3(half.x, -half.y, -half.z),
		Vector3(half.x, -half.y, half.z),
		Vector3(-half.x, -half.y, half.z),
		Vector3(-half.x, half.y, -half.z),
		Vector3(half.x, half.y, -half.z),
		Vector3(half.x, half.y, half.z),
		Vector3(-half.x, half.y, half.z),
	]
	for corner in corners:
		bottom = minf(bottom, (transform * corner).y)
	return bottom

func _combined_bounds_for_nodes(nodes: Array) -> AABB:
	var has_bounds := false
	var combined := AABB()
	for node in nodes:
		var child := node as Node
		if child == null:
			continue
		var bounds := _combined_bounds(child)
		if bounds.size == Vector3.ZERO:
			continue
		if has_bounds:
			combined = combined.merge(bounds)
		else:
			combined = bounds
			has_bounds = true
	return combined

func _combined_bounds(node: Node) -> AABB:
	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(node, meshes)
	var has_bounds := false
	var combined := AABB()
	for mesh in meshes:
		var bounds := _aabb_to_global(mesh, mesh.get_aabb())
		if has_bounds:
			combined = combined.merge(bounds)
		else:
			combined = bounds
			has_bounds = true
	return combined

func _collect_meshes(node: Node, output: Array[MeshInstance3D]) -> void:
	var mesh := node as MeshInstance3D
	if mesh != null and mesh.mesh != null and mesh.visible:
		output.append(mesh)
	for child in node.get_children():
		_collect_meshes(child, output)

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
