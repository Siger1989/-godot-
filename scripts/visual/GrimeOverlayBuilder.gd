extends RefCounted

const GeneratedMeshRules = preload("res://scripts/scene/GeneratedMeshRules.gd")

const TYPE_CEILING_EDGE := "CeilingEdge_Grime"
const TYPE_BASEBOARD := "Baseboard_Dirt"
const TYPE_CORNER := "Corner_Grime"

const CEILING_EDGE_TEXTURES := [
	"res://materials/textures/grime/ceiling_edge_grime_01.png",
	"res://materials/textures/grime/ceiling_edge_grime_02.png",
	"res://materials/textures/grime/ceiling_edge_grime_03.png",
]
const BASEBOARD_TEXTURES := [
	"res://materials/textures/grime/baseboard_dirt_01.png",
	"res://materials/textures/grime/baseboard_dirt_02.png",
	"res://materials/textures/grime/baseboard_dirt_03.png",
]
const CORNER_TEXTURES := [
	"res://materials/textures/grime/corner_grime_01.png",
	"res://materials/textures/grime/corner_grime_02.png",
	"res://materials/textures/grime/corner_grime_03.png",
]

const ROOM_HALF_DEFAULT := 3.0
const WALL_THICKNESS := 0.2
const SURFACE_OFFSET := 0.014
const FLOOR_Y := 0.0
const CEILING_Y := 2.55
const STATIC_GEOMETRY_LAYER := 1 << 0
const OPENING_MARGIN := 0.22
const MIN_SEGMENT_LENGTH := 0.45
const GRIME_MATERIAL_ALPHA := 1.00

var _material_cache := {}

func build(scene: Node3D, overlay_root_name := "GrimeOverlays") -> Dictionary:
	var stats := {
		TYPE_CEILING_EDGE: 0,
		TYPE_BASEBOARD: 0,
		TYPE_CORNER: 0,
		"total": 0,
	}

	var geometry_root := scene.get_node_or_null("LevelRoot/Geometry") as Node3D
	if geometry_root == null:
		return stats

	var existing := geometry_root.get_node_or_null(overlay_root_name)
	if existing != null:
		existing.free()

	var overlay_root := Node3D.new()
	overlay_root.name = overlay_root_name
	overlay_root.set_meta("system", "global_reusable_grime_experiment")
	overlay_root.set_meta("rule", "Subtle structural-edge grime only; AO/contact darkening remains separate.")
	geometry_root.add_child(overlay_root)

	var rooms := _collect_room_specs(scene)
	var portals := _collect_portal_specs(scene)
	for room in rooms:
		var room_id := String(room["room_id"])
		var rng := RandomNumberGenerator.new()
		rng.seed = _room_seed(room_id)
		var openings_by_side := _get_openings_by_side(room, portals)
		_add_baseboard_dirt(overlay_root, room, openings_by_side, rng, stats)
		_add_ceiling_edge_grime(overlay_root, room, openings_by_side, rng, stats)
		_add_corner_grime(overlay_root, room, rng, stats)

	overlay_root.set_meta("ceiling_edge_count", int(stats[TYPE_CEILING_EDGE]))
	overlay_root.set_meta("baseboard_count", int(stats[TYPE_BASEBOARD]))
	overlay_root.set_meta("corner_count", int(stats[TYPE_CORNER]))
	overlay_root.set_meta("total_count", int(stats["total"]))
	return stats

func _collect_room_specs(scene: Node3D) -> Array[Dictionary]:
	var output: Array[Dictionary] = []
	var areas_root := scene.get_node_or_null("LevelRoot/Areas")
	if areas_root == null:
		return output
	for node in areas_root.get_children():
		var room_node := node as Node3D
		if room_node == null:
			continue
		var room_id_variant: Variant = room_node.get("room_id")
		var bounds_variant: Variant = room_node.get("bounds_size")
		if room_id_variant == null or not (bounds_variant is Vector3):
			continue
		var portal_ids := PackedStringArray()
		var portal_ids_variant: Variant = room_node.get("portal_ids")
		if portal_ids_variant is PackedStringArray:
			portal_ids = portal_ids_variant
		elif portal_ids_variant is Array:
			for item in portal_ids_variant:
				portal_ids.append(String(item))
		var bounds := bounds_variant as Vector3
		output.append({
			"room_id": String(room_id_variant),
			"center": room_node.global_position,
			"size": Vector2(bounds.x, bounds.z),
			"portal_ids": portal_ids,
		})
	return output

