extends Node3D
class_name Level0Demo

const PlayerScene := preload("res://scenes/characters/Player.tscn")
const FuseScene := preload("res://scenes/items/FusePickup.tscn")
const ElectricalPanelScene := preload("res://scenes/items/ElectricalPanel.tscn")
const ExitDoorScene := preload("res://scenes/items/ExitDoor.tscn")
const DoorOpenableScene := preload("res://scenes/modules/Door_Openable.tscn")
const DoorLockedScene := preload("res://scenes/modules/Door_Locked.tscn")
const DoorBlockedScene := preload("res://scenes/modules/Door_Blocked.tscn")
const ShadowScene := preload("res://scenes/characters/ShadowEntity.tscn")
const ObjectiveScript := preload("res://scripts/core/ObjectiveManager.gd")
const RoomPrototypeSectionScript := preload("res://scripts/environment/RoomPrototypeSection.gd")
const RoomVolumeScript := preload("res://scripts/environment/RoomVolume.gd")
const RoomPrototypeManagerScript := preload("res://scripts/environment/RoomPrototypeManager.gd")
const WallFadeScript := preload("res://scripts/environment/WallFade.gd")
const CeilingCutawayScript := preload("res://scripts/environment/CeilingCutaway.gd")

const WALL_HEIGHT := 2.7
const WALL_THICKNESS := 0.28
const SHOW_CEILING := false
const TEXTURE_ROOT := "res://assets/textures/backrooms/"
const TEXTURE_WALL := TEXTURE_ROOT + "wallpaper_yellow_green"
const TEXTURE_WALL_DIRTY := TEXTURE_ROOT + "wallpaper_dirty"
const TEXTURE_CARPET := TEXTURE_ROOT + "carpet_old_tan"
const TEXTURE_CEILING := TEXTURE_ROOT + "ceiling_acoustic_tile"

var mat_floor: StandardMaterial3D
var mat_wall: StandardMaterial3D
var mat_wall_dirty: StandardMaterial3D
var mat_ceiling: StandardMaterial3D
var mat_light: StandardMaterial3D
var mat_column: StandardMaterial3D
var mat_prop: StandardMaterial3D
var mat_dark: StandardMaterial3D
var mat_void: StandardMaterial3D
var mat_baseboard: StandardMaterial3D

var sections_root: Node3D
var walls_root: Node3D
var void_root: Node3D
var volumes_root: Node3D
var sections: Dictionary = {}
var section_defs: Array[Dictionary] = []


func _ready() -> void:
	add_to_group("level")
	_make_materials()
	_setup_world()
	_add_objective_manager()
	sections_root = Node3D.new()
	sections_root.name = "LevelSections"
	add_child(sections_root)
	walls_root = Node3D.new()
	walls_root.name = "OpaqueWalls"
	add_child(walls_root)
	void_root = Node3D.new()
	void_root.name = "OutOfBoundsVoid"
	add_child(void_root)
	volumes_root = Node3D.new()
	volumes_root.name = "RoomVolumes"
	add_child(volumes_root)
	_define_sections()
	_build_out_of_bounds_void()
	void_root.visible = false
	_build_sections_and_volumes()
	_build_wall_network()
	_build_edge_disguises()
	_build_props_and_details()
	_spawn_gameplay()
	_add_visibility_and_wall_fade()


func _add_objective_manager() -> void:
	var objective := ObjectiveScript.new()
	objective.name = "ObjectiveManager"
	add_child(objective)


func _setup_world() -> void:
	var world_environment := WorldEnvironment.new()
	world_environment.name = "WorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.04, 0.04, 0.035)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.98, 0.92, 0.66)
	env.ambient_light_energy = 1.12
	env.fog_enabled = false
	env.glow_enabled = true
	env.glow_intensity = 0.11
	env.glow_strength = 0.34
	world_environment.environment = env
	add_child(world_environment)

	var sun := DirectionalLight3D.new()
	sun.name = "SoftRoomFill"
	sun.light_energy = 0.1
	sun.light_color = Color(0.95, 0.88, 0.62)
	sun.rotation_degrees = Vector3(-62.0, -20.0, 0.0)
	add_child(sun)


