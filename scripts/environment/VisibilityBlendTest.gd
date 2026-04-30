extends Node3D
class_name VisibilityBlendTest

const SectionScript := preload("res://scripts/environment/VisibilityBlendSection.gd")
const DoorScript := preload("res://scripts/environment/VisibilityBlendDoor.gd")
const PlayerScript := preload("res://scripts/player/VisibilityBlendPlayer.gd")

const WALL_HEIGHT := 2.7
const WALL_THICKNESS := 0.3
const FLOOR_TILE := 1.0
const TEXTURE_ROOT := "res://assets/textures/backrooms/"
const TEXTURE_WALL := TEXTURE_ROOT + "wallpaper_yellow_green"
const TEXTURE_WALL_DIRTY := TEXTURE_ROOT + "wallpaper_dirty"
const TEXTURE_CARPET := TEXTURE_ROOT + "carpet_old_tan"
const TEXTURE_CEILING := TEXTURE_ROOT + "ceiling_acoustic_tile"
const SHOW_CEILING_EDGES := false

enum LogicState { UNKNOWN, VISITED, VISIBLE }

var sections: Dictionary = {}
var room_rects := {
	"RoomA": Rect2(-9.0, -5.0, 9.0, 10.0),
	"Corridor": Rect2(0.0, -1.8, 8.0, 3.6),
	"RoomB": Rect2(8.0, -5.0, 10.0, 10.0)
}
var visited: Dictionary = {}
var current_room := "RoomA"

var player: Node3D
var camera: Camera3D
var door: Node

var camera_yaw := 0.0
var target_camera_yaw := 0.0
var camera_distance := 7.4
var target_camera_distance := 7.4
var _dragging_camera := false
var _touch_drag_index := -1
var _faded_walls: Dictionary = {}
var _wall_fade_targets: Dictionary = {}
var _wall_fade_alphas: Dictionary = {}

var mat_floor: StandardMaterial3D
var mat_floor_dark: StandardMaterial3D
var mat_visible_floor: StandardMaterial3D
var mat_memory_floor: StandardMaterial3D
var mat_wall: StandardMaterial3D
var mat_wall_dirty: StandardMaterial3D
var mat_ceiling: StandardMaterial3D
var mat_baseboard: StandardMaterial3D
var mat_light: StandardMaterial3D
var mat_camera_cutline: StandardMaterial3D
var visible_floor_mesh: MeshInstance3D
var memory_floor_mesh: MeshInstance3D
var last_visibility_ray_count := 0
var last_memory_vertex_count := 0
var _memory_vertices := PackedVector3Array()
var _memory_colors := PackedColorArray()
var _memory_indices := PackedInt32Array()
var _last_memory_sample := Vector3.INF
var _memory_sample_timer := 0.0


func _ready() -> void:
	_make_materials()
	_setup_world()
	_build_level()
	_build_visibility_surfaces()
	_spawn_player_and_camera()
	_force_initial_visibility()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_RIGHT or mouse.button_index == MOUSE_BUTTON_MIDDLE:
			_dragging_camera = mouse.pressed
		elif mouse.pressed and mouse.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_camera_distance = max(5.8, target_camera_distance - 0.8)
			get_viewport().set_input_as_handled()
		elif mouse.pressed and mouse.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_camera_distance = min(10.2, target_camera_distance + 0.8)
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _dragging_camera:
		var motion := event as InputEventMouseMotion
		target_camera_yaw -= motion.relative.x * 0.006
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and touch.position.x > get_viewport().get_visible_rect().size.x * 0.5:
			_touch_drag_index = touch.index
		elif touch.index == _touch_drag_index:
			_touch_drag_index = -1
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _touch_drag_index:
			target_camera_yaw -= drag.relative.x * 0.006


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("rotate_camera_left"):
		target_camera_yaw += deg_to_rad(45.0)
	if Input.is_action_just_pressed("rotate_camera_right"):
		target_camera_yaw -= deg_to_rad(45.0)
	if Input.is_action_just_pressed("zoom_camera"):
		_cycle_zoom()

	camera_yaw = lerp_angle(camera_yaw, target_camera_yaw, 1.0 - exp(-8.0 * delta))
	camera_distance = lerp(camera_distance, target_camera_distance, 1.0 - exp(-7.0 * delta))
	if player:
		player.set("camera_yaw", camera_yaw)

	_update_camera()
	_update_visibility(delta)
	_update_visibility_floor(delta)
	_update_foreground_wall_fade(delta)


