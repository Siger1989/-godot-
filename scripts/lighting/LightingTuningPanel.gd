extends CanvasLayer

const ContactShadowMaterial = preload("res://scripts/visual/ContactShadowMaterial.gd")
const PANEL_WIDTH := 380.0
const DEFAULT_LIGHT_COLOR := Color(1.0, 0.93, 0.78, 1.0)
const DEFAULT_AMBIENT_ENERGY := 0.07
const RUNTIME_UNIQUE_MATERIAL_META := "runtime_unique_light_material"

var _root_control: Control
var _panel: PanelContainer
var _lighting_controller: Node
var _world_environment: WorldEnvironment

var _light_bases: Dictionary = {}
var _panel_bases: Dictionary = {}
var _contact_shadow_bases: Dictionary = {}
var _sliders: Dictionary = {}
var _value_labels: Dictionary = {}
var _color_pickers: Dictionary = {}
var _toggles: Dictionary = {}

var _light_color := DEFAULT_LIGHT_COLOR
var _ambient_color := Color(1.0, 0.9, 0.66, 1.0)
var _ambient_energy := DEFAULT_AMBIENT_ENERGY
var _base_ambient_color := Color(1.0, 0.9, 0.66, 1.0)
var _base_ambient_energy := DEFAULT_AMBIENT_ENERGY
var _contact_shadow_enabled := true
var _contact_shadow_strength := 1.0
var _contact_shadow_max := 0.24
var _base_contact_shadow_enabled := true
var _base_contact_shadow_strength := 1.0
var _base_contact_shadow_max := 0.24
var _light_energy_multiplier := 1.0
var _light_range_multiplier := 1.0
var _light_attenuation_multiplier := 1.0
var _panel_emission_multiplier := 1.0
var _refresh_pending := false
var _updating_controls := false

func _ready() -> void:
	layer = 80
	add_to_group("runtime_lighting_tuning_panel", true)
	_free_runtime_children()
	_build_ui()
	call_deferred("_initialize_lighting_state")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if is_panel_open():
			close_panel()
		else:
			open_panel()
		get_viewport().set_input_as_handled()
		return

	if not is_panel_open():
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _panel != null and not _panel.get_global_rect().has_point(event.position):
			close_panel()
			get_viewport().set_input_as_handled()

func open_panel() -> void:
	if _root_control == null:
		return
	_root_control.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func close_panel() -> void:
	if _root_control == null:
		return
	_root_control.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func is_panel_open() -> bool:
	return _root_control != null and _root_control.visible

func debug_get_control_count() -> int:
	return _sliders.size() + _color_pickers.size() + _toggles.size()

func debug_get_tuned_light_count() -> int:
	return _light_bases.size()

func _free_runtime_children() -> void:
	for child in get_children():
		remove_child(child)
		child.free()

