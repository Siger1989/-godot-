extends RefCounted

const SOURCE_SCENE_PATH := "res://scenes/mvp/FourRoomMVP.tscn"

const TEMPLATE_PATHS := {
	"normal": "MonsterRoot/Monster",
	"normal_b": "MonsterRoot/Monster",
	"red_key_bearer": "MonsterRoot/Monster_Red_KeyBearer_MVP",
	"red_hunter": "MonsterRoot/Monster_Red_KeyBearer_MVP",
	"nightmare": "MonsterRoot/NightmareCreature_A_MVP",
	"nightmare_b": "MonsterRoot/NightmareCreature_A_MVP",
}

const TEMPLATE_SCENES := {
	"normal": "res://scenes/modules/MonsterModule.tscn",
	"normal_b": "res://scenes/modules/MonsterModule.tscn",
	"red_key_bearer": "res://scenes/modules/MonsterModule.tscn",
	"red_hunter": "res://scenes/modules/MonsterModule.tscn",
	"nightmare": "res://assets/backrooms/monsters/NightmareCreature_Monster.tscn",
	"nightmare_b": "res://assets/backrooms/monsters/NightmareCreature_Monster.tscn",
}

static func instantiate_template(template_id: String) -> Node3D:
	var template_scene_path := String(TEMPLATE_SCENES.get(template_id, ""))
	if template_scene_path.is_empty():
		return null
	var packed := load(template_scene_path) as PackedScene
	if packed == null:
		return null
	var monster := packed.instantiate() as Node3D
	if monster == null:
		return null
	monster.transform = template_transform(template_id)
	monster.set_meta("default_size_source", template_source_reference(template_id))
	monster.set_meta("monster_size_source_id", _canonical_template_id(template_id))
	_apply_role_defaults(monster, template_id)
	return monster

static func template_scale(template_id: String) -> Vector3:
	return template_transform(template_id).basis.get_scale()

static func template_transform(template_id: String) -> Transform3D:
	var scene_state := _source_scene_state()
	if scene_state == null:
		return Transform3D.IDENTITY
	var template_path := String(TEMPLATE_PATHS.get(template_id, ""))
	if template_path.is_empty():
		return Transform3D.IDENTITY
	var node_index := _find_state_node(scene_state, template_path)
	if node_index < 0:
		return Transform3D.IDENTITY
	var transform_value = _state_node_property(scene_state, node_index, &"transform", Transform3D.IDENTITY)
	if typeof(transform_value) == TYPE_TRANSFORM3D:
		return transform_value
	return Transform3D.IDENTITY

static func template_source_reference(template_id: String) -> String:
	var template_path := String(TEMPLATE_PATHS.get(template_id, ""))
	if template_path.is_empty():
		return SOURCE_SCENE_PATH
	return "%s/%s" % [SOURCE_SCENE_PATH, template_path]

static func _source_scene_state() -> SceneState:
	var packed := load(SOURCE_SCENE_PATH) as PackedScene
	if packed == null:
		return null
	return packed.get_state()

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

static func _canonical_template_id(template_id: String) -> String:
	if template_id == "normal_b":
		return "normal"
	if template_id == "red_key_bearer":
		return "red_hunter"
	if template_id == "nightmare_b":
		return "nightmare"
	return template_id

static func _apply_role_defaults(monster: Node3D, template_id: String) -> void:
	var canonical_id := _canonical_template_id(template_id)
	if canonical_id == "red_hunter":
		monster.set("monster_role", "red")
		monster.set("attach_escape_key", false)
		monster.set_meta("monster_role", "red")
		monster.add_to_group("red_monster", true)
		if monster.has_meta("has_escape_key"):
			monster.remove_meta("has_escape_key")
	elif canonical_id == "nightmare":
		monster.set("monster_role", "nightmare")
		monster.set_meta("monster_role", "nightmare")
		monster.add_to_group("nightmare_monster", true)
	else:
		monster.set_meta("monster_role", "normal")