func _collect_portal_specs(scene: Node3D) -> Dictionary:
	var output := {}
	var portals_root := scene.get_node_or_null("LevelRoot/Portals")
	if portals_root == null:
		return output
	for node in portals_root.get_children():
		var portal := node as Node3D
		if portal == null:
			continue
		var portal_id_variant: Variant = portal.get("portal_id")
		if portal_id_variant == null:
			continue
		output[String(portal_id_variant)] = {
			"position": portal.global_position,
			"width": float(portal.get("opening_width")),
		}
	return output

func _get_openings_by_side(room: Dictionary, portals: Dictionary) -> Dictionary:
	var openings := {
		"north": [],
		"south": [],
		"east": [],
		"west": [],
	}
	var center := room["center"] as Vector3
	var portal_ids := room["portal_ids"] as PackedStringArray
	for portal_id in portal_ids:
		if not portals.has(portal_id):
			continue
		var portal := portals[portal_id] as Dictionary
		var portal_position := portal["position"] as Vector3
		var relative := portal_position - center
		var side := ""
		var line_center := 0.0
		if absf(relative.x) > absf(relative.z):
			side = "east" if relative.x > 0.0 else "west"
			line_center = relative.z
		else:
			side = "north" if relative.z > 0.0 else "south"
			line_center = relative.x
		var side_openings := openings[side] as Array
		side_openings.append({
			"center": line_center,
			"width": float(portal["width"]),
		})
	return openings

func _add_baseboard_dirt(
	parent: Node3D,
	room: Dictionary,
	openings_by_side: Dictionary,
	rng: RandomNumberGenerator,
	stats: Dictionary
) -> void:
	for side in ["north", "south", "east", "west"]:
		if rng.randf() > 0.76:
			continue
		var segment := _pick_segment(room, openings_by_side, side, rng, 1.25, 3.35)
		if segment.is_empty():
			continue
		var height := rng.randf_range(0.16, 0.26)
		var center_y := FLOOR_Y + 0.018 + height * 0.5
		var opacity := rng.randf_range(0.12, 0.22)
		var strength := rng.randf_range(0.55, 0.90)
		_create_grime_strip(
			parent,
			room,
			side,
			float(segment["center"]),
			center_y,
			float(segment["length"]),
			height,
			TYPE_BASEBOARD,
			opacity,
			strength,
			rng,
			stats
		)

func _add_ceiling_edge_grime(
	parent: Node3D,
	room: Dictionary,
	openings_by_side: Dictionary,
	rng: RandomNumberGenerator,
	stats: Dictionary
) -> void:
	for side in ["north", "south", "east", "west"]:
		if rng.randf() > 0.42:
			continue
		var segment := _pick_segment(room, openings_by_side, side, rng, 0.95, 2.55)
		if segment.is_empty():
			continue
		var height := rng.randf_range(0.10, 0.17)
		var center_y := CEILING_Y - 0.014 - height * 0.5
		var opacity := rng.randf_range(0.07, 0.15)
		var strength := rng.randf_range(0.50, 0.78)
		_create_grime_strip(
			parent,
			room,
			side,
			float(segment["center"]),
			center_y,
			float(segment["length"]),
			height,
			TYPE_CEILING_EDGE,
			opacity,
			strength,
			rng,
			stats
		)

func _add_corner_grime(parent: Node3D, room: Dictionary, rng: RandomNumberGenerator, stats: Dictionary) -> void:
	if rng.randf() > 0.72:
		return
	var corners := [
		{"x": -1.0, "z": -1.0, "name": "SW"},
		{"x": 1.0, "z": -1.0, "name": "SE"},
		{"x": 1.0, "z": 1.0, "name": "NE"},
		{"x": -1.0, "z": 1.0, "name": "NW"},
	]
	corners.shuffle()
	var count := 1
	if rng.randf() < 0.22:
		count = 2
	for index in range(count):
		var corner := corners[index] as Dictionary
		var height := rng.randf_range(0.85, 1.55)
		var width := rng.randf_range(0.22, 0.36)
		var center_y := FLOOR_Y + 0.05 + height * 0.5
		var opacity := rng.randf_range(0.08, 0.16)
		var strength := rng.randf_range(0.45, 0.76)
		_create_corner_side(
			parent,
			room,
			corner,
			true,
			center_y,
			width,
			height,
			opacity,
			strength,
			rng,
			stats
		)
		_create_corner_side(
			parent,
			room,
			corner,
			false,
			center_y,
			width,
			height,
			opacity * 0.82,
			strength,
			rng,
			stats
		)

