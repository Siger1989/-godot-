extends RefCounted

const RoomModuleScript = preload("res://scripts/scene/RoomModule.gd")
const PortalComponentScript = preload("res://scripts/scene/PortalComponent.gd")
const MarkerComponentScript = preload("res://scripts/scene/MarkerComponent.gd")
const DoorFrameVisualScript = preload("res://scripts/scene/DoorFrameVisual.gd")
const WallOpeningBodyScript = preload("res://scripts/scene/WallOpeningBody.gd")
const GeneratedMeshRules = preload("res://scripts/scene/GeneratedMeshRules.gd")
const ContactShadowMaterial = preload("res://scripts/visual/ContactShadowMaterial.gd")
const RedAlarmAttractorScript = preload("res://scripts/gameplay/RedAlarmAttractor.gd")
const WallMaterial = preload("res://materials/backrooms_wall.tres")
const FloorMaterial = preload("res://materials/backrooms_floor.tres")
const CeilingMaterial = preload("res://materials/backrooms_ceiling.tres")
const DoorFrameMaterial = preload("res://materials/backrooms_door_frame.tres")
const CeilingLightMaterial = preload("res://materials/backrooms_ceiling_light.tres")
const KeyedExitDoorScene = preload("res://assets/backrooms/props/doors/OldOfficeDoor_A.tscn")
const EscapeKeyPickupScene = preload("res://scenes/modules/EscapeKeyPickup.tscn")

const GUIDANCE_ARROW_TEXTURES := [
	preload("res://assets/backrooms/decals/graffiti_arrows/GraffitiArrow_01.png"),
	preload("res://assets/backrooms/decals/graffiti_arrows/GraffitiArrow_02.png"),
	preload("res://assets/backrooms/decals/graffiti_arrows/GraffitiArrow_03.png"),
	preload("res://assets/backrooms/decals/graffiti_arrows/GraffitiArrow_04.png"),
	preload("res://assets/backrooms/decals/graffiti_arrows/GraffitiArrow_05.png"),
	preload("res://assets/backrooms/decals/graffiti_arrows/GraffitiArrow_06.png"),
]

const PROP_SCENES := {
	"Box_Small_A": preload("res://assets/backrooms/props/boxes/Box_Small_A.tscn"),
	"Box_Medium_A": preload("res://assets/backrooms/props/boxes/Box_Medium_A.tscn"),
	"Box_Stack_2_A": preload("res://assets/backrooms/props/boxes/Box_Stack_2_A.tscn"),
	"Box_Stack_3_A": preload("res://assets/backrooms/props/boxes/Box_Stack_3_A.tscn"),
	"Bucket_A": preload("res://assets/backrooms/props/cleaning/Bucket_A.tscn"),
	"Mop_A": preload("res://assets/backrooms/props/cleaning/Mop_A.tscn"),
	"CleaningClothPile_A": preload("res://assets/backrooms/props/cleaning/CleaningClothPile_A.tscn"),
	"Chair_Old_A": preload("res://assets/backrooms/props/furniture/Chair_Old_A.tscn"),
	"SmallCabinet_A": preload("res://assets/backrooms/props/furniture/SmallCabinet_A.tscn"),
	"MetalShelf_A": preload("res://assets/backrooms/props/furniture/MetalShelf_A.tscn"),
	"HideLocker_A": preload("res://assets/backrooms/props/furniture/HideLocker_A.tscn"),
	"ElectricBox_A": preload("res://assets/backrooms/props/industrial/ElectricBox_A.tscn"),
	"Vent_Wall_A": preload("res://assets/backrooms/props/industrial/Vent_Wall_A.tscn"),
	"Pipe_Straight_A": preload("res://assets/backrooms/props/industrial/Pipe_Straight_A.tscn"),
	"Pipe_Corner_A": preload("res://assets/backrooms/props/industrial/Pipe_Corner_A.tscn"),
}

const WALL_PROP_IDS := {
	"ElectricBox_A": true,
	"Vent_Wall_A": true,
	"Pipe_Straight_A": true,
	"Pipe_Corner_A": true,
}
const PROC_PROP_MAX_FLOOR := 22
const PROC_PROP_MAX_WALL := 18
const PROC_PROP_MAX_HIDEABLE := 3
const FLOOR_PROP_WALL_INSET := 0.62
const WALL_PROP_FACE_INSET := 0.12
const GUIDANCE_GRAFFITI_MAX := 14
const GUIDANCE_GRAFFITI_DOOR_SIDE_OFFSET := 1.20
const GUIDANCE_GRAFFITI_WALL_OFFSET := 0.24
const GUIDANCE_GRAFFITI_Y := 1.36
const GUIDANCE_GRAFFITI_BASE_SIZE := Vector2(0.74, 0.37)
const GUIDANCE_GRAFFITI_COLOR_STEPS := 8
const GUIDANCE_GRAFFITI_COLD_COLOR := Color(0.30, 0.50, 0.78, 0.78)
const GUIDANCE_GRAFFITI_HOT_COLOR := Color(1.0, 0.16, 0.08, 0.84)

const CELL_SIZE := 2.5
const WALL_HEIGHT := 2.55
const WALL_THICKNESS := 0.2
const WALL_Y := WALL_HEIGHT * 0.5
const WALL_UV_WORLD_SIZE := 6.0
const WALL_VISUAL_VERTICAL_OVERLAP := 0.025
const WALL_CORNER_VISUAL_CLEARANCE := 0.01
const WALL_CORNER_VISUAL_OVERLAP := WALL_THICKNESS * 0.5 - WALL_CORNER_VISUAL_CLEARANCE
const DOOR_OPENING_WIDTH := 1.15
const DOOR_FRAME_TRIM_WIDTH := 0.10
const DOOR_FRAME_DEPTH := WALL_THICKNESS - 0.04
const DOOR_FRAME_OUTER_HEIGHT := 2.18
const DOOR_CLEARANCE_HEIGHT := 2.15
const WALL_HEADER_OVERLAP := 0.02
const WALL_OPENING_HEIGHT := DOOR_FRAME_OUTER_HEIGHT - WALL_HEADER_OVERLAP
const DOOR_REVEAL_DEPTH := 1.10
const DOOR_REVEAL_WIDTH := DOOR_OPENING_WIDTH + DOOR_FRAME_TRIM_WIDTH * 2.0 + 0.80
const DOOR_REVEAL_TRIM_CLEARANCE := 0.12
const MIN_INTERNAL_WALL_SEGMENT := 0.35
const FLOOR_THICKNESS := 0.1
const FLOOR_Y := -0.05
const FLOOR_COLLISION_THICKNESS := 0.12
const FLOOR_UV_WORLD_SIZE := 12.0
const CEILING_THICKNESS := 0.1
const CEILING_Y := WALL_HEIGHT + CEILING_THICKNESS * 0.5
const CEILING_LIGHT_PANEL_SIZE := Vector3(1.2, 0.08, 0.7)
const CEILING_LIGHT_PANEL_Y := WALL_HEIGHT - CEILING_LIGHT_PANEL_SIZE.y * 0.5 + 0.01
const CEILING_LIGHT_Y := WALL_HEIGHT - 0.26
const CEILING_LIGHT_ENERGY := 1.05
const CEILING_LIGHT_RANGE := 3.85
const CEILING_LIGHT_ATTENUATION := 1.65
const CEILING_LIGHT_DISTRIBUTED_MIN_LENGTH := 1.75
const CEILING_LIGHT_SOURCE_SPACING := 1.45
const CEILING_LIGHT_SOURCE_END_MARGIN := 0.55
const CEILING_LIGHT_MAX_SOURCES := 4
const CEILING_LIGHT_DISTRIBUTED_TOTAL_ENERGY_MULTIPLIER := 1.22
const CEILING_LIGHT_DISTRIBUTED_RANGE := 3.05
const CEILING_LIGHT_DISTRIBUTED_ATTENUATION := 1.75
const CEILING_LIGHT_SHADOW_BIAS := 0.02
const CEILING_LIGHT_SHADOW_NORMAL_BIAS := 0.35
const CEILING_LIGHT_SHADOW_OPACITY := 1.0
const CEILING_LIGHT_WALL_CLEARANCE := 0.16
const WORLD_AMBIENT_COLOR := Color(1.0, 0.9, 0.66)
const WORLD_AMBIENT_ENERGY := 0.028
const WORLD_BACKGROUND_COLOR := Color(0.015, 0.014, 0.012)
const INTERNAL_PASSAGE_WIDTH := 1.60
const STATIC_GEOMETRY_LAYER := 1 << 0
const ACTOR_LIGHT_LAYER := 1 << 8
const WALL_FLOOR_BITE := 0.02
const WALL_CONTACT_Y := WALL_Y - WALL_FLOOR_BITE
const LOW_WALL_HEIGHT := 1.05
const LOW_WALL_THICKNESS := 0.18
const LOW_WALL_Y := LOW_WALL_HEIGHT * 0.5 - WALL_FLOOR_BITE
const RED_ALARM_LIGHT_COLOR := Color(1.0, 0.08, 0.035)
const RED_ALARM_LIGHT_ENERGY := 2.85
const RED_ALARM_LIGHT_RANGE := 8.2
const RED_ALARM_LIGHT_ATTENUATION := 1.55

var include_ceilings := true
var include_ceiling_lights := true
var include_guidance_graffiti := false
var _surface_material_cache: Dictionary = {}
var _guidance_material_cache: Dictionary = {}
var _guidance_tinted_texture_cache: Dictionary = {}

func build(scene_root: Node3D, graph: Dictionary, registry) -> Dictionary:
	_surface_material_cache.clear()
	_guidance_material_cache.clear()
	_guidance_tinted_texture_cache.clear()
	var level_root = _get_or_create_node3d(scene_root, "LevelRoot")
	_clear_children(level_root)
	level_root.set_meta("proc_maze_seed", int(graph.get("seed", 0)))
	level_root.set_meta("generator_version", String(graph.get("generator_version", "")))

	var geometry_root = _get_or_create_node3d(level_root, "Geometry")
	var modules_root = _get_or_create_node3d(geometry_root, "Modules")
	var walls_root = _get_or_create_node3d(geometry_root, "Walls")
	var areas_root = _get_or_create_node3d(level_root, "Areas")
	var portals_root = _get_or_create_node3d(level_root, "Portals")
	var markers_root = _get_or_create_node3d(level_root, "Markers")
	var lights_root = _get_or_create_node3d(level_root, "Lights")
	var props_root = _get_or_create_node3d(level_root, "Props")
	var doors_root = _get_or_create_node3d(level_root, "Doors")
	var guidance_root = _get_or_create_node3d(level_root, "GuidanceGraffiti")

	_create_world_environment(lights_root)

	var nodes: Array = graph.get("nodes", [])
	var edges: Array = graph.get("edges", [])
	var node_map = _build_node_map(nodes)
	var adjacency = _build_adjacency(nodes, edges)
	var internal_opening_specs = _build_opening_specs(edges, node_map)
	var door_reveals_by_node = _build_door_reveals_by_node(internal_opening_specs, node_map)
	var keyed_exit_spec = _build_keyed_outer_exit_spec(nodes, node_map, internal_opening_specs)
	var opening_specs = internal_opening_specs.duplicate(true)
	if not keyed_exit_spec.is_empty():
		opening_specs[String(keyed_exit_spec.get("boundary_key", ""))] = keyed_exit_spec

	for node in nodes:
		var module_id = String(node.get("id", ""))
		_create_module(modules_root, areas_root, lights_root, node, adjacency, door_reveals_by_node.get(module_id, []))

	_create_boundary_walls(walls_root, node_map, opening_specs)
	_create_portals(portals_root, opening_specs, node_map)
	_create_markers(markers_root, node_map)
	var prop_summary := _create_proc_maze_props(props_root, nodes, opening_specs)
	var keyed_exit_summary := _create_keyed_outer_exit(doors_root, props_root, markers_root, nodes, node_map, keyed_exit_spec)
	var guidance_summary := {"total": 0}
	if include_guidance_graffiti:
		guidance_summary = _create_guidance_graffiti(guidance_root, nodes, edges, node_map, opening_specs)
	_create_overview_camera(scene_root, node_map)

	return {
		"module_count": nodes.size(),
		"portal_count": edges.size(),
		"opening_count": internal_opening_specs.size(),
		"keyed_exit_count": int(keyed_exit_summary.get("door", 0)),
		"escape_key_count": int(keyed_exit_summary.get("key", 0)),
		"prop_count": int(prop_summary.get("total", 0)),
		"floor_prop_count": int(prop_summary.get("floor", 0)),
		"wall_prop_count": int(prop_summary.get("wall", 0)),
		"feature_prop_count": int(prop_summary.get("feature", 0)),
		"hideable_prop_count": int(prop_summary.get("hideable", 0)),
		"guidance_graffiti_count": int(guidance_summary.get("total", 0)),
		"active_light_count": _get_nodes_in_group(level_root, "ceiling_light_panel").size(),
		"active_light_fixture_count": _get_nodes_in_group(level_root, "ceiling_light_panel").size(),
		"active_light_source_count": _get_nodes_in_group(level_root, "ceiling_light").size(),
	}

func _surface_material(kind: String) -> Material:
	if _surface_material_cache.has(kind):
		return _surface_material_cache[kind]
	var material: Material = null
	match kind:
		"wall":
			material = ContactShadowMaterial.make_wall(WallMaterial)
		"ceiling":
			material = ContactShadowMaterial.make_ceiling(CeilingMaterial)
		"door_frame":
			material = ContactShadowMaterial.make_door_frame(DoorFrameMaterial)
		_:
			material = WallMaterial
	_surface_material_cache[kind] = material
	return material

func _wall_material_instance(node_name: String, local_position: Vector3) -> Material:
	return ContactShadowMaterial.make_wall_instance(WallMaterial, _stable_grime_seed("%s:%s" % [node_name, str(local_position)]))

func _stable_grime_seed(text: String) -> float:
	var seed := 23
	for index in range(text.length()):
		seed = int((seed * 131 + text.unicode_at(index)) % 1000003)
	return float(seed)

