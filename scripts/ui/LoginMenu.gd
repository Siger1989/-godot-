extends Control

@export_file("*.tscn") var game_scene_path := "res://scenes/tests/Test_ProcMazeMap.tscn"

var _player_name_input: LineEdit
var _room_code_input: LineEdit
var _status_label: Label
var _buttons: Array[Button] = []
var _changing_scene := false
var _debug_skip_online_start := false

func _ready() -> void:
	name = "LoginMenu"
	_build_ui()
	_bind_session_signals()

func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var background := ColorRect.new()
	background.name = "Background"
	background.color = Color(0.015, 0.014, 0.011, 1.0)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var root_margin := MarginContainer.new()
	root_margin.name = "RootMargin"
	root_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_margin.add_theme_constant_override("margin_left", 32)
	root_margin.add_theme_constant_override("margin_right", 32)
	root_margin.add_theme_constant_override("margin_top", 42)
	root_margin.add_theme_constant_override("margin_bottom", 42)
	add_child(root_margin)

	var layout := VBoxContainer.new()
	layout.name = "Layout"
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	layout.add_theme_constant_override("separation", 14)
	root_margin.add_child(layout)

	var title := Label.new()
	title.name = "Title"
	title.text = "BACKROOMS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color(0.96, 0.89, 0.68, 1.0))
	layout.add_child(title)

	var subtitle := Label.new()
	subtitle.name = "Subtitle"
	subtitle.text = "单人 / 联机房间"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	subtitle.add_theme_font_size_override("font_size", 24)
	subtitle.add_theme_color_override("font_color", Color(0.68, 0.66, 0.56, 1.0))
	layout.add_child(subtitle)

	var form := VBoxContainer.new()
	form.name = "Form"
	form.custom_minimum_size = Vector2(320.0, 0.0)
	form.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	form.add_theme_constant_override("separation", 12)
	layout.add_child(form)

	_player_name_input = _make_line_edit("PlayerNameInput", "玩家名", "Player")
	form.add_child(_player_name_input)

	_room_code_input = _make_line_edit("RoomCodeInput", "输入房号加入", "")
	_room_code_input.max_length = 8
	form.add_child(_room_code_input)

	var single_button := _make_button("SingleButton", "单人", Vector2(320.0, 74.0))
	single_button.pressed.connect(_start_single)
	form.add_child(single_button)

	var button_row := HBoxContainer.new()
	button_row.name = "ModeButtons"
	button_row.custom_minimum_size = Vector2(320.0, 0.0)
	button_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button_row.add_theme_constant_override("separation", 10)
	form.add_child(button_row)

	var host_button := _make_button("HostButton", "创建房间", Vector2(155.0, 74.0))
	host_button.pressed.connect(_start_host)
	button_row.add_child(host_button)

	var join_button := _make_button("JoinButton", "加入房间", Vector2(155.0, 74.0))
	join_button.pressed.connect(_start_join)
	button_row.add_child(join_button)

	_status_label = Label.new()
	_status_label.name = "StatusLabel"
	_status_label.text = "电脑下蹲：C | 手机：下蹲按钮"
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.custom_minimum_size = Vector2(320.0, 0.0)
	_status_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_status_label.add_theme_font_size_override("font_size", 19)
	_status_label.add_theme_color_override("font_color", Color(0.72, 0.70, 0.60, 1.0))
	form.add_child(_status_label)

func _make_line_edit(node_name: String, placeholder: String, value: String) -> LineEdit:
	var input := LineEdit.new()
	input.name = node_name
	input.placeholder_text = placeholder
	input.text = value
	input.custom_minimum_size = Vector2(320.0, 76.0)
	input.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	input.add_theme_font_size_override("font_size", 34)
	return input

func _make_button(node_name: String, text: String, minimum_size: Vector2) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.custom_minimum_size = minimum_size
	button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.add_theme_font_size_override("font_size", 24)
	_buttons.append(button)
	return button

func _start_single() -> void:
	_prepare_mode_button_press()
	_session_call("configure_single", [_player_name_input.text])
	_begin_session_or_online()

func _start_host() -> void:
	_prepare_mode_button_press()
	_session_call("configure_host", [_player_name_input.text, _room_code_input.text])
	_begin_session_or_online()

func _start_join() -> void:
	_prepare_mode_button_press()
	var ok := bool(_session_call("configure_join", [_player_name_input.text, _room_code_input.text]))
	_status_label.text = _session_message()
	if ok:
		_begin_session_or_online()

func _prepare_mode_button_press() -> void:
	if _player_name_input != null:
		_player_name_input.release_focus()
	if _room_code_input != null:
		_room_code_input.release_focus()
	var viewport := get_viewport()
	if viewport != null:
		viewport.gui_release_focus()
	DisplayServer.virtual_keyboard_hide()

