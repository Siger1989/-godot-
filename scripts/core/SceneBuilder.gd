extends Node

@export_file("*.yaml") var layout_path := "res://data/four_room_mvp_layout.yaml"

const RoomModuleScript = preload("res://scripts/scene/RoomModule.gd")
const WallModuleScript = preload("res://scripts/scene/WallModule.gd")
const PortalComponentScript = preload("res://scripts/scene/PortalComponent.gd")
const MarkerComponentScript = preload("res://scripts/scene/MarkerComponent.gd")
const DoorFrameVisualScript = preload("res://scripts/scene/DoorFrameVisual.gd")
const WallOpeningBodyScript = preload("res://scripts/scene/WallOpeningBody.gd")
const GeneratedMeshRules = preload("res://scripts/scene/GeneratedMeshRules.gd")
const ContactShadowMaterial = preload("res://scripts/visual/ContactShadowMaterial.gd")
const WallMaterial = preload("res://materials/backrooms_wall.tres")
const FloorMaterial = preload("res://materials/backrooms_floor.tres")
const CeilingMaterial = preload("res://materials/backrooms_ceiling.tres")
const DoorFrameMaterial = preload("res://materials/backrooms_door_frame.tres")
const CeilingLightMaterial = preload("res://materials/backrooms_ceiling_light.tres")

const ROOM_SIZE := 6.0
const ROOM_HALF_SIZE := ROOM_SIZE * 0.5
const WALL_HEIGHT := 2.55
const WALL_THICKNESS := 0.2
const WALL_JOIN_OVERLAP := 0.04
const WALL_JOINT_SIZE := 0.36
const WALL_SPAN_LENGTH := ROOM_SIZE - WALL_JOINT_SIZE
const DOOR_OPENING_WIDTH := 1.15
const DOOR_FRAME_TRIM_WIDTH := 0.10
const DOOR_FRAME_SIDE_CLEARANCE := 0.0
const DOOR_FRAME_DEPTH := WALL_THICKNESS - 0.04
const DOOR_FRAME_OUTER_HEIGHT := 2.18
const DOOR_CLEARANCE_HEIGHT := 2.15
const WALL_HEADER_OVERLAP := 0.02
const WALL_OPENING_HEIGHT := DOOR_FRAME_OUTER_HEIGHT - WALL_HEADER_OVERLAP
const FLOOR_THICKNESS := 0.1
const FLOOR_Y := -0.05
const FLOOR_COLLISION_THICKNESS := 0.12
const FLOOR_COLLISION_Y := -FLOOR_COLLISION_THICKNESS * 0.5
const FLOOR_COLLISION_SIZE := Vector3(12.16, FLOOR_COLLISION_THICKNESS, 12.16)
const FLOOR_UV_WORLD_SIZE := 12.0
const WALL_UV_WORLD_SIZE := 6.0
const WALL_VISUAL_VERTICAL_OVERLAP := 0.08
const WALL_Y := WALL_HEIGHT * 0.5
const CEILING_THICKNESS := 0.1
const CEILING_Y := WALL_HEIGHT + CEILING_THICKNESS * 0.5
const CEILING_LIGHT_PANEL_SIZE := Vector3(1.2, 0.08, 0.7)
const CEILING_LIGHT_PANEL_Y := WALL_HEIGHT - CEILING_LIGHT_PANEL_SIZE.y * 0.5 + 0.01
const CEILING_LIGHT_Y := WALL_HEIGHT - 0.26
const CEILING_LIGHT_ENERGY := 1.12
const CEILING_LIGHT_RANGE := 6.0
const CEILING_LIGHT_ATTENUATION := 0.92
const CEILING_LIGHT_SHADOW_BIAS := 0.02
const CEILING_LIGHT_SHADOW_NORMAL_BIAS := 0.35
const CEILING_LIGHT_SHADOW_OPACITY := 1.0
const WORLD_AMBIENT_COLOR := Color(1.0, 0.9, 0.66)
const WORLD_AMBIENT_ENERGY := 0.07
const WORLD_BACKGROUND_COLOR := Color(0.015, 0.014, 0.012)
# Type-level visual rule: rooms define space and area metadata only. Static
# geometry uses one layer regardless of which room it helps form.
const STATIC_GEOMETRY_LAYER := 1 << 0
const ACTOR_LIGHT_LAYER := 1 << 8

var _surface_material_cache: Dictionary = {}