func has_line_of_sight(origin: Vector3, target: Vector3) -> bool:
	var params := PhysicsRayQueryParameters3D.create(origin, target)
	var exclude: Array[RID] = []
	var player_collision := player as CollisionObject3D
	if player_collision:
		exclude.append(player_collision.get_rid())
	params.exclude = exclude
	params.hit_from_inside = false
	var hit := get_world_3d().direct_space_state.intersect_ray(params)
	if hit.is_empty():
		return true
	var hit_position := hit.get("position") as Vector3
	return hit_position.distance_to(target) < 0.28


func get_section_debug(section_id: String) -> Dictionary:
	var section := sections.get(section_id) as Node
	if section and section.has_method("get_debug_weights"):
		return section.call("get_debug_weights")
	return {}


func get_visibility_debug() -> Dictionary:
	return {
		"ray_count": last_visibility_ray_count,
		"memory_vertices": last_memory_vertex_count
	}


func _setup_world() -> void:
	var world_environment := WorldEnvironment.new()
	world_environment.name = "WorldEnvironment_NoFog"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.015, 0.015, 0.013)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.78, 0.72, 0.52)
	env.ambient_light_energy = 0.68
	env.fog_enabled = false
	env.glow_enabled = true
	env.glow_strength = 0.18
	env.glow_intensity = 0.08
	world_environment.environment = env
	add_child(world_environment)


func _make_materials() -> void:
	mat_floor = _textured_material(Color(0.96, 0.88, 0.62), _load_texture(TEXTURE_CARPET + ".png"), 0.98, Vector3(7.0, 7.0, 1.0), _load_texture(TEXTURE_CARPET + "_normal.png"), _load_texture(TEXTURE_CARPET + "_roughness.png"), 0.24)
	mat_floor_dark = _textured_material(Color(0.38, 0.33, 0.20), _load_texture(TEXTURE_CARPET + ".png"), 1.0, Vector3(7.0, 7.0, 1.0), _load_texture(TEXTURE_CARPET + "_normal.png"), _load_texture(TEXTURE_CARPET + "_roughness.png"), 0.2)
	mat_visible_floor = _vertex_material(2, true)
	mat_memory_floor = _vertex_material(-1, true)
	mat_wall = _textured_material(Color(0.82, 0.77, 0.47), _load_texture(TEXTURE_WALL + ".png"), 0.93, Vector3(2.4, 1.0, 1.0), _load_texture(TEXTURE_WALL + "_normal.png"), _load_texture(TEXTURE_WALL + "_roughness.png"), 0.22)
	mat_wall_dirty = _textured_material(Color(0.58, 0.53, 0.32), _load_texture(TEXTURE_WALL_DIRTY + ".png"), 0.96, Vector3(2.4, 1.0, 1.0), _load_texture(TEXTURE_WALL_DIRTY + "_normal.png"), _load_texture(TEXTURE_WALL_DIRTY + "_roughness.png"), 0.3)
	mat_ceiling = _textured_material(Color(0.76, 0.73, 0.60), _load_texture(TEXTURE_CEILING + ".png"), 0.94, Vector3(1.0, 1.0, 1.0), _load_texture(TEXTURE_CEILING + "_normal.png"), _load_texture(TEXTURE_CEILING + "_roughness.png"), 0.14)
	mat_baseboard = _material(Color(0.34, 0.29, 0.17), 0.92)
	mat_light = _material(Color(1.0, 0.98, 0.78), 0.34)
	mat_light.emission_enabled = true
	mat_light.emission = Color(1.0, 0.96, 0.74)
	mat_light.emission_energy_multiplier = 2.0
	mat_camera_cutline = _material(Color(0.13, 0.095, 0.03, 0.78), 1.0)
	mat_camera_cutline.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_camera_cutline.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_camera_cutline.render_priority = 8