func _build_ui() -> void:
	_root_control = Control.new()
	_root_control.name = "LightingTuningRoot"
	_root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root_control.visible = false
	add_child(_root_control)

	_panel = PanelContainer.new()
	_panel.name = "LightingPanel"
	_panel.custom_minimum_size = Vector2(PANEL_WIDTH, 0.0)
	_panel.position = Vector2(16.0, 16.0)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.add_theme_stylebox_override("panel", _make_panel_style())
	_root_control.add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	_panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	margin.add_child(content)

	var title := Label.new()
	title.text = "灯光控制"
	title.add_theme_font_size_override("font_size", 20)
	content.add_child(title)

	var hint := Label.new()
	hint.text = "ESC 显示/隐藏，点击面板外回到游戏"
	hint.modulate = Color(0.82, 0.80, 0.68, 1.0)
	content.add_child(hint)

	_add_separator(content)
	_add_color_picker(content, "light_color", "灯光颜色", _light_color)
	_add_slider(content, "light_energy", "灯光强度", 0.25, 2.0, 0.01, _light_energy_multiplier)
	_add_slider(content, "light_range", "照射范围", 0.45, 1.8, 0.01, _light_range_multiplier)
	_add_slider(content, "light_attenuation", "衰减强度", 0.45, 2.4, 0.01, _light_attenuation_multiplier)
	_add_slider(content, "panel_emission", "灯板亮度", 0.15, 2.0, 0.01, _panel_emission_multiplier)

	_add_separator(content)
	_add_color_picker(content, "ambient_color", "环境光颜色", _ambient_color)
	_add_slider(content, "ambient_energy", "环境光强度", 0.0, 0.16, 0.001, _ambient_energy)
	_add_separator(content)
	_add_toggle(content, "contact_shadow_enabled", "闭塞阴影", _contact_shadow_enabled)
	_add_slider(content, "contact_shadow_strength", "闭塞强度", 0.0, 2.5, 0.01, _contact_shadow_strength)
	_add_slider(content, "contact_shadow_max", "最大压暗", 0.0, 0.45, 0.005, _contact_shadow_max)
	_add_flicker_toggle(content)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	content.add_child(buttons)

	var warm_white := Button.new()
	warm_white.text = "暖白"
	warm_white.pressed.connect(_apply_warm_white_preset)
	buttons.add_child(warm_white)

	var softer := Button.new()
	softer.text = "暗一点"
	softer.pressed.connect(_apply_darker_preset)
	buttons.add_child(softer)

	var reset := Button.new()
	reset.text = "还原"
	reset.pressed.connect(_reset_to_scene_values)
	buttons.add_child(reset)

func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.075, 0.055, 0.94)
	style.border_color = Color(0.48, 0.43, 0.22, 0.95)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	return style

func _add_separator(parent: VBoxContainer) -> void:
	var separator := HSeparator.new()
	parent.add_child(separator)

func _add_color_picker(parent: VBoxContainer, key: String, label_text: String, initial_color: Color) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)

	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	var picker := ColorPickerButton.new()
	picker.color = initial_color
	picker.edit_alpha = false
	picker.custom_minimum_size = Vector2(96.0, 30.0)
	picker.color_changed.connect(func(color: Color) -> void:
		_on_color_changed(key, color)
	)
	row.add_child(picker)
	_color_pickers[key] = picker

func _add_slider(parent: VBoxContainer, key: String, label_text: String, min_value: float, max_value: float, step: float, initial_value: float) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 2)
	parent.add_child(container)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	container.add_child(row)

	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	var value_label := Label.new()
	value_label.text = _format_value(initial_value)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.custom_minimum_size = Vector2(58.0, 0.0)
	row.add_child(value_label)
	_value_labels[key] = value_label

	var slider := HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.value = initial_value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(func(value: float) -> void:
		_on_slider_changed(key, value)
	)
	container.add_child(slider)
	_sliders[key] = slider

func _add_toggle(parent: VBoxContainer, key: String, label_text: String, initial_value: bool) -> void:
	var toggle := CheckBox.new()
	toggle.text = label_text
	toggle.button_pressed = initial_value
	toggle.toggled.connect(func(pressed: bool) -> void:
		_on_toggle_changed(key, pressed)
	)
	parent.add_child(toggle)
	_toggles[key] = toggle

func _add_flicker_toggle(parent: VBoxContainer) -> void:
	var toggle := CheckBox.new()
	toggle.text = "启用灯光闪烁"
	toggle.button_pressed = true
	toggle.toggled.connect(func(pressed: bool) -> void:
		if _lighting_controller != null:
			_lighting_controller.set("enabled", pressed)
	)
	parent.add_child(toggle)

func _initialize_lighting_state() -> void:
	var scene_root := _get_scene_root()
	_lighting_controller = scene_root.get_node_or_null("Systems/LightingController") if scene_root != null else null
	_world_environment = _find_world_environment(scene_root)
	if _world_environment != null and _world_environment.environment != null:
		_ambient_color = _world_environment.environment.ambient_light_color
		_ambient_energy = _world_environment.environment.ambient_light_energy
		_base_ambient_color = _ambient_color
		_base_ambient_energy = _ambient_energy
	_collect_light_bases()
	_collect_panel_bases()
	_collect_contact_shadow_bases()
	_light_color = DEFAULT_LIGHT_COLOR
	_sync_controls()
	_apply_lighting()

