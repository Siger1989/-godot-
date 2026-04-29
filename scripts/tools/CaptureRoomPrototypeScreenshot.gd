extends SceneTree


func _initialize() -> void:
	var packed_scene: PackedScene = load("res://scenes/levels/FogOfWar_RoomPrototype.tscn")
	var scene: Node = packed_scene.instantiate()
	root.add_child(scene)
	_capture.call_deferred()


func _capture() -> void:
	await _wait_frames(90)
	_save_png("res://screenshots/fog_room_prototype_initial.png")
	_save_png("res://screenshots/fog_room_prototype.png")

	var door_a: Node = root.find_child("Door_A_Corridor", true, false)
	if door_a and door_a.has_method("toggle"):
		door_a.call("toggle")
	await _wait_frames(40)
	_save_png("res://screenshots/fog_room_prototype_open_door.png")

	var player := root.find_child("RoomPrototypePlayer", true, false) as Node3D
	if player:
		player.global_position = Vector3(5.0, 0.0, 0.0)
	await _wait_frames(20)

	var door_b: Node = root.find_child("Door_Corridor_B", true, false)
	if door_b and door_b.has_method("toggle"):
		door_b.call("toggle")
	await _wait_frames(20)

	if player:
		player.global_position = Vector3(18.0, 0.0, 0.0)
	await _wait_frames(50)
	_save_png("res://screenshots/fog_room_prototype_room_b.png")
	quit()


func _wait_frames(count: int) -> void:
	for i in count:
		await process_frame


func _save_png(path: String) -> void:
	var image: Image = root.get_texture().get_image()
	image.save_png(path)
