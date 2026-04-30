extends SceneTree

const SCENE_PATH := "res://scenes/levels/Visibility_Blend_Test.tscn"
const CHECK_INTERVAL := 12
const MIN_LIGHT_ENERGY_WHEN_VISIBLE := 0.10
const MIN_RAY_COUNT := 300

var failed := false
var scene: Node
var player: Node3D
var door: Node
var _frame_index := 0


func _initialize() -> void:
	var packed_scene: PackedScene = load(SCENE_PATH)
	scene = packed_scene.instantiate()
	root.add_child(scene)
	_run.call_deferred()


func _run() -> void:
	await _wait_frames(120)
	player = root.find_child("VisibilityBlendPlayer", true, false) as Node3D
	door = root.find_child("BlendDoor_Corridor_RoomB", true, false)
	if not player:
		_fail("VisibilityBlendPlayer was not found")
		_finish()
		return

	if door and door.has_method("force_open"):
		door.call("force_open", true)
	await _wait_frames(60)

	var yaws := [0.0, PI * 0.5, PI, PI * 1.5]
	for yaw in yaws:
		_set_camera_yaw(float(yaw))
		await _wait_frames(30)
		await _walk_path("yaw_%.0f" % rad_to_deg(float(yaw)), [
			Vector3(-6.0, 0.0, -2.8),
			Vector3(-2.0, 0.0, -2.2),
			Vector3(1.0, 0.0, -1.05),
			Vector3(5.8, 0.0, -0.75),
			Vector3(6.9, 0.0, -1.35),
			Vector3(7.35, 0.0, -0.10),
			Vector3(6.4, 0.0, 1.25),
			Vector3(2.6, 0.0, 1.25),
			Vector3(-0.7, 0.0, 2.7),
			Vector3(-5.5, 0.0, 2.7)
		], 42)

	if door and door.has_method("force_open"):
		door.call("force_open", false)
	await _walk_path("closed_door_return", [
		Vector3(5.4, 0.0, 0.0),
		Vector3(6.8, 0.0, -0.8),
		Vector3(6.8, 0.0, 0.8),
		Vector3(4.8, 0.0, 1.2),
		Vector3(2.0, 0.0, 0.0)
	], 55)

	_finish()


func _walk_path(label: String, points: Array, frames_per_segment: int) -> void:
	if points.size() < 2:
		return
	player.global_position = points[0]
	await _wait_frames(20)
	for index in range(points.size() - 1):
		var from_position: Vector3 = points[index]
		var to_position: Vector3 = points[index + 1]
		for frame in frames_per_segment:
			var t := float(frame + 1) / float(frames_per_segment)
			player.global_position = from_position.lerp(to_position, t)
			await process_frame
			_frame_index += 1
			if _frame_index % CHECK_INTERVAL == 0:
				_check_runtime_state("%s_%02d_%02d" % [label, index, frame])


func _check_runtime_state(label: String) -> void:
	var visibility := _visibility_debug()
	var ray_count := int(visibility.get("ray_count", 0))
	if ray_count < MIN_RAY_COUNT:
		_fail("%s ray count dropped to %d" % [label, ray_count])

	var room_a := _weights("RoomA")
	var corridor := _weights("Corridor")
	var room_b := _weights("RoomB")
	var active_lights := _count_active_lights(root)
	var visible_lamps := _count_visible_light_meshes(root)
	var visible_floor_target := maxf(
		float(room_a.get("floor_light_target", 0.0)),
		maxf(float(corridor.get("floor_light_target", 0.0)), float(room_b.get("floor_light_target", 0.0)))
	)

	if visible_floor_target > 0.20 and active_lights <= 0:
		_fail("%s visible floor has no active light floor_target=%.3f" % [label, visible_floor_target])
	if visible_floor_target > 0.45 and _max_light_energy(root) < MIN_LIGHT_ENERGY_WHEN_VISIBLE:
		_fail("%s light energy dropped near visible floor floor_target=%.3f max_energy=%.3f" % [label, visible_floor_target, _max_light_energy(root)])

	print("VISIBILITY_LONG %s pos=(%.2f,%.2f) rays=%d floor=%.3f lights=%d lamps=%d A[v=%.2f m=%.2f] C[v=%.2f m=%.2f] B[v=%.2f m=%.2f]" % [
		label,
		player.global_position.x,
		player.global_position.z,
		ray_count,
		visible_floor_target,
		active_lights,
		visible_lamps,
		float(room_a.get("visible", 0.0)),
		float(room_a.get("memory", 0.0)),
		float(corridor.get("visible", 0.0)),
		float(corridor.get("memory", 0.0)),
		float(room_b.get("visible", 0.0)),
		float(room_b.get("memory", 0.0))
	])


func _set_camera_yaw(yaw: float) -> void:
	if scene:
		scene.set("camera_yaw", yaw)
		scene.set("target_camera_yaw", yaw)
		scene.set("target_camera_distance", 7.4)
		scene.set("camera_distance", 7.4)


func _weights(section_id: String) -> Dictionary:
	if scene and scene.has_method("get_section_debug"):
		return scene.call("get_section_debug", section_id)
	return {}


func _visibility_debug() -> Dictionary:
	if scene and scene.has_method("get_visibility_debug"):
		return scene.call("get_visibility_debug")
	return {}


func _count_visible_light_meshes(node: Node) -> int:
	var count := 0
	if node is MeshInstance3D:
		var mesh := node as MeshInstance3D
		if String(mesh.get_meta("visibility_role", "")) == "light_mesh" and mesh.visible:
			count += 1
	for child in node.get_children():
		count += _count_visible_light_meshes(child)
	return count


func _count_active_lights(node: Node) -> int:
	var count := 0
	if node is Light3D:
		var light := node as Light3D
		if light.visible and light.light_energy > 0.001:
			count += 1
	for child in node.get_children():
		count += _count_active_lights(child)
	return count


func _max_light_energy(node: Node) -> float:
	var best := 0.0
	if node is Light3D:
		var light := node as Light3D
		if light.visible:
			best = maxf(best, light.light_energy)
	for child in node.get_children():
		best = maxf(best, _max_light_energy(child))
	return best


func _wait_frames(count: int) -> void:
	for i in count:
		await process_frame


func _finish() -> void:
	if failed:
		push_error("VISIBILITY_LONG_FAILED")
		quit(1)
	else:
		print("VISIBILITY_LONG_OK")
		quit()


func _fail(message: String) -> void:
	failed = true
	push_error(message)
