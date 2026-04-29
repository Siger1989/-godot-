extends SceneTree


func _initialize() -> void:
	var packed_scene: PackedScene = load("res://scenes/levels/Visibility_Blend_Test.tscn")
	var scene := packed_scene.instantiate()
	root.add_child(scene)
	_capture.call_deferred()


func _capture() -> void:
	await _wait_frames(90)
	_save_png("res://screenshots/visibility_blend_initial.png")

	var player := root.find_child("VisibilityBlendPlayer", true, false) as Node3D
	var door := root.find_child("BlendDoor_Corridor_RoomB", true, false)
	if door and door.has_method("force_open"):
		door.call("force_open", true)
	if player:
		player.global_position = Vector3(6.4, 0.0, 0.0)
	await _wait_frames(70)
	_save_png("res://screenshots/visibility_blend_door_reveal.png")

	if player:
		player.global_position = Vector3(10.6, 0.0, 0.0)
	await _wait_frames(90)
	_save_png("res://screenshots/visibility_blend_room_b_memory.png")
	quit()


func _wait_frames(count: int) -> void:
	for i in count:
		await process_frame


func _save_png(path: String) -> void:
	var image: Image = root.get_texture().get_image()
	image.save_png(path)
