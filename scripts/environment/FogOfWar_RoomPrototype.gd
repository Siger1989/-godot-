extends Node3D
class_name FogOfWarRoomPrototype

const RoomVolumeScript := preload("res://scripts/environment/RoomVolume.gd")
const SectionScript := preload("res://scripts/environment/RoomPrototypeSection.gd")
const DoorScript := preload("res://scripts/environment/RoomPrototypeDoor.gd")
const ManagerScript := preload("res://scripts/environment/RoomPrototypeManager.gd")
const PlayerScript := preload("res://scripts/player/RoomPrototypePlayer.gd")

const WALL_HEIGHT := 2.7
const WALL_THICKNESS := 0.3
const TILE := 2.0

var sections: Dictionary = {}
var volumes_root: Node3D
var player: Node3D
var camera: Camera3D

var mat_floor: StandardMaterial3D
var mat_wall: StandardMaterial3D
var mat_wall_dirty: StandardMaterial3D
var mat_ceiling: StandardMaterial3D
var mat_light: StandardMaterial3D
var mat_baseboard: StandardMaterial3D


func _ready() -> void:
	_make_materials()
	_setup_world()
	_build_rooms()
	_spawn_player_camera_manager()


func _process(_delta: float) -> void:
	if not player or not camera:
		return
	camera.global_position = player.global_position + Vector3(-2.2, 4.25, 6.2)
	camera.look_at(player.global_position + Vector3(0.0, 0.95, 0.0), Vector3.UP)


func _setup_world() -> void:
	var world_environment := WorldEnvironment.new()
	world_environment.name = "WorldEnvironment_NoFog"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.015, 0.015, 0.013)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.74, 0.68, 0.50)
	env.ambient_light_energy = 0.58
	env.fog_enabled = false
	env.glow_enabled = true
	env.glow_intensity = 0.08
	env.glow_strength = 0.22
	world_environment.environment = env
	add_child(world_environment)


func _make_materials() -> void:
	mat_floor = _make_material(Color(0.62, 0.53, 0.32), 0.98)
	mat_wall = _make_material(Color(0.78, 0.71, 0.36), 0.9)
	mat_wall_dirty = _make_material(Color(0.58, 0.53, 0.30), 0.96)
	mat_ceiling = _make_material(Color(0.70, 0.68, 0.54), 0.92)
	mat_light = StandardMaterial3D.new()
	mat_light.albedo_color = Color(0.98, 0.97, 0.80)
	mat_light.emission_enabled = true
	mat_light.emission = Color(0.98, 0.95, 0.70)
	mat_light.emission_energy_multiplier = 2.2
	mat_light.roughness = 0.32
	mat_baseboard = StandardMaterial3D.new()
	mat_baseboard.albedo_color = Color(0.28, 0.23, 0.13)
	mat_baseboard.roughness = 0.9


func _make_material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material


func _build_rooms() -> void:
	volumes_root = Node3D.new()
	volumes_root.name = "RoomVolumes"
	add_child(volumes_root)

	_build_section("RoomA", Rect2(-14, -6, 14, 12), ["Corridor"], false)
	_build_section("Corridor", Rect2(0, -2, 10, 4), ["RoomA", "RoomB"], true)
	_build_section("RoomB", Rect2(10, -6, 16, 12), ["Corridor"], false)
	_build_section("RoomC", Rect2(-14, 6, 14, 12), [], false)

	_build_walls()
	_build_doors()
	_build_partial_reveals()

	for section in sections.values():
		if section.has_method("initialize"):
			section.call("initialize")


func _build_section(section_id: String, rect: Rect2, connections: Array[String], is_corridor: bool) -> void:
	var section: Node3D = SectionScript.new()
	section.name = section_id
	section.set("section_id", section_id)
	add_child(section)
	sections[section_id] = section

	_add_floor_tiles(section, rect)
	_add_ceiling_grid(section, rect)
	_add_fluorescent_light(section, rect, is_corridor)
	_add_room_volume(section_id, rect, connections, is_corridor, section)


func _add_floor_tiles(section: Node3D, rect: Rect2) -> void:
	var x_count := int(rect.size.x / TILE)
	var z_count := int(rect.size.y / TILE)
	for xi in x_count:
		for zi in z_count:
			var x := rect.position.x + TILE * (float(xi) + 0.5)
			var z := rect.position.y + TILE * (float(zi) + 0.5)
			_add_box(section, "CarpetTile", Vector3(x, -0.055, z), Vector3(TILE, 0.11, TILE), mat_floor, false, "floor")