func _make_materials() -> void:
	mat_floor = _textured_material(Color(0.96, 0.88, 0.62), _texture_or_pattern(TEXTURE_CARPET, "carpet", Color(0.72, 0.64, 0.43), Color(0.42, 0.37, 0.25)), 0.98, Vector3(9.5, 9.5, 1.0), _load_texture(TEXTURE_CARPET + "_normal.png"), _load_texture(TEXTURE_CARPET + "_roughness.png"), 0.28)
	mat_wall = _textured_material(Color(0.90, 0.86, 0.58), _texture_or_pattern(TEXTURE_WALL, "wallpaper", Color(0.84, 0.78, 0.45), Color(0.48, 0.54, 0.31)), 0.88, Vector3(2.8, 1.0, 1.0), _load_texture(TEXTURE_WALL + "_normal.png"), _load_texture(TEXTURE_WALL + "_roughness.png"), 0.28)
	mat_wall_dirty = _textured_material(Color(0.72, 0.67, 0.42), _texture_or_pattern(TEXTURE_WALL_DIRTY, "dirty_wall", Color(0.68, 0.63, 0.38), Color(0.24, 0.28, 0.17)), 0.94, Vector3(2.8, 1.0, 1.0), _load_texture(TEXTURE_WALL_DIRTY + "_normal.png"), _load_texture(TEXTURE_WALL_DIRTY + "_roughness.png"), 0.34)
	mat_ceiling = _textured_material(Color(0.88, 0.86, 0.74, 0.62), _texture_or_pattern(TEXTURE_CEILING, "ceiling", Color(0.84, 0.82, 0.67), Color(0.44, 0.44, 0.34)), 0.92, Vector3(1.0, 1.0, 1.0), _load_texture(TEXTURE_CEILING + "_normal.png"), _load_texture(TEXTURE_CEILING + "_roughness.png"), 0.18)
	mat_ceiling.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_light = StandardMaterial3D.new()
	mat_light.albedo_color = Color(0.98, 0.98, 0.80)
	mat_light.emission_enabled = true
	mat_light.emission = Color(0.98, 0.96, 0.72)
	mat_light.emission_energy_multiplier = 2.2
	mat_light.roughness = 0.32
	mat_column = _textured_material(Color(0.64, 0.60, 0.40), _texture_or_pattern(TEXTURE_WALL_DIRTY, "column", Color(0.61, 0.58, 0.37), Color(0.31, 0.34, 0.24)), 0.9, Vector3(1.6, 1.2, 1.0), _load_texture(TEXTURE_WALL_DIRTY + "_normal.png"), _load_texture(TEXTURE_WALL_DIRTY + "_roughness.png"), 0.22)
	mat_prop = StandardMaterial3D.new()
	mat_prop.albedo_color = Color(0.30, 0.25, 0.16)
	mat_prop.roughness = 0.88
	mat_dark = StandardMaterial3D.new()
	mat_dark.albedo_color = Color(0.055, 0.052, 0.04)
	mat_dark.roughness = 0.98
	mat_void = StandardMaterial3D.new()
	mat_void.albedo_color = Color(0.055, 0.054, 0.042)
	mat_void.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_void.roughness = 1.0
	mat_baseboard = StandardMaterial3D.new()
	mat_baseboard.albedo_color = Color(0.29, 0.25, 0.15)
	mat_baseboard.roughness = 0.9


func _load_texture(path: String) -> Texture2D:
	if FileAccess.file_exists(path):
		var image := Image.new()
		if image.load(path) == OK:
			image.generate_mipmaps()
			return ImageTexture.create_from_image(image)
	return null


func _texture_or_pattern(stem: String, kind: String, base: Color, accent: Color) -> Texture2D:
	var texture := _load_texture(stem + ".png")
	if texture:
		return texture
	return _pattern_texture(kind, base, accent)


func _textured_material(base: Color, texture: Texture2D, roughness: float, uv_scale := Vector3(2.2, 2.2, 1.0), normal_texture: Texture2D = null, roughness_texture: Texture2D = null, normal_scale := 0.25) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = base
	mat.albedo_texture = texture
	mat.roughness = roughness
	mat.uv1_scale = uv_scale
	mat.texture_repeat = true
	if normal_texture:
		mat.normal_enabled = true
		mat.normal_texture = normal_texture
		mat.normal_scale = normal_scale
	if roughness_texture:
		mat.roughness_texture = roughness_texture
	return mat


func _pattern_texture(kind: String, base: Color, accent: Color) -> ImageTexture:
	var image := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = abs(hash(kind))
	for x in 128:
		for y in 128:
			var noise: float = rng.randf_range(-0.04, 0.05)
			var pattern := 0.0
			if kind.contains("wall"):
				pattern = 0.18 if x % 24 < 2 else 0.0
				pattern += 0.10 if y % 38 < 2 else 0.0
				if (x + y * 2) % 31 < 2:
					pattern += 0.07
			elif kind == "carpet":
				pattern = 0.10 if (x + y) % 9 < 2 else 0.0
				pattern += 0.06 if y % 17 < 2 else 0.0
				if rng.randf() > 0.91:
					pattern += rng.randf_range(0.08, 0.28)
			elif kind == "ceiling":
				pattern = 0.22 if x % 32 < 2 or y % 32 < 2 else 0.0
			var dirt := rng.randf_range(0.12, 0.42) if rng.randf() > 0.955 else 0.0
			var color := base.lerp(accent, clamp(pattern + dirt + noise, 0.0, 1.0))
			color.a = base.a
			image.set_pixel(x, y, color)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