func _create_module(modules_root: Node3D, areas_root: Node3D, lights_root: Node3D, node: Dictionary, adjacency: Dictionary, door_reveals: Array) -> void:
	var module_id = String(node["id"])
	var module_root = Node3D.new()
	module_root.name = "Module_%s_%s" % [module_id, String(node.get("module_id", ""))]
	module_root.add_to_group("proc_maze_module", true)
	module_root.set_meta("id", module_id)
	module_root.set_meta("module_id", String(node.get("module_id", "")))
	module_root.set_meta("scene_path", String(node.get("scene_path", "")))
	module_root.set_meta("type", String(node.get("type", "")))
	module_root.set_meta("space_kind", String(node.get("space_kind", "")))
	module_root.set_meta("room_signature", String(node.get("room_signature", "")))
	module_root.set_meta("feature_template", String(node.get("feature_template", "")))
	module_root.set_meta("dark_zone", String(node.get("dark_zone", "")))
	module_root.set_meta("red_alarm_extra", bool(node.get("red_alarm_extra", false)))
	module_root.set_meta("shape_cells", node.get("shape_cells", []))
	module_root.set_meta("area_id", String(node.get("area_id", "")))
	module_root.set_meta("footprint", node.get("footprint", {}))
	module_root.set_meta("rotation", int(node.get("rotation", 0)))
	module_root.set_meta("is_main_path", bool(node.get("is_main_path", false)))
	module_root.set_meta("is_hub", bool(node.get("is_hub", false)))
	module_root.set_meta("is_dead_end", bool(node.get("is_dead_end", false)))
	module_root.set_meta("is_long_corridor", bool(node.get("is_long_corridor", false)))
	module_root.set_meta("is_special", bool(node.get("is_special", false)))
	if not String(node.get("feature_template", "")).is_empty():
		module_root.add_to_group("proc_feature_anchor", true)
	if not String(node.get("dark_zone", "")).is_empty():
		module_root.add_to_group("proc_dark_zone", true)
	modules_root.add_child(module_root)

	var rect = _rect(node)
	var center = _node_center_world(node)
	var size = _rect_size_world(rect)
	module_root.position = Vector3(center.x, 0.0, center.z)

	_create_floor(module_root, "Floor_%s" % module_id, node, center)
	_create_floor_collision(module_root, "FloorCollision_%s" % module_id, node, center)
	if include_ceilings:
		_create_ceiling(module_root, "Ceiling_%s" % module_id, node, center, String(node.get("area_id", "")))
	_create_internal_structure(module_root, node, center, size, door_reveals)
	_create_feature_structure(module_root, lights_root, node, center, size)
	if bool(node.get("red_alarm_extra", false)) and String(node.get("feature_template", "")) != "red_alarm_hall":
		_create_red_alarm_feature(module_root, lights_root, module_id, center, size)
	_create_area_node(areas_root, node, adjacency.get(module_id, []))
	if include_ceiling_lights:
		var light_layout = _ceiling_light_layout(node, center, size)
		module_root.set_meta("has_ceiling_light", not light_layout.is_empty())
		module_root.set_meta("lighting_policy", "safe_ceiling_light" if not light_layout.is_empty() else _unlit_reason(node))
		if not light_layout.is_empty():
			_create_ceiling_light(module_root, lights_root, module_id, center, node, light_layout)

func _create_floor(parent: Node3D, node_name: String, node: Dictionary, center: Vector3) -> void:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	for cell in _occupied_cells(node):
		var x0 = float(cell.x) * CELL_SIZE
		var z0 = float(cell.y) * CELL_SIZE
		var x1 = float(cell.x + 1) * CELL_SIZE
		var z1 = float(cell.y + 1) * CELL_SIZE
		var a = Vector3(x0 - center.x, 0.0, z0 - center.z)
		var b = Vector3(x1 - center.x, 0.0, z0 - center.z)
		var c = Vector3(x1 - center.x, 0.0, z1 - center.z)
		var d = Vector3(x0 - center.x, 0.0, z1 - center.z)
		_append_quad(vertices, normals, uvs, a, b, c, d, Vector3.UP, _floor_uv_world(x0, z0), _floor_uv_world(x1, z0), _floor_uv_world(x1, z1), _floor_uv_world(x0, z1))
	var instance = MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = GeneratedMeshRules.build_array_mesh(vertices, normals, uvs, FloorMaterial)
	instance.material_override = FloorMaterial
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.layers = STATIC_GEOMETRY_LAYER
	instance.add_to_group("floor_visual", true)
	instance.add_to_group("proc_maze_generated", true)
	parent.add_child(instance)
	instance.position = Vector3(0.0, FLOOR_Y + FLOOR_THICKNESS * 0.5, 0.0)

func _create_floor_collision(parent: Node3D, node_name: String, node: Dictionary, center: Vector3) -> void:
	var body = StaticBody3D.new()
	body.name = node_name
	body.add_to_group("floor_collision", true)
	body.add_to_group("proc_maze_generated", true)
	parent.add_child(body)

	var index = 0
	for cell in _occupied_cells(node):
		var shape = BoxShape3D.new()
		shape.size = Vector3(CELL_SIZE, FLOOR_COLLISION_THICKNESS, CELL_SIZE)
		var collision = CollisionShape3D.new()
		collision.name = "Collision_%02d" % index
		collision.shape = shape
		body.add_child(collision)
		collision.position = Vector3((cell.x + 0.5) * CELL_SIZE - center.x, -FLOOR_COLLISION_THICKNESS * 0.5, (cell.y + 0.5) * CELL_SIZE - center.z)
		index += 1

func _create_ceiling(parent: Node3D, node_name: String, node: Dictionary, center: Vector3, area_id: String) -> void:
	var ceiling = StaticBody3D.new()
	ceiling.name = node_name
	ceiling.add_to_group("proc_maze_generated", true)
	parent.add_child(ceiling)
	ceiling.set_meta("area_id", area_id)
	ceiling.add_to_group("ceiling", true)
	ceiling.add_to_group("foreground_occluder", true)

	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var y = CEILING_Y - CEILING_THICKNESS * 0.5
	for cell in _occupied_cells(node):
		var x0 = float(cell.x) * CELL_SIZE
		var z0 = float(cell.y) * CELL_SIZE
		var x1 = float(cell.x + 1) * CELL_SIZE
		var z1 = float(cell.y + 1) * CELL_SIZE
		var a = Vector3(x0 - center.x, y, z1 - center.z)
		var b = Vector3(x1 - center.x, y, z1 - center.z)
		var c = Vector3(x1 - center.x, y, z0 - center.z)
		var d = Vector3(x0 - center.x, y, z0 - center.z)
		_append_quad(vertices, normals, uvs, a, b, c, d, Vector3.DOWN, _floor_uv_world(x0, z1), _floor_uv_world(x1, z1), _floor_uv_world(x1, z0), _floor_uv_world(x0, z0))
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "Mesh"
	mesh_instance.mesh = GeneratedMeshRules.build_array_mesh(vertices, normals, uvs, CeilingMaterial)
	mesh_instance.material_override = CeilingMaterial
	mesh_instance.layers = STATIC_GEOMETRY_LAYER
	mesh_instance.add_to_group("proc_maze_generated_mesh", true)
	ceiling.add_child(mesh_instance)

	var index = 0
	for cell in _occupied_cells(node):
		var shape = BoxShape3D.new()
		shape.size = Vector3(CELL_SIZE, CEILING_THICKNESS, CELL_SIZE)
		var collision = CollisionShape3D.new()
		collision.name = "Collision_%02d" % index
		collision.shape = shape
		collision.position = Vector3((cell.x + 0.5) * CELL_SIZE - center.x, CEILING_Y, (cell.y + 0.5) * CELL_SIZE - center.z)
		ceiling.add_child(collision)
		index += 1

func _create_internal_structure(parent: Node3D, node: Dictionary, center: Vector3, size: Vector2, door_reveals: Array) -> void:
	var module_id = String(node.get("id", ""))
	var wall_specs = _trim_internal_wall_specs_for_door_reveals(_internal_wall_specs(node, size), center, door_reveals)
	var index = 0
	for wall_spec in wall_specs:
		var suffix = String(wall_spec.get("suffix", "Part_%02d" % index))
		_create_internal_wall(parent, module_id, suffix, wall_spec["position"], wall_spec["size"])
		index += 1
	_create_internal_navigation_waypoints(parent, node, size)

func _create_internal_navigation_waypoints(parent: Node3D, node: Dictionary, size: Vector2) -> void:
	var module_id := String(node.get("id", ""))
	var index := 0
	for spec in _internal_navigation_waypoint_specs(node, size):
		var waypoint := Node3D.new()
		waypoint.name = "InternalNavWaypoint_%s_%02d" % [module_id, index]
		waypoint.position = spec.get("position", Vector3.ZERO)
		waypoint.set_meta("owner_module_id", module_id)
		waypoint.set_meta("area_id", String(node.get("area_id", "")))
		waypoint.set_meta("navigation_role", String(spec.get("role", "internal_passage")))
		waypoint.add_to_group("proc_internal_navigation_waypoint", true)
		waypoint.add_to_group("proc_maze_generated", true)
		parent.add_child(waypoint)
		index += 1

func _internal_navigation_waypoint_specs(node: Dictionary, size: Vector2) -> Array[Dictionary]:
	var module_type := String(node.get("module_id", ""))
	if module_type == "large_room_split_ns":
		var gap_center := -size.x * 0.16
		return [
			{"position": Vector3(gap_center, 0.05, 0.0), "role": "split_ns_inner_door"},
		]
	if module_type == "large_room_split_ew":
		var gap_center := size.y * 0.14
		return [
			{"position": Vector3(0.0, 0.05, gap_center), "role": "split_ew_inner_door"},
		]
	if module_type == "large_room_offset_inner_door":
		var offset := minf(size.y * 0.18, CELL_SIZE * 0.35)
		return [
			{"position": Vector3(0.0, 0.05, offset), "role": "offset_inner_door"},
		]
	return []

func _create_internal_wall(parent: Node3D, module_id: String, suffix: String, local_position: Vector3, size: Vector3) -> void:
	var wall_name = "InternalWall_%s_%s" % [module_id, suffix]
	var contact_position := _wall_contact_position(local_position)
	var wall = _create_box_body(parent, wall_name, contact_position, size, _wall_material_instance(wall_name, contact_position), true, false)
	wall.set_meta("owner_module_id", module_id)
	wall.set_meta("wall_height", WALL_HEIGHT)
	wall.set_meta("floor_bite_m", WALL_FLOOR_BITE)
	wall.add_to_group("proc_internal_wall", true)
	wall.add_to_group("foreground_occluder", true)

func _create_feature_structure(parent: Node3D, lights_parent: Node3D, node: Dictionary, center: Vector3, size: Vector2) -> void:
	var feature := String(node.get("feature_template", ""))
	var module_id := String(node.get("id", ""))
	match feature:
		"pillar_hall":
			var index := 0
			for pillar_spec in _feature_pillar_specs(size):
				var suffix := String(pillar_spec.get("suffix", "Pillar_%02d" % index))
				_create_feature_pillar(parent, module_id, feature, suffix, pillar_spec["position"], pillar_spec["size"])
				index += 1
		"low_wall_maze_hall":
			var index := 0
			for low_wall_spec in _feature_low_wall_specs(size):
				var suffix := String(low_wall_spec.get("suffix", "LowWall_%02d" % index))
				_create_feature_low_wall(parent, module_id, feature, suffix, low_wall_spec["position"], low_wall_spec["size"], String(low_wall_spec.get("module", "")))
				index += 1
		"red_alarm_hall":
			_create_red_alarm_feature(parent, lights_parent, module_id, center, size)
		_:
			return

func _create_feature_pillar(parent: Node3D, module_id: String, feature: String, suffix: String, local_position: Vector3, size: Vector3) -> void:
	var pillar_name := "FeaturePillar_%s_%s" % [module_id, suffix]
	var pillar := _create_box_body(parent, pillar_name, local_position, size, _wall_material_instance(pillar_name, local_position), true, false)
	pillar.set_meta("owner_module_id", module_id)
	pillar.set_meta("feature_template", feature)
	pillar.set_meta("wall_height", WALL_HEIGHT)
	pillar.set_meta("floor_bite_m", WALL_FLOOR_BITE)
	pillar.add_to_group("proc_feature_anchor_geometry", true)
	pillar.add_to_group("proc_feature_pillar", true)
	pillar.add_to_group("proc_internal_wall", true)
	pillar.add_to_group("foreground_occluder", true)

func _create_feature_low_wall(parent: Node3D, module_id: String, feature: String, suffix: String, local_position: Vector3, size: Vector3, low_wall_module: String) -> void:
	var wall_name := "FeatureLowWall_%s_%s" % [module_id, suffix]
	var wall := _create_box_body(parent, wall_name, local_position, size, _wall_material_instance(wall_name, local_position), true, true)
	wall.set_meta("owner_module_id", module_id)
	wall.set_meta("feature_template", feature)
	wall.set_meta("low_wall_module", low_wall_module)
	wall.set_meta("wall_height", LOW_WALL_HEIGHT)
	wall.set_meta("floor_bite_m", WALL_FLOOR_BITE)
	wall.add_to_group("proc_feature_anchor_geometry", true)
	wall.add_to_group("proc_feature_low_wall", true)
	wall.add_to_group("proc_half_wall", true)
	wall.add_to_group("foreground_occluder", true)

