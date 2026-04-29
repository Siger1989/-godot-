extends Node3D
class_name FogOfWarTestScene

const RoomVolumeScript := preload("res://scripts/environment/RoomVolume.gd")
const FogTestSectionScript := preload("res://scripts/environment/FogTestSection.gd")
const FogTestManagerScript := preload("res://scripts/environment/FogTestManager.gd")
const FogTestDoorScript := preload("res://scripts/environment/FogTestDoor.gd")
const FogTestPlayerScript := preload("res://scripts/player/FogTestPlayer.gd")

const WALL_HEIGHT := 2.7
const WALL_THICKNESS := 0.28

var sections: Dictionary = {}
var volumes_root: Node3D
var camera: Camera3D
var player: Node3D

var mat_floor: StandardMaterial3D
var mat_wall: StandardMaterial3D
var mat_wall_dirty: StandardMaterial3D
var mat_ceiling: StandardMaterial3D
var mat_light: StandardMaterial3D
var mat_prop: StandardMaterial3D


func _ready() -> void:
	_make_materials()
	_setup_world_without_global_fog()
	_build_test_level()
	_spawn_player_and_camera()
	var manager := FogTestManagerScript.new()
	manager.name = "FogTestManager"
	add_child(manager)


func _process(_delta: float) -> void:
	if camera and player:
		camera.global_position = player.global_position + Vector3(0.0, 8.2, 9.0)
		camera.look_at(player.global_position + Vector3(0.0, 0.8, 0.0), Vector3.UP)


func _make_materials() -> void:
	mat_floor = _make_mat(Color(0.72, 0.62, 0.38), 0.98, false)
	mat_wall = _make_mat(Color(0.86, 0.78, 0.38), 0.9, false)
	mat_wall_dirty = _make_mat(Color(0.62, 0.57, 0.32), 0.96, false)
	mat_ceiling = _make_mat(Color(0.78, 0.76, 0.60, 0.32), 0.95, false)
	mat_ceiling.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_light = _make_mat(Color(1.0, 0.98, 0.76), 0.35, false)
	mat_light.emission_enabled = true
	mat_light.emission = Color(1.0, 0.96, 0.68)
	mat_light.emission_energy_multiplier = 1.8
	mat_prop = _make_mat(Color(0.30, 0.24, 0.14), 0.9, false)


func _make_mat(color: Color, roughness: float, unshaded: bool) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	if unshaded:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat


func _setup_world_without_global_fog() -> void:
	var world_environment := WorldEnvironment.new()
	world_environment.name = "WorldEnvironment_NoGlobalFog"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.025, 0.025, 0.022)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.92, 0.86, 0.62)
	env.ambient_light_energy = 0.55
	env.fog_enabled = false
	env.glow_enabled = false
	world_environment.environment = env
	add_child(world_environment)


func _build_test_level() -> void:
	volumes_root = Node3D.new()
	volumes_root.name = "RoomVolumes"
	add_child(volumes_root)

	_build_section("RoomA", Rect2(-18, -8, 18, 16), ["Corridor"], false)
	_build_section("Corridor", Rect2(0, -3, 20, 6), ["RoomA", "RoomB"], true)
	_build_section("RoomB", Rect2(20, -8, 18, 16), ["Corridor"], false)
	_build_section("RoomC", Rect2(-18, 8, 18, 16), [], false)

	_build_walls()
	_build_doors()
	_build_props()

	for section in sections.values():
		if section.has_method("initialize"):
			section.call("initialize")


func _build_section(section_id: String, rect: Rect2, connections: Array[String], is_corridor: bool) -> void:
	var section: Node3D = FogTestSectionScript.new()
	section.name = section_id
	section.set("section_id", section_id)
	add_child(section)
	sections[section_id] = section

	var center := _rect_center(rect)
	_add_box(section, "CarpetFloor", center + Vector3(0.0, -0.055, 0.0), Vector3(rect.size.x, 0.11, rect.size.y), mat_floor, false, "floor")
	_add_ceiling_grid(section, rect)
	_add_light(section, center + Vector3(0.0, 0.0, 0.0), is_corridor)
	_add_unknown_mask(section, rect)
	_add_room_volume(section_id, rect, connections, is_corridor, section)


