extends SceneTree

const PLAYER_SCENE_PATH := "res://scenes/modules/PlayerModule.tscn"
const MODEL_SCENE_PATH := "res://3D模型/zhujiao.glb"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await _inspect_model_rest_pose()
	await _inspect_player_idle_pose()
	quit(0)

func _inspect_model_rest_pose() -> void:
	var model_scene := load(MODEL_SCENE_PATH) as PackedScene
	if model_scene == null:
		_fail("Failed to load %s" % MODEL_SCENE_PATH)
		return
	var model := model_scene.instantiate()
	root.add_child(model)
	await process_frame

	var skeleton := _find_skeleton(model)
	if skeleton == null:
		model.queue_free()
		await process_frame
		_fail("Skeleton not found in model scene.")
		return
	_print_pose("MODEL_REST", skeleton)
	model.queue_free()
	await process_frame

func _inspect_player_idle_pose() -> void:
	var player_scene := load(PLAYER_SCENE_PATH) as PackedScene
	if player_scene == null:
		_fail("Failed to load %s" % PLAYER_SCENE_PATH)
		return
	var player := player_scene.instantiate()
	root.add_child(player)
	await process_frame
	await physics_frame
	await physics_frame

	var animation_player := player.get_node_or_null("ModelRoot/zhujiao/AnimationPlayer") as AnimationPlayer
	var skeleton := _find_skeleton(player)
	if animation_player == null or skeleton == null:
		player.queue_free()
		await process_frame
		_fail("AnimationPlayer or Skeleton not found in player scene.")
		return
	print("PLAYER_CURRENT_ANIMATION name=%s playing=%s" % [
		animation_player.current_animation,
		animation_player.is_playing(),
	])
	if animation_player.has_animation("idle_generated"):
		animation_player.play("idle_generated")
		animation_player.seek(0.0, true)
		await process_frame
		_print_pose("PLAYER_IDLE_0", skeleton)
		animation_player.seek(3.0, true)
		await process_frame
		_print_pose("PLAYER_IDLE_3", skeleton)
	player.queue_free()
	await process_frame

func _print_pose(label: String, skeleton: Skeleton3D) -> void:
	var left_foot := _find_bone_containing(skeleton, "LeftFoot")
	var right_foot := _find_bone_containing(skeleton, "RightFoot")
	var left_toe := _find_bone_containing(skeleton, "LeftToeBase")
	var right_toe := _find_bone_containing(skeleton, "RightToeBase")
	var left_hand := _find_bone_containing(skeleton, "LeftHand_")
	var right_hand := _find_bone_containing(skeleton, "RightHand_")
	var head := _find_bone_containing(skeleton, "Head")
	var names := PackedStringArray()
	for bone_index in range(skeleton.get_bone_count()):
		names.append(skeleton.get_bone_name(bone_index))
	print("POSE_%s bones=%d head=%s" % [
		label,
		skeleton.get_bone_count(),
		skeleton.get_bone_name(head) if head >= 0 else "missing",
	])
	if left_foot >= 0 and right_foot >= 0 and left_toe >= 0 and right_toe >= 0:
		var left_foot_y := skeleton.get_bone_global_pose(left_foot).origin.y
		var right_foot_y := skeleton.get_bone_global_pose(right_foot).origin.y
		var left_toe_y := skeleton.get_bone_global_pose(left_toe).origin.y
		var right_toe_y := skeleton.get_bone_global_pose(right_toe).origin.y
		print("POSE_%s feet lf=%.2f rf=%.2f lt=%.2f rt=%.2f foot_delta=%.2f toe_delta=%.2f" % [
			label,
			left_foot_y,
			right_foot_y,
			left_toe_y,
			right_toe_y,
			absf(left_foot_y - right_foot_y),
			absf(left_toe_y - right_toe_y),
		])
	if left_hand >= 0 and right_hand >= 0:
		var left_hand_origin := skeleton.get_bone_global_pose(left_hand).origin
		var right_hand_origin := skeleton.get_bone_global_pose(right_hand).origin
		print("POSE_%s hands lh=%s rh=%s" % [label, left_hand_origin, right_hand_origin])
	print("POSE_%s bone_names=%s" % [label, ",".join(names)])

func _find_skeleton(node: Node) -> Skeleton3D:
	var skeleton := node as Skeleton3D
	if skeleton != null:
		return skeleton
	for child in node.get_children():
		var result := _find_skeleton(child)
		if result != null:
			return result
	return null

func _find_bone_containing(skeleton: Skeleton3D, text: String) -> int:
	for bone_index in range(skeleton.get_bone_count()):
		if skeleton.get_bone_name(bone_index).contains(text):
			return bone_index
	return -1

func _fail(message: String) -> void:
	push_error("PLAYER_POSE_INSPECT FAIL: %s" % message)
	quit(1)