func _create_red_alarm_feature(parent: Node3D, lights_parent: Node3D, module_id: String, center: Vector3, size: Vector2) -> void:
	var local_position := Vector3(-size.x * 0.5 + 0.08, 1.62, -size.y * 0.18)
	var panel := MeshInstance3D.new()
	panel.name = "RedAlarmPanel_%s" % module_id
	var panel_mesh := BoxMesh.new()
	panel_mesh.size = Vector3(0.08, 0.24, 0.42)
	panel.mesh = panel_mesh
	panel.material_override = _red_alarm_material(false)
	panel.layers = STATIC_GEOMETRY_LAYER
	panel.set_meta("owner_module_id", module_id)
	panel.set_meta("feature_template", "red_alarm_hall")
	panel.add_to_group("proc_feature_anchor_geometry", true)
	panel.add_to_group("proc_red_alarm_panel", true)
	parent.add_child(panel)
	panel.position = local_position

	var light := OmniLight3D.new()
	light.name = "RedAlarmLight_%s" % module_id
	light.light_color = RED_ALARM_LIGHT_COLOR
	light.light_energy = 0.0
	light.visible = false
	light.omni_range = clampf(maxf(size.x, size.y) * 0.82, 6.2, RED_ALARM_LIGHT_RANGE)
	light.omni_attenuation = RED_ALARM_LIGHT_ATTENUATION
	light.shadow_enabled = true
	light.shadow_bias = CEILING_LIGHT_SHADOW_BIAS
	light.shadow_normal_bias = CEILING_LIGHT_SHADOW_NORMAL_BIAS
	light.shadow_opacity = 0.65
	light.light_cull_mask = STATIC_GEOMETRY_LAYER | ACTOR_LIGHT_LAYER
	light.shadow_caster_mask = STATIC_GEOMETRY_LAYER | ACTOR_LIGHT_LAYER
	light.set_meta("owner_module_id", module_id)
	light.set_meta("feature_template", "red_alarm_hall")
	light.set_meta("lighting_policy", "localized_red_alarm")
	light.set_meta("inactive_red_alarm_energy", 0.0)
	light.set_meta("active_red_alarm_energy", RED_ALARM_LIGHT_ENERGY)
	light.set_meta("active_red_alarm_range", light.omni_range)
	light.set_meta("active_red_alarm_attenuation", RED_ALARM_LIGHT_ATTENUATION)
	light.add_to_group("proc_red_alarm_light", true)
	lights_parent.add_child(light)
	light.position = center + local_position + Vector3(0.34, 0.0, 0.0)

	var attractor := Area3D.new()
	attractor.name = "RedAlarmAttractor_%s" % module_id
	attractor.set_script(RedAlarmAttractorScript)
	attractor.set_meta("owner_module_id", module_id)
	attractor.set_meta("feature_template", "red_alarm_hall")
	attractor.add_to_group("proc_red_alarm_attractor", true)
	parent.add_child(attractor)
	attractor.position = Vector3(0.0, 0.55, 0.0)

func _feature_pillar_specs(size: Vector2) -> Array[Dictionary]:
	var max_x := maxf(size.x * 0.5 - 0.72, 0.65)
	var max_z := maxf(size.y * 0.5 - 0.72, 0.65)
	var raw_specs: Array[Dictionary] = [
		{"suffix": "IrregularA", "offset": Vector2(-0.68, -0.52), "footprint": Vector2(0.46, 0.62)},
		{"suffix": "IrregularB", "offset": Vector2(0.38, -0.68), "footprint": Vector2(0.58, 0.46)},
		{"suffix": "IrregularC", "offset": Vector2(-0.16, 0.08), "footprint": Vector2(0.50, 0.50)},
		{"suffix": "IrregularD", "offset": Vector2(0.70, 0.42), "footprint": Vector2(0.48, 0.66)},
		{"suffix": "IrregularE", "offset": Vector2(-0.62, 0.68), "footprint": Vector2(0.62, 0.48)},
	]
	var result: Array[Dictionary] = []
	for spec in raw_specs:
		var offset: Vector2 = spec["offset"]
		var footprint: Vector2 = spec["footprint"]
		result.append({
			"suffix": String(spec["suffix"]),
			"position": Vector3(clampf(offset.x * max_x, -max_x, max_x), WALL_CONTACT_Y, clampf(offset.y * max_z, -max_z, max_z)),
			"size": Vector3(footprint.x, WALL_HEIGHT, footprint.y),
		})
	return result

func _feature_low_wall_specs(size: Vector2) -> Array[Dictionary]:
	var max_x := maxf(size.x * 0.5 - 0.9, 0.75)
	var max_z := maxf(size.y * 0.5 - 0.9, 0.75)
	var raw_specs: Array[Dictionary] = [
		{"suffix": "Straight", "module": "low_wall_straight", "position": Vector3(-max_x * 0.28, LOW_WALL_Y, -max_z * 0.36), "size": Vector3(2.65, LOW_WALL_HEIGHT, LOW_WALL_THICKNESS)},
		{"suffix": "Baffle", "module": "low_wall_baffle", "position": Vector3(max_x * 0.30, LOW_WALL_Y, -max_z * 0.05), "size": Vector3(LOW_WALL_THICKNESS, LOW_WALL_HEIGHT, 2.10)},
		{"suffix": "CornerA", "module": "low_wall_corner", "position": Vector3(-max_x * 0.48, LOW_WALL_Y, max_z * 0.28), "size": Vector3(LOW_WALL_THICKNESS, LOW_WALL_HEIGHT, 1.75)},
		{"suffix": "CornerB", "module": "low_wall_l_shape", "position": Vector3(-max_x * 0.29, LOW_WALL_Y, max_z * 0.50), "size": Vector3(1.55, LOW_WALL_HEIGHT, LOW_WALL_THICKNESS)},
		{"suffix": "Cluster", "module": "low_wall_cluster", "position": Vector3(max_x * 0.45, LOW_WALL_Y, max_z * 0.42), "size": Vector3(1.35, LOW_WALL_HEIGHT, LOW_WALL_THICKNESS)},
	]
	return raw_specs

func _red_alarm_material(active: bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.38, 0.025, 0.018) if active else Color(0.055, 0.045, 0.038)
	material.emission_enabled = active
	material.emission = RED_ALARM_LIGHT_COLOR if active else Color.BLACK
	material.emission_energy_multiplier = 2.2 if active else 0.0
	material.roughness = 0.72
	return material

func _wall_contact_position(position: Vector3) -> Vector3:
	return Vector3(position.x, position.y - WALL_FLOOR_BITE, position.z)

func _trim_internal_wall_specs_for_door_reveals(wall_specs: Array[Dictionary], center: Vector3, door_reveals: Array) -> Array[Dictionary]:
	if wall_specs.is_empty() or door_reveals.is_empty():
		return wall_specs

	var local_reveals: Array[Rect2] = []
	for reveal in door_reveals:
		var reveal_rect: Rect2 = reveal.get("rect", Rect2())
		if reveal_rect.size == Vector2.ZERO:
			continue
		local_reveals.append(Rect2(reveal_rect.position - Vector2(center.x, center.z), reveal_rect.size))
	if local_reveals.is_empty():
		return wall_specs

	var trimmed: Array[Dictionary] = wall_specs.duplicate(true)
	for reveal_rect in local_reveals:
		var next_specs: Array[Dictionary] = []
		for wall_spec in trimmed:
			next_specs.append_array(_trim_internal_wall_spec_for_reveal(wall_spec, reveal_rect))
		trimmed = next_specs
	return trimmed

func _trim_internal_wall_spec_for_reveal(wall_spec: Dictionary, reveal_rect: Rect2) -> Array[Dictionary]:
	var position: Vector3 = wall_spec["position"]
	var size: Vector3 = wall_spec["size"]
	var wall_rect = _local_xz_rect(position, Vector2(size.x, size.z))
	if not wall_rect.intersects(reveal_rect.grow(DOOR_REVEAL_TRIM_CLEARANCE), true):
		return [wall_spec]

	var result: Array[Dictionary] = []
	var base_suffix = String(wall_spec.get("suffix", "Trimmed"))
	if size.x >= size.z:
		var left_min = wall_rect.position.x
		var left_max = minf(wall_rect.end.x, reveal_rect.position.x - DOOR_REVEAL_TRIM_CLEARANCE)
		var right_min = maxf(wall_rect.position.x, reveal_rect.end.x + DOOR_REVEAL_TRIM_CLEARANCE)
		var right_max = wall_rect.end.x
		_append_horizontal_wall_segment(result, wall_spec, base_suffix + "_L", left_min, left_max)
		_append_horizontal_wall_segment(result, wall_spec, base_suffix + "_R", right_min, right_max)
	else:
		var near_min = wall_rect.position.y
		var near_max = minf(wall_rect.end.y, reveal_rect.position.y - DOOR_REVEAL_TRIM_CLEARANCE)
		var far_min = maxf(wall_rect.position.y, reveal_rect.end.y + DOOR_REVEAL_TRIM_CLEARANCE)
		var far_max = wall_rect.end.y
		_append_vertical_wall_segment(result, wall_spec, base_suffix + "_A", near_min, near_max)
		_append_vertical_wall_segment(result, wall_spec, base_suffix + "_B", far_min, far_max)
	return result

func _append_horizontal_wall_segment(result: Array[Dictionary], wall_spec: Dictionary, suffix: String, min_x: float, max_x: float) -> void:
	var length = max_x - min_x
	if length < MIN_INTERNAL_WALL_SEGMENT:
		return
	var position: Vector3 = wall_spec["position"]
	var size: Vector3 = wall_spec["size"]
	result.append({
		"suffix": suffix,
		"position": Vector3((min_x + max_x) * 0.5, position.y, position.z),
		"size": Vector3(length, size.y, size.z),
	})

func _append_vertical_wall_segment(result: Array[Dictionary], wall_spec: Dictionary, suffix: String, min_z: float, max_z: float) -> void:
	var length = max_z - min_z
	if length < MIN_INTERNAL_WALL_SEGMENT:
		return
	var position: Vector3 = wall_spec["position"]
	var size: Vector3 = wall_spec["size"]
	result.append({
		"suffix": suffix,
		"position": Vector3(position.x, position.y, (min_z + max_z) * 0.5),
		"size": Vector3(size.x, size.y, length),
	})

func _create_area_node(parent: Node3D, node: Dictionary, connected_nodes: Array) -> void:
	var module_id = String(node["id"])
	var area = Node3D.new()
	area.name = "Area_%s" % module_id
	area.set_script(RoomModuleScript)
	area.room_id = module_id
	area.area_id = String(node.get("area_id", ""))
	area.room_type = String(node.get("type", ""))
	var rect = _rect(node)
	area.bounds_size = Vector3(rect.size.x * CELL_SIZE, WALL_HEIGHT, rect.size.y * CELL_SIZE)
	var portal_ids = PackedStringArray()
	for next_node in connected_nodes:
		portal_ids.append("P_%s_%s" % [module_id, String(next_node)])
	area.portal_ids = portal_ids
	parent.add_child(area)
	area.position = _node_center_world(node)

func _create_boundary_walls(parent: Node3D, node_map: Dictionary, opening_specs: Dictionary) -> void:
	var cell_owner = _build_cell_owner(node_map)
	var handled_boundaries = {}
	for cell_key in cell_owner.keys():
		var parts = String(cell_key).split(",")
		var gx = int(parts[0])
		var gz = int(parts[1])
		var node_id = String(cell_owner[cell_key])
		_handle_boundary(parent, handled_boundaries, opening_specs, cell_owner, node_id, gx, gz, -1, 0)
		_handle_boundary(parent, handled_boundaries, opening_specs, cell_owner, node_id, gx, gz, 1, 0)
		_handle_boundary(parent, handled_boundaries, opening_specs, cell_owner, node_id, gx, gz, 0, -1)
		_handle_boundary(parent, handled_boundaries, opening_specs, cell_owner, node_id, gx, gz, 0, 1)

func _handle_boundary(parent: Node3D, handled: Dictionary, opening_specs: Dictionary, cell_owner: Dictionary, node_id: String, gx: int, gz: int, dx: int, dz: int) -> void:
	var neighbor_key = "%d,%d" % [gx + dx, gz + dz]
	if cell_owner.get(neighbor_key, "") == node_id:
		return

	var boundary_key = _boundary_key(gx, gz, dx, dz)
	if handled.has(boundary_key):
		return
	handled[boundary_key] = true

	if opening_specs.has(boundary_key):
		_create_opening_wall(parent, opening_specs[boundary_key])
	else:
		_create_solid_boundary_wall(parent, boundary_key, gx, gz, dx, dz)

func _create_solid_boundary_wall(parent: Node3D, boundary_key: String, gx: int, gz: int, dx: int, dz: int) -> void:
	var center = _boundary_world_center(gx, gz, dx, dz)
	var size = Vector3(WALL_THICKNESS, WALL_HEIGHT, CELL_SIZE)
	var visual_size = size
	visual_size.z += WALL_CORNER_VISUAL_OVERLAP * 2.0
	if dz != 0:
		size = Vector3(CELL_SIZE, WALL_HEIGHT, WALL_THICKNESS)
		visual_size = size
		visual_size.x += WALL_CORNER_VISUAL_OVERLAP * 2.0
	var wall_name = "Wall_%s" % boundary_key.replace(":", "_")
	var wall_position := Vector3(center.x, WALL_CONTACT_Y, center.z)
	var wall = _create_box_body(parent, wall_name, wall_position, size, _wall_material_instance(wall_name, wall_position), true, false, visual_size)
	wall.set_meta("boundary_key", boundary_key)
	wall.set_meta("wall_height", WALL_HEIGHT)
	wall.set_meta("floor_bite_m", WALL_FLOOR_BITE)
	wall.set_meta("corner_visual_overlap", WALL_CORNER_VISUAL_OVERLAP)
	wall.add_to_group("proc_wall_body", true)
	wall.add_to_group("foreground_occluder", true)

func _create_opening_wall(parent: Node3D, spec: Dictionary) -> void:
	var edge_id := String(spec["edge_id"])
	var is_outer_exit := bool(spec.get("is_outer_exit", false))
	var opening = StaticBody3D.new()
	opening.name = "WallOpening_%s" % edge_id
	opening.set_script(WallOpeningBodyScript)
	opening.opening_id = edge_id
	opening.wall_id = opening.name
	opening.area_id = String(spec.get("area_a", ""))
	opening.span_axis = String(spec["span_axis"])
	opening.span_length = CELL_SIZE
	opening.opening_width = DOOR_OPENING_WIDTH
	opening.opening_height = WALL_OPENING_HEIGHT
	opening.wall_height = WALL_HEIGHT
	opening.wall_thickness = WALL_THICKNESS
	opening.visual_material = _wall_material_instance(opening.name, spec["center"])
	opening.visual_layers = STATIC_GEOMETRY_LAYER
	opening.set_meta("edge_id", edge_id)
	opening.set_meta("boundary_key", String(spec["boundary_key"]))
	opening.set_meta("is_outer_exit", is_outer_exit)
	opening.set_meta("wall_height", WALL_HEIGHT)
	if is_outer_exit:
		opening.add_to_group("proc_keyed_exit_opening", true)
	else:
		opening.add_to_group("proc_wall_opening", true)
	opening.add_to_group("wall_opening", true)
	opening.add_to_group("foreground_occluder", true)
	parent.add_child(opening)
	opening.position = spec["center"]
	if opening.has_method("_rebuild_body"):
		opening._rebuild_body()

	var frame = MeshInstance3D.new()
	frame.name = "DoorFrame_%s" % edge_id
	frame.set_script(DoorFrameVisualScript)
	frame.frame_id = edge_id
	frame.span_axis = String(spec["span_axis"])
	frame.opening_width = maxf(0.1, DOOR_OPENING_WIDTH - DOOR_FRAME_TRIM_WIDTH * 2.0)
	frame.outer_height = DOOR_FRAME_OUTER_HEIGHT
	frame.trim_width = DOOR_FRAME_TRIM_WIDTH
	frame.frame_depth = DOOR_FRAME_DEPTH
	frame.visual_material = _surface_material("door_frame")
	frame.scale = Vector3.ONE
	frame.layers = STATIC_GEOMETRY_LAYER
	frame.set_meta("edge_id", edge_id)
	frame.set_meta("boundary_key", String(spec["boundary_key"]))
	frame.set_meta("is_outer_exit", is_outer_exit)
	if is_outer_exit:
		frame.add_to_group("proc_keyed_exit_frame", true)
	else:
		frame.add_to_group("proc_door_frame", true)
	frame.add_to_group("door_frame", true)
	parent.add_child(frame)
	frame.position = spec["center"]

