extends SceneTree

const SCENE_PATH := "res://scenes/modules/PlayerModule.tscn"

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

	var animation_players: Array[AnimationPlayer] = []
	_collect_animation_players(player, animation_players)
	if animation_players.is_empty():
		_fail("No AnimationPlayer found under PlayerModule.")
		return

	print("PLAYER_ANIMATION_INSPECT PASS players=%d" % animation_players.size())
	for animation_player in animation_players:
		var player_path := player.get_path_to(animation_player)
		var animation_names := animation_player.get_animation_list()
		print("AnimationPlayer path=%s animations=%d" % [player_path, animation_names.size()])
		for animation_name in animation_names:
			var animation := animation_player.get_animation(animation_name)
			var length := 0.0
			var loop_mode := -1
			if animation != null:
				length = animation.length
				loop_mode = animation.loop_mode
			print("- %s length=%.3f loop_mode=%d" % [animation_name, length, loop_mode])

	quit(0)

func _collect_animation_players(node: Node, output: Array[AnimationPlayer]) -> void:
	var animation_player := node as AnimationPlayer
	if animation_player != null:
		output.append(animation_player)
	for child in node.get_children():
		_collect_animation_players(child, output)

func _fail(message: String) -> void:
	push_error("PLAYER_ANIMATION_INSPECT FAIL: %s" % message)
	quit(1)
