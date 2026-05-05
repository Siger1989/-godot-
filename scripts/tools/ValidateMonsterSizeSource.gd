extends SceneTree

const SOURCE_SCENE_PATH := "res://scenes/mvp/FourRoomMVP.tscn"
const EXPECTED_CHILDREN := [
	"Monster",
	"Monster_Red_KeyBearer_MVP",
	"NightmareCreature_A_MVP",
]
const FORBIDDEN_CHILDREN := [
	"Monster_Normal_B",
	"NightmareCreature_B_MVP",
	"CreatureZombie_A_MVP",
]
const CONTROLLED_TEMPLATES := {
	"Monster": "normal",
	"Monster_Red_KeyBearer_MVP": "red_hunter",
	"NightmareCreature_A_MVP": "nightmare",
}
const TEMPLATE_ALIASES := {
	"normal_b": "normal",
	"red_key_bearer": "red_hunter",
	"nightmare_b": "nightmare",
}
const ROOM_MIN := Vector2(-2.45, -2.45)
const ROOM_MAX := Vector2(8.45, 8.45)
const DOOR_CENTERS := [
	Vector2(3.0, 0.0),
	Vector2(6.0, 3.0),
	Vector2(3.0, 6.0),
	Vector2(0.0, 3.0),
]
const MonsterSizeSource = preload("res://scripts/monster/MonsterSizeSource.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var source := _instantiate_scene(SOURCE_SCENE_PATH)
	if source == null:
		return

	var monster_root := source.get_node_or_null("MonsterRoot") as Node3D
	if monster_root == null:
		_fail("FourRoomMVP missing MonsterRoot.")
		return
	if not monster_root.scene_file_path.is_empty():
		_fail("FourRoomMVP MonsterRoot must be a direct editable node, got scene_file_path=%s." % monster_root.scene_file_path)
		return
	if not bool(monster_root.get_meta("mvp_editable_monster_root", false)):
		_fail("MonsterRoot is missing mvp_editable_monster_root metadata.")
		return
	if not bool(monster_root.get_meta("monster_size_source", false)):
		_fail("MonsterRoot is missing monster_size_source metadata.")
		return

	for child_name in FORBIDDEN_CHILDREN:
		if monster_root.get_node_or_null(child_name) != null:
			_fail("FourRoomMVP should keep one source per monster type, but found duplicate/removed node: %s." % child_name)
			return

	root.add_child(source)
	await process_frame
	await physics_frame
	await process_frame

	for child_name in EXPECTED_CHILDREN:
		var monster := monster_root.get_node_or_null(child_name) as Node3D
		if monster == null:
			_fail("MonsterRoot missing editable child: %s." % child_name)
			return
		if String(monster.get_meta("monster_size_source_id", "")) != String(CONTROLLED_TEMPLATES[child_name]):
			_fail("%s monster_size_source_id mismatch." % child_name)
			return
		if not _has_mesh(monster):
			_fail("%s has no visible mesh." % child_name)
			return
		if not _has_positive_scale(monster):
			_fail("%s has invalid scale: %s." % [child_name, monster.transform.basis.get_scale()])
			return
		if not _is_inside_mvp_rooms(monster.global_position):
			_fail("%s is outside the FourRoomMVP bounds: %s." % [child_name, monster.global_position])
			return
		if _is_on_door_center(monster.global_position):
			_fail("%s is too close to a doorway center: %s." % [child_name, monster.global_position])
			return

	var monsters := _monster_children(monster_root)
	if monsters.size() != EXPECTED_CHILDREN.size():
		_fail("Expected one editable monster per type, found %d controller-backed children." % monsters.size())
		return

	var red_monster := monster_root.get_node_or_null("Monster_Red_KeyBearer_MVP") as Node3D
	if red_monster == null or String(red_monster.get("monster_role")) != "red":
		_fail("Red hunter source monster is not configured as role=red.")
		return
	if bool(red_monster.get("attach_escape_key")) or red_monster.get_node_or_null("ChestEscapeKey") != null or bool(red_monster.get_meta("has_escape_key", false)):
		_fail("Red hunter source monster must not carry the escape key.")
		return

	var nightmare_monster := monster_root.get_node_or_null("NightmareCreature_A_MVP") as CharacterBody3D
	if nightmare_monster == null or String(nightmare_monster.get("monster_role")) != "nightmare":
		_fail("NightmareCreature source monster is not configured as an active hearing AI.")
		return
	if not nightmare_monster.is_in_group("nightmare_monster"):
		_fail("NightmareCreature source monster is missing nightmare_monster group.")
		return
	if nightmare_monster.get_node_or_null("NightmareSonarAudio") == null:
		_fail("NightmareCreature source monster is missing NightmareSonarAudio.")
		return

	for alias_id in TEMPLATE_ALIASES.keys():
		var source_id := String(TEMPLATE_ALIASES[alias_id])
		var alias_scale := MonsterSizeSource.template_scale(String(alias_id))
		var source_scale := MonsterSizeSource.template_scale(source_id)
		if not _is_near_vec3(alias_scale, source_scale, 0.001):
			_fail("Template alias %s scale=%s does not match %s scale=%s." % [alias_id, alias_scale, source_id, source_scale])
			return

	print("MONSTER_SIZE_SOURCE_VALIDATION PASS source=%s editable_children=%d aliases=%d" % [
		SOURCE_SCENE_PATH,
		EXPECTED_CHILDREN.size(),
		TEMPLATE_ALIASES.size(),
	])
	quit(0)

func _instantiate_scene(scene_path: String) -> Node3D:
	var packed := load(scene_path) as PackedScene
	if packed == null:
		_fail("Missing scene: %s." % scene_path)
		return null
	var scene := packed.instantiate() as Node3D
	if scene == null:
		_fail("Scene root is not Node3D: %s." % scene_path)
	return scene

func _monster_children(monster_root: Node) -> Array[CharacterBody3D]:
	var result: Array[CharacterBody3D] = []
	for child in monster_root.get_children():
		var monster := child as CharacterBody3D
		if monster != null:
			result.append(monster)
	return result

func _has_mesh(node: Node) -> bool:
	var mesh := node as MeshInstance3D
	if mesh != null and mesh.mesh != null:
		return true
	for child in node.get_children():
		if _has_mesh(child):
			return true
	return false

func _has_positive_scale(node: Node3D) -> bool:
	var scale := node.transform.basis.get_scale()
	return scale.x > 0.0 and scale.y > 0.0 and scale.z > 0.0

func _is_inside_mvp_rooms(position: Vector3) -> bool:
	var flat := Vector2(position.x, position.z)
	return flat.x >= ROOM_MIN.x and flat.x <= ROOM_MAX.x and flat.y >= ROOM_MIN.y and flat.y <= ROOM_MAX.y

func _is_on_door_center(position: Vector3) -> bool:
	var flat := Vector2(position.x, position.z)
	for door_center in DOOR_CENTERS:
		if flat.distance_to(door_center) < 0.82:
			return true
	return false

func _is_near_vec3(a: Vector3, b: Vector3, tolerance: float) -> bool:
	return (
		absf(a.x - b.x) <= tolerance
		and absf(a.y - b.y) <= tolerance
		and absf(a.z - b.z) <= tolerance
	)

func _fail(message: String) -> void:
	push_error("MONSTER_SIZE_SOURCE_VALIDATION FAIL %s" % message)
	quit(1)