static func get_actor_light_layer() -> int:
	return ACTOR_LIGHT_LAYER

static func get_all_room_light_layers() -> int:
	return STATIC_GEOMETRY_LAYER

func build() -> void:
	_surface_material_cache.clear()
	var scene_root := _get_owning_scene_root()
	if scene_root == null:
		return
	var level_root := scene_root.get_node_or_null("LevelRoot") as Node3D
	if level_root == null:
		push_warning("SceneBuilder could not find LevelRoot.")
		return

	_remove_legacy_rooms_root(level_root)
	var geometry_root := _get_or_create_level_child(level_root, "Geometry")
	var areas_root := _get_or_create_level_child(level_root, "Areas")
	var portals_root := _get_or_create_level_child(level_root, "Portals")
	var markers_root := _get_or_create_level_child(level_root, "Markers")
	var lights_root := _get_or_create_level_child(level_root, "Lights")

	_clear_children(geometry_root)
	_clear_children(areas_root)
	_clear_children(portals_root)
	_clear_children(markers_root)
	_clear_children(lights_root)

	_create_world_environment(lights_root)

	var rooms := _get_room_specs()
	_create_floor_slabs(geometry_root, rooms)
	for room in rooms:
		_create_room_area(areas_root, room)

	_create_ceilings(geometry_root, rooms)

	for wall_piece in _get_wall_piece_specs():
		_create_wall_piece(geometry_root, wall_piece)

	for frame in _get_door_frame_specs():
		_create_door_frame(geometry_root, frame)

	for room in rooms:
		_create_ceiling_light(geometry_root, lights_root, room)

	for portal in _get_portal_specs():
		_create_portal(portals_root, portal)

	for marker in _get_marker_specs():
		_create_marker(markers_root, marker)

	_relink_existing_doors(level_root, portals_root)

func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.free()

func _relink_existing_doors(level_root: Node3D, portals_root: Node3D) -> void:
	var doors_root := level_root.get_node_or_null("Doors") as Node3D
	if doors_root == null:
		return
	for child in doors_root.get_children():
		var door := child as Node3D
		if door == null:
			continue
		var portal_id := String(door.get_meta("portal_id", ""))
		if portal_id.is_empty():
			continue
		var portal := portals_root.get_node_or_null(portal_id)
		if portal != null:
			portal.set("door_node_path", portal.get_path_to(door))

func _remove_legacy_rooms_root(level_root: Node3D) -> void:
	var legacy_rooms_root := level_root.get_node_or_null("Rooms")
	if legacy_rooms_root != null:
		legacy_rooms_root.free()

func _get_or_create_level_child(level_root: Node3D, child_name: String) -> Node3D:
	var existing := level_root.get_node_or_null(child_name) as Node3D
	if existing != null:
		return existing
	var created := Node3D.new()
	created.name = child_name
	level_root.add_child(created)
	return created

func _surface_material(kind: String) -> Material:
	if _surface_material_cache.has(kind):
		return _surface_material_cache[kind]
	var material: Material = null
	match kind:
		"wall":
			material = ContactShadowMaterial.make_wall(WallMaterial)
		"floor":
			material = ContactShadowMaterial.make_floor(FloorMaterial)
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
	var seed := 17
	for index in range(text.length()):
		seed = int((seed * 131 + text.unicode_at(index)) % 1000003)
	return float(seed)

func _get_owning_scene_root() -> Node:
	var node: Node = self
	while node.get_parent() != null and node.get_parent() != get_tree().root:
		node = node.get_parent()
	return node

func _get_room_specs() -> Array[Dictionary]:
	return [
		{
			"id": "Room_A",
			"name": "Room_A_Start",
			"area_id": "area_start",
			"type": "player_start",
			"center": Vector3(0.0, 0.0, 0.0),
			"size": Vector2(ROOM_SIZE, ROOM_SIZE),
			"portals": PackedStringArray(["P_AB", "P_DA"]),
		},
		{
			"id": "Room_B",
			"name": "Room_B_Light",
			"area_id": "area_light",
			"type": "lighting_test",
			"center": Vector3(6.0, 0.0, 0.0),
			"size": Vector2(ROOM_SIZE, ROOM_SIZE),
			"portals": PackedStringArray(["P_AB", "P_BC"]),
		},
		{
			"id": "Room_C",
			"name": "Room_C_Objective",
			"area_id": "area_objective",
			"type": "objective_test",
			"center": Vector3(6.0, 0.0, 6.0),
			"size": Vector2(ROOM_SIZE, ROOM_SIZE),
			"portals": PackedStringArray(["P_BC", "P_CD"]),
		},
		{
			"id": "Room_D",
			"name": "Room_D_Occlusion",
			"area_id": "area_narrow",
			"type": "occlusion_test",
			"center": Vector3(0.0, 0.0, 6.0),
			"size": Vector2(ROOM_SIZE, ROOM_SIZE),
			"portals": PackedStringArray(["P_CD", "P_DA"]),
		},
	]

