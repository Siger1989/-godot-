extends CanvasLayer
class_name UIRoot

var game_manager: Node
var objective_label: Label
var fuse_label: Label
var prompt_label: Label
var feedback_label: Label
var result_panel: PanelContainer
var result_title: Label
var result_body: Label
var signal_label: Label
var film_material: ShaderMaterial
var move_vector := Vector2.ZERO
var feedback_timer := 0.0
var threat_level := 0.0


func _ready() -> void:
	add_to_group("ui_root")
	add_to_group("mobile_controls")
	_build_overlay()
	_build_hud()
	_build_mobile_controls()
	_build_result_panel()


func _process(delta: float) -> void:
	threat_level = max(threat_level - delta * 0.28, 0.0)
	if film_material:
		film_material.set_shader_parameter("threat_level", threat_level)
	_update_prompt()
	if feedback_timer > 0.0:
		feedback_timer -= delta
		if feedback_timer <= 0.0:
			feedback_label.text = ""
			feedback_label.visible = false


func set_game_manager(manager: Node) -> void:
	game_manager = manager


func set_objective(text: String, fuse_count: int, required_fuses: int, power_restored: bool) -> void:
	if objective_label:
		objective_label.text = text
	if fuse_label:
		var power_text := "POWER OK" if power_restored else "NO POWER"
		fuse_label.text = "FUSE %d/%d   %s" % [fuse_count, required_fuses, power_text]


func show_feedback(text: String) -> void:
	feedback_label.text = text
	feedback_label.visible = true
	feedback_timer = 2.4


func show_result(title: String, body: String) -> void:
	result_title.text = title
	result_body.text = body + "\n\n按 Esc 重新开始"
	result_panel.visible = true


func get_move_vector() -> Vector2:
	return move_vector


func set_threat_level(value: float) -> void:
	threat_level = max(threat_level, value)
	if signal_label:
		if threat_level > 0.55:
			signal_label.text = "SIGNAL\n// //"
		elif threat_level > 0.22:
			signal_label.text = "SIGNAL\n-- /-"
		else:
			signal_label.text = "SIGNAL\n-- --"


func _update_prompt() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("get_interaction_text"):
		var text: String = player.get_interaction_text()
		prompt_label.visible = not text.is_empty()
		prompt_label.text = "E  " + text
	else:
		prompt_label.visible = false


func _build_overlay() -> void:
	var overlay := ColorRect.new()
	overlay.name = "FilmOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
