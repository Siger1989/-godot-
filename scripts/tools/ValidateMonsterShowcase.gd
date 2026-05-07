extends SceneTree

const SHOWCASE_SCENE := "res://scenes/tests/Test_MonsterShowcase.tscn"
const TransformStore = preload("res://scripts/tools/MonsterSourceTransformStore.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var missing := TransformStore.validate_source_targets()
	if not missing.is_empty():
		_fail("missing source targets: %s" % ", ".join(missing))
		return
	var packed := load(SHOWCASE_SCENE) as PackedScene
	if packed == null:
		_fail("missing showcase scene")
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	if not scene.has_method("debug_get_entry_count"):
		_fail("showcase root missing debug API")
		return
	if int(scene.call("debug_get_entry_count")) != 3:
		_fail("expected three global monster entries")
		return
	if not bool(scene.call("debug_has_preview_monster")):
		_fail("preview monster was not instantiated")
		return
	if not bool(scene.call("debug_is_preview_centered")):
		_fail("preview monster is not centered on the showcase floor")
		return
	if not bool(scene.call("debug_has_reference_door")):
		_fail("reference door was not instantiated")
		return
	if not bool(scene.call("debug_has_collision_controls")):
		_fail("collision controls or collision preview were not created")
		return
	if not bool(scene.call("debug_has_visual_yaw_control")):
		_fail("visual yaw calibration controls were not created")
		return
	var collision_size: Vector3 = scene.call("debug_get_collision_size")
	if collision_size.x <= 0.0 or collision_size.y <= 0.0 or collision_size.z <= 0.0:
		_fail("preview collision size is invalid: %s" % collision_size)
		return
	var controller_yaw_before := float(scene.call("debug_get_controller_forward_yaw"))
	var model_yaw_before := float(scene.call("debug_get_model_forward_yaw"))
	scene.call("debug_set_visual_yaw_degrees", 37.0)
	await process_frame
	var controller_yaw_after := float(scene.call("debug_get_controller_forward_yaw"))
	var model_yaw_after := float(scene.call("debug_get_model_forward_yaw"))
	var controller_delta := absf(_angle_delta_degrees(controller_yaw_after - controller_yaw_before))
	var model_delta := absf(_angle_delta_degrees(model_yaw_after - model_yaw_before))
	if controller_delta > 0.5:
		_fail("visual yaw changed controller/root forward yaw by %.2f degrees." % controller_delta)
		return
	if model_delta < 25.0:
		_fail("visual yaw did not move model-facing marker enough: %.2f degrees." % model_delta)
		return
	scene.call("debug_set_visual_yaw_degrees", 0.0)
	if int(scene.call("debug_get_selected_animation_count")) <= 0:
		_fail("selected monster animation list was not populated")
		return
	scene.call("debug_select_index", 2)
	await process_frame
	var nightmare_animation_names: Array[String] = scene.call("debug_get_animation_names")
	var expected_nightmare := [
		"Creature_armature|idle",
		"Creature_armature|walk",
		"Creature_armature|Run",
		"Creature_armature|attack_1",
		"Creature_armature|death_1",
	]
	if nightmare_animation_names != expected_nightmare:
		_fail("Nightmare showcase animation list should be gameplay-only: %s." % [nightmare_animation_names])
		return
	var nightmare_collision_root_bottom := float(scene.call("debug_get_collision_root_bottom_y"))
	if absf(nightmare_collision_root_bottom) > 0.04:
		_fail("Nightmare collision bottom is not synced with runtime root floor: %.3f." % nightmare_collision_root_bottom)
		return
	var nightmare_game_floor_bottom := float(scene.call("debug_get_game_floor_visible_bottom_y"))
	if nightmare_game_floor_bottom < -0.06 or nightmare_game_floor_bottom > 0.14:
		_fail("Nightmare game-floor visible bottom is not grounded: %.3f." % nightmare_game_floor_bottom)
		return
	var sample := TransformStore.load_transform("normal")
	var replaced := TransformStore.replace_transform_text(
		FileAccess.get_file_as_string(ProjectSettings.globalize_path(TransformStore.SOURCE_SCENE_PATH)),
		"MonsterRoot/Monster",
		sample
	)
	if replaced.find("MonsterRoot") < 0 or replaced.find("Transform3D(") < 0:
		_fail("transform replacement dry-run did not produce valid scene text")
		return
	var collision_replaced := TransformStore.replace_node_property_text(
		FileAccess.get_file_as_string(ProjectSettings.globalize_path(TransformStore.SOURCE_SCENE_PATH)),
		"MonsterRoot/Monster",
		"metadata/monster_collision_box_size",
		"Vector3(0.72, 0.62, 2.22)"
	)
	if collision_replaced.find("metadata/monster_collision_box_size = Vector3(") < 0:
		_fail("collision metadata replacement dry-run did not produce valid scene text")
		return
	var visual_replaced := TransformStore.replace_node_property_text(
		FileAccess.get_file_as_string(ProjectSettings.globalize_path(TransformStore.SOURCE_SCENE_PATH)),
		"MonsterRoot/Monster",
		TransformStore.VISUAL_YAW_PROPERTY,
		"37"
	)
	if visual_replaced.find("metadata/monster_visual_yaw_degrees = 37") < 0:
		_fail("visual yaw metadata replacement dry-run did not produce valid scene text")
		return
	print("MONSTER_SHOWCASE_VALIDATION PASS entries=%d animations=%d collision=%s visual_model_delta=%.2f nightmare_actions=%d" % [
		int(scene.call("debug_get_entry_count")),
		int(scene.call("debug_get_selected_animation_count")),
		collision_size,
		model_delta,
		nightmare_animation_names.size(),
	])
	quit(0)

func _fail(message: String) -> void:
	push_error("MONSTER_SHOWCASE_VALIDATION FAIL %s" % message)
	quit(1)

func _angle_delta_degrees(value: float) -> float:
	var wrapped := fmod(value + 180.0, 360.0)
	if wrapped < 0.0:
		wrapped += 360.0
	return wrapped - 180.0