func _define_sections() -> void:
	section_defs = [
		{"id": "StartHall", "rect": Rect2(-84, -16, 22, 32), "connections": ["MainWest"], "corridor": false},
		{"id": "StorageRoom", "rect": Rect2(-82, -34, 18, 14), "connections": ["StartHall", "SouthWest"], "corridor": false},
		{"id": "MainWest", "rect": Rect2(-62, -4, 40, 8), "connections": ["StartHall", "MainMid", "NorthWest", "SouthWest", "TinyUtility"], "corridor": true},
		{"id": "TinyUtility", "rect": Rect2(-62, -18, 10, 14), "connections": ["MainWest"], "corridor": false},
		{"id": "MainMid", "rect": Rect2(-22, -4, 44, 8), "connections": ["MainWest", "MainEast", "NorthMid", "SouthMid"], "corridor": true},
		{"id": "MainEast", "rect": Rect2(22, -4, 40, 8), "connections": ["MainMid", "DangerCorridor", "NorthEast", "SouthEast"], "corridor": true},
		{"id": "NorthWest", "rect": Rect2(-54, 4, 26, 24), "connections": ["MainWest", "NorthMid"], "corridor": false},
		{"id": "NorthMid", "rect": Rect2(-28, 4, 28, 24), "connections": ["MainMid", "NorthWest", "NorthEast", "BigNorthOpen"], "corridor": false},
		{"id": "NorthEast", "rect": Rect2(0, 4, 30, 24), "connections": ["MainEast", "NorthMid", "NorthDanger", "BigNorthOpen"], "corridor": false},
		{"id": "NorthDanger", "rect": Rect2(30, 4, 28, 24), "connections": ["NorthEast", "DangerCorridor", "BigNorthOpen"], "corridor": false},
		{"id": "BigNorthOpen", "rect": Rect2(-28, 28, 66, 20), "connections": ["NorthMid", "NorthEast", "NorthDanger"], "corridor": false},
		{"id": "SouthWest", "rect": Rect2(-54, -32, 30, 28), "connections": ["MainWest", "StorageRoom", "SouthMid"], "corridor": false},
		{"id": "SouthMid", "rect": Rect2(-24, -32, 36, 28), "connections": ["MainMid", "SouthWest", "SouthEast", "NarrowSouthDeadEnd"], "corridor": false},
		{"id": "NarrowSouthDeadEnd", "rect": Rect2(-16, -42, 12, 10), "connections": ["SouthMid"], "corridor": false},
		{"id": "SouthEast", "rect": Rect2(12, -32, 38, 28), "connections": ["MainEast", "SouthMid", "ElectricalRoom"], "corridor": false},
		{"id": "ElectricalRoom", "rect": Rect2(52, -30, 14, 16), "connections": ["SouthEast"], "corridor": false},
		{"id": "DangerCorridor", "rect": Rect2(62, -4, 8, 38), "connections": ["MainEast", "NorthDanger", "ExitArea"], "corridor": true},
		{"id": "ExitArea", "rect": Rect2(70, 28, 22, 20), "connections": ["DangerCorridor"], "corridor": false},
	]


func _build_out_of_bounds_void() -> void:
	_add_box_to(void_root, "VoidFloor", Vector3(0.0, -0.22, 2.0), Vector3(230.0, 0.10, 130.0), mat_void, false, "void")
	_add_box_to(void_root, "VoidNorthMass", Vector3(0.0, 1.3, 62.0), Vector3(230.0, 2.8, 16.0), mat_void, true, "void")
	_add_box_to(void_root, "VoidSouthMass", Vector3(0.0, 1.3, -56.0), Vector3(230.0, 2.8, 16.0), mat_void, true, "void")
	_add_box_to(void_root, "VoidWestMass", Vector3(-98.0, 1.3, 0.0), Vector3(24.0, 2.8, 118.0), mat_void, true, "void")
	_add_box_to(void_root, "VoidEastMass", Vector3(104.0, 1.3, 0.0), Vector3(24.0, 2.8, 118.0), mat_void, true, "void")


func _build_sections_and_volumes() -> void:
	for def in section_defs:
		var id := String(def["id"])
		var rect := def["rect"] as Rect2
		var section: Node3D = RoomPrototypeSectionScript.new()
		section.name = id
		section.set("section_id", id)
		sections_root.add_child(section)
		sections[id] = section
		_add_section_floor(section, rect)
		if SHOW_CEILING:
			_add_section_ceiling(section, rect)
		_add_section_lights(section, rect, bool(def["corridor"]))
		_add_room_volume(id, rect, def["connections"], bool(def["corridor"]), section)

	_add_floor_extension("StorageRoom", Rect2(-78, -20, 8, 4))
	_add_floor_extension("ElectricalRoom", Rect2(50, -24, 2, 8))
	_add_floor_extension("ExitArea", Rect2(68, 28, 2, 6))


func _add_section_floor(section: Node3D, rect: Rect2) -> void:
	var center := _rect_center(rect)
	_add_box_to(section, "CarpetFloor", center + Vector3(0.0, -0.055, 0.0), Vector3(rect.size.x, 0.11, rect.size.y), mat_floor, true, "floor")
	for i in 4:
		var stain_x := rect.position.x + 3.0 + fmod(float(i * 11 + int(rect.position.x)), max(rect.size.x - 6.0, 1.0))
		var stain_z := rect.position.y + 3.0 + fmod(float(i * 7 + int(rect.position.y)), max(rect.size.y - 6.0, 1.0))
		var stain := _add_box_to(section, "CarpetStain_%d" % i, Vector3(stain_x, 0.008, stain_z), Vector3(2.4 + i * 0.35, 0.012, 1.0 + (i % 2) * 0.6), mat_wall_dirty, false, "floor")
		stain.rotation.y = deg_to_rad(float(i * 31))


