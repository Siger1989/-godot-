extends SceneTree

const NIGHTMARE_WRAPPER_PATH := "res://assets/backrooms/monsters/NightmareCreature_A.tscn"
const NIGHTMARE_MONSTER_PATH := "res://assets/backrooms/monsters/NightmareCreature_Monster.tscn"
const MONSTER_MODULE_PATH := "res://scenes/modules/MonsterModule.tscn"

const EXPECTED_MAPPING := {
	"gameplay_idle_animation": "Creature_armature|idle",
	"gameplay_walk_animation": "Creature_armature|walk",
	"gameplay_run_animation": "Creature_armature|Run",
	"gameplay_attack_animation": "Creature_armature|attack_1",
	"gameplay_death_animation": "Creature_armature|death_1",
	"gameplay_hit_animation": "Creature_armature|hit_1",
	"gameplay_roar_animation": "Creature_armature|roar",
}

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var wrapper_scene := load(NIGHTMARE_WRAPPER_PATH) as PackedScene
	if wrapper_scene == null:
		_fail("Missing NightmareCreature wrapper scene.")
		return
	var wrapper := wrapper_scene.instantiate() as Node3D
	if wrapper == null:
		_fail("NightmareCreature wrapper is not Node3D.")
		return
	root.add_child(wrapper)
	await process_frame

	if String(wrapper.get_meta("gameplay_status", "")) != "visual_wrapper_for_nightmare_ai":
		_fail("NightmareCreature wrapper gameplay_status mismatch.")
		return

	var animation_player := _find_animation_player(wrapper)
	if animation_player == null:
		_fail("NightmareCreature wrapper has no AnimationPlayer.")
		return

	for key in EXPECTED_MAPPING.keys():
		var expected_name := String(EXPECTED_MAPPING[key])
		var mapped_name := String(wrapper.get_meta(String(key), ""))
		if mapped_name != expected_name:
			_fail("%s metadata mismatch: %s expected %s." % [key, mapped_name, expected_name])
			return
		if not animation_player.has_animation(mapped_name):
			_fail("%s animation missing from imported GLB: %s." % [key, mapped_name])
			return

	var module_scene := load(MONSTER_MODULE_PATH) as PackedScene
	if module_scene == null:
		_fail("Missing MonsterModule scene.")
		return
	var monster := module_scene.instantiate()
	if monster == null:
		_fail("MonsterModule did not instantiate.")
		return
	root.add_child(monster)
	await process_frame

	if monster.get("attack_animation") == null:
		_fail("MonsterController does not expose attack_animation.")
		return
	if monster.get("death_animation") == null:
		_fail("MonsterController does not expose death_animation.")
		return

	var nightmare_scene := load(NIGHTMARE_MONSTER_PATH) as PackedScene
	if nightmare_scene == null:
		_fail("Missing NightmareCreature active monster scene.")
		return
	var nightmare := nightmare_scene.instantiate()
	if nightmare == null:
		_fail("NightmareCreature active monster did not instantiate.")
		return
	root.add_child(nightmare)
	await process_frame

	if String(nightmare.get("monster_role")) != "nightmare":
		_fail("NightmareCreature active monster role mismatch.")
		return
	for key in EXPECTED_MAPPING.keys():
		var property_name := String(key).replace("gameplay_", "")
		if property_name == "hit_animation" or property_name == "roar_animation":
			continue
		var active_mapping := String(nightmare.get(property_name))
		if active_mapping != String(EXPECTED_MAPPING[key]):
			_fail("NightmareCreature active %s mismatch: %s." % [property_name, active_mapping])
			return
	if bool(nightmare.call("debug_can_see_player")):
		_fail("NightmareCreature active monster must not use player vision.")
		return

	print("NIGHTMARE_CREATURE_ANIMATION_MAPPING_VALIDATION PASS animations=%d attack=%s death=%s" % [
		animation_player.get_animation_list().size(),
		String(EXPECTED_MAPPING["gameplay_attack_animation"]),
		String(EXPECTED_MAPPING["gameplay_death_animation"]),
	])
	quit(0)

func _find_animation_player(node: Node) -> AnimationPlayer:
	var player := node as AnimationPlayer
	if player != null:
		return player
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null

func _fail(message: String) -> void:
	push_error("NIGHTMARE_CREATURE_ANIMATION_MAPPING_VALIDATION FAIL %s" % message)
	quit(1)