func _build_level() -> void:
	_build_section("RoomA", room_rects["RoomA"])
	_build_section("Corridor", room_rects["Corridor"])
	_build_section("RoomB", room_rects["RoomB"])
	_build_room_walls()
	_build_static_door_wall()
	_build_door()
	for section in sections.values():
		if section.has_method("initialize"):
			section.call("initialize")
		if section.has_method("set_manager"):
			section.call("set_manager", self)


func _build_section(section_id: String, rect: Rect2) -> void:
	var section: Node3D = SectionScript.new()
	section.name = section_id
	section.set("section_id", section_id)
	add_child(section)
	sections[section_id] = section
	_add_floor_tiles(section, rect)
	if SHOW_CEILING_EDGES:
		_add_ceiling_edges(section, rect)
	_add_fluorescent_light(section, rect)


func _add_floor_tiles(section: Node3D, rect: Rect2) -> void:
	var center := _rect_center(rect)
	_add_box(section, "ContinuousCarpetFloor", center + Vector3(0.0, -0.045, 0.0), Vector3(rect.size.x, 0.09, rect.size.y), mat_floor, false, "visibility_floor")


func _add_ceiling_edges(section: Node3D, rect: Rect2) -> void:
	var center := _rect_center(rect)
	_add_box(section, "CeilingEdgeSouth", Vector3(center.x, WALL_HEIGHT + 0.035, rect.position.y), Vector3(rect.size.x, 0.045, 0.045), mat_ceiling, false, "ceiling")
	_add_box(section, "CeilingEdgeNorth", Vector3(center.x, WALL_HEIGHT + 0.035, rect.position.y + rect.size.y), Vector3(rect.size.x, 0.045, 0.045), mat_ceiling, false, "ceiling")
	_add_box(section, "CeilingEdgeWest", Vector3(rect.position.x, WALL_HEIGHT + 0.035, center.z), Vector3(0.045, 0.045, rect.size.y), mat_ceiling, false, "ceiling")
	_add_box(section, "CeilingEdgeEast", Vector3(rect.position.x + rect.size.x, WALL_HEIGHT + 0.035, center.z), Vector3(0.045, 0.045, rect.size.y), mat_ceiling, false, "ceiling")


func _add_fluorescent_light(section: Node3D, rect: Rect2) -> void:
	var center := _rect_center(rect)
	var panel_size := Vector3(2.8, 0.07, 0.9) if rect.size.x >= rect.size.y else Vector3(0.9, 0.07, 2.8)
	_add_fluorescent_panel(section, center + Vector3(0.0, WALL_HEIGHT + 0.08, 0.0), panel_size)
	var light := OmniLight3D.new()
	light.name = "FluorescentLight"
	light.light_color = Color(1.0, 0.96, 0.75)
	light.light_energy = 1.9
	light.omni_range = 8.0
	light.shadow_enabled = true
	light.position = center + Vector3(0.0, WALL_HEIGHT - 0.25, 0.0)
	section.add_child(light)


func _add_fluorescent_panel(section: Node3D, center: Vector3, panel_size: Vector3) -> void:
	var segment_count := 8
	var gap := 0.018
	if panel_size.x >= panel_size.z:
		var segment_width := (panel_size.x - gap * float(segment_count - 1)) / float(segment_count)
		for i in segment_count:
			var offset_x := -panel_size.x * 0.5 + segment_width * 0.5 + float(i) * (segment_width + gap)
			_add_box(section, "FluorescentPanel_%02d" % i, center + Vector3(offset_x, 0.0, 0.0), Vector3(segment_width, panel_size.y, panel_size.z), mat_light, false, "light_mesh")
	else:
		var segment_depth := (panel_size.z - gap * float(segment_count - 1)) / float(segment_count)
		for i in segment_count:
			var offset_z := -panel_size.z * 0.5 + segment_depth * 0.5 + float(i) * (segment_depth + gap)
			_add_box(section, "FluorescentPanel_%02d" % i, center + Vector3(0.0, 0.0, offset_z), Vector3(panel_size.x, panel_size.y, segment_depth), mat_light, false, "light_mesh")


