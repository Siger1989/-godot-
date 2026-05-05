extends SceneTree

const SCENE_PATH := "res://scenes/tests/Test_NaturalPropsShowcase.tscn"
const CONTROLLER_SCRIPT_PATH := "res://scripts/tools/ResourceShowcaseController.gd"
const MonsterSizeSource = preload("res://scripts/monster/MonsterSizeSource.gd")

const REQUIRED_NODES := {
	"NaturalProps/Box_Small_A_Showcase": "Box_Small_A",
	"NaturalProps/Box_Medium_A_Showcase": "Box_Medium_A",
	"NaturalProps/Box_Large_A_Showcase": "Box_Large_A",
	"NaturalProps/Box_Stack_2_A_Showcase": "Box_Stack_2_A",
	"NaturalProps/Box_Stack_3_A_Showcase": "Box_Stack_3_A",
	"NaturalProps/Bucket_A_Showcase": "Bucket_A",
	"NaturalProps/Mop_A_Showcase": "Mop_A",
	"NaturalProps/CleaningClothPile_A_Showcase": "CleaningClothPile_A",
	"NaturalProps/Chair_Old_A_Showcase": "Chair_Old_A",
	"NaturalProps/SmallCabinet_A_Showcase": "SmallCabinet_A",
	"NaturalProps/MetalShelf_A_Showcase": "MetalShelf_A",
	"NaturalProps/ElectricBox_A_Showcase": "ElectricBox_A",
	"NaturalProps/Vent_Wall_A_Showcase": "Vent_Wall_A",
	"NaturalProps/Pipe_Straight_A_Showcase": "Pipe_Straight_A",
	"NaturalProps/Pipe_Corner_A_Showcase": "Pipe_Corner_A",
	"DoorProps/OldOfficeDoor_A_Showcase": "OldOfficeDoor_A",
	"HideableProps/HideLocker_A_Showcase": "HideLocker_A",
	"Characters/Player_Showcase": "PlayerModule",
	"Characters/Monster_Default_Showcase": "MonsterModule",
	"Characters/Monster_Red_KeyBearer_Showcase": "MonsterModule_Red_Hunter",
	"Characters/NightmareCreature_A_Showcase": "NightmareCreature_A",
}

const IMPORTED_MONSTER_META := {
	"Characters/NightmareCreature_A_Showcase": {
		"license": "CC-BY-4.0",
		"triangles": 6718,
		"animations": 22,
	},
}

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load(SCENE_PATH) as PackedScene
	if packed == null:
		_fail("missing scene: %s" % SCENE_PATH)
		return
	var scene := packed.instantiate() as Node3D
	if scene == null:
		_fail("scene root is not Node3D")
		return
	root.add_child(scene)
	current_scene = scene
	await process_frame
	await physics_frame

	var controller_script := scene.get_script() as Script
	if controller_script == null or controller_script.resource_path != CONTROLLER_SCRIPT_PATH:
		_fail("showcase root must use ResourceShowcaseController.gd")
		return
	if not scene.has_method("_focus_all") or not scene.has_method("_scale_selected") or not scene.has_method("_rotate_selected"):
		_fail("showcase controller is missing orbit/scale/rotate methods")
		return
	if scene.get_node_or_null("ResourceShowcaseUI") == null:
		_fail("showcase controller did not create the review UI")
		return
	if _count_buttons(scene.get_node("ResourceShowcaseUI")) < 9:
		_fail("showcase review UI should expose resource navigation and scale/rotate buttons")
		return

	for node_path in REQUIRED_NODES.keys():
		var node := scene.get_node_or_null(node_path) as Node3D
		if node == null:
			_fail("missing showcase node: %s" % node_path)
			return
		if String(node.get_meta("resource_model_id", node.get_meta("natural_prop_id", ""))) != String(REQUIRED_NODES[node_path]):
			_fail("resource metadata mismatch at %s" % node_path)
			return
		if not _has_mesh(node):
			_fail("showcase node has no visible mesh: %s" % node_path)
			return

	if scene.get_node_or_null("NaturalProps").get_child_count() != 15:
		_fail("NaturalProps must keep the first 15 authored prop assets")
		return
	if scene.get_node_or_null("DoorProps").get_child_count() != 1:
		_fail("DoorProps should contain the current authored door asset")
		return
	if scene.get_node_or_null("HideableProps").get_child_count() != 1:
		_fail("HideableProps should contain the current hideable locker asset")
		return
	if scene.get_node_or_null("Characters").get_child_count() != 4:
		_fail("Characters should show player, normal monster, red hunter monster, and the active Nightmare monster")
		return

	var source_template_by_showcase_path := {
		"Characters/Monster_Default_Showcase": "normal",
		"Characters/Monster_Red_KeyBearer_Showcase": "red_hunter",
		"Characters/NightmareCreature_A_Showcase": "nightmare",
	}
	for monster_path in source_template_by_showcase_path.keys():
		var monster := scene.get_node_or_null(monster_path) as Node3D
		var scale := monster.transform.basis.get_scale()
		var expected_scale := MonsterSizeSource.template_scale(String(source_template_by_showcase_path[monster_path]))
		if not _is_near_vec3(scale, expected_scale, 0.001):
			_fail("%s scale=%s does not match MonsterSizeSource %s" % [monster_path, scale, expected_scale])
			return

	var red_monster := scene.get_node_or_null("Characters/Monster_Red_KeyBearer_Showcase") as Node3D
	if red_monster == null or String(red_monster.get("monster_role")) != "red":
		_fail("red monster showcase is missing or is not role=red")
		return
	if bool(red_monster.get("attach_escape_key")) or red_monster.get_node_or_null("ChestEscapeKey") != null or bool(red_monster.get_meta("has_escape_key", false)):
		_fail("red monster showcase must not carry the escape key")
		return

	for monster_path in IMPORTED_MONSTER_META.keys():
		var monster := scene.get_node_or_null(monster_path) as Node3D
		var expected: Dictionary = IMPORTED_MONSTER_META[monster_path]
		if monster == null:
			_fail("imported monster showcase node is missing: %s" % monster_path)
			return
		if String(monster.get_meta("source_license", "")) != String(expected["license"]):
			_fail("imported monster license metadata mismatch: %s" % monster_path)
			return
		if int(monster.get_meta("approx_triangles", 0)) != int(expected["triangles"]):
			_fail("imported monster triangle metadata mismatch: %s" % monster_path)
			return
		if int(monster.get_meta("animation_count", 0)) != int(expected["animations"]):
			_fail("imported monster animation metadata mismatch: %s" % monster_path)
			return

	print("RESOURCE_SHOWCASE_VALIDATION PASS resources=%d source_normal_scale=%s" % [REQUIRED_NODES.size(), MonsterSizeSource.template_scale("normal")])
	quit(0)

func _has_mesh(node: Node) -> bool:
	var mesh_instance := node as MeshInstance3D
	if mesh_instance != null and mesh_instance.mesh != null:
		return true
	for child in node.get_children():
		if _has_mesh(child):
			return true
	return false

func _count_buttons(node: Node) -> int:
	var count := 1 if node is Button else 0
	for child in node.get_children():
		count += _count_buttons(child)
	return count

func _is_near_vec3(a: Vector3, b: Vector3, tolerance: float) -> bool:
	return (
		absf(a.x - b.x) <= tolerance
		and absf(a.y - b.y) <= tolerance
		and absf(a.z - b.z) <= tolerance
	)

func _fail(message: String) -> void:
	push_error("RESOURCE_SHOWCASE_VALIDATION FAIL %s" % message)
	quit(1)