func _add_floor_extension(section_id: String, rect: Rect2) -> void:
	var section := sections.get(section_id) as Node3D
	if not section:
		return
	_add_section_floor(section, rect)


func _add_section_ceiling(section: Node3D, rect: Rect2) -> void:
	var x_start := int(floor(rect.position.x / 4.0)) * 4
	var z_start := int(floor(rect.position.y / 4.0)) * 4
	var x_end := int(ceil((rect.position.x + rect.size.x) / 4.0)) * 4
	var z_end := int(ceil((rect.position.y + rect.size.y) / 4.0)) * 4
	for x in range(x_start, x_end, 4):
		for z in range(z_start, z_end, 4):
			var panel_mat := mat_ceiling.duplicate() as StandardMaterial3D
			var panel := _add_box_to(section, "CeilingTile", Vector3(float(x) + 2.0, WALL_HEIGHT + 0.05, float(z) + 2.0), Vector3(3.82, 0.045, 3.82), panel_mat, false, "ceiling")
			panel.set_meta("ceiling_piece", true)
			for child in panel.get_children():
				if child is MeshInstance3D:
					child.add_to_group("ceiling_piece")


func _add_section_lights(section: Node3D, rect: Rect2, is_corridor: bool) -> void:
	var spacing: float = 14.0 if is_corridor else 10.0
	var count: int = max(1, int(rect.size.x / spacing))
	for i in count:
		var x: float = rect.position.x + rect.size.x * (float(i) + 0.5) / float(count)
		var z: float = rect.position.y + rect.size.y * 0.5
		if not is_corridor:
			z = rect.position.y + 6.0 + fmod(float(i * 9), max(rect.size.y - 12.0, 1.0))
		_add_light_panel(section, "FluorescentPanel_%d" % i, Vector3(x, 0.0, z), is_corridor)


func _add_room_volume(id: String, rect: Rect2, connections: Array, is_corridor: bool, section: Node3D) -> void:
	var volume: Area3D = RoomVolumeScript.new()
	volume.name = id + "_RoomVolume"
	volume.set("room_id", id)
	var typed_connections: Array[String] = []
	for connection in connections:
		typed_connections.append(String(connection))
	volume.set("connected_rooms", typed_connections)
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