func _build_room_walls() -> void:
	_add_wall_h("RoomA", -9.0, 0.0, -5.0)
	_add_wall_h("RoomA", -9.0, 0.0, 5.0)
	_add_wall_v("RoomA", -9.0, -5.0, 5.0)
	_add_wall_v("RoomA", 0.0, -5.0, -1.8)
	_add_wall_v("RoomA", 0.0, 1.8, 5.0)

	_add_wall_h("Corridor", 0.0, 8.0, -1.8)
	_add_wall_h("Corridor", 0.0, 8.0, 1.8)

	_add_wall_h("RoomB", 8.0, 18.0, -5.0)
	_add_wall_h("RoomB", 8.0, 18.0, 5.0)
	_add_wall_v("RoomB", 18.0, -5.0, 5.0)

	for point in [
		Vector3(-9.0, 0.0, -5.0), Vector3(-9.0, 0.0, 5.0), Vector3(0.0, 0.0, -5.0), Vector3(0.0, 0.0, 5.0),
		Vector3(0.0, 0.0, -1.8), Vector3(0.0, 0.0, 1.8), Vector3(8.0, 0.0, -5.0), Vector3(8.0, 0.0, 5.0),
		Vector3(18.0, 0.0, -5.0), Vector3(18.0, 0.0, 5.0)
	]:
		var section_id := _section_for_point(point)
		_add_box(sections[section_id], "CornerPillar", point + Vector3(0.0, WALL_HEIGHT * 0.5, 0.0), Vector3(0.32, WALL_HEIGHT, 0.32), mat_wall, true, "wall_trim")


func _build_static_door_wall() -> void:
	var shared := Node3D.new()
	shared.name = "SharedDoorWall_NoSectionSwitch"
	add_child(shared)
	_add_box(shared, "DoorWallLower", Vector3(8.0, WALL_HEIGHT * 0.5, -2.88), Vector3(WALL_THICKNESS, WALL_HEIGHT, 4.24), mat_wall, true, "wall")
	_add_box(shared, "DoorWallUpper", Vector3(8.0, WALL_HEIGHT * 0.5, 2.88), Vector3(WALL_THICKNESS, WALL_HEIGHT, 4.24), mat_wall, true, "wall")
	_add_box(shared, "DoorOverwall", Vector3(8.0, 2.54, 0.0), Vector3(WALL_THICKNESS, 0.28, 1.84), mat_wall, true, "wall")


func _build_door() -> void:
	door = DoorScript.new()
	door.name = "BlendDoor_Corridor_RoomB"
	door.position = Vector3(8.0, 0.0, 0.0)
	door.rotation.y = deg_to_rad(90.0)
	add_child(door)


func _build_visibility_surfaces() -> void:
	memory_floor_mesh = MeshInstance3D.new()
	memory_floor_mesh.name = "PhysicalVisibilityMemoryFloor"
	memory_floor_mesh.visible = false
	memory_floor_mesh.material_override = mat_memory_floor
	add_child(memory_floor_mesh)

	visible_floor_mesh = MeshInstance3D.new()
	visible_floor_mesh.name = "PhysicalVisibilityLiveFloor"
	visible_floor_mesh.visible = false
	visible_floor_mesh.material_override = mat_visible_floor
	add_child(visible_floor_mesh)


func _spawn_player_and_camera() -> void:
	player = PlayerScript.new()
	player.name = "VisibilityBlendPlayer"
	player.position = Vector3(-5.5, 0.0, 0.0)
	add_child(player)

	camera = Camera3D.new()
	camera.name = "VisibilityBlendCamera"
	camera.current = true
	camera.fov = 50.0
	add_child(camera)