func _create_portals(parent: Node3D, opening_specs: Dictionary, node_map: Dictionary) -> void:
	for boundary_key in opening_specs.keys():
		var spec: Dictionary = opening_specs[boundary_key]
		if bool(spec.get("is_outer_exit", false)):
			continue
		var portal = Node3D.new()
		portal.name = "Portal_%s" % String(spec["edge_id"])
		portal.set_script(PortalComponentScript)
		portal.portal_id = "P_%s" % String(spec["edge_id"])
		portal.area_a = String(spec["node_a"])
		portal.area_b = String(spec["node_b"])
		portal.opening_width = DOOR_OPENING_WIDTH
		portal.opening_height = DOOR_CLEARANCE_HEIGHT
		portal.initial_state = "open"
		portal.set_meta("edge_id", String(spec["edge_id"]))
		portal.set_meta("boundary_key", boundary_key)
		portal.add_to_group("proc_portal", true)
		parent.add_child(portal)
		portal.position = spec["center"]

		var left_edge = Marker3D.new()
		left_edge.name = "LeftEdge"
		portal.add_child(left_edge)
		var right_edge = Marker3D.new()
		right_edge.name = "RightEdge"
		portal.add_child(right_edge)
		if String(spec["span_axis"]) == "z":
			left_edge.position = Vector3(0.0, 0.0, -DOOR_OPENING_WIDTH * 0.5)
			right_edge.position = Vector3(0.0, 0.0, DOOR_OPENING_WIDTH * 0.5)
		else:
			left_edge.position = Vector3(-DOOR_OPENING_WIDTH * 0.5, 0.0, 0.0)
			right_edge.position = Vector3(DOOR_OPENING_WIDTH * 0.5, 0.0, 0.0)

func _create_markers(parent: Node3D, node_map: Dictionary) -> void:
	for node_id in node_map.keys():
		var node: Dictionary = node_map[node_id]
		if bool(node.get("is_entrance", false)) or bool(node.get("is_exit", false)) or bool(node.get("is_special", false)):
			var marker = Marker3D.new()
			marker.name = "Marker_%s" % String(node_id)
			marker.set_script(MarkerComponentScript)
			marker.marker_id = String(node_id)
			marker.marker_type = "Entrance" if bool(node.get("is_entrance", false)) else ("Exit" if bool(node.get("is_exit", false)) else "SpecialReserve")
			marker.room_id = String(node_id)
			marker.area_id = String(node.get("area_id", ""))
			parent.add_child(marker)
			marker.position = _node_center_world(node) + Vector3(0.0, 0.05, 0.0)

func _create_keyed_outer_exit(doors_root: Node3D, props_root: Node3D, markers_root: Node3D, nodes: Array, node_map: Dictionary, spec: Dictionary) -> Dictionary:
	var summary := {"door": 0, "key": 0}
	if spec.is_empty():
		return summary
	var center: Vector3 = spec.get("center", Vector3.ZERO)

	var door := KeyedExitDoorScene.instantiate() as Node3D
	if door != null:
		door.name = "Door_KeyedOuterExit"
		door.position = Vector3(center.x, 0.0, center.z)
		door.rotation.y = _door_yaw_for_span_axis(String(spec.get("span_axis", "")))
		door.set("door_id", "ProcMaze_KeyedOuterExit")
		door.set("requires_escape_key", true)
		door.add_to_group("proc_keyed_exit_door", true)
		door.add_to_group("interactive_door", true)
		door.set_meta("requires_escape_key", true)
		door.set_meta("placement_group", "proc_maze_keyed_outer_exit")
		door.set_meta("boundary_key", String(spec.get("boundary_key", "")))
		door.set_meta("owner_module_id", String(spec.get("owner_module_id", "")))
		door.set_meta("exit_marker_id", "Marker_KeyedOuterExit")
		doors_root.add_child(door)
		summary["door"] = 1

	var marker := Marker3D.new()
	marker.name = "Marker_KeyedOuterExit"
	marker.set_script(MarkerComponentScript)
	marker.marker_id = "KeyedOuterExit"
	marker.marker_type = "KeyedExit"
	marker.room_id = String(spec.get("owner_module_id", ""))
	marker.area_id = String(spec.get("area_a", ""))
	marker.set_meta("requires_escape_key", true)
	marker.set_meta("boundary_key", String(spec.get("boundary_key", "")))
	markers_root.add_child(marker)
	marker.position = center + _outer_side_normal(String(spec.get("side", ""))) * 0.45 + Vector3(0.0, 0.05, 0.0)

	var key := EscapeKeyPickupScene.instantiate() as Node3D
	if key != null:
		key.name = "ProcMaze_EscapeKey"
		key.add_to_group("escape_key_pickup", true)
		key.set_meta("escape_key_owner", "proc_maze_random")
		key.set_meta("collected", false)
		key.set_meta("opens_door_id", "ProcMaze_KeyedOuterExit")
		props_root.add_child(key)
		if not _try_place_key_on_generated_cabinet(key, props_root, spec):
			var key_node := _choose_escape_key_node(nodes, node_map, String(spec.get("owner_module_id", "")))
			_place_key_on_floor_in_node(key, key_node)
		summary["key"] = 1
	return summary

func _door_yaw_for_span_axis(span_axis: String) -> float:
	return -PI * 0.5 if span_axis == "z" else 0.0

func _outer_side_normal(side: String) -> Vector3:
	match side:
		"west":
			return Vector3.LEFT
		"east":
			return Vector3.RIGHT
		"north":
			return Vector3.FORWARD
		"south":
			return Vector3.BACK
		_:
			return Vector3.ZERO

func _try_place_key_on_generated_cabinet(key: Node3D, props_root: Node3D, spec: Dictionary) -> bool:
	var cabinets: Array[Node3D] = []
	for node in _get_nodes_in_group(props_root, "proc_maze_prop"):
		var prop := node as Node3D
		if prop == null:
			continue
		if String(prop.get_meta("proc_maze_prop_id", "")) != "SmallCabinet_A":
			continue
		cabinets.append(prop)
	if cabinets.is_empty():
		return false
	cabinets.sort_custom(func(a: Node3D, b: Node3D) -> bool:
		return String(a.name) < String(b.name)
	)
	var cabinet := cabinets[_stable_index("%s:key_cabinet:%d" % [String(spec.get("boundary_key", "")), cabinets.size()], cabinets.size())]
	key.position = cabinet.transform * Vector3(0.04, 0.92, 0.02)
	key.rotation = Vector3(PI * 0.5, cabinet.rotation.y, 0.0)
	key.scale = Vector3(1.32, 1.32, 1.32)
	key.set_meta("placement_surface", "cabinet_top")
	key.set_meta("owner_module_id", String(cabinet.get_meta("owner_module_id", "")))
	return true

func _choose_escape_key_node(nodes: Array, node_map: Dictionary, exit_node_id: String) -> Dictionary:
	var candidates: Array[Dictionary] = []
	for node in nodes:
		var node_dict: Dictionary = node
		var node_id := String(node_dict.get("id", ""))
		if node_id.is_empty() or node_id == exit_node_id:
			continue
		if bool(node_dict.get("is_entrance", false)) or bool(node_dict.get("is_exit", false)):
			continue
		var kind := String(node_dict.get("space_kind", ""))
		if kind in ["narrow_corridor", "long_corridor", "l_turn", "junction", "offset_corridor"]:
			continue
		candidates.append(node_dict)
	if candidates.is_empty():
		for node_id in node_map.keys():
			var fallback: Dictionary = node_map[node_id]
			if not bool(fallback.get("is_exit", false)):
				candidates.append(fallback)
	if candidates.is_empty():
		return {}
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a.get("id", "")) < String(b.get("id", ""))
	)
	return candidates[_stable_index("proc_maze_escape_key:%d" % candidates.size(), candidates.size())]

func _place_key_on_floor_in_node(key: Node3D, node: Dictionary) -> void:
	var position := _node_center_world(node)
	var node_id := String(node.get("id", "fallback"))
	position.x += _stable_signed_offset("%s:key:x" % node_id, 0.34)
	position.z += _stable_signed_offset("%s:key:z" % node_id, 0.34)
	position.y = 0.10
	key.position = position
	key.rotation = Vector3(PI * 0.5, _stable_signed_offset("%s:key:yaw" % node_id, PI), 0.0)
	key.scale = Vector3(1.32, 1.32, 1.32)
	key.set_meta("placement_surface", "floor")
	key.set_meta("owner_module_id", node_id)

func _create_guidance_graffiti(parent: Node3D, nodes: Array, edges: Array, node_map: Dictionary, opening_specs: Dictionary) -> Dictionary:
	var summary := {"total": 0}
	if GUIDANCE_ARROW_TEXTURES.is_empty():
		return summary
	var exit_id := _find_exit_node_id(nodes)
	if exit_id.is_empty():
		return summary
	var adjacency := _build_adjacency(nodes, edges)
	var distances := _shortest_distances_from(exit_id, adjacency)
	var next_hops := _next_hops_to_exit(nodes, adjacency, distances)
	var max_distance_to_exit := _max_guidance_distance_to_exit(nodes, next_hops, distances)
	for index in range(nodes.size()):
		if int(summary["total"]) >= GUIDANCE_GRAFFITI_MAX:
			break
		var node: Dictionary = nodes[index]
		var node_id := String(node.get("id", ""))
		if node_id == exit_id or not next_hops.has(node_id):
			continue
		var distance_to_exit := int(distances.get(node_id, -1))
		if distance_to_exit <= 0:
			continue
		if not _should_place_guidance_graffiti(node, index, distance_to_exit):
			continue
		var next_id := String(next_hops[node_id])
		var opening := _opening_spec_between(opening_specs, node_id, next_id)
		if opening.is_empty():
			continue
		if _place_guidance_arrow(parent, node, node_map, opening, next_id, exit_id, distance_to_exit, max_distance_to_exit, int(summary["total"])):
			summary["total"] = int(summary["total"]) + 1
	return summary

func _max_guidance_distance_to_exit(nodes: Array, next_hops: Dictionary, distances: Dictionary) -> int:
	var max_distance := 1
	for node in nodes:
		var node_id := String((node as Dictionary).get("id", ""))
		if not next_hops.has(node_id):
			continue
		max_distance = maxi(max_distance, int(distances.get(node_id, 1)))
	return max_distance

func _find_exit_node_id(nodes: Array) -> String:
	for node in nodes:
		if bool((node as Dictionary).get("is_exit", false)):
			return String((node as Dictionary).get("id", ""))
	return ""

func _shortest_distances_from(start_id: String, adjacency: Dictionary) -> Dictionary:
	var distances := {start_id: 0}
	var queue := [start_id]
	var head := 0
	while head < queue.size():
		var current_id := String(queue[head])
		head += 1
		var current_distance := int(distances[current_id])
		for neighbor in adjacency.get(current_id, []):
			var neighbor_id := String(neighbor)
			if distances.has(neighbor_id):
				continue
			distances[neighbor_id] = current_distance + 1
			queue.append(neighbor_id)
	return distances

func _next_hops_to_exit(nodes: Array, adjacency: Dictionary, distances: Dictionary) -> Dictionary:
	var next_hops := {}
	for node in nodes:
		var node_id := String((node as Dictionary).get("id", ""))
		if not distances.has(node_id):
			continue
		var distance := int(distances[node_id])
		if distance <= 0:
			continue
		var best_neighbor := ""
		var best_distance := distance
		for neighbor in adjacency.get(node_id, []):
			var neighbor_id := String(neighbor)
			if not distances.has(neighbor_id):
				continue
			var neighbor_distance := int(distances[neighbor_id])
			if neighbor_distance < best_distance:
				best_distance = neighbor_distance
				best_neighbor = neighbor_id
		if not best_neighbor.is_empty():
			next_hops[node_id] = best_neighbor
	return next_hops

func _should_place_guidance_graffiti(node: Dictionary, index: int, distance_to_exit: int) -> bool:
	if bool(node.get("is_entrance", false)):
		return true
	var kind := String(node.get("space_kind", ""))
	var selector := _stable_index("%s:guidance:%d:%d" % [String(node.get("id", "")), index, distance_to_exit], 10)
	if kind in ["hub", "large_internal", "special"]:
		return selector <= 4
	if kind in ["long_corridor", "l_turn", "junction", "offset_corridor"]:
		return selector in [1, 5, 8]
	if distance_to_exit % 3 == 0:
		return selector <= 5
	return selector <= 2

func _opening_spec_between(opening_specs: Dictionary, node_a: String, node_b: String) -> Dictionary:
	for key in opening_specs.keys():
		var spec: Dictionary = opening_specs[key]
		var spec_a := String(spec.get("node_a", ""))
		var spec_b := String(spec.get("node_b", ""))
		if (spec_a == node_a and spec_b == node_b) or (spec_a == node_b and spec_b == node_a):
			return spec
	return {}