func _add_room_volume(id: String, rect: Rect2, connections: Array[String], is_corridor: bool, section: Node3D) -> void:
	var volume: Area3D = RoomVolumeScript.new()
	volume.name = id + "_RoomVolume"
	volume.set("room_id", id)
	volume.set("connected_rooms", connections)
	volume.set("section_root", section.get_path())
	volume.set("is_corridor", is_corridor)
	volume.set("bounds", rect)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(rect.size.x, WALL_HEIGHT + 0.4, rect.size.y)
	shape.shape = box
	shape.position = _rect_center(rect) + Vector3(0.0, WALL_HEIGHT * 0.5, 0.0)
	volume.add_child(shape)
	volumes_root.add_child(volume)


func _build_walls() -> void:
	# Room A: clear current room, but solid north wall blocks Room C.
	_add_wall_h("RoomA", -18, 0, -8, [])
	_add_wall_h("RoomA", -18, 0, 8, [])
	_add_wall_v("RoomA", -18, -8, 8, [])
	_add_wall_v("RoomA", 0, -8, 8, [Vector2(-1.25, 1.25)])

	# Corridor: only doors reveal adjacent space; side walls block diagonal sight.
	_add_wall_h("Corridor", 0, 20, -3, [])
	_add_wall_h("Corridor", 0, 20, 3, [])
	_add_wall_v("Corridor", 0, -3, 3, [Vector2(-1.25, 1.25)])
	_add_wall_v("Corridor", 20, -3, 3, [Vector2(-1.25, 1.25)])

	# Room B: starts UNKNOWN and only becomes VISIBLE after entry.
	_add_wall_h("RoomB", 20, 38, -8, [])
	_add_wall_h("RoomB", 20, 38, 8, [])
	_add_wall_v("RoomB", 20, -8, 8, [Vector2(-1.25, 1.25)])
	_add_wall_v("RoomB", 38, -8, 8, [])

	# Room C shares a wall with A but has no door or connection.
	_add_wall_h("RoomC", -18, 0, 8, [])
	_add_wall_h("RoomC", -18, 0, 24, [])
	_add_wall_v("RoomC", -18, 8, 24, [])
	_add_wall_v("RoomC", 0, 8, 24, [])


func _build_doors() -> void:
	_add_door("Door_A_Corridor", "RoomA", "Corridor", Vector3(0.0, 0.0, 0.0), deg_to_rad(90.0))
	_add_door("Door_Corridor_B", "Corridor", "RoomB", Vector3(20.0, 0.0, 0.0), deg_to_rad(90.0))


func _build_props() -> void:
	_add_box(sections["RoomA"], "RoomA_Table", Vector3(-11, 0.45, -4), Vector3(2.2, 0.9, 1.0), mat_prop, true, "detail")
	_add_box(sections["RoomB"], "RoomB_FuseBox", Vector3(31, 0.8, 5.8), Vector3(1.1, 1.4, 0.35), mat_prop, true, "detail")
	_add_box(sections["RoomC"], "RoomC_HiddenCrate", Vector3(-9, 0.55, 16), Vector3(2.0, 1.1, 1.4), mat_prop, true, "detail")


func _spawn_player_and_camera() -> void:
	player = FogTestPlayerScript.new()
	player.name = "FogTestPlayer"
	player.position = Vector3(-10.0, 0.0, 0.0)
	add_child(player)

	camera = Camera3D.new()
	camera.name = "FogTestCamera"
	camera.current = true
	camera.fov = 52.0
	add_child(camera)


func _add_unknown_mask(section: Node3D, rect: Rect2) -> void:
	var mask := MeshInstance3D.new()
	mask.name = "UnknownBlackMask"
	mask.set_meta("fog_role", "unknown_mask")
	var mesh := PlaneMesh.new()
	mesh.size = rect.size
	mask.mesh = mesh
	mask.position = _rect_center(rect) + Vector3(0.0, 0.04, 0.0)
	mask.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	section.add_child(mask)