func _pick_segment(
	room: Dictionary,
	openings_by_side: Dictionary,
	side: String,
	rng: RandomNumberGenerator,
	min_length: float,
	max_length: float
) -> Dictionary:
	var intervals := _get_available_intervals(room, openings_by_side, side)
	var total_length := 0.0
	for interval in intervals:
		var interval_dict := interval as Dictionary
		var interval_length := float(interval_dict["end"]) - float(interval_dict["start"])
		if interval_length >= MIN_SEGMENT_LENGTH:
			total_length += interval_length
	if total_length <= 0.0:
		return {}

	var pick := rng.randf_range(0.0, total_length)
	var selected := {}
	for interval in intervals:
		var interval_dict := interval as Dictionary
		var interval_length := float(interval_dict["end"]) - float(interval_dict["start"])
		if interval_length < MIN_SEGMENT_LENGTH:
			continue
		if pick <= interval_length:
			selected = interval_dict
			break
		pick -= interval_length
	if selected.is_empty():
		return {}

	var available := float(selected["end"]) - float(selected["start"])
	var length := minf(rng.randf_range(min_length, max_length), available * 0.86)
	if length < MIN_SEGMENT_LENGTH:
		length = available * 0.70
	var start := float(selected["start"]) + length * 0.5
	var end := float(selected["end"]) - length * 0.5
	var center := (float(selected["start"]) + float(selected["end"])) * 0.5
	if end > start:
		center = rng.randf_range(start, end)
	return {
		"center": center,
		"length": length,
	}

func _get_available_intervals(room: Dictionary, openings_by_side: Dictionary, side: String) -> Array[Dictionary]:
	var size := room["size"] as Vector2
	var half_length := size.x * 0.5 if side == "north" or side == "south" else size.y * 0.5
	if half_length <= 0.0:
		half_length = ROOM_HALF_DEFAULT
	var intervals: Array[Dictionary] = [{"start": -half_length, "end": half_length}]
	var side_openings := openings_by_side[side] as Array
	for opening in side_openings:
		var opening_dict := opening as Dictionary
		var remove_start := float(opening_dict["center"]) - float(opening_dict["width"]) * 0.5 - OPENING_MARGIN
		var remove_end := float(opening_dict["center"]) + float(opening_dict["width"]) * 0.5 + OPENING_MARGIN
		intervals = _subtract_interval(intervals, remove_start, remove_end)
	return intervals

func _subtract_interval(intervals: Array[Dictionary], remove_start: float, remove_end: float) -> Array[Dictionary]:
	var output: Array[Dictionary] = []
	for interval in intervals:
		var start := float(interval["start"])
		var end := float(interval["end"])
		if remove_end <= start or remove_start >= end:
			output.append(interval)
			continue
		if remove_start - start > MIN_SEGMENT_LENGTH:
			output.append({"start": start, "end": remove_start})
		if end - remove_end > MIN_SEGMENT_LENGTH:
			output.append({"start": remove_end, "end": end})
	return output

func _create_corner_side(
	parent: Node3D,
	room: Dictionary,
	corner: Dictionary,
	use_x_wall: bool,
	center_y: float,
	width: float,
	height: float,
	opacity: float,
	strength: float,
	rng: RandomNumberGenerator,
	stats: Dictionary
) -> void:
	var side := ""
	var line_center := 0.0
	var sign_x := float(corner["x"])
	var sign_z := float(corner["z"])
	if use_x_wall:
		side = "east" if sign_x > 0.0 else "west"
		line_center = sign_z * ((room["size"] as Vector2).y * 0.5 - width * 0.5)
	else:
		side = "north" if sign_z > 0.0 else "south"
		line_center = sign_x * ((room["size"] as Vector2).x * 0.5 - width * 0.5)
	_create_grime_strip(
		parent,
		room,
		side,
		line_center,
		center_y,
		width,
		height,
		TYPE_CORNER,
		opacity,
		strength,
		rng,
		stats
	)

