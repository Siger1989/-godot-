extends SceneTree


func _initialize() -> void:
	var packed_scene: PackedScene = load("res://scenes/main/Main.tscn")
	var scene: Node = packed_scene.instantiate()
	root.add_child(scene)
	_capture.call_deferred()


func _capture() -> void:
	for i in 90:
		await process_frame
	var image: Image = root.get_texture().get_image()
	image.save_png("res://screenshots/latest.png")
	image.save_png("res://screenshots/v4_boundary_fog_monster_patch.png")
	quit()