func _place_guidance_arrow(
	parent: Node3D,
	node: Dictionary,
	node_map: Dictionary,
	opening: Dictionary,
	next_id: String,
	exit_id: String,
	distance_to_exit: int,
	max_distance_to_exit: int,
	arrow_index: int
) -> bool:
	var node_id := String(node.get("id", ""))
	if not node_map.has(node_id):
		return false
	var center := _node_center_world(node_map[node_id])
	var door_center: Vector3 = opening.get("center", Vector3.ZERO)
	var normal := _guidance_wall_normal(center, door_center, String(opening.get("span_axis", "")))
	if normal.length_squared() <= 0.0001:
		return false
	var tangent := _guidance_wall_tangent(String(opening.get("span_axis", "")))
	var side_sign := -1.0 if _stable_index("%s:%s:side" % [node_id, next_id], 2) == 0 else 1.0
	var offset_jitter := _stable_signed_offset("%s:%s:offset" % [node_id, next_id], 0.035)
	var y_jitter := _stable_signed_offset("%s:%s:y" % [node_id, next_id], 0.16)
	var side_offset := side_sign * (GUIDANCE_GRAFFITI_DOOR_SIDE_OFFSET + offset_jitter)
	var position := door_center
	position += tangent * side_offset
	position += normal * GUIDANCE_GRAFFITI_WALL_OFFSET
	position.y = GUIDANCE_GRAFFITI_Y + y_jitter

	var texture_index := _stable_index("%s:%s:texture" % [node_id, next_id], GUIDANCE_ARROW_TEXTURES.size())
	var exit_heat := _guidance_arrow_exit_heat(distance_to_exit, max_distance_to_exit)
	var distance_color := _guidance_arrow_color(exit_heat)
	var material := _guidance_arrow_material(texture_index, exit_heat)
	if material == null:
		return false
	var mesh := QuadMesh.new()
	var size_scale := 0.86 + float(_stable_index("%s:%s:scale" % [node_id, next_id], 7)) * 0.045
	mesh.size = GUIDANCE_GRAFFITI_BASE_SIZE * size_scale

	var arrow_direction := -tangent * side_sign
	var basis := _guidance_arrow_basis(normal, arrow_direction)
	var arrow := MeshInstance3D.new()
	arrow.name = "GuidanceArrow_%s_to_%s_%02d" % [node_id, next_id, arrow_index]
	arrow.mesh = mesh
	arrow.material_override = material
	arrow.transform = Transform3D(basis, position)
	arrow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	arrow.layers = STATIC_GEOMETRY_LAYER
	arrow.add_to_group("proc_guidance_graffiti", true)
	arrow.add_to_group("proc_maze_generated", true)
	arrow.set_meta("owner_module_id", node_id)
	arrow.set_meta("next_node_id", next_id)
	arrow.set_meta("exit_node_id", exit_id)
	arrow.set_meta("path_distance_to_exit", distance_to_exit)
	arrow.set_meta("target_edge_id", String(opening.get("edge_id", "")))
	arrow.set_meta("texture_index", texture_index)
	arrow.set_meta("points_to_door", true)
	arrow.set_meta("door_side_offset", side_offset)
	arrow.set_meta("wall_offset", GUIDANCE_GRAFFITI_WALL_OFFSET)
	arrow.set_meta("exit_heat", exit_heat)
	arrow.set_meta("distance_color", distance_color)
	parent.add_child(arrow)
	return true

func _guidance_wall_normal(node_center: Vector3, door_center: Vector3, span_axis: String) -> Vector3:
	if span_axis == "z":
		var sign_x := -1.0 if node_center.x < door_center.x else 1.0
		return Vector3(sign_x, 0.0, 0.0)
	var sign_z := -1.0 if node_center.z < door_center.z else 1.0
	return Vector3(0.0, 0.0, sign_z)

func _guidance_wall_tangent(span_axis: String) -> Vector3:
	if span_axis == "z":
		return Vector3(0.0, 0.0, 1.0)
	return Vector3(1.0, 0.0, 0.0)

func _guidance_arrow_basis(normal: Vector3, arrow_direction: Vector3) -> Basis:
	var up := Vector3.UP
	var normal_axis := normal.normalized()
	var base_x := up.cross(normal_axis).normalized()
	var x_axis := base_x
	var y_axis := up
	if x_axis.dot(arrow_direction.normalized()) < 0.0:
		x_axis = -x_axis
		y_axis = -up
	return Basis(x_axis, y_axis, normal_axis)

func _guidance_arrow_exit_heat(distance_to_exit: int, max_distance_to_exit: int) -> float:
	if max_distance_to_exit <= 1:
		return 1.0
	var raw := 1.0 - float(maxi(distance_to_exit, 1) - 1) / float(max_distance_to_exit - 1)
	return clampf(raw, 0.0, 1.0)

func _guidance_arrow_color(exit_heat: float) -> Color:
	var heat := clampf(exit_heat, 0.0, 1.0)
	var smoothed := heat * heat * (3.0 - 2.0 * heat)
	return GUIDANCE_GRAFFITI_COLD_COLOR.lerp(GUIDANCE_GRAFFITI_HOT_COLOR, smoothed)

func _guidance_arrow_material(texture_index: int, exit_heat: float) -> StandardMaterial3D:
	if texture_index < 0 or texture_index >= GUIDANCE_ARROW_TEXTURES.size():
		return null
	var heat_step := clampi(roundi(clampf(exit_heat, 0.0, 1.0) * float(GUIDANCE_GRAFFITI_COLOR_STEPS - 1)), 0, GUIDANCE_GRAFFITI_COLOR_STEPS - 1)
	var cache_key := "%d:%d" % [texture_index, heat_step]
	if _guidance_material_cache.has(cache_key):
		return _guidance_material_cache[cache_key] as StandardMaterial3D
	var stepped_heat := float(heat_step) / float(maxi(GUIDANCE_GRAFFITI_COLOR_STEPS - 1, 1))
	var material := StandardMaterial3D.new()
	material.resource_name = "GuidanceGraffitiArrow_%02d_Heat_%02d" % [texture_index, heat_step]
	material.albedo_texture = _guidance_arrow_tinted_texture(texture_index, stepped_heat)
	material.albedo_color = Color.WHITE
	material.roughness = 0.92
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	_guidance_material_cache[cache_key] = material
	return material

func _guidance_arrow_tinted_texture(texture_index: int, stepped_heat: float) -> Texture2D:
	var heat_step := clampi(roundi(clampf(stepped_heat, 0.0, 1.0) * float(GUIDANCE_GRAFFITI_COLOR_STEPS - 1)), 0, GUIDANCE_GRAFFITI_COLOR_STEPS - 1)
	var cache_key := "%d:%d" % [texture_index, heat_step]
	if _guidance_tinted_texture_cache.has(cache_key):
		return _guidance_tinted_texture_cache[cache_key] as Texture2D
	var source := GUIDANCE_ARROW_TEXTURES[texture_index] as Texture2D
	var source_image := source.get_image()
	if source_image == null:
		return source
	if source_image.is_compressed():
		var decompress_error := source_image.decompress()
		if decompress_error != OK:
			return source
	source_image.convert(Image.FORMAT_RGBA8)
	var tint := _guidance_arrow_color(stepped_heat)
	var image := Image.create(source_image.get_width(), source_image.get_height(), false, Image.FORMAT_RGBA8)
	for y in range(source_image.get_height()):
		for x in range(source_image.get_width()):
			var source_color := source_image.get_pixel(x, y)
			image.set_pixel(x, y, Color(tint.r, tint.g, tint.b, source_color.a * tint.a))
	var texture := ImageTexture.create_from_image(image)
	texture.resource_name = "GuidanceGraffitiArrow_%02d_Tinted_%02d" % [texture_index, heat_step]
	_guidance_tinted_texture_cache[cache_key] = texture
	return texture

func _create_proc_maze_props(parent: Node3D, nodes: Array, opening_specs: Dictionary) -> Dictionary:
	var summary := {
		"total": 0,
		"floor": 0,
		"wall": 0,
		"feature": 0,
		"hideable": 0,
	}
	for index in range(nodes.size()):
		var node: Dictionary = nodes[index]
		var feature_prop_ids := _place_feature_prop_group(parent, node, "feature_group_%02d" % index)
		for feature_prop_id in feature_prop_ids:
			summary["feature"] = int(summary["feature"]) + 1
			summary["floor"] = int(summary["floor"]) + 1
			summary["total"] = int(summary["total"]) + 1
			if feature_prop_id == "HideLocker_A":
				summary["hideable"] = int(summary["hideable"]) + 1
		if not String(node.get("feature_template", "")).is_empty():
			continue

		var wall_prop_id := _wall_prop_id_for_node(node, index)
		if wall_prop_id != "" and int(summary["wall"]) < PROC_PROP_MAX_WALL:
			if _place_wall_prop(parent, node, opening_specs, wall_prop_id, "wall_detail_%02d" % index):
				summary["wall"] = int(summary["wall"]) + 1
				summary["total"] = int(summary["total"]) + 1

		if int(summary["floor"]) >= PROC_PROP_MAX_FLOOR:
			continue
		var floor_prop_ids := _floor_prop_ids_for_node(node, index)
		if floor_prop_ids.is_empty():
			continue
		if floor_prop_ids.has("HideLocker_A") and int(summary["hideable"]) >= PROC_PROP_MAX_HIDEABLE:
			continue
		var placed_ids := _place_floor_prop_group(parent, node, opening_specs, floor_prop_ids, "floor_group_%02d" % index)
		for prop_id in placed_ids:
			summary["floor"] = int(summary["floor"]) + 1
			summary["total"] = int(summary["total"]) + 1
			if prop_id == "HideLocker_A":
				summary["hideable"] = int(summary["hideable"]) + 1
	return summary

func _wall_prop_id_for_node(node: Dictionary, index: int) -> String:
	var kind := String(node.get("space_kind", ""))
	var module_type := String(node.get("type", ""))
	var selector := _stable_index("%s:wall:%d" % [String(node.get("id", "")), index], 9)
	if module_type == "corridor" or kind in ["narrow_corridor", "long_corridor", "l_turn", "junction", "offset_corridor"]:
		if selector in [0, 2, 5, 7]:
			return ["Vent_Wall_A", "Pipe_Straight_A", "ElectricBox_A", "Pipe_Corner_A"][selector % 4]
		return ""
	if kind in ["large_internal", "hub"]:
		if selector in [0, 1, 4, 6]:
			return ["ElectricBox_A", "Pipe_Straight_A", "Vent_Wall_A", "Pipe_Corner_A"][selector % 4]
		return ""
	if selector in [0, 2, 4]:
		return ["Vent_Wall_A", "Pipe_Straight_A", "ElectricBox_A"][int(selector / 2)]
	return ""

func _floor_prop_ids_for_node(node: Dictionary, index: int) -> Array[String]:
	var kind := String(node.get("space_kind", ""))
	var module_type := String(node.get("type", ""))
	if bool(node.get("is_entrance", false)):
		return []
	if module_type == "corridor" or kind in ["narrow_corridor", "long_corridor", "l_turn", "junction", "offset_corridor"]:
		return []
	var selector := _stable_index("%s:floor:%d" % [String(node.get("id", "")), index], 8)
	if bool(node.get("is_dead_end", false)):
		if selector % 2 == 0:
			return ["Bucket_A", "Mop_A"]
		return ["Box_Stack_2_A", "Box_Small_A"]
	if kind == "large_internal":
		match selector % 4:
			0:
				return ["MetalShelf_A", "Box_Stack_3_A"]
			1:
				return ["SmallCabinet_A", "Chair_Old_A"]
			2:
				return ["HideLocker_A"]
			_:
				return ["Box_Stack_2_A", "CleaningClothPile_A"]
	if kind == "hub":
		match selector % 4:
			0:
				return ["HideLocker_A"]
			1:
				return ["MetalShelf_A"]
			2:
				return ["SmallCabinet_A", "Box_Medium_A"]
			_:
				return ["HideLocker_A"]
	if kind in ["l_room", "recognizable_room", "special", "normal_room", "room_wide"]:
		match selector % 5:
			0:
				return []
			1:
				return ["Box_Stack_2_A", "Box_Medium_A"]
			2:
				return ["Chair_Old_A"]
			3:
				return ["SmallCabinet_A"]
			_:
				return ["Bucket_A", "CleaningClothPile_A"]
	if selector in [1, 5]:
		return ["Box_Medium_A", "Box_Small_A"]
	return []

func _place_feature_prop_group(parent: Node3D, node: Dictionary, placement_group: String) -> Array[String]:
	var prop_specs := _feature_prop_specs_for_node(node)
	if prop_specs.is_empty():
		return []
	var center := _node_center_world(node)
	var feature := String(node.get("feature_template", ""))
	var placed: Array[String] = []
	for index in range(prop_specs.size()):
		var spec: Dictionary = prop_specs[index]
		var prop_id := String(spec.get("prop_id", ""))
		var local_position: Vector3 = spec.get("local_position", Vector3.ZERO)
		var position := center + local_position
		var instance := _instantiate_proc_prop(parent, prop_id, node, placement_group, position, float(spec.get("yaw", 0.0)))
		if instance == null:
			continue
		instance.add_to_group("proc_feature_prop", true)
		instance.set_meta("feature_template", feature)
		instance.set_meta("feature_prop_role", String(spec.get("role", feature)))
		instance.set_meta("feature_layout", String(spec.get("layout", feature)))
		instance.set_meta("placement_surface", "floor")
		placed.append(prop_id)
	return placed

