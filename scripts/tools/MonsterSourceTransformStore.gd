extends RefCounted

const SOURCE_SCENE_PATH := "res://scenes/mvp/FourRoomMVP.tscn"
const VISUAL_YAW_PROPERTY := "metadata/monster_visual_yaw_degrees"

const MONSTER_ENTRIES := [
	{
		"source_id": "normal",
		"template_id": "normal",
		"node_path": "MonsterRoot/Monster",
		"display_name": "普通怪物",
	},
	{
		"source_id": "red_hunter",
		"template_id": "red_hunter",
		"node_path": "MonsterRoot/Monster_Red_KeyBearer_MVP",
		"display_name": "红色猎手",
	},
	{
		"source_id": "nightmare",
		"template_id": "nightmare",
		"node_path": "MonsterRoot/NightmareCreature_A_MVP",
		"display_name": "Nightmare 听觉怪",
	},
]

static func monster_entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in MONSTER_ENTRIES:
		var copy: Dictionary = entry.duplicate(true)
		copy["transform"] = load_transform(String(copy["source_id"]))
		copy["collision_config"] = load_collision_config(String(copy["source_id"]))
		copy["visual_yaw_degrees"] = load_visual_yaw_degrees(String(copy["source_id"]))
		result.append(copy)
	return result