func _build_wall_network() -> void:
	# Start and side rooms.
	_add_wall_h("StartHall", "Start_North", -84, -62, 16, [])
	_add_wall_h("StartHall", "Start_South", -84, -62, -16, [Vector2(-78, -70)])
	_add_wall_v("StartHall", "Start_West", -84, -16, 16, [])
	_add_wall_v("StartHall", "Start_East", -62, -16, 16, [Vector2(-4, 4)])
	_add_wall_h("StorageRoom", "Storage_North", -82, -64, -20, [Vector2(-78, -70)])
	_add_wall_h("StorageRoom", "Storage_South", -82, -64, -34, [])
	_add_wall_v("StorageRoom", "Storage_West", -82, -34, -20, [])
	_add_wall_v("StorageRoom", "Storage_East", -64, -34, -20, [Vector2(-30, -24)])
	_add_wall_v("StorageRoom", "StorageConnector_Left", -78, -20, -16, [])
	_add_wall_v("StorageRoom", "StorageConnector_Right", -70, -20, -16, [])

	# Main corridor split into sections; openings are at least 12m wide and snap to grid.
	_add_wall_h("MainWest", "MainWest_North", -62, -22, 4, [Vector2(-54, -42)])
	_add_wall_h("MainWest", "MainWest_South", -62, -22, -4, [Vector2(-60, -54), Vector2(-52, -36)])
	_add_wall_h("TinyUtility", "TinyUtility_North", -62, -52, -4, [Vector2(-60, -54)])
	_add_wall_h("TinyUtility", "TinyUtility_South", -62, -52, -18, [])
	_add_wall_v("TinyUtility", "TinyUtility_West", -62, -18, -4, [])
	_add_wall_v("TinyUtility", "TinyUtility_East", -52, -18, -4, [])
	_add_wall_h("MainMid", "MainMid_North", -22, 22, 4, [Vector2(-18, -6)])
	_add_wall_h("MainMid", "MainMid_South", -22, 22, -4, [Vector2(-18, -4)])
	_add_wall_h("MainEast", "MainEast_North", 22, 62, 4, [Vector2(26, 40), Vector2(46, 56)])
	_add_wall_h("MainEast", "MainEast_South", 22, 62, -4, [Vector2(26, 44)])
	_add_wall_v("MainEast", "MainEast_East", 62, -4, 4, [Vector2(-4, 4)])

	# North repeated rooms.
	_add_wall_h("NorthWest", "North_North_A", -54, -28, 28, [])
	_add_wall_v("NorthWest", "North_West_A", -54, 4, 28, [])
	_add_wall_v("NorthWest", "North_Partition_A", -28, 4, 28, [Vector2(14, 20)])
	_add_wall_h("NorthMid", "North_North_B", -28, 0, 28, [Vector2(-18, -8)])
	_add_wall_v("NorthMid", "North_Partition_B", 0, 4, 28, [Vector2(10, 18)])
	_add_wall_h("NorthEast", "North_North_C", 0, 30, 28, [Vector2(8, 20)])
	_add_wall_v("NorthEast", "North_Partition_C", 30, 4, 28, [Vector2(14, 22)])
	_add_wall_h("NorthDanger", "North_North_D", 30, 58, 28, [Vector2(32, 36), Vector2(44, 50)])
	_add_wall_v("NorthDanger", "North_East_D", 58, 4, 28, [Vector2(14, 22)])
	_add_wall_h("BigNorthOpen", "BigNorth_South", -28, 38, 28, [Vector2(-18, -8), Vector2(8, 20), Vector2(32, 36)])
	_add_wall_h("BigNorthOpen", "BigNorth_North", -28, 38, 48, [Vector2(14, 22)])
	_add_wall_v("BigNorthOpen", "BigNorth_West", -28, 28, 48, [])
	_add_wall_v("BigNorthOpen", "BigNorth_East", 38, 28, 48, [])
	_add_wall_v("BigNorthOpen", "BigNorth_OffsetDivider_A", -4, 30, 44, [Vector2(34, 38)])
	_add_wall_h("BigNorthOpen", "BigNorth_OffsetDivider_B", 12, 34, 39, [Vector2(18, 24)])

	# South open halls and loop.
	_add_wall_h("SouthWest", "South_South_A", -54, -24, -32, [])
	_add_wall_v("SouthWest", "South_West_A", -54, -32, -4, [])
	_add_wall_v("SouthWest", "South_Partition_A", -24, -32, -4, [Vector2(-24, -18)])
	_add_wall_h("SouthWest", "SouthWest_PocketWall", -50, -34, -16, [Vector2(-43, -38)])
	_add_wall_h("SouthMid", "South_South_B", -24, 12, -32, [Vector2(-10, -4)])
	_add_wall_h("NarrowSouthDeadEnd", "NarrowDead_North", -16, -4, -32, [Vector2(-10, -4)])
	_add_wall_h("NarrowSouthDeadEnd", "NarrowDead_South", -16, -4, -42, [])
	_add_wall_v("NarrowSouthDeadEnd", "NarrowDead_West", -16, -42, -32, [])
	_add_wall_v("NarrowSouthDeadEnd", "NarrowDead_East", -4, -42, -32, [])
	_add_wall_v("SouthMid", "South_Partition_B", 12, -32, -4, [Vector2(-28, -20)])
	_add_wall_h("SouthEast", "South_South_C", 12, 50, -32, [])
	_add_wall_v("SouthEast", "South_East_C", 50, -32, -4, [Vector2(-24, -18)])
	_add_wall_v("SouthEast", "SouthEast_LongDivider", 28, -30, -12, [Vector2(-24, -18)])
	_add_wall_v("ElectricalRoom", "Electrical_West", 52, -30, -14, [Vector2(-24, -18)])
	_add_wall_v("ElectricalRoom", "Electrical_East", 66, -30, -14, [])
	_add_wall_h("ElectricalRoom", "Electrical_North", 52, 66, -14, [])
	_add_wall_h("ElectricalRoom", "Electrical_South", 52, 66, -30, [])

	# Danger corridor and exit.
	_add_wall_v("DangerCorridor", "Danger_West", 62, -4, 34, [Vector2(-4, 4), Vector2(14, 22)])
	_add_wall_v("DangerCorridor", "Danger_East", 70, -4, 34, [Vector2(28, 34)])
	_add_wall_h("DangerCorridor", "Danger_South", 62, 70, -4, [Vector2(62, 68)])
	_add_wall_h("ExitArea", "Exit_North", 70, 92, 48, [])
	_add_wall_h("ExitArea", "Exit_South", 70, 92, 28, [Vector2(72, 82)])
	_add_wall_v("ExitArea", "Exit_East", 92, 28, 48, [])
	_add_wall_v("ExitArea", "Exit_West", 70, 28, 48, [Vector2(28, 34)])

	_add_wall_caps_and_columns()