func _add_ceiling_grid(section: Node3D, rect: Rect2) -> void:
	var center := _rect_center(rect)
	for x in range(int(rect.position.x), int(rect.position.x + rect.size.x) + 1, 4):
		_add_box(section, "CeilingGridX", Vector3(float(x), WALL_HEIGHT + 0.045, center.z), Vector3(0.035, 0.04, rect.size.y), mat_wall_dirty, false, "ceiling")
	for z in range(int(rect.position.y), int(rect.position.y + rect.size.y) + 1, 4):
		_add_box(section, "CeilingGridZ", Vector3(center.x, WALL_HEIGHT + 0.05, float(z)), Vector3(rect.size.x, 0.04, 0.035), mat_wall_dirty, false, "ceiling")


func _add_light(section: Node3D, center: Vector3, along_x: bool) -> void:
	var light_size := Vector3(2.6, 0.06, 1.0) if along_x else Vector3(1.0, 0.06, 2.6)
	_add_box(section, "FluorescentPanel", center + Vector3(0.0, WALL_HEIGHT + 0.08, 0.0), light_size, mat_light, false, "light_mesh")
	var light := OmniLight3D.new()
	light.name = "FluorescentLight"
	light.light_color = Color(0.98, 0.95, 0.70)
	light.light_energy = 1.7
	light.omni_range = 10.0
	light.position = center + Vector3(0.0, WALL_HEIGHT - 0.18, 0.0)
	section.add_child(light)


func _add_door(node_name: String, room_a: String, room_b: String, position: Vector3, yaw: float) -> void:
	var door: Node3D = FogTestDoorScript.new()
	door.name = node_name
	door.set("room_a", room_a)
	door.set("room_b", room_b)
	door.position = position
	door.rotation.y = yaw
	add_child(door)


func _add_wall_h(section_id: String, x1: float, x2: float, z: float, openings: Array[Vector2]) -> void:
	var cursor := x1
	for opening in openings:
		_add_wall_h_segment(section_id, cursor, opening.x, z)
		cursor = opening.y
	_add_wall_h_segment(section_id, cursor, x2, z)


func _add_wall_v(section_id: String, x: float, z1: float, z2: float, openings: Array[Vector2]) -> void:
	var cursor := z1
	for opening in openings:
		_add_wall_v_segment(section_id, x, cursor, opening.x)
		cursor = opening.y
	_add_wall_v_segment(section_id, x, cursor, z2)


func _add_wall_h_segment(section_id: String, x1: float, x2: float, z: float) -> void:
	if x2 - x1 < 0.5:
		return
	_add_box(sections[section_id], "WallSegment", Vector3((x1 + x2) * 0.5, WALL_HEIGHT * 0.5, z), Vector3(x2 - x1, WALL_HEIGHT, WALL_THICKNESS), mat_wall, true, "wall")


func _add_wall_v_segment(section_id: String, x: float, z1: float, z2: float) -> void:
	if z2 - z1 < 0.5:
		return
	_add_box(sections[section_id], "WallSegment", Vector3(x, WALL_HEIGHT * 0.5, (z1 + z2) * 0.5), Vector3(WALL_THICKNESS, WALL_HEIGHT, z2 - z1), mat_wall, true, "wall")


func _add_box(parent: Node, node_name: String, position: Vector3, size: Vector3, material: Material, collision: bool, role: String) -> Node3D:
	var container: Node3D = StaticBody3D.new() if collision else Node3D.new()
	container.name = node_name
	container.position = position
	container.set_meta("fog_role", role)
	parent.add_child(container)

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name + "Mesh"
	mesh_instance.set_meta("fog_role", role)
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	container.add_child(mesh_instance)

	if collision:
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size
		shape.shape = box
		container.add_child(shape)
	return container


func _rect_center(rect: Rect2) -> Vector3:
	return Vector3(rect.position.x + rect.size.x * 0.5, 0.0, rect.position.y + rect.size.y * 0.5)