static func load_transform(source_id: String) -> Transform3D:
	var entry := _entry_for_source(source_id)
	if entry.is_empty():
		return Transform3D.IDENTITY
	var packed := ResourceLoader.load(SOURCE_SCENE_PATH, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if packed == null:
		return Transform3D.IDENTITY
	var state := packed.get_state()
	var target_path := String(entry["node_path"])
	for node_index in range(state.get_node_count()):
		var state_path := String(state.get_node_path(node_index, false))
		if state_path != target_path and state_path != "./%s" % target_path:
			continue
		for property_index in range(state.get_node_property_count(node_index)):
			if state.get_node_property_name(node_index, property_index) == &"transform":
				var value = state.get_node_property_value(node_index, property_index)
				if typeof(value) == TYPE_TRANSFORM3D:
					return value
	return Transform3D.IDENTITY

static func save_transform(source_id: String, transform: Transform3D) -> int:
	var entry := _entry_for_source(source_id)
	if entry.is_empty():
		return ERR_DOES_NOT_EXIST
	var scene_path := ProjectSettings.globalize_path(SOURCE_SCENE_PATH)
	var text := FileAccess.get_file_as_string(scene_path)
	if text.is_empty():
		return ERR_FILE_CANT_READ
	var updated := replace_transform_text(text, String(entry["node_path"]), transform)
	if updated == text:
		return OK
	var file := FileAccess.open(scene_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(updated)
	file.close()
	return OK

static func load_collision_config(source_id: String) -> Dictionary:
	var entry := _entry_for_source(source_id)
	if entry.is_empty():
		return {}
	var packed := ResourceLoader.load(SOURCE_SCENE_PATH, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if packed == null:
		return {}
	var state := packed.get_state()
	var node_index := _find_state_node(state, String(entry["node_path"]))
	if node_index < 0:
		return {}
	var size_value = _state_node_property(state, node_index, &"metadata/monster_collision_box_size", null)
	if typeof(size_value) != TYPE_VECTOR3:
		return {}
	var position_value = _state_node_property(state, node_index, &"metadata/monster_collision_box_position", Vector3.ZERO)
	var position := Vector3.ZERO
	if typeof(position_value) == TYPE_VECTOR3:
		position = position_value
	return {
		"size": size_value,
		"position": position,
	}

static func save_collision_config(source_id: String, size: Vector3, position: Vector3) -> int:
	var entry := _entry_for_source(source_id)
	if entry.is_empty():
		return ERR_DOES_NOT_EXIST
	var scene_path := ProjectSettings.globalize_path(SOURCE_SCENE_PATH)
	var text := FileAccess.get_file_as_string(scene_path)
	if text.is_empty():
		return ERR_FILE_CANT_READ
	var updated := replace_node_property_text(
		text,
		String(entry["node_path"]),
		"metadata/monster_collision_box_size",
		vector3_to_text(size)
	)
	updated = replace_node_property_text(
		updated,
		String(entry["node_path"]),
		"metadata/monster_collision_box_position",
		vector3_to_text(position)
	)
	if updated == text:
		return OK
	var file := FileAccess.open(scene_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(updated)
	file.close()
	return OK

static func load_visual_yaw_degrees(source_id: String) -> float:
	var entry := _entry_for_source(source_id)
	if entry.is_empty():
		return 0.0
	var packed := ResourceLoader.load(SOURCE_SCENE_PATH, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if packed == null:
		return 0.0
	var state := packed.get_state()
	var node_index := _find_state_node(state, String(entry["node_path"]))
	if node_index < 0:
		return 0.0
	var value = _state_node_property(state, node_index, &"metadata/monster_visual_yaw_degrees", 0.0)
	if typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_INT:
		return float(value)
	return 0.0

static func save_visual_yaw_degrees(source_id: String, yaw_degrees: float) -> int:
	var entry := _entry_for_source(source_id)
	if entry.is_empty():
		return ERR_DOES_NOT_EXIST
	var scene_path := ProjectSettings.globalize_path(SOURCE_SCENE_PATH)
	var text := FileAccess.get_file_as_string(scene_path)
	if text.is_empty():
		return ERR_FILE_CANT_READ
	var updated := replace_node_property_text(
		text,
		String(entry["node_path"]),
		VISUAL_YAW_PROPERTY,
		_format_float(yaw_degrees)
	)
	if updated == text:
		return OK
	var file := FileAccess.open(scene_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(updated)
	file.close()
	return OK

static func replace_transform_text(text: String, node_path: String, transform: Transform3D) -> String:
	var normalized := text.replace("\r\n", "\n").replace("\r", "\n")
	var lines := normalized.split("\n", true)
	var parts := node_path.split("/")
	if parts.size() < 2:
		return text
	var node_name := String(parts[parts.size() - 1])
	var parent_path := "/".join(parts.slice(0, parts.size() - 1))
	var transform_line := "transform = %s" % transform_to_text(transform)
	var output: Array[String] = []
	var in_target := false
	var wrote_transform := false
	var found_target := false

	for line in lines:
		if line.begins_with("[node "):
			if in_target and not wrote_transform:
				output.append(transform_line)
			in_target = _is_target_node_header(line, node_name, parent_path)
			wrote_transform = false
			found_target = found_target or in_target
			output.append(line)
			continue
		if in_target and line.begins_with("transform = "):
			if not wrote_transform:
				output.append(transform_line)
				wrote_transform = true
			continue
		output.append(line)

	if in_target and not wrote_transform:
		output.append(transform_line)
	if not found_target:
		return text
	return "\n".join(output)

static func replace_node_property_text(text: String, node_path: String, property_name: String, value_text: String) -> String:
	var normalized := text.replace("\r\n", "\n").replace("\r", "\n")
	var lines := normalized.split("\n", true)
	var parts := node_path.split("/")
	if parts.size() < 2:
		return text
	var node_name := String(parts[parts.size() - 1])
	var parent_path := "/".join(parts.slice(0, parts.size() - 1))
	var property_line := "%s = %s" % [property_name, value_text]
	var output: Array[String] = []
	var in_target := false
	var wrote_property := false
	var found_target := false
	var prefix := "%s = " % property_name

	for line in lines:
		if line.begins_with("[node "):
			if in_target and not wrote_property:
				output.append(property_line)
			in_target = _is_target_node_header(line, node_name, parent_path)
			wrote_property = false
			found_target = found_target or in_target
			output.append(line)
			continue
		if in_target and line.begins_with(prefix):
			if not wrote_property:
				output.append(property_line)
				wrote_property = true
			continue
		output.append(line)

	if in_target and not wrote_property:
		output.append(property_line)
	if not found_target:
		return text
	return "\n".join(output)

static func transform_to_text(transform: Transform3D) -> String:
	var basis := transform.basis
	var origin := transform.origin
	var values := [
		basis.x.x, basis.x.y, basis.x.z,
		basis.y.x, basis.y.y, basis.y.z,
		basis.z.x, basis.z.y, basis.z.z,
		origin.x, origin.y, origin.z,
	]
	var formatted: Array[String] = []
	for value in values:
		formatted.append(_format_float(float(value)))
	return "Transform3D(%s)" % ", ".join(formatted)

static func vector3_to_text(value: Vector3) -> String:
	return "Vector3(%s, %s, %s)" % [
		_format_float(value.x),
		_format_float(value.y),
		_format_float(value.z),
	]

static func build_transform(position: Vector3, rotation_degrees: Vector3, scale: Vector3) -> Transform3D:
	var rotation := Vector3(
		deg_to_rad(rotation_degrees.x),
		deg_to_rad(rotation_degrees.y),
		deg_to_rad(rotation_degrees.z)
	)
	var basis := Basis.from_euler(rotation).scaled(scale)
	return Transform3D(basis, position)

static func decompose_transform(transform: Transform3D) -> Dictionary:
	var scale := transform.basis.get_scale()
	var rotation := transform.basis.orthonormalized().get_euler()
	return {
		"position": transform.origin,
		"rotation_degrees": Vector3(rad_to_deg(rotation.x), rad_to_deg(rotation.y), rad_to_deg(rotation.z)),
		"scale": scale,
	}

static func _find_state_node(scene_state: SceneState, target_path: String) -> int:
	for node_index in range(scene_state.get_node_count()):
		var state_path := String(scene_state.get_node_path(node_index, false))
		if state_path == target_path or state_path == "./%s" % target_path:
			return node_index
	return -1

static func _state_node_property(scene_state: SceneState, node_index: int, property_name: StringName, fallback: Variant) -> Variant:
	for property_index in range(scene_state.get_node_property_count(node_index)):
		if scene_state.get_node_property_name(node_index, property_index) == property_name:
			return scene_state.get_node_property_value(node_index, property_index)
	return fallback

static func validate_source_targets() -> Array[String]:
	var missing: Array[String] = []
	var text := FileAccess.get_file_as_string(ProjectSettings.globalize_path(SOURCE_SCENE_PATH))
	for entry in MONSTER_ENTRIES:
		var node_path := String(entry["node_path"])
		var parts := node_path.split("/")
		var node_name := String(parts[parts.size() - 1])
		var parent_path := "/".join(parts.slice(0, parts.size() - 1))
		if not _text_has_target_node(text, node_name, parent_path):
			missing.append(node_path)
	return missing

static func _entry_for_source(source_id: String) -> Dictionary:
	for entry in MONSTER_ENTRIES:
		if String(entry["source_id"]) == source_id:
			return entry
	return {}

static func _text_has_target_node(text: String, node_name: String, parent_path: String) -> bool:
	for line in text.split("\n", false):
		if _is_target_node_header(line.strip_edges(), node_name, parent_path):
			return true
	return false

static func _is_target_node_header(line: String, node_name: String, parent_path: String) -> bool:
	return (
		line.begins_with("[node ")
		and line.find('name="%s"' % node_name) >= 0
		and line.find('parent="%s"' % parent_path) >= 0
	)

static func _format_float(value: float) -> String:
	if absf(value) < 0.0000005:
		value = 0.0
	var text := "%.7f" % value
	while text.ends_with("0") and text.find(".") >= 0:
		text = text.left(text.length() - 1)
	if text.ends_with("."):
		text = text.left(text.length() - 1)
	if text == "-0":
		text = "0"
	return text