func _feature_prop_specs_for_node(node: Dictionary) -> Array[Dictionary]:
	match String(node.get("feature_template", "")):
		"box_heap_hall", "box_hall":
			return [
				{"prop_id": "Box_Stack_3_A", "local_position": Vector3(1.15, 0.0, 0.45), "yaw": 0.32, "role": "irregular_box_pile", "layout": "asymmetric_side_pile"},
				{"prop_id": "Box_Stack_2_A", "local_position": Vector3(1.65, 0.0, -0.32), "yaw": -0.46, "role": "irregular_box_pile", "layout": "asymmetric_side_pile"},
				{"prop_id": "Box_Medium_A", "local_position": Vector3(0.72, 0.0, 1.22), "yaw": 1.05, "role": "loose_box", "layout": "asymmetric_side_pile"},
				{"prop_id": "Box_Small_A", "local_position": Vector3(1.95, 0.0, 0.92), "yaw": -0.85, "role": "loose_box", "layout": "asymmetric_side_pile"},
				{"prop_id": "Box_Medium_A", "local_position": Vector3(0.20, 0.0, 1.75), "yaw": 0.18, "role": "loose_box", "layout": "asymmetric_side_pile"},
			]
		"side_chamber_hall":
			return [
				{"prop_id": "Box_Small_A", "local_position": Vector3(1.35, 0.0, -1.48), "yaw": 0.44, "role": "side_chamber_leftover", "layout": "sparse_side_chamber"},
				{"prop_id": "Chair_Old_A", "local_position": Vector3(0.42, 0.0, -1.72), "yaw": -0.72, "role": "side_chamber_leftover", "layout": "sparse_side_chamber"},
			]
		"maintenance_hall":
			return [
				{"prop_id": "SmallCabinet_A", "local_position": Vector3(-1.05, 0.0, 0.82), "yaw": 0.35, "role": "equipment_storage", "layout": "maintenance_side_cluster"},
				{"prop_id": "Bucket_A", "local_position": Vector3(-1.58, 0.0, 0.16), "yaw": -0.22, "role": "cleaning", "layout": "maintenance_side_cluster"},
				{"prop_id": "Mop_A", "local_position": Vector3(-1.42, 0.0, -0.54), "yaw": 0.74, "role": "cleaning", "layout": "maintenance_side_cluster"},
				{"prop_id": "CleaningClothPile_A", "local_position": Vector3(-0.62, 0.0, -0.18), "yaw": -0.35, "role": "cleaning", "layout": "maintenance_side_cluster"},
				{"prop_id": "Box_Small_A", "local_position": Vector3(1.04, 0.0, -0.72), "yaw": 1.12, "role": "leftover_box", "layout": "maintenance_side_cluster"},
			]
		_:
			return []

func _place_floor_prop_group(parent: Node3D, node: Dictionary, opening_specs: Dictionary, prop_ids: Array[String], placement_group: String) -> Array[String]:
	var candidates := _solid_wall_candidates_for_node(node, opening_specs)
	if candidates.is_empty():
		return []
	var candidate: Dictionary = candidates[_stable_index("%s:%s:side" % [String(node.get("id", "")), placement_group], candidates.size())]
	var placed: Array[String] = []
	for prop_index in range(prop_ids.size()):
		var prop_id := String(prop_ids[prop_index])
		var transform_data := _floor_prop_transform(candidate, prop_index, prop_ids.size())
		var instance := _instantiate_proc_prop(parent, prop_id, node, placement_group, transform_data["position"], float(transform_data["yaw"]))
		if instance == null:
			continue
		instance.set_meta("placement_surface", "floor")
		instance.set_meta("placement_side", String(candidate.get("side", "")))
		placed.append(prop_id)
	return placed

func _place_wall_prop(parent: Node3D, node: Dictionary, opening_specs: Dictionary, prop_id: String, placement_group: String) -> bool:
	var candidates := _solid_wall_candidates_for_node(node, opening_specs)
	if candidates.is_empty():
		return false
	var candidate: Dictionary = candidates[_stable_index("%s:%s:wall" % [String(node.get("id", "")), placement_group], candidates.size())]
	var transform_data := _wall_prop_transform(candidate, prop_id, node)
	var instance := _instantiate_proc_prop(parent, prop_id, node, placement_group, transform_data["position"], float(transform_data["yaw"]))
	if instance == null:
		return false
	instance.set_meta("placement_surface", "wall")
	instance.set_meta("placement_side", String(candidate.get("side", "")))
	return true

func _instantiate_proc_prop(parent: Node3D, prop_id: String, node: Dictionary, placement_group: String, position: Vector3, yaw: float) -> Node3D:
	if not PROP_SCENES.has(prop_id):
		return null
	var packed: PackedScene = PROP_SCENES[prop_id]
	var instance := packed.instantiate() as Node3D
	if instance == null:
		return null
	instance.name = "ProcProp_%s_%s_%s" % [String(node.get("id", "")), placement_group, prop_id]
	instance.position = position
	instance.rotation.y = yaw
	instance.add_to_group("proc_maze_prop", true)
	instance.set_meta("owner_module_id", String(node.get("id", "")))
	instance.set_meta("space_kind", String(node.get("space_kind", "")))
	instance.set_meta("width_tier", String(node.get("width_tier", "")))
	instance.set_meta("feature_template", String(node.get("feature_template", "")))
	instance.set_meta("dark_zone", String(node.get("dark_zone", "")))
	instance.set_meta("placement_group", placement_group)
	instance.set_meta("proc_maze_prop_id", prop_id)
	if bool(instance.get_meta("blocks_path", false)):
		instance.add_to_group("proc_maze_blocking_prop", true)
	if WALL_PROP_IDS.has(prop_id):
		instance.add_to_group("proc_maze_wall_prop", true)
	parent.add_child(instance)
	return instance

func _solid_wall_candidates_for_node(node: Dictionary, opening_specs: Dictionary) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	var occupied := {}
	for cell in _occupied_cells(node):
		occupied[_cell_key(cell)] = true
	for cell in _occupied_cells(node):
		_append_solid_wall_candidate(candidates, occupied, opening_specs, cell, -1, 0, "west")
		_append_solid_wall_candidate(candidates, occupied, opening_specs, cell, 1, 0, "east")
		_append_solid_wall_candidate(candidates, occupied, opening_specs, cell, 0, -1, "north")
		_append_solid_wall_candidate(candidates, occupied, opening_specs, cell, 0, 1, "south")
	return candidates

func _append_solid_wall_candidate(candidates: Array[Dictionary], occupied: Dictionary, opening_specs: Dictionary, cell: Vector2i, dx: int, dz: int, side: String) -> void:
	var neighbor := Vector2i(cell.x + dx, cell.y + dz)
	if occupied.has(_cell_key(neighbor)):
		return
	var boundary_key := _boundary_key(cell.x, cell.y, dx, dz)
	if opening_specs.has(boundary_key):
		return
	candidates.append({
		"cell": cell,
		"side": side,
		"boundary_key": boundary_key,
	})

func _floor_prop_transform(candidate: Dictionary, prop_index: int, prop_count: int) -> Dictionary:
	var cell: Vector2i = candidate["cell"]
	var side := String(candidate.get("side", "north"))
	var x0 := float(cell.x) * CELL_SIZE
	var z0 := float(cell.y) * CELL_SIZE
	var x1 := float(cell.x + 1) * CELL_SIZE
	var z1 := float(cell.y + 1) * CELL_SIZE
	var along_offset := _cluster_along_offset(prop_index, prop_count)
	var inset := FLOOR_PROP_WALL_INSET + (0.14 if prop_index % 2 == 1 else 0.0)
	var position := Vector3.ZERO
	match side:
		"west":
			position = Vector3(x0 + inset, 0.0, clampf((z0 + z1) * 0.5 + along_offset, z0 + 0.38, z1 - 0.38))
		"east":
			position = Vector3(x1 - inset, 0.0, clampf((z0 + z1) * 0.5 + along_offset, z0 + 0.38, z1 - 0.38))
		"north":
			position = Vector3(clampf((x0 + x1) * 0.5 + along_offset, x0 + 0.38, x1 - 0.38), 0.0, z0 + inset)
		_:
			position = Vector3(clampf((x0 + x1) * 0.5 + along_offset, x0 + 0.38, x1 - 0.38), 0.0, z1 - inset)
	return {
		"position": position,
		"yaw": _side_yaw(side) + _prop_yaw_jitter(String(candidate.get("boundary_key", "")), prop_index),
	}

func _wall_prop_transform(candidate: Dictionary, prop_id: String, node: Dictionary) -> Dictionary:
	var cell: Vector2i = candidate["cell"]
	var side := String(candidate.get("side", "north"))
	var x0 := float(cell.x) * CELL_SIZE
	var z0 := float(cell.y) * CELL_SIZE
	var x1 := float(cell.x + 1) * CELL_SIZE
	var z1 := float(cell.y + 1) * CELL_SIZE
	var along_offset := _stable_signed_offset("%s:%s:%s" % [String(node.get("id", "")), prop_id, String(candidate.get("boundary_key", ""))], 0.42)
	var y := _wall_prop_height(prop_id)
	var position := Vector3.ZERO
	match side:
		"west":
			position = Vector3(x0 + WALL_PROP_FACE_INSET, y, clampf((z0 + z1) * 0.5 + along_offset, z0 + 0.42, z1 - 0.42))
		"east":
			position = Vector3(x1 - WALL_PROP_FACE_INSET, y, clampf((z0 + z1) * 0.5 + along_offset, z0 + 0.42, z1 - 0.42))
		"north":
			position = Vector3(clampf((x0 + x1) * 0.5 + along_offset, x0 + 0.42, x1 - 0.42), y, z0 + WALL_PROP_FACE_INSET)
		_:
			position = Vector3(clampf((x0 + x1) * 0.5 + along_offset, x0 + 0.42, x1 - 0.42), y, z1 - WALL_PROP_FACE_INSET)
	return {
		"position": position,
		"yaw": _side_yaw(side),
	}

func _cluster_along_offset(prop_index: int, prop_count: int) -> float:
	if prop_count <= 1:
		return 0.0
	var offsets := [-0.48, 0.48, 0.0, 0.82]
	return float(offsets[prop_index % offsets.size()])

func _side_yaw(side: String) -> float:
	match side:
		"west":
			return PI * 0.5
		"east":
			return -PI * 0.5
		"north":
			return 0.0
		_:
			return PI

func _wall_prop_height(prop_id: String) -> float:
	match prop_id:
		"ElectricBox_A":
			return 1.28
		"Vent_Wall_A":
			return 2.05
		"Pipe_Straight_A":
			return 2.08
		"Pipe_Corner_A":
			return 2.02
		_:
			return 1.4

func _stable_index(text: String, modulo: int) -> int:
	if modulo <= 0:
		return 0
	var value := 17
	for index in range(text.length()):
		value = int((value * 109 + text.unicode_at(index)) % 10000019)
	return value % modulo

func _stable_signed_offset(text: String, max_abs: float) -> float:
	var normalized := float(_stable_index(text, 1001)) / 1000.0
	return (normalized * 2.0 - 1.0) * max_abs

func _prop_yaw_jitter(text: String, prop_index: int) -> float:
	return _stable_signed_offset("%s:%d:yaw" % [text, prop_index], 0.20)

func _create_ceiling_light(visual_parent: Node3D, lights_parent: Node3D, module_id: String, center: Vector3, node: Dictionary, layout: Dictionary) -> void:
	var panel_mesh = BoxMesh.new()
	var panel_size: Vector3 = layout["panel_size"]
	var local_position: Vector3 = layout["local_position"]
	panel_mesh.size = panel_size
	var light_positions := _ceiling_light_source_positions(local_position, panel_size)
	var panel = MeshInstance3D.new()
	panel.name = "CeilingLightPanel_%s" % module_id
	panel.mesh = panel_mesh
	panel.material_override = CeilingLightMaterial
	panel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	panel.layers = STATIC_GEOMETRY_LAYER
	panel.set_meta("owner_module_id", module_id)
	panel.set_meta("space_kind", String(node.get("space_kind", "")))
	panel.set_meta("width_tier", String(node.get("width_tier", "")))
	panel.set_meta("lighting_policy", "safe_ceiling_light")
	panel.set_meta("clearance_m", CEILING_LIGHT_WALL_CLEARANCE)
	panel.set_meta("light_source_count", light_positions.size())
	panel.set_meta("light_distribution", _ceiling_light_distribution_axis(panel_size))
	panel.add_to_group("ceiling_light_panel", true)
	visual_parent.add_child(panel)
	panel.position = Vector3(local_position.x, CEILING_LIGHT_PANEL_Y, local_position.z)

	var source_count := light_positions.size()
	for source_index in range(source_count):
		var source_position: Vector3 = light_positions[source_index]
		var light = OmniLight3D.new()
		light.name = "CeilingLight_%s" % module_id
		if source_count > 1:
			light.name = "CeilingLight_%s_%02d" % [module_id, source_index + 1]
		light.light_color = Color(1.0, 0.86, 0.58)
		light.light_energy = _ceiling_light_source_energy(source_count)
		light.omni_range = _ceiling_light_source_range(source_count)
		light.omni_attenuation = _ceiling_light_source_attenuation(source_count)
		light.shadow_enabled = true
		light.shadow_bias = CEILING_LIGHT_SHADOW_BIAS
		light.shadow_normal_bias = CEILING_LIGHT_SHADOW_NORMAL_BIAS
		light.shadow_opacity = CEILING_LIGHT_SHADOW_OPACITY
		light.light_cull_mask = STATIC_GEOMETRY_LAYER | ACTOR_LIGHT_LAYER
		light.shadow_caster_mask = STATIC_GEOMETRY_LAYER | ACTOR_LIGHT_LAYER
		light.set_meta("owner_module_id", module_id)
		light.set_meta("fixture_panel_name", panel.name)
		light.set_meta("fixture_light_index", source_index)
		light.set_meta("fixture_light_count", source_count)
		light.set_meta("space_kind", String(node.get("space_kind", "")))
		light.set_meta("width_tier", String(node.get("width_tier", "")))
		light.set_meta("lighting_policy", "safe_ceiling_light")
		light.set_meta("distributed_source", source_count > 1)
		light.add_to_group("ceiling_light", true)
		lights_parent.add_child(light)
		light.position = Vector3(center.x + source_position.x, CEILING_LIGHT_Y, center.z + source_position.z)

func _ceiling_light_source_positions(local_position: Vector3, panel_size: Vector3) -> Array[Vector3]:
	var positions: Array[Vector3] = []
	var long_extent = maxf(panel_size.x, panel_size.z)
	var source_count := 1
	if long_extent >= CEILING_LIGHT_DISTRIBUTED_MIN_LENGTH:
		source_count = int(ceil(long_extent / CEILING_LIGHT_SOURCE_SPACING))
		if source_count < 2:
			source_count = 2
		if source_count > CEILING_LIGHT_MAX_SOURCES:
			source_count = CEILING_LIGHT_MAX_SOURCES
	if source_count == 1:
		positions.append(local_position)
		return positions

	var half_span = maxf(long_extent * 0.5 - CEILING_LIGHT_SOURCE_END_MARGIN, 0.0)
	if half_span <= 0.05:
		positions.append(local_position)
		return positions
	for source_index in range(source_count):
		var t = -1.0 + 2.0 * float(source_index) / float(source_count - 1)
		var source_position := local_position
		if panel_size.x >= panel_size.z:
			source_position.x += t * half_span
		else:
			source_position.z += t * half_span
		positions.append(source_position)
	return positions