func _force_initial_visibility() -> void:
	visited["RoomA"] = true
	(sections["RoomA"] as Node).call("force_state", LogicState.VISIBLE)
	(sections["Corridor"] as Node).call("force_state", LogicState.UNKNOWN)
	(sections["RoomB"] as Node).call("force_state", LogicState.UNKNOWN)


func _update_camera() -> void:
	if not player or not camera:
		return
	var offset := Vector3(sin(camera_yaw) * camera_distance, 4.65, cos(camera_yaw) * camera_distance)
	camera.global_position = player.global_position + offset
	camera.look_at(player.global_position + Vector3(0.0, 1.0, 0.0), Vector3.UP)


func _update_visibility(delta: float) -> void:
	if not player:
		return
	current_room = _find_current_room(player.global_position)
	if not current_room.is_empty():
		visited[current_room] = true

	var player_eye := player.global_position + Vector3(0.0, 1.15, 0.0)
	for section_id in sections.keys():
		var section := sections[section_id] as Node
		var target_state := _target_state_for_section(String(section_id))
		section.call("set_target_state", target_state)
		section.call("set_door_reveal", Vector3(8.15, 0.0, 0.0), 0.0, 0.0, player_eye)
		section.call("tick", delta, player_eye)


func _target_state_for_section(section_id: String) -> int:
	if section_id == current_room:
		return LogicState.VISIBLE
	if visited.has(section_id):
		return LogicState.VISITED
	return LogicState.UNKNOWN


func _find_current_room(world_position: Vector3) -> String:
	var point := Vector2(world_position.x, world_position.z)
	if (room_rects["RoomB"] as Rect2).has_point(point):
		return "RoomB"
	if (room_rects["Corridor"] as Rect2).has_point(point):
		return "Corridor"
	if (room_rects["RoomA"] as Rect2).has_point(point):
		return "RoomA"
	return current_room


func _cycle_zoom() -> void:
	if target_camera_distance < 6.4:
		target_camera_distance = 7.4
	elif target_camera_distance < 8.6:
		target_camera_distance = 9.6
	else:
		target_camera_distance = 5.8


func _update_foreground_wall_fade(delta: float) -> void:
	if not player or not camera:
		return
	var active_walls: Dictionary = {}
	var from := camera.global_position
	var to := player.global_position + Vector3(0.0, 1.0, 0.0)
	var exclude: Array[RID] = []
	var player_collision := player as CollisionObject3D
	if player_collision:
		exclude.append(player_collision.get_rid())

	for i in 5:
		var params := PhysicsRayQueryParameters3D.create(from, to)
		params.exclude = exclude
		params.hit_from_inside = false
		var hit := get_world_3d().direct_space_state.intersect_ray(params)
		if hit.is_empty():
			break
		var collider := hit.get("collider") as Node
		if not collider:
			break
		if collider.is_in_group("visibility_blend_foreground_wall"):
			active_walls[collider] = true
			_set_wall_fade_target(collider, 0.62)
		if collider is CollisionObject3D:
			exclude.append((collider as CollisionObject3D).get_rid())
		else:
			break

	for wall in _wall_fade_targets.keys():
		if not active_walls.has(wall):
			_set_wall_fade_target(wall as Node, 1.0)
	_apply_wall_fades(delta)


func _update_visibility_floor(delta: float) -> void:
	if not player or not visible_floor_mesh:
		return
	var eye := player.global_position + Vector3(0.0, 1.05, 0.0)
	var polygon := _sample_physical_visibility_polygon(eye, 19.0, 360)
	last_visibility_ray_count = polygon.size()

	_memory_sample_timer += delta
	if polygon.size() > 2 and (_memory_sample_timer >= 0.20 or _last_memory_sample.distance_to(player.global_position) > 0.85):
		_memory_sample_timer = 0.0
		_last_memory_sample = player.global_position
		_append_memory_polygon(polygon)


