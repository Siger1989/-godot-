extends CanvasLayer
class_name PlayerModelAdjustPanel

const PREVIEW_SIZE := Vector2(280, 184)

var live_model: Node
var preview_model: PlayerModelVisual
var sliders: Dictionary = {}
var value_labels: Dictionary = {}
var status_label: Label
var _updating := false


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		return
	layer = 40
	_build_ui()
	call_deferred("_bind_live_model")


func _bind_live_model() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player:
		live_model = player.find_child("ImportedModelRoot", true, false)
	if live_model and live_model.has_method("get_adjustment"):
		var adjustment: Dictionary = live_model.call("get_adjustment")
		var offset := adjustment.get("extra_offset", Vector3.ZERO) as Vector3
		_set_slider_values(float(adjustment.get("target_height", 1.58)), float(adjustment.get("yaw_degrees", 180.0)), offset)
		_apply_current_values()
		_set_status("已连接主角模型")
	else:
		_set_status("未找到主角模型")


func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.name = "PlayerModelAdjustWindow"
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.offset_left = -330.0
	panel.offset_right = -16.0
	panel.offset_top = 16.0
	panel.offset_bottom = 520.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.052, 0.038, 0.92)
	style.border_color = Color(0.42, 0.36, 0.17, 0.95)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)

	var title := Label.new()
	title.text = "人物展示"
	title.add_theme_font_size_override("font_size", 18)
	box.add_child(title)

	_add_preview(box)
	_add_slider(box, "height", "高度", 0.80, 2.20, 0.01, 1.58)
	_add_slider(box, "yaw", "朝向", -180.0, 180.0, 1.0, 180.0)
	_add_slider(box, "offset_y", "上下", -0.60, 0.60, 0.01, 0.0)
	_add_slider(box, "offset_x", "左右", -0.60, 0.60, 0.01, 0.0)
	_add_slider(box, "offset_z", "前后", -0.60, 0.60, 0.01, 0.0)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	box.add_child(buttons)

	var reset := Button.new()
	reset.text = "重置"
	reset.pressed.connect(_reset_values)
	buttons.add_child(reset)

	var save := Button.new()
	save.text = "保存"
	save.pressed.connect(_save_values)
	buttons.add_child(save)

	status_label = Label.new()
	status_label.text = ""
	status_label.add_theme_font_size_override("font_size", 12)
	box.add_child(status_label)


func _add_preview(parent: VBoxContainer) -> void:
	var container := SubViewportContainer.new()
	container.custom_minimum_size = PREVIEW_SIZE
	container.stretch = true
	parent.add_child(container)

	var viewport := SubViewport.new()
	viewport.size = Vector2i(int(PREVIEW_SIZE.x), int(PREVIEW_SIZE.y))
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	container.add_child(viewport)

	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.025, 0.024, 0.02)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.78, 0.58)
	env.ambient_light_energy = 0.9
	world.environment = env
	viewport.add_child(world)

	var light := DirectionalLight3D.new()
	light.light_energy = 1.2
	light.rotation_degrees = Vector3(-45.0, 35.0, 0.0)
	viewport.add_child(light)

	var floor := MeshInstance3D.new()
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(2.0, 0.02, 2.0)
	floor.mesh = floor_mesh
	floor.position = Vector3(0.0, -0.01, 0.0)
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.26, 0.23, 0.14)
	floor_mat.roughness = 0.95
	floor.material_override = floor_mat
	viewport.add_child(floor)

	preview_model = PlayerModelVisual.new()
	preview_model.name = "PreviewPlayerModel"
	preview_model.target_height = 1.58
	preview_model.yaw_degrees = 180.0
	viewport.add_child(preview_model)

	var camera := Camera3D.new()
	camera.current = true
	camera.fov = 42.0
	camera.position = Vector3(0.0, 1.0, 4.0)
	viewport.add_child(camera)
	camera.look_at(Vector3(0.0, 0.85, 0.0), Vector3.UP)


func _add_slider(parent: VBoxContainer, key: String, label_text: String, min_value: float, max_value: float, step: float, initial: float) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(42, 0)
	row.add_child(label)

	var slider := HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.value = initial
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(func(_value: float) -> void:
		_on_value_changed()
	)
	row.add_child(slider)
	sliders[key] = slider

	var value_label := Label.new()
	value_label.text = _format_value(initial)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.custom_minimum_size = Vector2(54, 0)
	row.add_child(value_label)
	value_labels[key] = value_label


func _on_value_changed() -> void:
	if _updating:
		return
	_apply_current_values()


func _apply_current_values() -> void:
	var height := _slider_value("height")
	var yaw := _slider_value("yaw")
	var offset := Vector3(_slider_value("offset_x"), _slider_value("offset_y"), _slider_value("offset_z"))
	_update_value_labels()
	if live_model and live_model.has_method("apply_adjustment"):
		live_model.call("apply_adjustment", height, yaw, offset)
	if preview_model:
		preview_model.apply_adjustment(height, yaw, offset)


func _set_slider_values(height: float, yaw: float, offset: Vector3) -> void:
	_updating = true
	(sliders["height"] as HSlider).value = height
	(sliders["yaw"] as HSlider).value = yaw
	(sliders["offset_x"] as HSlider).value = offset.x
	(sliders["offset_y"] as HSlider).value = offset.y
	(sliders["offset_z"] as HSlider).value = offset.z
	_updating = false
	_update_value_labels()


func _reset_values() -> void:
	_set_slider_values(1.58, 180.0, Vector3.ZERO)
	_apply_current_values()
	_set_status("已重置")


func _save_values() -> void:
	_apply_current_values()
	if live_model and live_model.has_method("save_adjustment_config"):
		live_model.call("save_adjustment_config")
		_set_status("已保存到 assets/models/player_model_adjustment.cfg")
	else:
		_set_status("保存失败")


func _update_value_labels() -> void:
	for key in sliders.keys():
		(value_labels[key] as Label).text = _format_value((sliders[key] as HSlider).value)


func _slider_value(key: String) -> float:
	return float((sliders[key] as HSlider).value)


func _format_value(value: float) -> String:
	return "%.2f" % value


func _set_status(text: String) -> void:
	if status_label:
		status_label.text = text