func _get_wall_piece_specs() -> Array[Dictionary]:
	return [
		{"type": "solid", "id": "Wall_South_A", "center": Vector3(0.0, WALL_Y, -ROOM_HALF_SIZE), "size": Vector3(WALL_SPAN_LENGTH, WALL_HEIGHT, WALL_THICKNESS), "area": "area_start", "void": true},
		{"type": "solid", "id": "Wall_West_A", "center": Vector3(-ROOM_HALF_SIZE, WALL_Y, 0.0), "size": Vector3(WALL_THICKNESS, WALL_HEIGHT, WALL_SPAN_LENGTH), "area": "area_start", "void": true},
		{"type": "solid", "id": "Wall_South_B", "center": Vector3(6.0, WALL_Y, -ROOM_HALF_SIZE), "size": Vector3(WALL_SPAN_LENGTH, WALL_HEIGHT, WALL_THICKNESS), "area": "area_light", "void": true},
		{"type": "solid", "id": "Wall_East_B", "center": Vector3(9.0, WALL_Y, 0.0), "size": Vector3(WALL_THICKNESS, WALL_HEIGHT, WALL_SPAN_LENGTH), "area": "area_light", "void": true},
		{"type": "solid", "id": "Wall_East_C", "center": Vector3(9.0, WALL_Y, 6.0), "size": Vector3(WALL_THICKNESS, WALL_HEIGHT, WALL_SPAN_LENGTH), "area": "area_objective", "void": true},
		{"type": "opening", "id": "WallOpening_Exit_C_North", "center": Vector3(6.0, 0.0, 9.0), "axis": "z", "length": WALL_SPAN_LENGTH, "width": DOOR_OPENING_WIDTH, "area": "area_objective", "areas": ["area_objective"], "void": true},
		{"type": "solid", "id": "Wall_North_D", "center": Vector3(0.0, WALL_Y, 9.0), "size": Vector3(WALL_SPAN_LENGTH, WALL_HEIGHT, WALL_THICKNESS), "area": "area_narrow", "void": true},
		{"type": "solid", "id": "Wall_West_D", "center": Vector3(-ROOM_HALF_SIZE, WALL_Y, 6.0), "size": Vector3(WALL_THICKNESS, WALL_HEIGHT, WALL_SPAN_LENGTH), "area": "area_narrow", "void": true},
		{"type": "solid", "id": "WallJoint_A_SouthWest", "center": Vector3(-3.0, WALL_Y, -3.0), "size": Vector3(WALL_JOINT_SIZE, WALL_HEIGHT, WALL_JOINT_SIZE), "area": "area_start", "void": true},
		{"type": "solid", "id": "WallJoint_AB_SouthOuter", "center": Vector3(3.0, WALL_Y, -3.0), "size": Vector3(WALL_JOINT_SIZE, WALL_HEIGHT, WALL_JOINT_SIZE), "area": "area_start", "areas": ["area_start", "area_light"], "void": true},
		{"type": "solid", "id": "WallJoint_B_SouthEast", "center": Vector3(9.0, WALL_Y, -3.0), "size": Vector3(WALL_JOINT_SIZE, WALL_HEIGHT, WALL_JOINT_SIZE), "area": "area_light", "void": true},
		{"type": "solid", "id": "WallJoint_BC_EastOuter", "center": Vector3(9.0, WALL_Y, 3.0), "size": Vector3(WALL_JOINT_SIZE, WALL_HEIGHT, WALL_JOINT_SIZE), "area": "area_light", "areas": ["area_light", "area_objective"], "void": true},
		{"type": "solid", "id": "WallJoint_C_NorthEast", "center": Vector3(9.0, WALL_Y, 9.0), "size": Vector3(WALL_JOINT_SIZE, WALL_HEIGHT, WALL_JOINT_SIZE), "area": "area_objective", "void": true},
		{"type": "solid", "id": "WallJoint_CD_NorthOuter", "center": Vector3(3.0, WALL_Y, 9.0), "size": Vector3(WALL_JOINT_SIZE, WALL_HEIGHT, WALL_JOINT_SIZE), "area": "area_objective", "areas": ["area_objective", "area_narrow"], "void": true},
		{"type": "solid", "id": "WallJoint_D_NorthWest", "center": Vector3(-3.0, WALL_Y, 9.0), "size": Vector3(WALL_JOINT_SIZE, WALL_HEIGHT, WALL_JOINT_SIZE), "area": "area_narrow", "void": true},
		{"type": "solid", "id": "WallJoint_DA_WestOuter", "center": Vector3(-3.0, WALL_Y, 3.0), "size": Vector3(WALL_JOINT_SIZE, WALL_HEIGHT, WALL_JOINT_SIZE), "area": "area_narrow", "areas": ["area_narrow", "area_start"], "void": true},
		{"type": "solid", "id": "WallJoint_Center", "center": Vector3(3.0, WALL_Y, 3.0), "size": Vector3(WALL_JOINT_SIZE, WALL_HEIGHT, WALL_JOINT_SIZE), "area": "area_start", "areas": ["area_start", "area_light", "area_objective", "area_narrow"], "void": false},
		{"type": "opening", "id": "WallOpening_P_AB", "center": Vector3(3.0, 0.0, 0.0), "axis": "z", "length": WALL_SPAN_LENGTH, "width": DOOR_OPENING_WIDTH, "area": "area_start", "areas": ["area_start", "area_light"], "void": false},
		{"type": "opening", "id": "WallOpening_P_BC", "center": Vector3(6.0, 0.0, 3.0), "axis": "x", "length": WALL_SPAN_LENGTH, "width": DOOR_OPENING_WIDTH, "area": "area_light", "areas": ["area_light", "area_objective"], "void": false},
		{"type": "opening", "id": "WallOpening_P_CD", "center": Vector3(3.0, 0.0, 6.0), "axis": "z", "length": WALL_SPAN_LENGTH, "width": DOOR_OPENING_WIDTH, "area": "area_objective", "areas": ["area_objective", "area_narrow"], "void": false},
		{"type": "opening", "id": "WallOpening_P_DA", "center": Vector3(0.0, 0.0, 3.0), "axis": "x", "length": WALL_SPAN_LENGTH, "width": DOOR_OPENING_WIDTH, "area": "area_narrow", "areas": ["area_narrow", "area_start"], "void": false},
	]