func _sample_physical_visibility_polygon(eye: Vector3, max_radius: float, ray_count: int) -> PackedVector3Array:
	var points := PackedVector3Array()
	var exclude: Array[RID] = []
	var player_collision := player as CollisionObject3D
	if player_collision:
		exclude.append(player_collision.get_rid())
	for i in ray_count:
		var angle := TAU * float(i) / float(ray_count)
		var target := eye + Vector3(cos(angle) * max_radius, 0.0, sin(angle) * max_radius)
		var params := PhysicsRayQueryParameters3D.create(eye, target)
		params.exclude = exclude
		params.hit_from_inside = false
		var hit := get_world_3d().direct_space_state.intersect_ray(params)
		var point := target
		if not hit.is_empty():
			point = hit.get("position") as Vector3
		points.append(Vector3(point.x, 0.0, point.z))
	return points


func _build_floor_visibility_mesh(points: PackedVector3Array, color: Color, y: float, live_alpha: bool) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	if points.size() < 3 or not player:
		return mesh

	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	var center := Vector3(player.global_position.x, y, player.global_position.z)
	vertices.append(center)
	colors.append(color)
	for i in points.size():
		var next_i := (i + 1) % points.size()
		var point_a := points[i]
		var point_b := points[next_i]
		var distance_a := Vector2(player.global_position.x, player.global_position.z).distance_to(Vector2(point_a.x, point_a.z))
		var distance_b := Vector2(player.global_position.x, player.global_position.z).distance_to(Vector2(point_b.x, point_b.z))

		var outer_a := Vector3(point_a.x, y, point_a.z)
		var outer_b := Vector3(point_b.x, y, point_b.z)
		var base := vertices.size()
		vertices.append(outer_a)
		vertices.append(outer_b)

		var alpha_a := color.a
		var alpha_b := color.a
		if live_alpha:
			alpha_a = 1.0
			alpha_b = 1.0
		else:
			alpha_a *= _visibility_alpha_for_distance(distance_a)
			alpha_b *= _visibility_alpha_for_distance(distance_b)
			alpha_a *= 0.32
			alpha_b *= 0.32
		if live_alpha:
			colors.append(color)
			colors.append(color)
		else:
			colors.append(Color(color.r, color.g, color.b, alpha_a))
			colors.append(Color(color.r, color.g, color.b, alpha_b))

		indices.append(0)
		indices.append(base)
		indices.append(base + 1)

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _append_memory_polygon(points: PackedVector3Array) -> void:
	if not memory_floor_mesh or points.size() < 3 or not player:
		return
	if _memory_vertices.size() > 7000:
		_memory_vertices.clear()
		_memory_colors.clear()
		_memory_indices.clear()

	var base_index := _memory_vertices.size()
	_memory_vertices.append(Vector3(player.global_position.x, 0.008, player.global_position.z))
	_memory_colors.append(Color(0.28, 0.26, 0.18, 0.09))
	for point in points:
		var distance := Vector2(player.global_position.x, player.global_position.z).distance_to(Vector2(point.x, point.z))
		var alpha := 0.075 * _visibility_alpha_for_distance(distance)
		_memory_vertices.append(Vector3(point.x, 0.008, point.z))
		_memory_colors.append(Color(0.28, 0.26, 0.18, alpha))

	for i in points.size():
		_memory_indices.append(base_index)
		_memory_indices.append(base_index + i + 1)
		_memory_indices.append(base_index + ((i + 1) % points.size()) + 1)

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = _memory_vertices
	arrays[Mesh.ARRAY_COLOR] = _memory_colors
	arrays[Mesh.ARRAY_INDEX] = _memory_indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	memory_floor_mesh.mesh = mesh
	last_memory_vertex_count = _memory_vertices.size()


