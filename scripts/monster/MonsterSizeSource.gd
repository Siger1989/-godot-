extends RefCounted

const SOURCE_SCENE_PATH := "res://scenes/mvp/FourRoomMVP.tscn"
const COLLISION_SIZE_META := &"monster_collision_box_size"
const COLLISION_POSITION_META := &"monster_collision_box_position"
const VISUAL_YAW_META := &"monster_visual_yaw_degrees"
const VISUAL_YAW_BASE_META := &"monster_visual_yaw_base_transform"
const ANIMATION_GROUND_OFFSET_META := &"monster_animation_ground_offset"

const NIGHTMARE_GAMEPLAY_ANIMATIONS := [
	"Creature_armature|idle",
	"Creature_armature|walk",
	"Creature_armature|Run",
	"Creature_armature|attack_1",
	"Creature_armature|death_1",
]

const NIGHTMARE_OPTIONAL_ANIMATIONS := [
	"Creature_armature|hit_1",
	"Creature_armature|roar",
]

const NIGHTMARE_ANIMATION_GROUND_OFFSETS := {
	"Creature_armature|Run": 0.138,
	"Creature_armature|attack_1": 0.138,
	"Creature_armature|attack_2": 0.208,
	"Creature_armature|attack_3": 0.208,
	"Creature_armature|battle_idle": 0.208,
	"Creature_armature|bite": 0.088,
	"Creature_armature|crawl": 0.208,
	"Creature_armature|crawl_bite": 0.208,
	"Creature_armature|crawl_idol": 0.208,
	"Creature_armature|crawl_to_state": 0.208,
	"Creature_armature|crawl_to_state_001": 0.208,
	"Creature_armature|death_1": 0.208,
	"Creature_armature|death_2": 0.208,
	"Creature_armature|defence": 0.208,
	"Creature_armature|eating": 0.208,
	"Creature_armature|hit_1": 0.041,
	"Creature_armature|hit_2": 0.121,
	"Creature_armature|idle": 0.208,
	"Creature_armature|jump": 0.208,
	"Creature_armature|roar": 0.208,
	"Creature_armature|state_to_crawl": 0.088,
	"Creature_armature|walk": 0.208,
}