func _build_edge_disguises() -> void:
	# Fake extensions are collision blockers, but the line-of-sight fog now hides them.
	_add_box_to(void_root, "FakeWestCorridorDark", Vector3(-94, 1.2, 0), Vector3(12, 2.6, 5.5), mat_void, true, "void")
	_add_box_to(void_root, "FakeNorthTurnDark", Vector3(48, 1.2, 40), Vector3(6, 2.6, 14), mat_void, true, "void")
	_add_box_to(void_root, "BigNorthFakeDark", Vector3(18, 1.2, 56), Vector3(10, 2.6, 8), mat_void, true, "void")
	_add_box_to(void_root, "FakeExitBeyondDark", Vector3(82, 1.2, 60), Vector3(14, 2.6, 12), mat_void, true, "void")
	_instance_scene(DoorBlockedScene, "BlockedWestFakeDoor", Vector3(-84, 0, 7), deg_to_rad(90), sections["StartHall"])
	_instance_scene(DoorBlockedScene, "BlockedNorthFakeDoor", Vector3(47, 0, 28), 0.0, sections["NorthDanger"])
	_instance_scene(DoorBlockedScene, "BlockedSouthFakeDoor", Vector3(-7, 0, -32), 0.0, sections["SouthMid"])


func _build_props_and_details() -> void:
	_add_columns_in_section("StartHall", [Vector3(-78, 0, -10), Vector3(-68, 0, 10)])
	_add_columns_in_section("MainWest", [Vector3(-50, 0, 0), Vector3(-35, 0, 0)])
	_add_columns_in_section("TinyUtility", [Vector3(-58, 0, -14)])
	_add_columns_in_section("MainMid", [Vector3(-8, 0, 0), Vector3(12, 0, 0)])
	_add_columns_in_section("MainEast", [Vector3(34, 0, 0), Vector3(52, 0, 0)])
	_add_columns_in_section("NorthMid", [Vector3(-12, 0, 20)])
	_add_columns_in_section("NorthDanger", [Vector3(44, 0, 16)])
	_add_columns_in_section("BigNorthOpen", [Vector3(-16, 0, 40), Vector3(4, 0, 36), Vector3(26, 0, 42)])
	_add_columns_in_section("SouthWest", [Vector3(-44, 0, -22)])
	_add_columns_in_section("SouthMid", [Vector3(0, 0, -18)])
	_add_columns_in_section("SouthEast", [Vector3(32, 0, -22)])

	_add_table("StorageRoom", Vector3(-72, 0, -28), 0.25)
	_add_shelf("StorageRoom", Vector3(-66.5, 0, -29.8), deg_to_rad(90))
	_add_table("TinyUtility", Vector3(-57, 0, -12), 0.0)
	_add_table("SouthWest", Vector3(-42, 0, -20), -0.4)
	_add_shelf("NarrowSouthDeadEnd", Vector3(-13, 0, -38), deg_to_rad(90))
	_add_table("SouthEast", Vector3(34, 0, -22), 0.15)
	_add_shelf("ElectricalRoom", Vector3(63, 0, -27), 0.0)
	_add_pipe_run("ElectricalRoom", Vector3(52.2, 1.85, -24), 7.0, true)
	_add_pipe_run("ElectricalRoom", Vector3(58, 2.05, -14.2), 6.0, false)


func _spawn_gameplay() -> void:
	var player := PlayerScene.instantiate()
	player.name = "Player"
	player.position = Vector3(-74.0, 0.0, 0.0)
	add_child(player)

	var fuse1 := FuseScene.instantiate()
	fuse1.name = "Fuse_Storage"
	fuse1.fuse_name = "Fuse A"
	fuse1.position = Vector3(-66.5, 1.2, -29.8)
	_mark_detail(fuse1)
	sections["StorageRoom"].add_child(fuse1)

	var fuse2 := FuseScene.instantiate()
	fuse2.name = "Fuse_SouthHall"
	fuse2.fuse_name = "Fuse B"
	fuse2.position = Vector3(-42.0, 0.95, -20.0)
	_mark_detail(fuse2)
	sections["SouthWest"].add_child(fuse2)

	var fuse3 := FuseScene.instantiate()
	fuse3.name = "Fuse_Danger"
	fuse3.fuse_name = "Fuse C"
	fuse3.position = Vector3(43.0, 0.75, 16.0)
	_mark_detail(fuse3)
	sections["NorthDanger"].add_child(fuse3)

	var panel := ElectricalPanelScene.instantiate()
	panel.name = "ElectricalPanel"
	panel.position = Vector3(52.25, 1.1, -22.0)
	panel.rotation.y = deg_to_rad(90.0)
	_mark_detail(panel)
	sections["ElectricalRoom"].add_child(panel)

	var exit := ExitDoorScene.instantiate()
	exit.name = "ExitDoor"
	exit.position = Vector3(82.0, 0.0, 47.8)
	_mark_detail(exit)
	sections["ExitArea"].add_child(exit)

	var shadow := ShadowScene.instantiate()
	shadow.name = "ShadowEntity"
	shadow.position = Vector3(64.5, 0.0, 9.0)
	add_child(shadow)

	var storage_door := _instance_scene(DoorOpenableScene, "StorageDoor", Vector3(-74.0, 0.0, -20.0), 0.0, sections["StorageRoom"])
	_mark_connection_door(storage_door, "StartHall", "StorageRoom")
	var electrical_door := _instance_scene(DoorOpenableScene, "ElectricalDoor", Vector3(52.0, 0.0, -21.0), deg_to_rad(90.0), sections["ElectricalRoom"])
	_mark_connection_door(electrical_door, "SouthEast", "ElectricalRoom")
	var locked_north_door := _instance_scene(DoorLockedScene, "LockedNorthDoor", Vector3(15.0, 0.0, 28.0), 0.0, sections["NorthEast"])
	_mark_connection_door(locked_north_door, "NorthEast", "BigNorthOpen")


