extends SceneTree

const SCENE_PATH := "res://scenes/modules/PlayerModule.tscn"
const STEP := 0.05
const MAX_TIME := 2.0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene_resource := load(SCENE_PATH) as PackedScene
	if scene_resource == null:
		_fail("Failed to load %s" % SCENE_PATH)
		return

	var best_time := 0.0
	var best_score := INF
	var best_foot_delta := INF
	var best_toe_delta := INF
	print("GENERATED_IDLE_POSE_CANDIDATES step=%.2f" % STEP)

	for index in range(int(MAX_TIME / STEP) + 1):
		var time := index * STEP
		var idle_name := "idle_generated_candidate_%02d" % index
		var player := scene_resource.instantiate()
		player.set("idle_animation", idle_name)
		player.set("idle_pose_time", time)
		player.set("idle_breath_degrees", 0.0)
		player.set("idle_head_look_degrees", 0.0)
		root.add_child(player)
		await process_frame

		var animation_player := player.get_node_or_null("ModelRoot/zhujiao/AnimationPlayer") as AnimationPlayer
		var skeleton := _find_skeleton(player)
		if animation_player == null or skeleton == null or not animation_player.has_animation(idle_name):
			player.queue_free()
			await process_frame
			continue

		animation_player.play(idle_name)
		animation_player.seek(0.0, true)
		await process_frame

		var left_foot := _find_bone_containing(skeleton, "LeftFoot")
		var right_foot := _find_bone_containing(skeleton, "RightFoot")
		var left_toe := _find_bone_containing(skeleton, "LeftToeBase")
		var right_toe := _find_bone_containing(skeleton, "RightToeBase")
		var left_foot_y := skeleton.get_bone_global_pose(left_foot).origin.y
		var right_foot_y := skeleton.get_bone_global_pose(right_foot).origin.y
		var left_toe_y := skeleton.get_bone_global_pose(left_toe).origin.y
		var right_toe_y := skeleton.get_bone_global_pose(right_toe).origin.y
		var foot_delta := absf(left_foot_y - right_foot_y)
		var toe_delta := absf(left_toe_y - right_toe_y)
		var score := foot_delta * 1.5 + toe_delta * 2.0
		if score < best_score:
			best_score = score
			best_time = time
			best_foot_delta = foot_delta
			best_toe_delta = toe_delta
		print("GENERATED_IDLE_POSE_CANDIDATE t=%.2f score=%.3f foot_delta=%.2f toe_delta=%.2f lf=%.2f rf=%.2f lt=%.2f rt=%.2f" % [
			time,
			score,
			foot_delta,
			toe_delta,
			left_foot_y,
			right_foot_y,
			left_toe_y,
			right_toe_y,
		])

		player.queue_free()
		await process_frame

	print("GENERATED_IDLE_POSE_CANDIDATES_BEST time=%.2f score=%.3f foot_delta=%.2f toe_delta=%.2f" % [
		best_time,
		best_score,
		best_foot_delta,
		best_toe_delta,
	])
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

func _fail(message: String) -> void:
	push_error("GENERATED_IDLE_POSE_CANDIDATES FAIL: %s" % message)
	quit(1)