func _collect_light_bases() -> void:
	_light_bases.clear()
	var scene_tree := get_tree()
	if scene_tree == null:
		return
	for node in scene_tree.get_nodes_in_group("ceiling_light"):
		var light := node as Light3D
		if light == null:
			continue
		var light_base := {
			"node": light,
			"color": light.light_color,
			"energy": light.light_energy,
			"range": 1.0,
			"attenuation": 1.0,
		}
		var omni := light as OmniLight3D
		if omni != null:
			light_base["range"] = omni.omni_range
			light_base["attenuation"] = omni.omni_attenuation
		_light_bases[light.get_instance_id()] = light_base

func _collect_panel_bases() -> void:
	_panel_bases.clear()
	var scene_tree := get_tree()
	if scene_tree == null:
		return
	for node in scene_tree.get_nodes_in_group("ceiling_light_panel"):
		var panel := node as MeshInstance3D
		if panel == null:
			continue
		var material := _ensure_unique_panel_material(panel)
		if material == null:
			continue
		_panel_bases[panel.get_instance_id()] = {
			"node": panel,
			"albedo": material.albedo_color,
			"emission": material.emission,
			"emission_energy": material.emission_energy_multiplier,
		}

func _collect_contact_shadow_bases() -> void:
	_contact_shadow_bases.clear()
	var scene_root := _get_scene_root()
	if scene_root == null:
		return
	for mesh in _collect_contact_shadow_meshes(scene_root):
		var material := mesh.material_override as ShaderMaterial
		if material == null and mesh.mesh != null:
			material = mesh.mesh.surface_get_material(0) as ShaderMaterial
		if material == null or not ContactShadowMaterial.is_contact_material(material):
			continue
		var key := material.get_instance_id()
		if _contact_shadow_bases.has(key):
			continue
		_contact_shadow_bases[key] = {
			"material": material,
			"floor": float(material.get_shader_parameter("floor_contact_strength")),
			"ceiling": float(material.get_shader_parameter("ceiling_contact_strength")),
			"corner": float(material.get_shader_parameter("corner_contact_strength")),
			"door_edge": float(material.get_shader_parameter("door_edge_strength")),
			"max_shadow": float(material.get_shader_parameter("max_shadow")),
		}
		_contact_shadow_max = maxf(_contact_shadow_max, float(material.get_shader_parameter("max_shadow")))
		_base_contact_shadow_max = _contact_shadow_max