func _create_grime_strip(
	parent: Node3D,
	room: Dictionary,
	side: String,
	line_center: float,
	center_y: float,
	length: float,
	height: float,
	grime_type: String,
	opacity: float,
	strength: float,
	rng: RandomNumberGenerator,
	stats: Dictionary
) -> void:
	var side_info := _side_info(room, side, line_center, center_y)
	var texture_path := _choose_texture(grime_type, rng)
	var alpha := GRIME_MATERIAL_ALPHA
	var material := _get_or_create_material(texture_path, alpha)
	var node := MeshInstance3D.new()
	node.name = "%s_%s_%03d" % [grime_type, String(room["room_id"]), int(stats["total"]) + 1]
	node.mesh = _build_quad_mesh(length, height, material)
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.layers = STATIC_GEOMETRY_LAYER
	node.add_to_group("grime_overlay", true)
	node.add_to_group(grime_type, true)
	node.set_meta("grime_type", grime_type)
	node.set_meta("room_id", String(room["room_id"]))
	node.set_meta("side", side)
	node.set_meta("variant", texture_path)
	node.set_meta("opacity", opacity)
	node.set_meta("strength", strength)
	node.set_meta("material_alpha", alpha)
	node.set_meta("length", length)
	node.set_meta("height", height)
	parent.add_child(node)
	node.global_transform = side_info["transform"] as Transform3D
	stats[grime_type] = int(stats[grime_type]) + 1
	stats["total"] = int(stats["total"]) + 1

func _side_info(room: Dictionary, side: String, line_center: float, center_y: float) -> Dictionary:
	var center := room["center"] as Vector3
	var size := room["size"] as Vector2
	var half_x := size.x * 0.5
	var half_z := size.y * 0.5
	var normal := Vector3.ZERO
	var horizontal := Vector3.RIGHT
	var position := Vector3.ZERO
	if side == "north":
		normal = Vector3.FORWARD
		horizontal = Vector3.RIGHT
		position = Vector3(center.x + line_center, center_y, center.z + half_z - WALL_THICKNESS * 0.5)
	elif side == "south":
		normal = Vector3.BACK
		horizontal = Vector3.RIGHT
		position = Vector3(center.x + line_center, center_y, center.z - half_z + WALL_THICKNESS * 0.5)
	elif side == "east":
		normal = Vector3.LEFT
		horizontal = Vector3.BACK
		position = Vector3(center.x + half_x - WALL_THICKNESS * 0.5, center_y, center.z + line_center)
	else:
		normal = Vector3.RIGHT
		horizontal = Vector3.BACK
		position = Vector3(center.x - half_x + WALL_THICKNESS * 0.5, center_y, center.z + line_center)

	position += normal.normalized() * SURFACE_OFFSET
	var basis := Basis(horizontal.normalized(), Vector3.UP, normal.normalized()).orthonormalized()
	return {"transform": Transform3D(basis, position)}

func _build_quad_mesh(width: float, height: float, material: Material) -> ArrayMesh:
	var half_width := width * 0.5
	var half_height := height * 0.5
	var vertices := PackedVector3Array([
		Vector3(-half_width, -half_height, 0.0),
		Vector3(half_width, -half_height, 0.0),
		Vector3(half_width, half_height, 0.0),
		Vector3(-half_width, -half_height, 0.0),
		Vector3(half_width, half_height, 0.0),
		Vector3(-half_width, half_height, 0.0),
	])
	var normals := PackedVector3Array([
		Vector3.BACK,
		Vector3.BACK,
		Vector3.BACK,
		Vector3.BACK,
		Vector3.BACK,
		Vector3.BACK,
	])
	var uvs := PackedVector2Array([
		Vector2(0.0, 1.0),
		Vector2(1.0, 1.0),
		Vector2(1.0, 0.0),
		Vector2(0.0, 1.0),
		Vector2(1.0, 0.0),
		Vector2(0.0, 0.0),
	])
	return GeneratedMeshRules.build_array_mesh(vertices, normals, uvs, material)

func _choose_texture(grime_type: String, rng: RandomNumberGenerator) -> String:
	var variants := _texture_variants(grime_type)
	return variants[rng.randi_range(0, variants.size() - 1)]

func _texture_variants(grime_type: String) -> Array:
	if grime_type == TYPE_CEILING_EDGE:
		return CEILING_EDGE_TEXTURES
	if grime_type == TYPE_BASEBOARD:
		return BASEBOARD_TEXTURES
	return CORNER_TEXTURES

func _get_or_create_material(texture_path: String, alpha: float) -> StandardMaterial3D:
	var cache_key := "%s|%.3f" % [texture_path, alpha]
	if _material_cache.has(cache_key):
		return _material_cache[cache_key]
	var texture := load(texture_path) as Texture2D
	var material := StandardMaterial3D.new()
	material.resource_name = "M_%s" % texture_path.get_file().get_basename()
	material.albedo_texture = texture
	material.albedo_color = Color(1.0, 1.0, 1.0, alpha)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material_cache[cache_key] = material
	return material

func _room_seed(room_id: String) -> int:
	var seed := 18731
	for index in range(room_id.length()):
		seed = int((seed * 131 + room_id.unicode_at(index)) % 2147483647)
	return seed