render_mode blend_mix;
uniform float grain_strength = 0.085;
uniform float vignette_strength = 0.055;
uniform float threat_level = 0.0;
float rand(vec2 co) {
	return fract(sin(dot(co.xy, vec2(12.9898,78.233)) + TIME * 18.0) * 43758.5453);
}
void fragment() {
	vec2 uv = UV;
	float d = distance(uv, vec2(0.5));
	float vig = smoothstep(0.42, 0.86, d) * (vignette_strength + threat_level * 0.22);
	float grain = (rand(FRAGCOORD.xy) - 0.5) * grain_strength;
	vec3 edge = vec3(0.0, 0.0, 0.0) * vig;
	COLOR = vec4(edge + grain, 0.018 + vig * 0.48 + threat_level * 0.055);
}
"""
	film_material = ShaderMaterial.new()
	film_material.shader = shader
	overlay.material = film_material
	add_child(overlay)


func _build_hud() -> void:
	var root := Control.new()
	root.name = "HUD"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var objective_panel := PanelContainer.new()
	objective_panel.name = "ObjectivePanel"
	objective_panel.anchor_left = 0.5
	objective_panel.anchor_right = 0.5
	objective_panel.offset_left = -190
	objective_panel.offset_right = 190
	objective_panel.offset_top = 16
	objective_panel.offset_bottom = 70
	objective_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.05, 0.055, 0.045, 0.48), Color(0.58, 0.54, 0.34, 0.34)))
	root.add_child(objective_panel)
	var objective_box := VBoxContainer.new()
	objective_box.add_theme_constant_override("separation", 2)
	objective_panel.add_child(objective_box)
	objective_label = Label.new()
	objective_label.text = "寻找保险丝 0/3"
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label.add_theme_font_size_override("font_size", 17)
	objective_box.add_child(objective_label)
	fuse_label = Label.new()
	fuse_label.text = "FUSE 0/3   NO POWER"
	fuse_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fuse_label.add_theme_font_size_override("font_size", 10)
	fuse_label.add_theme_color_override("font_color", Color(0.78, 0.78, 0.58))
	objective_box.add_child(fuse_label)

	var signal_panel := PanelContainer.new()
	signal_panel.offset_left = 14
	signal_panel.offset_top = 16
	signal_panel.offset_right = 154
	signal_panel.offset_bottom = 62
	signal_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.04, 0.06, 0.05, 0.40), Color(0.35, 0.55, 0.38, 0.24)))
	root.add_child(signal_panel)
	signal_label = Label.new()
	signal_label.text = "SIGNAL\n-- --"
	signal_label.add_theme_font_size_override("font_size", 10)
	signal_label.add_theme_color_override("font_color", Color(0.58, 0.76, 0.56))
	signal_panel.add_child(signal_label)

	prompt_label = Label.new()
	prompt_label.name = "InteractionPrompt"
	prompt_label.visible = false
	prompt_label.anchor_left = 0.5
	prompt_label.anchor_right = 0.5
	prompt_label.anchor_top = 1.0
	prompt_label.anchor_bottom = 1.0
	prompt_label.offset_left = -170
	prompt_label.offset_right = 170
	prompt_label.offset_top = -160
	prompt_label.offset_bottom = -120
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt_label.add_theme_font_size_override("font_size", 14)
	prompt_label.add_theme_color_override("font_color", Color(0.92, 0.88, 0.68))
	root.add_child(prompt_label)

	feedback_label = Label.new()
	feedback_label.name = "Feedback"
	feedback_label.visible = false
	feedback_label.anchor_left = 0.5
	feedback_label.anchor_right = 0.5
	feedback_label.offset_left = -310
	feedback_label.offset_right = 310
	feedback_label.offset_top = 100
	feedback_label.offset_bottom = 132
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.add_theme_font_size_override("font_size", 13)
	feedback_label.add_theme_color_override("font_color", Color(0.96, 0.84, 0.52))
	root.add_child(feedback_label)

	var slots := HBoxContainer.new()
	slots.name = "ItemSlots"
	slots.anchor_left = 0.5
	slots.anchor_right = 0.5
	slots.anchor_top = 1.0
	slots.anchor_bottom = 1.0
	slots.offset_left = -76
	slots.offset_right = 76
	slots.offset_top = -62
	slots.offset_bottom = -22
	slots.add_theme_constant_override("separation", 10)
	root.add_child(slots)
	for i in 3:
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(40, 40)
		slot.add_theme_stylebox_override("panel", _panel_style(Color(0.08, 0.085, 0.07, 0.46), Color(0.54, 0.49, 0.3, 0.30)))
		var label := Label.new()
		label.text = "%d" % (i + 1)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color(0.55, 0.53, 0.36))
		slot.add_child(label)
		slots.add_child(slot)


func _build_mobile_controls() -> void:
	var controls := Control.new()
	controls.name = "MobileControls"
	controls.set_anchors_preset(Control.PRESET_FULL_RECT)
	controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(controls)

	var pad := Control.new()
	pad.name = "MovePad"
	pad.anchor_top = 1.0
	pad.anchor_bottom = 1.0
	pad.offset_left = 42
	pad.offset_top = -166
	pad.offset_right = 162
	pad.offset_bottom = -46
	pad.mouse_filter = Control.MOUSE_FILTER_PASS
	pad.gui_input.connect(_on_move_pad_input)
	controls.add_child(pad)
	var pad_bg := ColorRect.new()
	pad_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	pad_bg.color = Color(0.08, 0.09, 0.07, 0.18)
	pad_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.add_child(pad_bg)
	var pad_label := Label.new()
	pad_label.text = "MOVE"
	pad_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	pad_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pad_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pad_label.add_theme_color_override("font_color", Color(0.66, 0.68, 0.52))
	pad_label.add_theme_font_size_override("font_size", 11)
	pad_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.add_child(pad_label)

	_add_action_button(controls, "InteractButton", "E", "interact", Vector2(-96, -120), Vector2(58, 58))
	_add_hold_button(controls, "SprintButton", "RUN", "sprint", Vector2(-170, -100), Vector2(54, 54))
	_add_action_button(controls, "CameraButton", "CAM", "rotate_camera_right", Vector2(-96, -190), Vector2(54, 46))
	_add_action_button(controls, "ZoomButton", "ZOOM", "zoom_camera", Vector2(-170, -164), Vector2(54, 46))


func _build_result_panel() -> void:
	result_panel = PanelContainer.new()
	result_panel.name = "ResultScreen"
	result_panel.visible = false
	result_panel.anchor_left = 0.5
	result_panel.anchor_right = 0.5
	result_panel.anchor_top = 0.5
	result_panel.anchor_bottom = 0.5
	result_panel.offset_left = -240
	result_panel.offset_right = 240
	result_panel.offset_top = -130
	result_panel.offset_bottom = 130
	result_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.028, 0.024, 0.94), Color(0.78, 0.72, 0.42, 0.52)))
	add_child(result_panel)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 16)
	result_panel.add_child(box)
	result_title = Label.new()
	result_title.text = "LOST"
	result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_title.add_theme_font_size_override("font_size", 42)
	result_title.add_theme_color_override("font_color", Color(0.94, 0.87, 0.56))
	box.add_child(result_title)
	result_body = Label.new()
	result_body.text = ""
	result_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_body.add_theme_font_size_override("font_size", 17)
	result_body.add_theme_color_override("font_color", Color(0.82, 0.81, 0.66))
	box.add_child(result_body)


func _on_move_pad_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if not event.pressed:
			move_vector = Vector2.ZERO
			return
	if event is InputEventScreenDrag or event is InputEventMouseMotion or event is InputEventScreenTouch or event is InputEventMouseButton:
		var pad := get_node_or_null("MobileControls/MovePad") as Control
		if not pad:
			return
		var position := pad.get_local_mouse_position()
		var center := pad.size * 0.5
		move_vector = ((position - center) / (pad.size.x * 0.42)).limit_length(1.0)


func _add_action_button(parent: Control, node_name: String, text: String, action: String, offset: Vector2, size: Vector2) -> void:
	var button := _make_button(node_name, text, offset, size)
	parent.add_child(button)
	button.pressed.connect(func() -> void:
		Input.action_press(action)
		await get_tree().process_frame
		Input.action_release(action)
	)


func _add_hold_button(parent: Control, node_name: String, text: String, action: String, offset: Vector2, size: Vector2) -> void:
	var button := _make_button(node_name, text, offset, size)
	parent.add_child(button)
	button.button_down.connect(func() -> void:
		Input.action_press(action)
	)
	button.button_up.connect(func() -> void:
		Input.action_release(action)
	)


func _make_button(node_name: String, text: String, offset: Vector2, size: Vector2) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.anchor_left = 1.0
	button.anchor_right = 1.0
	button.anchor_top = 1.0
	button.anchor_bottom = 1.0
	button.offset_left = offset.x
	button.offset_top = offset.y
	button.offset_right = offset.x + size.x
	button.offset_bottom = offset.y + size.y
	button.add_theme_stylebox_override("normal", _button_style(Color(0.09, 0.10, 0.075, 0.44)))
	button.add_theme_stylebox_override("hover", _button_style(Color(0.13, 0.14, 0.095, 0.52)))
	button.add_theme_stylebox_override("pressed", _button_style(Color(0.19, 0.22, 0.12, 0.62)))
	button.add_theme_color_override("font_color", Color(0.78, 0.78, 0.56))
	button.add_theme_font_size_override("font_size", 11)
	return button


func _panel_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(10)
	return style


func _button_style(fill: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = Color(0.58, 0.54, 0.34, 0.44)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	return style