func _add_visibility_and_wall_fade() -> void:
	var fog := RoomPrototypeManagerScript.new()
	fog.name = "RoomPrototypeFogManager"
	add_child(fog)
	if SHOW_CEILING:
		var ceiling_cutaway := CeilingCutawayScript.new()
		ceiling_cutaway.name = "CeilingCutaway"
		add_child(ceiling_cutaway)


func _add_wall_caps_and_columns() -> void:
	var points := [
		Vector3(-62, 0, -4), Vector3(-62, 0, 4), Vector3(-54, 0, 4), Vector3(-42, 0, 4),
		Vector3(-28, 0, 14), Vector3(0, 0, 10), Vector3(30, 0, 14), Vector3(62, 0, 4),
		Vector3(-4, 0, 30), Vector3(-4, 0, 44), Vector3(12, 0, 39), Vector3(34, 0, 39),
		Vector3(-50, 0, -16), Vector3(-34, 0, -16), Vector3(28, 0, -30), Vector3(28, 0, -12),
		Vector3(-24, 0, -24), Vector3(12, 0, -20), Vector3(50, 0, -24), Vector3(70, 0, 28)
	]
	for i in points.size():
		var section_id := "MainMid"
		if points[i].x < -60:
			section_id = "StartHall"
		elif points[i].z > 8:
			section_id = "NorthDanger" if points[i].x > 20 else "NorthMid"
		elif points[i].z < -8:
			section_id = "SouthEast" if points[i].x > 20 else "SouthMid"
		_add_box_to(sections[section_id], "CornerPillar_%02d" % i, points[i] + Vector3(0, WALL_HEIGHT * 0.5, 0), Vector3(0.58, WALL_HEIGHT, 0.58), mat_column, true, "wall")


func _add_columns_in_section(section_id: String, points: Array[Vector3]) -> void:
	for i in points.size():
		_add_box_to(sections[section_id], "Pillar_%02d" % i, points[i] + Vector3(0.0, WALL_HEIGHT * 0.5, 0.0), Vector3(0.72, WALL_HEIGHT, 0.72), mat_column, true, "wall")


func _add_wall_h(section_id: String, node_name: String, x1: float, x2: float, z: float, openings: Array[Vector2]) -> void:
	var sorted := openings.duplicate()
	sorted.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	var cursor := x1
	for opening in sorted:
		_add_wall_h_segment(section_id, node_name, cursor, opening.x, z)
		cursor = opening.y
	_add_wall_h_segment(section_id, node_name, cursor, x2, z)


func _add_wall_v(section_id: String, node_name: String, x: float, z1: float, z2: float, openings: Array[Vector2]) -> void:
	var sorted := openings.duplicate()
	sorted.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	var cursor := z1
	for opening in sorted:
		_add_wall_v_segment(section_id, node_name, x, cursor, opening.x)
		cursor = opening.y
	_add_wall_v_segment(section_id, node_name, x, cursor, z2)


func _add_wall_h_segment(section_id: String, node_name: String, x1: float, x2: float, z: float) -> void:
	var length := x2 - x1
	if length < 1.2:
		return
	var mat := mat_wall_dirty if int(abs(x1 + z)) % 4 == 0 else mat_wall
	_add_box_to(sections[section_id], node_name, Vector3((x1 + x2) * 0.5, WALL_HEIGHT * 0.5, z), Vector3(length, WALL_HEIGHT, WALL_THICKNESS), mat, true, "wall")
	_add_baseboard_h(section_id, x1, x2, z)


func _add_wall_v_segment(section_id: String, node_name: String, x: float, z1: float, z2: float) -> void:
	var length := z2 - z1
	if length < 1.2:
		return
	var mat := mat_wall_dirty if int(abs(x + z1)) % 4 == 0 else mat_wall
	_add_box_to(sections[section_id], node_name, Vector3(x, WALL_HEIGHT * 0.5, (z1 + z2) * 0.5), Vector3(WALL_THICKNESS, WALL_HEIGHT, length), mat, true, "wall")
	_add_baseboard_v(section_id, x, z1, z2)


func _add_baseboard_h(section_id: String, x1: float, x2: float, z: float) -> void:
	var length := x2 - x1
	_add_box_to(sections[section_id], "Baseboard", Vector3((x1 + x2) * 0.5, 0.16, z - WALL_THICKNESS * 0.55), Vector3(length, 0.16, 0.08), mat_baseboard, false, "wall")
	_add_box_to(sections[section_id], "Baseboard", Vector3((x1 + x2) * 0.5, 0.16, z + WALL_THICKNESS * 0.55), Vector3(length, 0.16, 0.08), mat_baseboard, false, "wall")