func _ceiling_light_distribution_axis(panel_size: Vector3) -> String:
	var long_extent = maxf(panel_size.x, panel_size.z)
	if long_extent < CEILING_LIGHT_DISTRIBUTED_MIN_LENGTH:
		return "single"
	return "linear_x" if panel_size.x >= panel_size.z else "linear_z"

func _ceiling_light_source_energy(source_count: int) -> float:
	if source_count <= 1:
		return CEILING_LIGHT_ENERGY
	return CEILING_LIGHT_ENERGY * CEILING_LIGHT_DISTRIBUTED_TOTAL_ENERGY_MULTIPLIER / float(source_count)

func _ceiling_light_source_range(source_count: int) -> float:
	return CEILING_LIGHT_RANGE if source_count <= 1 else CEILING_LIGHT_DISTRIBUTED_RANGE

func _ceiling_light_source_attenuation(source_count: int) -> float:
	return CEILING_LIGHT_ATTENUATION if source_count <= 1 else CEILING_LIGHT_DISTRIBUTED_ATTENUATION

func _ceiling_light_layout(node: Dictionary, center: Vector3, size: Vector2) -> Dictionary:
	if _should_skip_ceiling_light(node):
		return {}
	var panel_size = _ceiling_light_panel_size(node)
	var local_position = _choose_ceiling_light_local_position(node, center, size, panel_size)
	if not bool(local_position.get("ok", false)):
		return {}
	return {
		"local_position": local_position["position"],
		"panel_size": panel_size,
	}

func _should_skip_ceiling_light(node: Dictionary) -> bool:
	var tier = String(node.get("width_tier", ""))
	var kind = String(node.get("space_kind", ""))
	var module_type = String(node.get("type", ""))
	if not String(node.get("dark_zone", "")).is_empty():
		return true
	if tier == "narrow_corridor":
		return true
	if kind in ["narrow_corridor", "l_turn", "junction", "offset_corridor"]:
		return true
	if module_type == "corridor" and not bool(node.get("is_long_corridor", false)):
		return true
	return false

func _unlit_reason(node: Dictionary) -> String:
	if not String(node.get("dark_zone", "")).is_empty():
		return "unlit_dark_zone_%s" % String(node.get("dark_zone", ""))
	if _should_skip_ceiling_light(node):
		return "unlit_narrow_or_complex_corridor"
	return "unlit_no_safe_ceiling_light_position"

func _choose_ceiling_light_local_position(node: Dictionary, center: Vector3, size: Vector2, panel_size: Vector3) -> Dictionary:
	var candidates: Array[Vector3] = [Vector3.ZERO]
	for cell in _occupied_cells(node):
		candidates.append(Vector3((float(cell.x) + 0.5) * CELL_SIZE - center.x, 0.0, (float(cell.y) + 0.5) * CELL_SIZE - center.z))

	var best_position = Vector3.ZERO
	var best_score = -INF
	for candidate in candidates:
		var score = _ceiling_light_candidate_score(node, center, size, panel_size, candidate)
		if score > best_score:
			best_score = score
			best_position = candidate

	if best_score <= -INF * 0.5:
		return {"ok": false}
	return {
		"ok": true,
		"position": best_position,
		"score": best_score,
	}

func _ceiling_light_candidate_score(node: Dictionary, center: Vector3, size: Vector2, panel_size: Vector3, local_position: Vector3) -> float:
	if not _panel_fits_occupied_cells(node, center, panel_size, local_position, CEILING_LIGHT_WALL_CLEARANCE):
		return -INF
	var panel_rect = _local_xz_rect(local_position, Vector2(panel_size.x, panel_size.z)).grow(CEILING_LIGHT_WALL_CLEARANCE)
	for wall_spec in _internal_wall_specs(node, size):
		var wall_position: Vector3 = wall_spec["position"]
		var wall_size: Vector3 = wall_spec["size"]
		var wall_rect = _local_xz_rect(wall_position, Vector2(wall_size.x, wall_size.z)).grow(CEILING_LIGHT_WALL_CLEARANCE)
		if panel_rect.intersects(wall_rect, true):
			return -INF
	for pillar_spec in _feature_pillar_specs_for_node(node, size):
		var pillar_position: Vector3 = pillar_spec["position"]
		var pillar_size: Vector3 = pillar_spec["size"]
		var pillar_rect = _local_xz_rect(pillar_position, Vector2(pillar_size.x, pillar_size.z)).grow(CEILING_LIGHT_WALL_CLEARANCE)
		if panel_rect.intersects(pillar_rect, true):
			return -INF

	var distance_penalty = Vector2(local_position.x, local_position.z).length() * 0.18
	var corridor_bonus = 0.0
	if String(node.get("space_kind", "")) == "long_corridor":
		corridor_bonus = 2.0
	return 100.0 + corridor_bonus - distance_penalty

func _panel_fits_occupied_cells(node: Dictionary, center: Vector3, panel_size: Vector3, local_position: Vector3, clearance: float) -> bool:
	var half_x = panel_size.x * 0.5 + clearance
	var half_z = panel_size.z * 0.5 + clearance
	var corners = [
		Vector2(center.x + local_position.x - half_x, center.z + local_position.z - half_z),
		Vector2(center.x + local_position.x + half_x, center.z + local_position.z - half_z),
		Vector2(center.x + local_position.x + half_x, center.z + local_position.z + half_z),
		Vector2(center.x + local_position.x - half_x, center.z + local_position.z + half_z),
	]
	for corner in corners:
		if not _world_xz_inside_occupied_cells(node, corner):
			return false
	return true

func _world_xz_inside_occupied_cells(node: Dictionary, world_xz: Vector2) -> bool:
	for cell in _occupied_cells(node):
		var rect = Rect2(Vector2(float(cell.x) * CELL_SIZE, float(cell.y) * CELL_SIZE), Vector2(CELL_SIZE, CELL_SIZE))
		if rect.has_point(world_xz):
			return true
	return false

func _local_xz_rect(position: Vector3, size: Vector2) -> Rect2:
	return Rect2(Vector2(position.x - size.x * 0.5, position.z - size.y * 0.5), size)

func _feature_pillar_specs_for_node(node: Dictionary, size: Vector2) -> Array[Dictionary]:
	if String(node.get("feature_template", "")) == "pillar_hall":
		return _feature_pillar_specs(size)
	return []

func _internal_wall_specs(node: Dictionary, size: Vector2) -> Array[Dictionary]:
	var module_type = String(node.get("module_id", ""))
	if module_type == "hub_room_partitioned":
		return _internal_hub_partition_specs(size)
	if String(node.get("space_kind", "")) != "large_internal":
		return []
	match module_type:
		"large_room_split_ns":
			return _internal_split_ns_specs(size)
		"large_room_split_ew":
			return _internal_split_ew_specs(size)
		"large_room_offset_inner_door":
			return _internal_offset_door_specs(size)
		"large_room_with_side_chamber":
			return _internal_side_chamber_specs(size)
		_:
			return _internal_split_ns_specs(size)

func _internal_split_ns_specs(size: Vector2) -> Array[Dictionary]:
	var gap = INTERNAL_PASSAGE_WIDTH
	var gap_center = -size.x * 0.16
	var left_length = maxf(0.1, gap_center + size.x * 0.5 - gap * 0.5)
	var right_length = maxf(0.1, size.x * 0.5 - gap_center - gap * 0.5)
	var left_center = -size.x * 0.5 + left_length * 0.5
	var right_center = gap_center + gap * 0.5 + right_length * 0.5
	return [
		{"suffix": "SplitNS_Left", "position": Vector3(left_center, WALL_Y, 0.0), "size": Vector3(left_length, WALL_HEIGHT, WALL_THICKNESS)},
		{"suffix": "SplitNS_Right", "position": Vector3(right_center, WALL_Y, 0.0), "size": Vector3(right_length, WALL_HEIGHT, WALL_THICKNESS)},
	]

func _internal_split_ew_specs(size: Vector2) -> Array[Dictionary]:
	var gap = INTERNAL_PASSAGE_WIDTH
	var gap_center = size.y * 0.14
	var south_length = maxf(0.1, gap_center + size.y * 0.5 - gap * 0.5)
	var north_length = maxf(0.1, size.y * 0.5 - gap_center - gap * 0.5)
	var south_center = -size.y * 0.5 + south_length * 0.5
	var north_center = gap_center + gap * 0.5 + north_length * 0.5
	return [
		{"suffix": "SplitEW_South", "position": Vector3(0.0, WALL_Y, south_center), "size": Vector3(WALL_THICKNESS, WALL_HEIGHT, south_length)},
		{"suffix": "SplitEW_North", "position": Vector3(0.0, WALL_Y, north_center), "size": Vector3(WALL_THICKNESS, WALL_HEIGHT, north_length)},
	]

func _internal_offset_door_specs(size: Vector2) -> Array[Dictionary]:
	var gap = INTERNAL_PASSAGE_WIDTH
	var segment_length = maxf(0.1, (size.x - gap) * 0.5)
	var offset = minf(size.y * 0.18, CELL_SIZE * 0.35)
	return [
		{"suffix": "OffsetDoor_Left", "position": Vector3(-gap * 0.5 - segment_length * 0.5, WALL_Y, offset), "size": Vector3(segment_length, WALL_HEIGHT, WALL_THICKNESS)},
		{"suffix": "OffsetDoor_Right", "position": Vector3(gap * 0.5 + segment_length * 0.5, WALL_Y, offset), "size": Vector3(segment_length, WALL_HEIGHT, WALL_THICKNESS)},
	]

func _internal_side_chamber_specs(size: Vector2) -> Array[Dictionary]:
	var chamber_depth = minf(CELL_SIZE * 0.72, size.y * 0.45)
	var wall_x = size.x * 0.22
	var wall_z = -size.y * 0.5 + chamber_depth * 0.5
	return [
		{"suffix": "SideChamber_Divider", "position": Vector3(wall_x, WALL_Y, wall_z), "size": Vector3(WALL_THICKNESS, WALL_HEIGHT, chamber_depth)},
		{"suffix": "SideChamber_Back", "position": Vector3(wall_x * 0.5, WALL_Y, -size.y * 0.5 + chamber_depth), "size": Vector3(size.x * 0.45, WALL_HEIGHT, WALL_THICKNESS)},
	]

func _internal_hub_partition_specs(size: Vector2) -> Array[Dictionary]:
	var vertical_segment = minf(size.y * 0.42, CELL_SIZE * 1.65)
	var horizontal_segment = minf(size.x * 0.42, CELL_SIZE * 1.65)
	return [
		{"suffix": "HubPartition_NS", "position": Vector3(-size.x * 0.18, WALL_Y, 0.0), "size": Vector3(WALL_THICKNESS, WALL_HEIGHT, vertical_segment)},
		{"suffix": "HubPartition_EW", "position": Vector3(size.x * 0.18, WALL_Y, -size.y * 0.12), "size": Vector3(horizontal_segment, WALL_HEIGHT, WALL_THICKNESS)},
	]

func _ceiling_light_panel_size(node: Dictionary) -> Vector3:
	if String(node.get("type", "")) != "corridor":
		return CEILING_LIGHT_PANEL_SIZE
	var rect = _rect(node)
	var long_axis = maxf(float(rect.size.x), float(rect.size.y)) * CELL_SIZE
	var panel_length = clampf(long_axis * 0.34, 1.35, 4.2)
	if rect.size.x >= rect.size.y:
		return Vector3(panel_length, CEILING_LIGHT_PANEL_SIZE.y, 0.42)
	return Vector3(0.42, CEILING_LIGHT_PANEL_SIZE.y, panel_length)

func _create_world_environment(parent: Node3D) -> void:
	var environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = WORLD_BACKGROUND_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = WORLD_AMBIENT_COLOR
	environment.ambient_light_energy = WORLD_AMBIENT_ENERGY
	environment.ambient_light_sky_contribution = 0.0
	environment.set("adjustment_enabled", false)
	environment.set("tonemap_exposure", 1.0)
	environment.set("sdfgi_enabled", false)
	environment.set("ssao_enabled", false)
	environment.set("ssil_enabled", false)
	var world_environment = WorldEnvironment.new()
	world_environment.name = "WorldEnvironment"
	world_environment.environment = environment
	parent.add_child(world_environment)

func _create_overview_camera(scene_root: Node3D, node_map: Dictionary) -> void:
	var bounds = _graph_world_bounds(node_map)
	var center = Vector3((bounds.position.x + bounds.end.x) * 0.5, 0.0, (bounds.position.y + bounds.end.y) * 0.5)
	var camera = scene_root.get_node_or_null("Camera3D") as Camera3D
	if camera == null:
		camera = Camera3D.new()
		camera.name = "Camera3D"
		scene_root.add_child(camera)
	camera.current = true
	camera.fov = 65.0
	camera.position = center + Vector3(0.0, 34.0, 30.0)
	camera.look_at_from_position(camera.position, center + Vector3(0.0, 0.7, 0.0), Vector3.UP)

func _build_opening_specs(edges: Array, node_map: Dictionary) -> Dictionary:
	var specs = {}
	for edge in edges:
		var a = String(edge["a"])
		var b = String(edge["b"])
		var shared = _get_shared_edge(node_map[a], node_map[b])
		if shared.is_empty():
			continue
		var boundary_key = _shared_boundary_key(shared)
		var center = _shared_boundary_world_center(shared)
		specs[boundary_key] = {
			"edge_id": String(edge["id"]),
			"node_a": a,
			"node_b": b,
			"area_a": String(node_map[a].get("area_id", "")),
			"area_b": String(node_map[b].get("area_id", "")),
			"boundary_key": boundary_key,
			"span_axis": String(shared["axis"]),
			"center": center,
		}
	return specs