func _get_door_frame_specs() -> Array[Dictionary]:
	return [
		{"id": "DoorFrame_P_AB", "center": Vector3(3.0, 0.0, 0.0), "axis": "z", "width": DOOR_OPENING_WIDTH, "areas": ["area_start", "area_light"]},
		{"id": "DoorFrame_P_BC", "center": Vector3(6.0, 0.0, 3.0), "axis": "x", "width": DOOR_OPENING_WIDTH, "areas": ["area_light", "area_objective"]},
		{"id": "DoorFrame_P_CD", "center": Vector3(3.0, 0.0, 6.0), "axis": "z", "width": DOOR_OPENING_WIDTH, "areas": ["area_objective", "area_narrow"]},
		{"id": "DoorFrame_P_DA", "center": Vector3(0.0, 0.0, 3.0), "axis": "x", "width": DOOR_OPENING_WIDTH, "areas": ["area_narrow", "area_start"]},
		{"id": "DoorFrame_Exit_C_North", "center": Vector3(6.0, 0.0, 9.0), "axis": "z", "width": DOOR_OPENING_WIDTH, "areas": ["area_objective"]},
	]

func _get_portal_specs() -> Array[Dictionary]:
	return [
		{"id": "P_AB", "name": "P_AB", "area_a": "area_start", "area_b": "area_light", "center": Vector3(3.0, 0.0, 0.0), "width": DOOR_OPENING_WIDTH, "height": DOOR_CLEARANCE_HEIGHT, "state": "open", "edge_axis": "z"},
		{"id": "P_BC", "name": "P_BC", "area_a": "area_light", "area_b": "area_objective", "center": Vector3(6.0, 0.0, 3.0), "width": DOOR_OPENING_WIDTH, "height": DOOR_CLEARANCE_HEIGHT, "state": "closed", "edge_axis": "x"},
		{"id": "P_CD", "name": "P_CD", "area_a": "area_objective", "area_b": "area_narrow", "center": Vector3(3.0, 0.0, 6.0), "width": DOOR_OPENING_WIDTH, "height": DOOR_CLEARANCE_HEIGHT, "state": "open", "edge_axis": "z"},
		{"id": "P_DA", "name": "P_DA", "area_a": "area_narrow", "area_b": "area_start", "center": Vector3(0.0, 0.0, 3.0), "width": DOOR_OPENING_WIDTH, "height": DOOR_CLEARANCE_HEIGHT, "state": "closed", "edge_axis": "x"},
	]