func _add_ceiling_grid(section: Node3D, rect: Rect2) -> void:
	var center := _rect_center(rect)
	_add_box(section, "CeilingEdgeSouth", Vector3(center.x, WALL_HEIGHT + 0.04, rect.position.y), Vector3(rect.size.x, 0.045, 0.045), mat_ceiling, false, "ceiling")
	_add_box(section, "CeilingEdgeNorth", Vector3(center.x, WALL_HEIGHT + 0.04, rect.position.y + rect.size.y), Vector3(rect.size.x, 0.045, 0.045), mat_ceiling, false, "ceiling")
	_add_box(section, "CeilingEdgeWest", Vector3(rect.position.x, WALL_HEIGHT + 0.04, center.z), Vector3(0.045, 0.045, rect.size.y), mat_ceiling, false, "ceiling")
	_add_box(section, "CeilingEdgeEast", Vector3(rect.position.x + rect.size.x, WALL_HEIGHT + 0.04, center.z), Vector3(0.045, 0.045, rect.size.y), mat_ceiling, false, "ceiling")


func _add_fluorescent_light(section: Node3D, rect: Rect2, along_x: bool) -> void:
	var center := _rect_center(rect)
	var panel_size := Vector3(2.6, 0.07, 0.85) if along_x else Vector3(0.95, 0.07, 2.55)
	_add_box(section, "FluorescentPanel", center + Vector3(0.0, WALL_HEIGHT + 0.08, 0.0), panel_size, mat_light, false, "light_mesh")
	var light := OmniLight3D.new()
	light.name = "FluorescentLight"
	light.light_color = Color(0.98, 0.96, 0.74)
	light.light_energy = 2.05
	light.omni_range = 9.5
	light.position = center + Vector3(0.0, WALL_HEIGHT - 0.20, 0.0)
	section.add_child(light)


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
	_add_room_walls("RoomA", Rect2(-14, -6, 14, 12), {"east": [Vector2(-0.75, 0.75)]})
	_add_room_walls("Corridor", Rect2(0, -2, 10, 4), {"west": [Vector2(-0.75, 0.75)], "east": [Vector2(-0.75, 0.75)]})
	_add_room_walls("RoomB", Rect2(10, -6, 16, 12), {"west": [Vector2(-0.75, 0.75)]})
	_add_wall_h("RoomC", -14, 0, 18, [])
	_add_wall_v("RoomC", -14, 6, 18, [])
	_add_wall_v("RoomC", 0, 6, 18, [])

	var pillars: Array[Vector3] = [
		Vector3(-14, 0, -6), Vector3(-14, 0, 6), Vector3(0, 0, -6), Vector3(0, 0, 6),
		Vector3(10, 0, -6), Vector3(10, 0, 6), Vector3(26, 0, -6), Vector3(26, 0, 6),
		Vector3(-14, 0, 18), Vector3(0, 0, 18)
	]
	for i in pillars.size():
		var point := pillars[i]
		var section_id := _section_for_point(point)
		_add_box(sections[section_id], "CornerPillar", point + Vector3(0.0, WALL_HEIGHT * 0.5, 0.0), Vector3(0.46, WALL_HEIGHT, 0.46), mat_wall_dirty, true, "wall")


func _add_room_walls(section_id: String, rect: Rect2, openings: Dictionary) -> void:
	var x1 := rect.position.x
	var x2 := rect.position.x + rect.size.x
	var z1 := rect.position.y
	var z2 := rect.position.y + rect.size.y
	_add_wall_h(section_id, x1, x2, z1, openings.get("south", []))
	_add_wall_h(section_id, x1, x2, z2, openings.get("north", []))
	_add_wall_v(section_id, x1, z1, z2, openings.get("west", []))
	_add_wall_v(section_id, x2, z1, z2, openings.get("east", []))


func _build_doors() -> void:
	_add_door("Door_A_Corridor", "RoomA", "Corridor", Vector3(0.0, 0.0, 0.0), deg_to_rad(90.0))
	_add_door("Door_Corridor_B", "Corridor", "RoomB", Vector3(10.0, 0.0, 0.0), deg_to_rad(90.0))


func _build_partial_reveals() -> void:
	_add_partial_reveal("RoomA", "Corridor", Rect2(-3.4, -2.2, 3.4, 4.4))
	_add_partial_reveal("Corridor", "RoomA", Rect2(0.0, -2.0, 3.2, 4.0))
	_add_partial_reveal("Corridor", "RoomB", Rect2(6.8, -2.0, 3.2, 4.0))
	_add_partial_reveal("RoomB", "Corridor", Rect2(10.0, -2.7, 3.4, 5.4))