func _visibility_alpha_for_distance(distance: float) -> float:
	if distance <= 8.0:
		return 1.0
	if distance <= 14.0:
		var t: float = clamp((distance - 8.0) / 6.0, 0.0, 1.0)
		return lerp(1.0, 0.42, smoothstep(0.0, 1.0, t))
	if distance <= 19.0:
		var t: float = clamp((distance - 14.0) / 5.0, 0.0, 1.0)
		return lerp(0.42, 0.0, smoothstep(0.0, 1.0, t))
	return 0.0


func _set_wall_alpha(wall: Node, alpha: float) -> void:
	if not is_instance_valid(wall):
		return
	for child in wall.get_children():
		if child is MeshInstance3D:
			var mesh := child as MeshInstance3D
			if String(mesh.get_meta("visibility_role", "")) == "camera_cutline":
				continue
			var material := mesh.material_override as StandardMaterial3D
			if not material:
				continue
			if not _faded_walls.has(wall):
				material = material.duplicate() as StandardMaterial3D
				mesh.material_override = material
				_faded_walls[wall] = material
			material = mesh.material_override as StandardMaterial3D
			if material:
				var color := material.albedo_color
				color.a = alpha
				material.albedo_color = color
				material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if alpha < 0.99 else BaseMaterial3D.TRANSPARENCY_DISABLED
	_set_wall_cutline_visible(wall, alpha < 0.985)


func _set_wall_fade_target(wall: Node, alpha: float) -> void:
	if not is_instance_valid(wall):
		return
	_wall_fade_targets[wall] = clamp(alpha, 0.0, 1.0)
	if not _wall_fade_alphas.has(wall):
		_wall_fade_alphas[wall] = 1.0


func _apply_wall_fades(delta: float) -> void:
	for wall in _wall_fade_targets.keys():
		if not is_instance_valid(wall):
			_wall_fade_targets.erase(wall)
			_wall_fade_alphas.erase(wall)
			continue
		var target: float = float(_wall_fade_targets[wall])
		var current: float = float(_wall_fade_alphas.get(wall, 1.0))
		current = move_toward(current, target, delta / 0.20)
		_wall_fade_alphas[wall] = current
		_set_wall_alpha(wall as Node, current)
		if current >= 0.995 and target >= 0.995:
			_wall_fade_targets.erase(wall)
			_wall_fade_alphas.erase(wall)


func _set_wall_cutline_visible(wall: Node, visible: bool) -> void:
	if not is_instance_valid(wall):
		return
	_ensure_wall_cutlines(wall)
	for child in wall.get_children():
		if child is MeshInstance3D and String(child.get_meta("visibility_role", "")) == "camera_cutline":
			(child as MeshInstance3D).visible = visible


func _ensure_wall_cutlines(wall: Node) -> void:
	for child in wall.get_children():
		if child is MeshInstance3D and String(child.get_meta("visibility_role", "")) == "camera_cutline":
			return

	var source_mesh: MeshInstance3D
	for child in wall.get_children():
		if child is MeshInstance3D:
			source_mesh = child as MeshInstance3D
			break
	if not source_mesh or not source_mesh.mesh:
		return

	var bounds := source_mesh.mesh.get_aabb()
	var size: Vector3 = bounds.size
	var thickness := 0.035
	var lift := 0.024
	if size.x >= size.z:
		_add_camera_cutline(wall, "CameraCutlineTop", Vector3(0.0, size.y * 0.5 + lift, 0.0), Vector3(size.x + thickness, thickness, thickness))
		_add_camera_cutline(wall, "CameraCutlineLeft", Vector3(-size.x * 0.5, 0.0, 0.0), Vector3(thickness, size.y + thickness, thickness))
		_add_camera_cutline(wall, "CameraCutlineRight", Vector3(size.x * 0.5, 0.0, 0.0), Vector3(thickness, size.y + thickness, thickness))
	else:
		_add_camera_cutline(wall, "CameraCutlineTop", Vector3(0.0, size.y * 0.5 + lift, 0.0), Vector3(thickness, thickness, size.z + thickness))
		_add_camera_cutline(wall, "CameraCutlineNear", Vector3(0.0, 0.0, -size.z * 0.5), Vector3(thickness, size.y + thickness, thickness))
		_add_camera_cutline(wall, "CameraCutlineFar", Vector3(0.0, 0.0, size.z * 0.5), Vector3(thickness, size.y + thickness, thickness))