func _get_marker_specs() -> Array[Dictionary]:
	return [
		{"id": "Spawn_Player_A", "type": "PlayerSpawn", "room": "Room_A", "area": "area_start", "position": Vector3(0.0, 0.05, 0.0)},
		{"id": "Spawn_Monster_D", "type": "MonsterSpawn", "room": "Room_D", "area": "area_narrow", "position": Vector3(-1.1, 0.05, 7.0)},
		{"id": "Spawn_Item_B", "type": "ItemSpawn", "room": "Room_B", "area": "area_light", "position": Vector3(7.0, 0.05, 0.5)},
		{"id": "Trigger_Event_C", "type": "EventTrigger", "room": "Room_C", "area": "area_objective", "position": Vector3(5.0, 0.05, 5.0)},
		{"id": "Exit_C_01", "type": "ExitPoint", "room": "Room_C", "area": "area_objective", "position": Vector3(6.0, 0.05, 8.45)},
		{"id": "ExitDoor_C_North", "type": "ExitDoor", "room": "Room_C", "area": "area_objective", "position": Vector3(6.0, 0.05, 8.72)},
	]

func _create_room_area(parent: Node3D, spec: Dictionary) -> void:
	var room := Node3D.new()
	room.name = spec["name"]
	room.set_script(RoomModuleScript)
	room.room_id = spec["id"]
	room.area_id = spec["area_id"]
	room.room_type = spec["type"]
	room.bounds_size = Vector3(spec["size"].x, WALL_HEIGHT, spec["size"].y)
	room.portal_ids = spec["portals"]
	parent.add_child(room)
	room.global_position = spec["center"]

func _create_floor_slabs(parent: Node3D, rooms: Array[Dictionary]) -> void:
	_create_collision_box(parent, "Floor_WalkableCollision", Vector3(3.0, FLOOR_COLLISION_Y, 3.0), FLOOR_COLLISION_SIZE)
	for room in rooms:
		var room_id: String = room["id"]
		var center: Vector3 = room["center"]
		var size: Vector2 = room["size"]
		_create_floor_visual_rect(parent, "Floor_%s" % room_id, center, size, STATIC_GEOMETRY_LAYER)

func _create_floor_visual_rect(parent: Node3D, node_name: String, center: Vector3, size: Vector2, visual_layers: int) -> MeshInstance3D:
	var half_size := size * 0.5
	var y := FLOOR_Y + FLOOR_THICKNESS * 0.5
	var local_a := Vector3(-half_size.x, 0.0, -half_size.y)
	var local_b := Vector3(half_size.x, 0.0, -half_size.y)
	var local_c := Vector3(half_size.x, 0.0, half_size.y)
	var local_d := Vector3(-half_size.x, 0.0, half_size.y)

	var vertices := PackedVector3Array([local_a, local_b, local_c, local_a, local_c, local_d])
	var normals := PackedVector3Array([
		Vector3.UP,
		Vector3.UP,
		Vector3.UP,
		Vector3.UP,
		Vector3.UP,
		Vector3.UP,
	])
	var uvs := PackedVector2Array([
		_floor_uv(center, local_a),
		_floor_uv(center, local_b),
		_floor_uv(center, local_c),
		_floor_uv(center, local_a),
		_floor_uv(center, local_c),
		_floor_uv(center, local_d),
	])

	var instance := MeshInstance3D.new()
	instance.name = node_name
	var floor_material := _surface_material("floor")
	instance.mesh = GeneratedMeshRules.build_array_mesh(vertices, normals, uvs, floor_material)
	instance.material_override = floor_material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.layers = visual_layers
	instance.add_to_group("floor_visual", true)
	parent.add_child(instance)
	instance.transform = Transform3D(Basis.IDENTITY, Vector3(center.x, y, center.z))
	return instance