func _add_baseboard_v(section_id: String, x: float, z1: float, z2: float) -> void:
	var length := z2 - z1
	_add_box_to(sections[section_id], "Baseboard", Vector3(x - WALL_THICKNESS * 0.55, 0.16, (z1 + z2) * 0.5), Vector3(0.08, 0.16, length), mat_baseboard, false, "wall")
	_add_box_to(sections[section_id], "Baseboard", Vector3(x + WALL_THICKNESS * 0.55, 0.16, (z1 + z2) * 0.5), Vector3(0.08, 0.16, length), mat_baseboard, false, "wall")


func _add_light_panel(section: Node3D, node_name: String, position_xz: Vector3, along_x: bool) -> void:
	var size := Vector3(2.4, 0.06, 1.15) if along_x else Vector3(1.15, 0.06, 2.4)
	_add_box_to(section, node_name, Vector3(position_xz.x, WALL_HEIGHT + 0.02, position_xz.z), size, mat_light, false, "light_mesh")
	var light := OmniLight3D.new()
	light.name = node_name + "_Light"
	light.add_to_group("fluorescent_light")
	light.light_color = Color(0.98, 0.96, 0.74)
	light.light_energy = 1.42
	light.omni_range = 10.0
	light.position = Vector3(position_xz.x, WALL_HEIGHT - 0.22, position_xz.z)
	section.add_child(light)


func _add_table(section_id: String, position: Vector3, yaw: float) -> void:
	var table := Node3D.new()
	table.name = "OldTable"
	table.position = position
	table.rotation.y = yaw
	_mark_detail(table)
	sections[section_id].add_child(table)
	_add_box_to(table, "Top", Vector3(0.0, 0.72, 0.0), Vector3(1.75, 0.12, 0.85), mat_prop, true, "detail")
	for x in [-0.7, 0.7]:
		for z in [-0.32, 0.32]:
			_add_box_to(table, "Leg", Vector3(x, 0.35, z), Vector3(0.11, 0.7, 0.11), mat_prop, true, "detail")


func _add_shelf(section_id: String, position: Vector3, yaw: float) -> void:
	var shelf := Node3D.new()
	shelf.name = "MetalShelf"
	shelf.position = position
	shelf.rotation.y = yaw
	_mark_detail(shelf)
	sections[section_id].add_child(shelf)
	_add_box_to(shelf, "Back", Vector3(0.0, 0.9, 0.0), Vector3(1.35, 1.8, 0.12), mat_dark, true, "detail")
	for y in [0.35, 0.85, 1.35]:
		_add_box_to(shelf, "Shelf", Vector3(0.0, y, -0.18), Vector3(1.35, 0.08, 0.55), mat_prop, true, "detail")


func _add_pipe_run(section_id: String, position: Vector3, length: float, vertical_wall: bool) -> void:
	var pipe_mat := StandardMaterial3D.new()
	pipe_mat.albedo_color = Color(0.16, 0.17, 0.15)
	pipe_mat.metallic = 0.25
	pipe_mat.roughness = 0.72
	var size := Vector3(0.09, 0.09, length) if vertical_wall else Vector3(length, 0.09, 0.09)
	_add_box_to(sections[section_id], "OldPipe", position, size, pipe_mat, false, "detail")


func _instance_scene(scene: PackedScene, node_name: String, position: Vector3, yaw: float, parent: Node) -> Node3D:
	var node := scene.instantiate() as Node3D
	node.name = node_name
	node.position = position
	node.rotation.y = yaw
	_mark_detail(node)
	parent.add_child(node)
	return node


func _mark_connection_door(node: Node3D, room_a: String, room_b: String) -> void:
	node.add_to_group("fog_connection_door")
	node.set_meta("room_a", room_a)
	node.set_meta("room_b", room_b)


func _mark_detail(node: Node) -> void:
	if node is Node3D:
		(node as Node3D).set_meta("fog_role", "detail")
		(node as Node3D).add_to_group("fog_detail")
	for child in node.get_children():
		_mark_detail(child)


func _rect_center(rect: Rect2) -> Vector3:
	return Vector3(rect.position.x + rect.size.x * 0.5, 0.0, rect.position.y + rect.size.y * 0.5)


func _add_box_to(parent: Node, node_name: String, position: Vector3, size: Vector3, material: Material, collision: bool, role: String) -> Node3D:
	var container: Node3D = StaticBody3D.new() if collision else Node3D.new()
	container.name = node_name
	container.position = position
	container.set_meta("fog_role", role)
	if role == "wall":
		container.add_to_group("camera_fade_wall")
		container.add_to_group("prototype_foreground_wall")
		container.add_to_group("prototype_los_blocker")
	elif role == "light":
		container.add_to_group("fog_light")
	parent.add_child(container)
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	mesh_instance.set_meta("fog_role", role)
	container.add_child(mesh_instance)
	if collision:
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size
		shape.shape = box
		container.add_child(shape)
	return container