func _begin_session_or_online() -> void:
	var session := _session()
	if session == null:
		_status_label.text = "Game session is unavailable."
		return

	_bind_session_signals()
	_set_buttons_disabled(true)
	var ready := true
	if session.has_method("start_online_if_needed"):
		if _debug_skip_online_start and session.has_method("is_online_mode") and bool(session.call("is_online_mode")):
			_status_label.text = _session_message()
			_set_buttons_disabled(false)
			return
		ready = bool(session.call("start_online_if_needed"))
	_status_label.text = _session_message()
	if ready:
		_change_to_game()
	elif String(session.get("service_status")) == "online_failed":
		_set_buttons_disabled(false)

func _change_to_game() -> void:
	if _changing_scene:
		return
	_changing_scene = true
	var error := get_tree().change_scene_to_file(game_scene_path)
	if error != OK:
		_changing_scene = false
		_set_buttons_disabled(false)
		_status_label.text = "Failed to enter game scene: %s" % str(error)

func _bind_session_signals() -> void:
	var session := _session()
	if session == null:
		return
	var status_callback := Callable(self, "_on_online_status_changed")
	if session.has_signal("online_status_changed") and not session.is_connected("online_status_changed", status_callback):
		session.connect("online_status_changed", status_callback)
	var ready_callback := Callable(self, "_on_online_ready")
	if session.has_signal("online_ready") and not session.is_connected("online_ready", ready_callback):
		session.connect("online_ready", ready_callback)

func _on_online_status_changed(message: String) -> void:
	_status_label.text = message
	var session := _session()
	if session != null and String(session.get("service_status")) == "online_failed":
		_set_buttons_disabled(false)

func _on_online_ready() -> void:
	_change_to_game()

func _set_buttons_disabled(disabled: bool) -> void:
	for button in _buttons:
		button.disabled = disabled
	_player_name_input.editable = not disabled
	_room_code_input.editable = not disabled

func _session() -> Node:
	return get_node_or_null("/root/GameSession")

func _session_call(method_name: String, args: Array = []) -> Variant:
	var session := _session()
	if session == null or not session.has_method(method_name):
		return null
	return session.callv(method_name, args)

func _session_message() -> String:
	var session := _session()
	if session == null:
		return "Online status is unavailable."
	return String(session.get("service_message"))

func debug_get_status_text() -> String:
	return _status_label.text if _status_label != null else ""

func debug_set_room_code(value: String) -> void:
	if _room_code_input != null:
		_room_code_input.text = value

func debug_has_login_controls() -> bool:
	return (
		get_node_or_null("RootMargin/Layout/Form/PlayerNameInput") != null
		and get_node_or_null("RootMargin/Layout/Form/RoomCodeInput") != null
		and get_node_or_null("RootMargin/Layout/Form/SingleButton") != null
		and get_node_or_null("RootMargin/Layout/Form/ModeButtons/HostButton") != null
		and get_node_or_null("RootMargin/Layout/Form/ModeButtons/JoinButton") != null
	)

func debug_get_input_minimum_size() -> Vector2:
	return _player_name_input.custom_minimum_size if _player_name_input != null else Vector2.ZERO

func debug_get_input_runtime_size() -> Vector2:
	return _player_name_input.size if _player_name_input != null else Vector2.ZERO

func debug_get_input_font_size() -> int:
	return _player_name_input.get_theme_font_size("font_size") if _player_name_input != null else 0

func debug_get_button_minimum_size() -> Vector2:
	return _buttons[0].custom_minimum_size if not _buttons.is_empty() else Vector2.ZERO

func debug_get_button_font_size() -> int:
	return _buttons[0].get_theme_font_size("font_size") if not _buttons.is_empty() else 0

func debug_get_host_button_minimum_size() -> Vector2:
	var button := get_node_or_null("RootMargin/Layout/Form/ModeButtons/HostButton") as Button
	return button.custom_minimum_size if button != null else Vector2.ZERO

func debug_get_control_global_rect(path: String) -> Rect2:
	var control := get_node_or_null(NodePath(path)) as Control
	return control.get_global_rect() if control != null else Rect2()

func debug_focus_room_code() -> void:
	if _room_code_input != null:
		_room_code_input.grab_focus()

func debug_is_any_input_focused() -> bool:
	var focus_owner := get_viewport().gui_get_focus_owner()
	return focus_owner == _player_name_input or focus_owner == _room_code_input

func debug_set_skip_online_start(value: bool) -> void:
	_debug_skip_online_start = value