func _collect_contact_shadow_meshes(node: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	var mesh := node as MeshInstance3D
	if mesh != null:
		result.append(mesh)
	for child in node.get_children():
		result.append_array(_collect_contact_shadow_meshes(child))
	return result

func _ensure_unique_panel_material(panel: MeshInstance3D) -> StandardMaterial3D:
	if panel == null:
		return null
	var material := panel.material_override as StandardMaterial3D
	if material != null and bool(panel.get_meta(RUNTIME_UNIQUE_MATERIAL_META, false)):
		return material
	var source_material: Material = panel.material_override
	if source_material == null and panel.mesh != null:
		source_material = panel.mesh.surface_get_material(0)
	var standard_material := source_material as StandardMaterial3D
	if standard_material == null:
		return null
	var unique_material := standard_material.duplicate(true) as StandardMaterial3D
	panel.material_override = unique_material
	panel.set_meta(RUNTIME_UNIQUE_MATERIAL_META, true)
	return unique_material

func _sync_controls() -> void:
	_updating_controls = true
	_set_picker_color("light_color", _light_color)
	_set_picker_color("ambient_color", _ambient_color)
	_set_slider_value("light_energy", _light_energy_multiplier)
	_set_slider_value("light_range", _light_range_multiplier)
	_set_slider_value("light_attenuation", _light_attenuation_multiplier)
	_set_slider_value("panel_emission", _panel_emission_multiplier)
	_set_slider_value("ambient_energy", _ambient_energy)
	_set_toggle_value("contact_shadow_enabled", _contact_shadow_enabled)
	_set_slider_value("contact_shadow_strength", _contact_shadow_strength)
	_set_slider_value("contact_shadow_max", _contact_shadow_max)
	_updating_controls = false

func _set_picker_color(key: String, color: Color) -> void:
	var picker := _color_pickers.get(key) as ColorPickerButton
	if picker != null:
		picker.color = color

func _set_slider_value(key: String, value: float) -> void:
	var slider := _sliders.get(key) as HSlider
	if slider != null:
		slider.value = value
	var label := _value_labels.get(key) as Label
	if label != null:
		label.text = _format_value(value)

func _set_toggle_value(key: String, value: bool) -> void:
	var toggle := _toggles.get(key) as CheckBox
	if toggle != null:
		toggle.button_pressed = value

func _on_color_changed(key: String, color: Color) -> void:
	if _updating_controls:
		return
	if key == "light_color":
		_light_color = color
	elif key == "ambient_color":
		_ambient_color = color
	_apply_lighting()

func _on_toggle_changed(key: String, pressed: bool) -> void:
	if _updating_controls:
		return
	if key == "contact_shadow_enabled":
		_contact_shadow_enabled = pressed
	_apply_lighting()

func _on_slider_changed(key: String, value: float) -> void:
	var label := _value_labels.get(key) as Label
	if label != null:
		label.text = _format_value(value)
	if _updating_controls:
		return
	match key:
		"light_energy":
			_light_energy_multiplier = value
		"light_range":
			_light_range_multiplier = value
		"light_attenuation":
			_light_attenuation_multiplier = value
		"panel_emission":
			_panel_emission_multiplier = value
		"ambient_energy":
			_ambient_energy = value
		"contact_shadow_strength":
			_contact_shadow_strength = value
		"contact_shadow_max":
			_contact_shadow_max = value
	_apply_lighting()

func _apply_warm_white_preset() -> void:
	_light_color = DEFAULT_LIGHT_COLOR
	_light_energy_multiplier = 1.08
	_light_range_multiplier = 0.96
	_light_attenuation_multiplier = 1.12
	_panel_emission_multiplier = 1.0
	_contact_shadow_enabled = true
	_contact_shadow_strength = 0.9
	_contact_shadow_max = 0.22
	_sync_controls()
	_apply_lighting()

func _apply_darker_preset() -> void:
	_ambient_energy = 0.045
	_light_energy_multiplier = 1.12
	_light_range_multiplier = 0.9
	_light_attenuation_multiplier = 1.25
	_panel_emission_multiplier = 0.95
	_contact_shadow_enabled = true
	_contact_shadow_strength = 1.25
	_contact_shadow_max = 0.28
	_sync_controls()
	_apply_lighting()

func _reset_to_scene_values() -> void:
	for light_id in _light_bases.keys():
		var base: Dictionary = _light_bases[light_id]
		var light := base.get("node") as Light3D
		if light == null or not is_instance_valid(light):
			continue
		light.light_color = base.get("color", light.light_color)
		light.light_energy = float(base.get("energy", light.light_energy))
		var omni := light as OmniLight3D
		if omni != null:
			omni.omni_range = float(base.get("range", omni.omni_range))
			omni.omni_attenuation = float(base.get("attenuation", omni.omni_attenuation))
	for panel_id in _panel_bases.keys():
		var panel_base: Dictionary = _panel_bases[panel_id]
		var panel := panel_base.get("node") as MeshInstance3D
		if panel == null or not is_instance_valid(panel):
			continue
		var material := _ensure_unique_panel_material(panel)
		if material == null:
			continue
		material.albedo_color = panel_base.get("albedo", material.albedo_color)
		material.emission = panel_base.get("emission", material.emission)
		material.emission_energy_multiplier = float(panel_base.get("emission_energy", material.emission_energy_multiplier))
	if _world_environment != null and _world_environment.environment != null:
		_world_environment.environment.ambient_light_energy = _base_ambient_energy
		_world_environment.environment.ambient_light_color = _base_ambient_color
	_light_color = _first_base_light_color()
	_ambient_color = _base_ambient_color
	_ambient_energy = _base_ambient_energy
	_contact_shadow_enabled = _base_contact_shadow_enabled
	_contact_shadow_strength = _base_contact_shadow_strength
	_contact_shadow_max = _base_contact_shadow_max
	_light_energy_multiplier = 1.0
	_light_range_multiplier = 1.0
	_light_attenuation_multiplier = 1.0
	_panel_emission_multiplier = 1.0
	_sync_controls()
	_queue_lighting_controller_refresh()

func _apply_lighting() -> void:
	for light_id in _light_bases.keys():
		var base: Dictionary = _light_bases[light_id]
		var light := base.get("node") as Light3D
		if light == null or not is_instance_valid(light):
			continue
		light.light_color = _light_color
		light.light_energy = float(base.get("energy", light.light_energy)) * _light_energy_multiplier
		var omni := light as OmniLight3D
		if omni != null:
			omni.omni_range = float(base.get("range", omni.omni_range)) * _light_range_multiplier
			omni.omni_attenuation = float(base.get("attenuation", omni.omni_attenuation)) * _light_attenuation_multiplier

	for panel_id in _panel_bases.keys():
		var panel_base: Dictionary = _panel_bases[panel_id]
		var panel := panel_base.get("node") as MeshInstance3D
		if panel == null or not is_instance_valid(panel):
			continue
		var material := _ensure_unique_panel_material(panel)
		if material == null:
			continue
		material.albedo_color = Color(_light_color.r, _light_color.g, _light_color.b, material.albedo_color.a)
		material.emission_enabled = true
		material.emission = _light_color
		material.emission_energy_multiplier = float(panel_base.get("emission_energy", material.emission_energy_multiplier)) * _panel_emission_multiplier

	if _world_environment != null and _world_environment.environment != null:
		var environment := _world_environment.environment
		environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		environment.ambient_light_color = _ambient_color
		environment.ambient_light_energy = _ambient_energy
		environment.ambient_light_sky_contribution = 0.0

	_apply_contact_shadow()
	_queue_lighting_controller_refresh()

func _apply_contact_shadow() -> void:
	var multiplier := _contact_shadow_strength if _contact_shadow_enabled else 0.0
	for contact_id in _contact_shadow_bases.keys():
		var base: Dictionary = _contact_shadow_bases[contact_id]
		var material := base.get("material") as ShaderMaterial
		if material == null:
			continue
		material.set_shader_parameter("floor_contact_strength", float(base.get("floor", 0.0)) * multiplier)
		material.set_shader_parameter("ceiling_contact_strength", float(base.get("ceiling", 0.0)) * multiplier)
		material.set_shader_parameter("corner_contact_strength", float(base.get("corner", 0.0)) * multiplier)
		material.set_shader_parameter("door_edge_strength", float(base.get("door_edge", 0.0)) * multiplier)
		material.set_shader_parameter("max_shadow", _contact_shadow_max)

func _queue_lighting_controller_refresh() -> void:
	if _refresh_pending:
		return
	_refresh_pending = true
	call_deferred("_refresh_lighting_controller")

func _refresh_lighting_controller() -> void:
	_refresh_pending = false
	if _lighting_controller != null and _lighting_controller.has_method("refresh_light_cache"):
		_lighting_controller.call("refresh_light_cache")

func _get_scene_root() -> Node:
	var current: Node = self
	var scene_tree := get_tree()
	if scene_tree == null:
		return current
	while current.get_parent() != null and current.get_parent() != scene_tree.root:
		current = current.get_parent()
	return current

func _find_world_environment(node: Node) -> WorldEnvironment:
	if node == null:
		return null
	var world_environment := node as WorldEnvironment
	if world_environment != null:
		return world_environment
	for child in node.get_children():
		var found := _find_world_environment(child)
		if found != null:
			return found
	return null

func _first_base_light_color() -> Color:
	for light_id in _light_bases.keys():
		var base: Dictionary = _light_bases[light_id]
		return base.get("color", DEFAULT_LIGHT_COLOR)
	return DEFAULT_LIGHT_COLOR

func _format_value(value: float) -> String:
	return "%.3f" % value if value < 0.2 else "%.2f" % value