func _build_keyed_outer_exit_spec(nodes: Array, node_map: Dictionary, opening_specs: Dictionary) -> Dictionary:
	var exit_id := _find_exit_node_id(nodes)
	if exit_id.is_empty() or not node_map.has(exit_id):
		return {}
	var cell_owner := _build_cell_owner(node_map)
	var candidates := _outer_wall_candidates_for_node(node_map[exit_id], cell_owner, opening_specs)
	if candidates.is_empty():
		return {}
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a.get("boundary_key", "")) < String(b.get("boundary_key", ""))
	)
	var candidate: Dictionary = candidates[_stable_index("%s:keyed_outer_exit:%d" % [exit_id, candidates.size()], candidates.size())]
	return {
		"edge_id": "KeyedOuterExit",
		"node_a": exit_id,
		"node_b": "__outside__",
		"area_a": String(node_map[exit_id].get("area_id", "")),
		"area_b": "outside",
		"boundary_key": String(candidate.get("boundary_key", "")),
		"span_axis": String(candidate.get("span_axis", "")),
		"center": candidate.get("center", Vector3.ZERO),
		"side": String(candidate.get("side", "")),
		"is_outer_exit": true,
		"owner_module_id": exit_id,
	}

func _outer_wall_candidates_for_node(node: Dictionary, cell_owner: Dictionary, opening_specs: Dictionary) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	for cell in _occupied_cells(node):
		_append_outer_wall_candidate(candidates, cell_owner, opening_specs, cell, -1, 0, "west")
		_append_outer_wall_candidate(candidates, cell_owner, opening_specs, cell, 1, 0, "east")
		_append_outer_wall_candidate(candidates, cell_owner, opening_specs, cell, 0, -1, "north")
		_append_outer_wall_candidate(candidates, cell_owner, opening_specs, cell, 0, 1, "south")
	return candidates

func _append_outer_wall_candidate(candidates: Array[Dictionary], cell_owner: Dictionary, opening_specs: Dictionary, cell: Vector2i, dx: int, dz: int, side: String) -> void:
	var neighbor_key := "%d,%d" % [cell.x + dx, cell.y + dz]
	if cell_owner.has(neighbor_key):
		return
	var boundary_key := _boundary_key(cell.x, cell.y, dx, dz)
	if opening_specs.has(boundary_key):
		return
	candidates.append({
		"cell": cell,
		"side": side,
		"boundary_key": boundary_key,
		"span_axis": "z" if dx != 0 else "x",
		"center": _boundary_world_center(cell.x, cell.y, dx, dz),
	})

func _build_door_reveals_by_node(opening_specs: Dictionary, node_map: Dictionary) -> Dictionary:
	var result = {}
	for boundary_key in opening_specs.keys():
		var spec: Dictionary = opening_specs[boundary_key]
		var candidates = _door_reveal_candidates_for_spec(spec)
		for node_id in [String(spec.get("node_a", "")), String(spec.get("node_b", ""))]:
			if not node_map.has(node_id):
				continue
			var node_reveals: Array = result.get(node_id, [])
			for candidate in candidates:
				var reveal_rect: Rect2 = candidate.get("rect", Rect2())
				if reveal_rect.size == Vector2.ZERO:
					continue
				if _rect_overlaps_node_occupied_cells(node_map[node_id], reveal_rect):
					var reveal = candidate.duplicate(true)
					reveal["edge_id"] = String(spec.get("edge_id", ""))
					reveal["node_id"] = node_id
					node_reveals.append(reveal)
			if not node_reveals.is_empty():
				result[node_id] = node_reveals
	return result

func _door_reveal_candidates_for_spec(spec: Dictionary) -> Array[Dictionary]:
	var center: Vector3 = spec.get("center", Vector3.ZERO)
	var span_axis = String(spec.get("span_axis", ""))
	if span_axis == "z":
		var reveal_size = Vector2(DOOR_REVEAL_DEPTH, DOOR_REVEAL_WIDTH)
		return [
			{"side": "negative_x", "rect": Rect2(Vector2(center.x - DOOR_REVEAL_DEPTH, center.z - DOOR_REVEAL_WIDTH * 0.5), reveal_size)},
			{"side": "positive_x", "rect": Rect2(Vector2(center.x, center.z - DOOR_REVEAL_WIDTH * 0.5), reveal_size)},
		]
	var reveal_size = Vector2(DOOR_REVEAL_WIDTH, DOOR_REVEAL_DEPTH)
	return [
		{"side": "negative_z", "rect": Rect2(Vector2(center.x - DOOR_REVEAL_WIDTH * 0.5, center.z - DOOR_REVEAL_DEPTH), reveal_size)},
		{"side": "positive_z", "rect": Rect2(Vector2(center.x - DOOR_REVEAL_WIDTH * 0.5, center.z), reveal_size)},
	]

func _rect_overlaps_node_occupied_cells(node: Dictionary, world_rect: Rect2) -> bool:
	for cell in _occupied_cells(node):
		var cell_rect = Rect2(Vector2(float(cell.x) * CELL_SIZE, float(cell.y) * CELL_SIZE), Vector2(CELL_SIZE, CELL_SIZE))
		if cell_rect.intersects(world_rect, false):
			return true
	return false

func _get_or_create_node3d(parent: Node, child_name: String) -> Node3D:
	var existing = parent.get_node_or_null(child_name) as Node3D
	if existing != null:
		return existing
	var created = Node3D.new()
	created.name = child_name
	parent.add_child(created)
	return created

func _get_nodes_in_group(root: Node, group_name: String) -> Array:
	var result = []
	_collect_nodes_in_group(root, group_name, result)
	return result

func _collect_nodes_in_group(node: Node, group_name: String, result: Array) -> void:
	if node.is_in_group(group_name):
		result.append(node)
	for child in node.get_children():
		_collect_nodes_in_group(child, group_name, result)

func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.free()

func _create_box_body(
	parent: Node3D,
	node_name: String,
	local_position: Vector3,
	size: Vector3,
	material: Material,
	add_collision: bool,
	include_horizontal_caps: bool,
	visual_size_override := Vector3.ZERO
) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.name = node_name
	body.add_to_group("proc_maze_generated", true)
	parent.add_child(body)
	body.position = local_position

	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "Mesh"
	var visual_size = size if visual_size_override == Vector3.ZERO else visual_size_override
	if not include_horizontal_caps:
		visual_size.y += WALL_VISUAL_VERTICAL_OVERLAP * 2.0
	mesh_instance.mesh = GeneratedMeshRules.build_box_mesh(
		visual_size,
		material,
		WALL_UV_WORLD_SIZE,
		include_horizontal_caps,
		include_horizontal_caps,
		0.0,
		not include_horizontal_caps,
		local_position,
		WALL_HEIGHT
	)
	mesh_instance.material_override = material
	mesh_instance.layers = STATIC_GEOMETRY_LAYER
	mesh_instance.add_to_group("proc_maze_generated_mesh", true)
	body.add_child(mesh_instance)

	if add_collision:
		var shape = BoxShape3D.new()
		shape.size = size
		var collision = CollisionShape3D.new()
		collision.name = "Collision"
		collision.shape = shape
		body.add_child(collision)
	return body

func _floor_uv_world(global_x: float, global_z: float) -> Vector2:
	return Vector2(global_x / FLOOR_UV_WORLD_SIZE, global_z / FLOOR_UV_WORLD_SIZE)

func _append_quad(
	vertices: PackedVector3Array,
	normals: PackedVector3Array,
	uvs: PackedVector2Array,
	a: Vector3,
	b: Vector3,
	c: Vector3,
	d: Vector3,
	normal: Vector3,
	uv_a: Vector2,
	uv_b: Vector2,
	uv_c: Vector2,
	uv_d: Vector2
) -> void:
	GeneratedMeshRules.append_oriented_triangle(vertices, normals, uvs, a, b, c, normal, uv_a, uv_b, uv_c)
	GeneratedMeshRules.append_oriented_triangle(vertices, normals, uvs, a, c, d, normal, uv_a, uv_c, uv_d)

func _boundary_key(gx: int, gz: int, dx: int, dz: int) -> String:
	if dx != 0:
		var x_line = gx + 1 if dx > 0 else gx
		return "v:%d:%d" % [x_line, gz]
	var z_line = gz + 1 if dz > 0 else gz
	return "h:%d:%d" % [z_line, gx]

func _boundary_world_center(gx: int, gz: int, dx: int, dz: int) -> Vector3:
	if dx != 0:
		var x_line = gx + 1 if dx > 0 else gx
		return Vector3(x_line * CELL_SIZE, 0.0, (gz + 0.5) * CELL_SIZE)
	var z_line = gz + 1 if dz > 0 else gz
	return Vector3((gx + 0.5) * CELL_SIZE, 0.0, z_line * CELL_SIZE)

func _shared_boundary_key(shared: Dictionary) -> String:
	if String(shared["axis"]) == "z":
		return "v:%d:%d" % [int(shared["line"]), int(shared["unit"])]
	return "h:%d:%d" % [int(shared["line"]), int(shared["unit"])]

func _shared_boundary_world_center(shared: Dictionary) -> Vector3:
	if String(shared["axis"]) == "z":
		return Vector3(int(shared["line"]) * CELL_SIZE, 0.0, (int(shared["unit"]) + 0.5) * CELL_SIZE)
	return Vector3((int(shared["unit"]) + 0.5) * CELL_SIZE, 0.0, int(shared["line"]) * CELL_SIZE)

func _build_cell_owner(node_map: Dictionary) -> Dictionary:
	var cell_owner = {}
	for node_id in node_map.keys():
		for cell in _occupied_cells(node_map[node_id]):
			cell_owner[_cell_key(cell)] = String(node_id)
	return cell_owner

func _build_node_map(nodes: Array) -> Dictionary:
	var node_map = {}
	for node in nodes:
		node_map[String(node.get("id", ""))] = node
	return node_map

func _build_adjacency(nodes: Array, edges: Array) -> Dictionary:
	var adjacency = {}
	for node in nodes:
		adjacency[String(node.get("id", ""))] = []
	for edge in edges:
		var a = String(edge.get("a", ""))
		var b = String(edge.get("b", ""))
		if not adjacency.has(a) or not adjacency.has(b):
			continue
		adjacency[a].append(b)
		adjacency[b].append(a)
	return adjacency

func _get_shared_edge(a_node: Dictionary, b_node: Dictionary) -> Dictionary:
	var b_lookup = {}
	for b_cell in _occupied_cells(b_node):
		b_lookup[_cell_key(b_cell)] = b_cell
	for a_cell in _occupied_cells(a_node):
		var candidates = [
			{"cell": Vector2i(a_cell.x + 1, a_cell.y), "axis": "z", "line": a_cell.x + 1, "unit": a_cell.y},
			{"cell": Vector2i(a_cell.x - 1, a_cell.y), "axis": "z", "line": a_cell.x, "unit": a_cell.y},
			{"cell": Vector2i(a_cell.x, a_cell.y + 1), "axis": "x", "line": a_cell.y + 1, "unit": a_cell.x},
			{"cell": Vector2i(a_cell.x, a_cell.y - 1), "axis": "x", "line": a_cell.y, "unit": a_cell.x},
		]
		for candidate in candidates:
			var other_cell: Vector2i = candidate["cell"]
			if b_lookup.has(_cell_key(other_cell)):
				return {
					"axis": String(candidate["axis"]),
					"line": int(candidate["line"]),
					"unit": int(candidate["unit"]),
				}
	return {}

func _rect(node: Dictionary) -> Rect2i:
	var footprint: Dictionary = node.get("footprint", {})
	return Rect2i(
		int(footprint.get("x", 0)),
		int(footprint.get("z", 0)),
		int(footprint.get("w", 1)),
		int(footprint.get("h", 1))
	)

func _rect_center_world(rect: Rect2i) -> Vector3:
	return Vector3((rect.position.x + rect.size.x * 0.5) * CELL_SIZE, 0.0, (rect.position.y + rect.size.y * 0.5) * CELL_SIZE)

func _rect_size_world(rect: Rect2i) -> Vector2:
	return Vector2(rect.size.x * CELL_SIZE, rect.size.y * CELL_SIZE)

func _node_center_world(node: Dictionary) -> Vector3:
	var cells = _occupied_cells(node)
	if cells.is_empty():
		return _rect_center_world(_rect(node))
	var sum = Vector2.ZERO
	for cell in cells:
		sum += Vector2((cell.x + 0.5) * CELL_SIZE, (cell.y + 0.5) * CELL_SIZE)
	sum /= float(cells.size())
	return Vector3(sum.x, 0.0, sum.y)

func _occupied_cells(node: Dictionary) -> Array[Vector2i]:
	var rect = _rect(node)
	var shape_cells: Array = node.get("shape_cells", [])
	var cells: Array[Vector2i] = []
	if shape_cells.is_empty():
		for gx in range(rect.position.x, rect.position.x + rect.size.x):
			for gz in range(rect.position.y, rect.position.y + rect.size.y):
				cells.append(Vector2i(gx, gz))
		return cells
	for raw_cell in shape_cells:
		var rel = _to_vector2i(raw_cell)
		if rel.x < 0 or rel.y < 0 or rel.x >= rect.size.x or rel.y >= rect.size.y:
			continue
		cells.append(Vector2i(rect.position.x + rel.x, rect.position.y + rel.y))
	return cells

func _to_vector2i(value) -> Vector2i:
	var value_type = typeof(value)
	if value_type == TYPE_VECTOR2I:
		return value
	if value_type == TYPE_VECTOR2:
		return Vector2i(int(value.x), int(value.y))
	if value_type == TYPE_ARRAY and value.size() >= 2:
		return Vector2i(int(value[0]), int(value[1]))
	if value_type == TYPE_DICTIONARY:
		return Vector2i(int(value.get("x", 0)), int(value.get("z", value.get("y", 0))))
	return Vector2i.ZERO

func _cell_key(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]

func _graph_world_bounds(node_map: Dictionary) -> Rect2:
	var initialized = false
	var min_x = 0.0
	var min_z = 0.0
	var max_x = 0.0
	var max_z = 0.0
	for node_id in node_map.keys():
		for cell in _occupied_cells(node_map[node_id]):
			var x0 = cell.x * CELL_SIZE
			var z0 = cell.y * CELL_SIZE
			var x1 = (cell.x + 1) * CELL_SIZE
			var z1 = (cell.y + 1) * CELL_SIZE
			if not initialized:
				min_x = x0
				min_z = z0
				max_x = x1
				max_z = z1
				initialized = true
			else:
				min_x = minf(min_x, x0)
				min_z = minf(min_z, z0)
				max_x = maxf(max_x, x1)
				max_z = maxf(max_z, z1)
	return Rect2(Vector2(min_x, min_z), Vector2(max_x - min_x, max_z - min_z))