func _add_camera_cutline(parent: Node, node_name: String, local_position: Vector3, size: Vector3) -> void:
	var line := MeshInstance3D.new()
	line.name = node_name
	line.set_meta("visibility_role", "camera_cutline")
	line.visible = false
	line.position = local_position
	var mesh := BoxMesh.new()
	mesh.size = size
	line.mesh = mesh
	line.material_override = mat_camera_cutline
	parent.add_child(line)


func _add_wall_h(section_id: String, x1: float, x2: float, z: float) -> void:
	if x2 - x1 < 0.45:
		return
	var center := Vector3((x1 + x2) * 0.5, WALL_HEIGHT * 0.5, z)
	_add_box(sections[section_id], "WallSegment", center, Vector3(x2 - x1, WALL_HEIGHT, WALL_THICKNESS), mat_wall, true, "wall")
	_add_box(sections[section_id], "Baseboard", center + Vector3(0.0, -WALL_HEIGHT * 0.5 + 0.16, -WALL_THICKNESS * 0.58), Vector3(x2 - x1, 0.16, 0.08), mat_baseboard, false, "baseboard")


func _add_wall_v(section_id: String, x: float, z1: float, z2: float) -> void:
	if z2 - z1 < 0.45:
		return
	var center := Vector3(x, WALL_HEIGHT * 0.5, (z1 + z2) * 0.5)
	_add_box(sections[section_id], "WallSegment", center, Vector3(WALL_THICKNESS, WALL_HEIGHT, z2 - z1), mat_wall, true, "wall")
	_add_box(sections[section_id], "Baseboard", center + Vector3(-WALL_THICKNESS * 0.58, -WALL_HEIGHT * 0.5 + 0.16, 0.0), Vector3(0.08, 0.16, z2 - z1), mat_baseboard, false, "baseboard")


func _add_box(parent: Node, node_name: String, position: Vector3, size: Vector3, material: Material, collision: bool, role: String) -> Node3D:
	var container: Node3D = StaticBody3D.new() if collision else Node3D.new()
	container.name = node_name
	container.position = position
	container.set_meta("visibility_role", role)
	if role == "wall" or role == "wall_trim":
		container.add_to_group("visibility_blend_foreground_wall")
		container.add_to_group("visibility_blend_los_blocker")
	parent.add_child(container)

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name + "Mesh"
	mesh_instance.set_meta("visibility_role", role)
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
	if point.x >= 8.0:
		return "RoomB"
	if point.x >= 0.0:
		return "Corridor"
	return "RoomA"


func _rect_center(rect: Rect2) -> Vector3:
	return Vector3(rect.position.x + rect.size.x * 0.5, 0.0, rect.position.y + rect.size.y * 0.5)


func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material


func _load_texture(path: String) -> Texture2D:
	if FileAccess.file_exists(path):
		var image := Image.new()
		if image.load(path) == OK:
			image.generate_mipmaps()
			return ImageTexture.create_from_image(image)
	return null


func _textured_material(color: Color, texture: Texture2D, roughness: float, uv_scale: Vector3, normal_texture: Texture2D = null, roughness_texture: Texture2D = null, normal_scale := 0.25) -> StandardMaterial3D:
	var material := _material(color, roughness)
	material.albedo_texture = texture
	material.uv1_scale = uv_scale
	material.texture_repeat = true
	if normal_texture:
		material.normal_enabled = true
		material.normal_texture = normal_texture
		material.normal_scale = normal_scale
	if roughness_texture:
		material.roughness_texture = roughness_texture
	return material


func _vertex_material(priority: int, transparent: bool) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if transparent else BaseMaterial3D.TRANSPARENCY_DISABLED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 1.0
	material.render_priority = priority
	return material
