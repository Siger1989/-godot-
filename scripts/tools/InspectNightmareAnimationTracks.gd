extends SceneTree

const NIGHTMARE_MONSTER_PATH := "res://assets/backrooms/monsters/NightmareCreature_Monster.tscn"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load(NIGHTMARE_MONSTER_PATH) as PackedScene
	if packed == null:
		_fail("missing Nightmare monster scene")
		return
	var monster := packed.instantiate() as Node3D
	root.add_child(monster)
	await process_frame
	var player := _find_animation_player(monster)
	if player == null:
		_fail("missing AnimationPlayer")
		return
	for animation_name_variant in player.get_animation_list():
		var animation_name := String(animation_name_variant)
		if animation_name not in [
			"Creature_armature|idle",
			"Creature_armature|walk",
			"Creature_armature|Run",
			"Creature_armature|attack_1",
			"Creature_armature|death_1",
		]:
			continue
		var animation := player.get_animation(StringName(animation_name))
		if animation == null:
			continue
		print("ANIM_TRACKS name=\"%s\" tracks=%d" % [animation_name, animation.get_track_count()])
		for track_index in range(animation.get_track_count()):
			if animation.track_get_type(track_index) != Animation.TYPE_POSITION_3D:
				continue
			print("POSITION_TRACK anim=\"%s\" index=%d enabled=%s path=\"%s\"" % [
				animation_name,
				track_index,
				str(animation.track_is_enabled(track_index)),
				String(animation.track_get_path(track_index)),
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
	push_error("NIGHTMARE_ANIMATION_TRACK_INSPECT_FAIL %s" % message)
	quit(1)