func _floor_uv(center: Vector3, local_point: Vector3) -> Vector2:
	var global_x := center.x + local_point.x
	var global_z := center.z + local_point.z
	return Vector2(global_x / FLOOR_UV_WORLD_SIZE, global_z / FLOOR_UV_WORLD_SIZE)

func _create_ceilings(parent: Node3D, rooms: Array[Dictionary]) -> void:
	for room in rooms:
		var room_id: String = room["id"]
		var center: Vector3 = room["center"]
		var size: Vector2 = room["size"]
		var ceiling_size := Vector3(size.x + WALL_JOIN_OVERLAP, CEILING_THICKNESS, size.y + WALL_JOIN_OVERLAP)
		var ceiling := _create_box(parent, "Ceiling_%s" % room_id, Vector3(center.x, CEILING_Y, center.z), ceiling_size, true, _surface_material("ceiling"), STATIC_GEOMETRY_LAYER)
		ceiling.set_script(WallModuleScript)
		ceiling.wall_id = "Ceiling_%s" % room_id
		ceiling.area_id = room["area_id"]
		ceiling.is_foreground_occluder = true
		ceiling.add_to_group("foreground_occluder", true)
		ceiling.add_to_group("ceiling", true)

func _create_wall_piece(parent: Node3D, spec: Dictionary) -> void:
	var piece_type := String(spec.get("type", "solid"))
	if piece_type == "opening":
		_create_opening_wall_body(parent, spec)
		return
	_create_solid_wall_body(parent, spec)

func _create_solid_wall_body(parent: Node3D, spec: Dictionary) -> void:
	var wall := _create_box(parent, spec["id"], spec["center"], spec["size"], true, _wall_material_instance(String(spec["id"]), spec["center"]), STATIC_GEOMETRY_LAYER, false)
	wall.set_script(WallModuleScript)
	wall.wall_id = spec["id"]
	wall.area_id = spec["area"]
	wall.is_foreground_occluder = true
	wall.has_void_outer_side = spec["void"]
	wall.add_to_group("foreground_occluder", true)

func _create_opening_wall_body(parent: Node3D, spec: Dictionary) -> void:
	var opening := StaticBody3D.new()
	opening.name = spec["id"]
	opening.set_script(WallOpeningBodyScript)
	opening.wall_id = spec["id"]
	opening.area_id = spec["area"]
	opening.is_foreground_occluder = true
	opening.has_void_outer_side = spec["void"]
	opening.opening_id = spec["id"]
	opening.span_axis = spec["axis"]
	opening.span_length = spec["length"]
	opening.opening_width = spec["width"]
	opening.opening_height = WALL_OPENING_HEIGHT
	opening.wall_height = WALL_HEIGHT
	opening.wall_thickness = WALL_THICKNESS
	opening.visual_material = _wall_material_instance(String(spec["id"]), spec["center"])
	opening.visual_layers = STATIC_GEOMETRY_LAYER
	opening.add_to_group("foreground_occluder", true)
	opening.add_to_group("wall_opening", true)
	parent.add_child(opening)
	opening.global_position = spec["center"]

func _create_door_frame(parent: Node3D, spec: Dictionary) -> void:
	var frame := MeshInstance3D.new()
	frame.name = spec["id"]
	frame.set_script(DoorFrameVisualScript)
	frame.frame_id = spec["id"]
	frame.span_axis = spec["axis"]
	frame.opening_width = maxf(0.1, float(spec["width"]) - DOOR_FRAME_SIDE_CLEARANCE - DOOR_FRAME_TRIM_WIDTH * 2.0)
	frame.outer_height = DOOR_FRAME_OUTER_HEIGHT
	frame.trim_width = DOOR_FRAME_TRIM_WIDTH
	frame.frame_depth = DOOR_FRAME_DEPTH
	frame.visual_material = _surface_material("door_frame")
	frame.scale = Vector3.ONE
	frame.layers = STATIC_GEOMETRY_LAYER
	frame.add_to_group("door_frame", true)
	parent.add_child(frame)
	frame.global_position = spec["center"]