const TEMPLATE_PATHS := {
	"normal": "MonsterRoot/Monster",
	"normal_b": "MonsterRoot/Monster",
	"red_key_bearer": "MonsterRoot/Monster",
	"red_hunter": "MonsterRoot/Monster",
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
	_apply_source_visual_yaw_override(monster, template_id)
	_apply_source_collision_override(monster, template_id)
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

static func template_collision_config(template_id: String) -> Dictionary:
	var scene_state := _source_scene_state()
	if scene_state == null:
		return {}
	var template_path := String(TEMPLATE_PATHS.get(template_id, ""))
	if template_path.is_empty():
		return {}
	var node_index := _find_state_node(scene_state, template_path)
	if node_index < 0:
		return {}
	var size_value = _state_node_property(scene_state, node_index, &"metadata/monster_collision_box_size", null)
	if typeof(size_value) != TYPE_VECTOR3:
		return {}
	var position_value = _state_node_property(scene_state, node_index, &"metadata/monster_collision_box_position", Vector3.ZERO)
	var position := Vector3.ZERO
	if typeof(position_value) == TYPE_VECTOR3:
		position = position_value
	return {
		"size": size_value,
		"position": position,
	}

static func template_visual_yaw_degrees(template_id: String) -> float:
	var scene_state := _source_scene_state()
	if scene_state == null:
		return 0.0
	var template_path := String(TEMPLATE_PATHS.get(template_id, ""))
	if template_path.is_empty():
		return 0.0
	var node_index := _find_state_node(scene_state, template_path)
	if node_index < 0:
		return 0.0
	var value = _state_node_property(scene_state, node_index, &"metadata/monster_visual_yaw_degrees", 0.0)
	if typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_INT:
		return float(value)
	return 0.0

static func apply_metadata_collision_override(monster: Node3D) -> bool:
	if monster == null or not monster.has_meta(COLLISION_SIZE_META):
		return false
	var size_value = monster.get_meta(COLLISION_SIZE_META)
	if typeof(size_value) != TYPE_VECTOR3:
		return false
	var position_value = monster.get_meta(COLLISION_POSITION_META, Vector3.ZERO)
	var position := Vector3.ZERO
	if typeof(position_value) == TYPE_VECTOR3:
		position = position_value
	return apply_collision_config(monster, size_value, position)

static func apply_metadata_visual_yaw_offset(monster: Node3D) -> bool:
	if monster == null or not monster.has_meta(VISUAL_YAW_META):
		return false
	var value = monster.get_meta(VISUAL_YAW_META)
	if typeof(value) != TYPE_FLOAT and typeof(value) != TYPE_INT:
		return false
	return apply_visual_yaw_offset(monster, float(value))

static func apply_visual_yaw_offset(monster: Node3D, yaw_degrees: float) -> bool:
	if monster == null:
		return false
	var model_root := monster.get_node_or_null("ModelRoot") as Node3D
	if model_root == null:
		return false
	var base_transform := model_root.transform
	if model_root.has_meta(VISUAL_YAW_BASE_META):
		var stored_base = model_root.get_meta(VISUAL_YAW_BASE_META)
		if typeof(stored_base) == TYPE_TRANSFORM3D:
			base_transform = stored_base
	else:
		model_root.set_meta(VISUAL_YAW_BASE_META, base_transform)
	var ground_offset := 0.0
	if monster.has_meta(ANIMATION_GROUND_OFFSET_META):
		var ground_value = monster.get_meta(ANIMATION_GROUND_OFFSET_META)
		if typeof(ground_value) == TYPE_FLOAT or typeof(ground_value) == TYPE_INT:
			ground_offset = float(ground_value)
	var yaw_basis := Basis.from_euler(Vector3(0.0, deg_to_rad(yaw_degrees), 0.0))
	model_root.transform = Transform3D(yaw_basis * base_transform.basis, base_transform.origin + Vector3(0.0, ground_offset, 0.0))
	monster.set_meta(VISUAL_YAW_META, yaw_degrees)
	return true

static func gameplay_animation_names(template_id: String, include_optional := false) -> Array[String]:
	if _canonical_template_id(template_id) != "nightmare":
		return []
	var names: Array[String] = []
	for animation_name in NIGHTMARE_GAMEPLAY_ANIMATIONS:
		names.append(String(animation_name))
	if include_optional:
		for animation_name in NIGHTMARE_OPTIONAL_ANIMATIONS:
			names.append(String(animation_name))
	return names

static func animation_ground_offset(template_id: String, animation_name: String) -> float:
	if _canonical_template_id(template_id) != "nightmare":
		return 0.0
	return float(NIGHTMARE_ANIMATION_GROUND_OFFSETS.get(animation_name, 0.0))

static func apply_animation_ground_offset(monster: Node3D, template_id: String, animation_name: String) -> bool:
	if monster == null:
		return false
	var offset := animation_ground_offset(template_id, animation_name)
	monster.set_meta(ANIMATION_GROUND_OFFSET_META, offset)
	var visual_yaw := 0.0
	if monster.has_meta(VISUAL_YAW_META):
		var yaw_value = monster.get_meta(VISUAL_YAW_META)
		if typeof(yaw_value) == TYPE_FLOAT or typeof(yaw_value) == TYPE_INT:
			visual_yaw = float(yaw_value)
	return apply_visual_yaw_offset(monster, visual_yaw)

static func apply_collision_config(monster: Node3D, size: Vector3, position: Vector3) -> bool:
	if monster == null:
		return false
	var collision := _find_collision_shape(monster)
	if collision == null:
		return false
	var box := collision.shape as BoxShape3D
	if box == null:
		return false
	if size.x <= 0.0 or size.y <= 0.0 or size.z <= 0.0:
		return false
	box = box.duplicate(true) as BoxShape3D
	box.size = size
	collision.shape = box
	collision.position = position
	return true

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

static func _apply_source_collision_override(monster: Node3D, template_id: String) -> void:
	var config := template_collision_config(template_id)
	if config.is_empty():
		return
	var size: Vector3 = config["size"]
	var position: Vector3 = config["position"]
	monster.set_meta(COLLISION_SIZE_META, size)
	monster.set_meta(COLLISION_POSITION_META, position)
	apply_collision_config(monster, size, position)

static func _apply_source_visual_yaw_override(monster: Node3D, template_id: String) -> void:
	var yaw_degrees := template_visual_yaw_degrees(template_id)
	monster.set_meta(VISUAL_YAW_META, yaw_degrees)
	apply_visual_yaw_offset(monster, yaw_degrees)

static func _find_collision_shape(node: Node) -> CollisionShape3D:
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

static func _combined_mesh_bounds(node: Node) -> AABB:
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

static func _collect_meshes(node: Node, output: Array[MeshInstance3D]) -> void:
	var mesh := node as MeshInstance3D
	if mesh != null and mesh.mesh != null and mesh.visible:
		output.append(mesh)
	for child in node.get_children():
		_collect_meshes(child, output)

static func _aabb_to_global(node: Node3D, local_aabb: AABB) -> AABB:
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
