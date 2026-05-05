extends SceneTree

const SCENE_PATH := "res://scenes/modules/PlayerModule.tscn"
const ANIMATION_NAME := "mixamo_com"

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
	if animation_player == null:
		_fail("AnimationPlayer not found.")
		return
	if not animation_player.has_animation(ANIMATION_NAME):
		_fail("Animation %s not found." % ANIMATION_NAME)
		return

	var animation := animation_player.get_animation(ANIMATION_NAME)
	if animation == null:
		_fail("Animation resource was null.")
		return

	print("PLAYER_ANIMATION_TRACK_INSPECT PASS animation=%s tracks=%d length=%.3f" % [
		ANIMATION_NAME,
		animation.get_track_count(),
		animation.length,
	])
	for track_index in range(animation.get_track_count()):
		var track_type := animation.track_get_type(track_index)
		var track_path := animation.track_get_path(track_index)
		var key_count := animation.track_get_key_count(track_index)
		var enabled := animation.track_is_enabled(track_index)
		if track_type == Animation.TYPE_POSITION_3D:
			var first_position := Vector3.ZERO
			var last_position := Vector3.ZERO
			if key_count > 0:
				var first_value: Variant = animation.track_get_key_value(track_index, 0)
				var last_value: Variant = animation.track_get_key_value(track_index, key_count - 1)
				if first_value is Vector3:
					first_position = first_value
				if last_value is Vector3:
					last_position = last_value
			print("TRACK %03d type=POSITION enabled=%s path=%s keys=%d first=%s last=%s delta=%s" % [
				track_index,
				enabled,
				track_path,
				key_count,
				first_position,
				last_position,
				last_position - first_position,
			])
		elif track_type == Animation.TYPE_ROTATION_3D:
			print("TRACK %03d type=ROTATION enabled=%s path=%s keys=%d" % [track_index, enabled, track_path, key_count])
		elif track_type == Animation.TYPE_SCALE_3D:
			print("TRACK %03d type=SCALE enabled=%s path=%s keys=%d" % [track_index, enabled, track_path, key_count])
		else:
			print("TRACK %03d type=%d enabled=%s path=%s keys=%d" % [track_index, track_type, enabled, track_path, key_count])

	quit(0)

func _fail(message: String) -> void:
	push_error("PLAYER_ANIMATION_TRACK_INSPECT FAIL: %s" % message)
	quit(1)