func _create_ceiling_light(visual_parent: Node3D, lights_parent: Node3D, room: Dictionary) -> void:
	var center: Vector3 = room["center"]
	var room_id: String = room["id"]
	var room_layer := STATIC_GEOMETRY_LAYER

	var panel_mesh := BoxMesh.new()
	panel_mesh.size = CEILING_LIGHT_PANEL_SIZE
	var panel := MeshInstance3D.new()
	panel.name = "CeilingLightPanel_%s" % room_id
	panel.mesh = panel_mesh
	panel.material_override = CeilingLightMaterial
	panel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	panel.layers = room_layer
	panel.add_to_group("ceiling_light_panel", true)
	visual_parent.add_child(panel)
	panel.global_position = Vector3(center.x, CEILING_LIGHT_PANEL_Y, center.z)

	var light := OmniLight3D.new()
	light.name = "CeilingLight_%s" % room_id
	light.light_color = Color(1.0, 0.86, 0.58)
	light.light_energy = CEILING_LIGHT_ENERGY
	light.omni_range = CEILING_LIGHT_RANGE
	light.omni_attenuation = CEILING_LIGHT_ATTENUATION
	light.shadow_enabled = true
	light.shadow_bias = CEILING_LIGHT_SHADOW_BIAS
	light.shadow_normal_bias = CEILING_LIGHT_SHADOW_NORMAL_BIAS
	light.shadow_opacity = CEILING_LIGHT_SHADOW_OPACITY
	light.light_cull_mask = room_layer | ACTOR_LIGHT_LAYER
	light.shadow_caster_mask = room_layer | ACTOR_LIGHT_LAYER
	light.add_to_group("ceiling_light", true)
	lights_parent.add_child(light)
	light.global_position = Vector3(center.x, CEILING_LIGHT_Y, center.z)

func _create_world_environment(parent: Node3D) -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = WORLD_BACKGROUND_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = WORLD_AMBIENT_COLOR
	environment.ambient_light_energy = WORLD_AMBIENT_ENERGY
	environment.ambient_light_sky_contribution = 0.0

	var world_environment := WorldEnvironment.new()
	world_environment.name = "WorldEnvironment"
	world_environment.environment = environment
	parent.add_child(world_environment)

func _create_portal(parent: Node3D, spec: Dictionary) -> void:
	var portal := Node3D.new()
	portal.name = spec["name"]
	portal.set_script(PortalComponentScript)
	portal.portal_id = spec["id"]
	portal.area_a = spec["area_a"]
	portal.area_b = spec["area_b"]
	portal.opening_width = spec["width"]
	portal.opening_height = spec["height"]
	portal.initial_state = spec["state"]
	parent.add_child(portal)
	portal.global_position = spec["center"]

	var left_edge := Marker3D.new()
	left_edge.name = "LeftEdge"
	portal.add_child(left_edge)

	var right_edge := Marker3D.new()
	right_edge.name = "RightEdge"
	portal.add_child(right_edge)

	if spec["edge_axis"] == "z":
		left_edge.position = Vector3(0.0, 0.0, -spec["width"] * 0.5)
		right_edge.position = Vector3(0.0, 0.0, spec["width"] * 0.5)
	else:
		left_edge.position = Vector3(-spec["width"] * 0.5, 0.0, 0.0)
		right_edge.position = Vector3(spec["width"] * 0.5, 0.0, 0.0)

func _create_marker(parent: Node3D, spec: Dictionary) -> void:
	var marker := Marker3D.new()
	marker.name = spec["id"]
	marker.set_script(MarkerComponentScript)
	marker.marker_id = spec["id"]
	marker.marker_type = spec["type"]
	marker.room_id = spec["room"]
	marker.area_id = spec["area"]
	parent.add_child(marker)
	marker.global_position = spec["position"]

func _create_box(parent: Node3D, node_name: String, local_position: Vector3, size: Vector3, add_collision: bool, material: Material = null, visual_layers: int = 1, include_horizontal_caps := true) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	parent.add_child(body)
	body.position = local_position

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "Mesh"
	var visual_size := size
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
	if material != null:
		mesh_instance.material_override = material
	mesh_instance.layers = visual_layers
	body.add_child(mesh_instance)

	if add_collision:
		var shape := BoxShape3D.new()
		shape.size = size
		var collision := CollisionShape3D.new()
		collision.name = "Collision"
		collision.shape = shape
		body.add_child(collision)

	return body

func _create_collision_box(parent: Node3D, node_name: String, local_position: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	parent.add_child(body)
	body.position = local_position

	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.name = "Collision"
	collision.shape = shape
	body.add_child(collision)

	return body
