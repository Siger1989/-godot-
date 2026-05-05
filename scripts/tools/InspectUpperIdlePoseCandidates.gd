extends SceneTree

const SCENE_PATH := "res://scenes/modules/PlayerModule.tscn"
const SOURCE_ANIMATION := "mixamo_com"
const STEP := 0.05

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene_resource := load(SCENE_PATH) as PackedScene
	if scene_resource == null:
		_fail("Failed to load %s" % SCENE_PATH)
		return

	var player := scene_resource.instantiate()
	root.add_child(player)
	await process_frame

	var animation_player := player.get_node_or_null("ModelRoot/zhujiao/AnimationPlayer") as AnimationPlayer
	var skeleton := _find_skeleton(player)
	if animation_player == null or skeleton == null:
		_fail("AnimationPlayer or Skeleton3D was not found.")
		return
	if not animation_player.has_animation(SOURCE_ANIMATION):
		_fail("Source animation %s was not found." % SOURCE_ANIMATION)
		return

	var left_hand := _find_bone_exact(skeleton, "mixamorig_LeftHand_011")
	var right_hand := _find_bone_exact(skeleton, "mixamorig_RightHand_019")
	var head := _find_bone_containing(skeleton, "Head")
	if left_hand < 0 or right_hand < 0 or head < 0:
		_fail("Required upper-body bones were not found.")
		return

	var animation := animation_player.get_animation(SOURCE_ANIMATION)
	var length := animation.length
	var best_time := 0.0
	var best_score := INF

	print("UPPER_IDLE_POSE_CANDIDATES animation=%s length=%.3f step=%.2f" % [SOURCE_ANIMATION, length, STEP])
	for index in range(int(length / STEP) + 1):
		var time := minf(index * STEP, length)
		animation_player.play(SOURCE_ANIMATION)
		animation_player.seek(time, true)
		await process_frame

		var left_hand_origin := skeleton.get_bone_global_pose(left_hand).origin
		var right_hand_origin := skeleton.get_bone_global_pose(right_hand).origin
		var hand_y_delta := absf(left_hand_origin.y - right_hand_origin.y)
		var hand_z_delta := absf(left_hand_origin.z - right_hand_origin.z)
		var hand_x_width := absf(left_hand_origin.x - right_hand_origin.x)
		var average_hand_y := (left_hand_origin.y + right_hand_origin.y) * 0.5
		var score := hand_y_delta * 2.5 + hand_z_delta * 0.4 + absf(hand_x_width - 300.0) * 0.15 + average_hand_y * 0.02
		if score < best_score:
			best_score = score
			best_time = time
		print("UPPER_IDLE_POSE_CANDIDATE t=%.2f score=%.3f hand_y_delta=%.2f hand_z_delta=%.2f hand_width=%.2f lh=%s rh=%s" % [
			time,
			score,
			hand_y_delta,
			hand_z_delta,
			hand_x_width,
			left_hand_origin,
			right_hand_origin,
		])

	print("UPPER_IDLE_POSE_CANDIDATES_BEST time=%.2f score=%.3f" % [best_time, best_score])
	quit(0)

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

func _find_bone_exact(skeleton: Skeleton3D, bone_name: String) -> int:
	for bone_index in range(skeleton.get_bone_count()):
		if skeleton.get_bone_name(bone_index) == bone_name:
			return bone_index
	return -1

func _fail(message: String) -> void:
	push_error("UPPER_IDLE_POSE_CANDIDATES FAIL: %s" % message)
	quit(1)