func _add_partial_reveal(section_id: String, from_room: String, rect: Rect2) -> void:
	var section := sections[section_id] as Node3D
	var container := Node3D.new()
	container.name = "PartialRevealFrom_" + from_room
	container.set_meta("fog_role", "partial_reveal")
	container.set_meta("partial_from", from_room)
	section.add_child(container)
	var center := _rect_center(rect)
	_add_box(container, "DoorwayFloorMemory", center + Vector3(0.0, -0.045, 0.0), Vector3(rect.size.x, 0.09, rect.size.y), mat_floor, false, "partial_reveal")


func _spawn_player_camera_manager() -> void:
	player = PlayerScript.new()
	player.name = "RoomPrototypePlayer"
	player.position = Vector3(-8.4, 0.0, 0.0)
	add_child(player)

	camera = Camera3D.new()
	camera.name = "RoomPrototypeCamera"
	camera.current = true
	camera.fov = 50.0
	add_child(camera)

	var manager: Node3D = ManagerScript.new()
	manager.name = "RoomPrototypeFogManager"
	add_child(manager)


func _add_door(node_name: String, room_a: String, room_b: String, position: Vector3, yaw: float) -> void:
	var door: Node3D = DoorScript.new()
	door.name = node_name
	door.set("room_a", room_a)
	door.set("room_b", room_b)
	door.position = position
	door.rotation.y = yaw
	add_child(door)


func _add_wall_h(section_id: String, x1: float, x2: float, z: float, openings: Array) -> void:
	var cursor := x1
	for opening in openings:
		var span := opening as Vector2
		_add_wall_h_segment(section_id, cursor, span.x, z)
		cursor = span.y
	_add_wall_h_segment(section_id, cursor, x2, z)


func _add_wall_v(section_id: String, x: float, z1: float, z2: float, openings: Array) -> void:
	var cursor := z1
	for opening in openings:
		var span := opening as Vector2
		_add_wall_v_segment(section_id, x, cursor, span.x)
		cursor = span.y
	_add_wall_v_segment(section_id, x, cursor, z2)


func _add_wall_h_segment(section_id: String, x1: float, x2: float, z: float) -> void:
	if x2 - x1 < 0.45:
		return
	var center := Vector3((x1 + x2) * 0.5, WALL_HEIGHT * 0.5, z)
	_add_box(sections[section_id], "WallSegment", center, Vector3(x2 - x1, WALL_HEIGHT, WALL_THICKNESS), mat_wall, true, "wall")
	_add_box(sections[section_id], "Baseboard", center + Vector3(0.0, -WALL_HEIGHT * 0.5 + 0.16, -WALL_THICKNESS * 0.58), Vector3(x2 - x1, 0.16, 0.08), mat_baseboard, false, "baseboard")


func _add_wall_v_segment(section_id: String, x: float, z1: float, z2: float) -> void:
	if z2 - z1 < 0.45:
		return
	var center := Vector3(x, WALL_HEIGHT * 0.5, (z1 + z2) * 0.5)
	_add_box(sections[section_id], "WallSegment", center, Vector3(WALL_THICKNESS, WALL_HEIGHT, z2 - z1), mat_wall, true, "wall")
	_add_box(sections[section_id], "Baseboard", center + Vector3(-WALL_THICKNESS * 0.58, -WALL_HEIGHT * 0.5 + 0.16, 0.0), Vector3(0.08, 0.16, z2 - z1), mat_baseboard, false, "baseboard")


func _add_box(parent: Node, node_name: String, position: Vector3, size: Vector3, material: Material, collision: bool, role: String) -> Node3D:
	var container: Node3D = StaticBody3D.new() if collision else Node3D.new()
	container.name = node_name
	container.position = position
	container.set_meta("fog_role", role)
	if role == "wall":
		container.add_to_group("prototype_foreground_wall")
		container.add_to_group("prototype_los_blocker")
	parent.add_child(container)

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name + "Mesh"
	mesh_instance.set_meta("fog_role", role)
	if role == "partial_reveal":
		mesh_instance.set_meta("partial_from", String(parent.get_meta("partial_from", "")))
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


func _section_for_point(point: Vector3) -> String:
	if point.z > 6.0:
		return "RoomC"
	if point.x >= 10.0:
		return "RoomB"
	if point.x >= 0.0:
		return "Corridor"
	return "RoomA"


func _rect_center(rect: Rect2) -> Vector3:
	return Vector3(rect.position.x + rect.size.x * 0.5, 0.0, rect.position.y + rect.size.y * 0.5)
