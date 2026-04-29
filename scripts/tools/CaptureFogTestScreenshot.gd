extends SceneTree


func _initialize() -> void:
	var packed_scene: PackedScene = load("res://scenes/levels/FogOfWar_Test.tscn")
	var scene: Node = packed_scene.instantiate()
	root.add_child(scene)
	_capture.call_deferred()


func _capture() -> void:
	for i in 90:
		await process_frame
	var image: Image = root.get_texture().get_image()
	image.save_png("res://screenshots/fog_of_war_test.png")
	quit()
