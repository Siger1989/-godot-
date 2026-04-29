extends Node3D
class_name FogTestManager

enum VisibilityState { UNKNOWN, VISITED, PARTIAL_VISIBLE, VISIBLE }

@export var clear_radius := 8.0
@export var dim_radius := 14.0
@export var black_radius := 20.0
@export var darkness_cell_size := 2.0

var _rooms: Array[Node] = []
var _sections: Dictionary = {}
var _doors: Array[Node] = []
var _visited: Dictionary = {}
var _darkness_tiles: Array[Dictionary] = []
var _darkness_root: Node3D
var _darkness_shader: Shader
var _initialized := false


func _ready() -> void:
	add_to_group("fog_test_manager")
	call_deferred("_initialize")


func _process(_delta: float) -> void:
	if not _initialized:
		return
	_update_section_states()
	_update_distance_darkness()


func _initialize() -> void:
	_rooms.clear()
	_sections.clear()
	_doors.clear()
	for room in get_tree().get_nodes_in_group("room_volume"):
		if room is Node and (room as Node).has_method("contains_world_point"):
			_rooms.append(room as Node)
			var room_id := String((room as Node).get("room_id"))
			var section := (room as Node).call("get_section") as Node
			if section:
				_sections[room_id] = section
	for door in get_tree().get_nodes_in_group("fog_test_door"):
		if door is Node:
			_doors.append(door as Node)
	for door in get_tree().get_nodes_in_group("fog_connection_door"):
		if door is Node and not _doors.has(door):
			_doors.append(door as Node)

	_build_darkness_tiles()
	_initialized = true
	_update_section_states()
	_update_distance_darkness()


func _update_section_states() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if not player:
		return

	var current_room := _find_room_at(player.global_position)
	if not current_room.is_empty():
		_visited[current_room] = true

	for room in _rooms:
		var room_id := String(room.get("room_id"))
		var target_state: int = VisibilityState.UNKNOWN
		if room_id == current_room:
			target_state = VisibilityState.VISIBLE
		elif _is_open_neighbor(current_room, room_id):
			target_state = VisibilityState.PARTIAL_VISIBLE
		elif _visited.has(room_id):
			target_state = VisibilityState.VISITED

		var section: Node = _sections.get(room_id) as Node
		if section and section.has_method("apply_visibility"):
			section.call("apply_visibility", target_state)


func _find_room_at(world_position: Vector3) -> String:
	for room in _rooms:
		if bool(room.call("contains_world_point", world_position)):
			return String(room.get("room_id"))
	return ""


func _is_open_neighbor(room_a: String, room_b: String) -> bool:
	if room_a.is_empty() or room_b.is_empty() or room_a == room_b:
		return false
	var room := _room_by_id(room_a)
	if not room:
		return false
	var connected_rooms: Array = room.get("connected_rooms")
	if not connected_rooms.has(room_b):
		return false
	return _connection_open(room_a, room_b)


func _room_by_id(room_id: String) -> Node:
	for room in _rooms:
		if String(room.get("room_id")) == room_id:
			return room
	return null


func _connection_open(room_a: String, room_b: String) -> bool:
	var has_door_for_connection := false
	for door in _doors:
		if _door_connects(door, room_a, room_b):
			has_door_for_connection = true
			return _door_is_open(door)
	return not has_door_for_connection


func _door_connects(door: Node, room_a: String, room_b: String) -> bool:
	if door.has_method("connects"):
		return bool(door.call("connects", room_a, room_b))
	var a := String(door.get_meta("room_a", ""))
	var b := String(door.get_meta("room_b", ""))
	return (a == room_a and b == room_b) or (a == room_b and b == room_a)


func _door_is_open(door: Node) -> bool:
	var open_value: Variant = door.get("is_open")
	if open_value is bool:
		return bool(open_value)
	return bool(door.get_meta("is_open", false))


func _build_darkness_tiles() -> void:
	if _darkness_root:
		_darkness_root.queue_free()
	_darkness_root = Node3D.new()
	_darkness_root.name = "LocalDistanceDarkness"
	add_child(_darkness_root)
	_darkness_tiles.clear()
	_build_darkness_shader()

	var bounds := _playable_bounds()
	if bounds.size == Vector2.ZERO:
		return

	var x_start := int(floor(bounds.position.x / darkness_cell_size))
	var x_end := int(ceil((bounds.position.x + bounds.size.x) / darkness_cell_size))
	var z_start := int(floor(bounds.position.y / darkness_cell_size))
	var z_end := int(ceil((bounds.position.y + bounds.size.y) / darkness_cell_size))

	for xi in range(x_start, x_end):
		for zi in range(z_start, z_end):
			var center := Vector3((float(xi) + 0.5) * darkness_cell_size, 2.66, (float(zi) + 0.5) * darkness_cell_size)
			var room_id: String = _find_room_at(center)
			if room_id.is_empty():
				continue

			var tile := MeshInstance3D.new()
			tile.name = "DistanceDarknessTile"
			var mesh := PlaneMesh.new()
			mesh.size = Vector2(darkness_cell_size * 2.45, darkness_cell_size * 2.45)
			tile.mesh = mesh
			tile.position = center
			tile.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var material := _make_darkness_material(0.0)
			tile.material_override = material
			tile.visible = false
			_darkness_root.add_child(tile)
			_darkness_tiles.append({
				"node": tile,
				"material": material,
				"center": center,
				"room_id": room_id
			})


func _build_darkness_shader() -> void:
	if _darkness_shader:
		return
	_darkness_shader = Shader.new()
	_darkness_shader.code = """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;
uniform float alpha = 0.0;
void fragment() {
	float edge = smoothstep(0.0, 0.32, UV.x) * smoothstep(0.0, 0.32, UV.y);
	edge *= (1.0 - smoothstep(0.68, 1.0, UV.x)) * (1.0 - smoothstep(0.68, 1.0, UV.y));
	ALBEDO = vec3(0.0);
	ALPHA = alpha * mix(0.20, 1.0, edge);
}
"""


func _make_darkness_material(alpha: float) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = _darkness_shader
	material.set_shader_parameter("alpha", alpha)
	return material


func _update_distance_darkness() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if not player:
		return
	var origin := player.global_position + Vector3(0.0, 1.15, 0.0)
	var current_room := _find_room_at(player.global_position)

	for i in _darkness_tiles.size():
		var tile := _darkness_tiles[i]
		var room_id := String(tile["room_id"])
		var alpha := 0.0
		if room_id == current_room or _is_open_neighbor(current_room, room_id):
			var center: Vector3 = tile["center"]
			var los_target := Vector3(center.x, origin.y, center.z)
			var distance := Vector2(origin.x, origin.z).distance_to(Vector2(center.x, center.z))
			if distance > black_radius or not _has_line_of_sight(origin, los_target):
				alpha = 0.96
			elif distance > dim_radius:
				var t: float = clamp((distance - dim_radius) / max(black_radius - dim_radius, 0.01), 0.0, 1.0)
				alpha = lerp(0.52, 0.94, smoothstep(0.0, 1.0, t))
			elif distance > clear_radius:
				var t: float = clamp((distance - clear_radius) / max(dim_radius - clear_radius, 0.01), 0.0, 1.0)
				alpha = lerp(0.0, 0.52, smoothstep(0.0, 1.0, t))

		var material := tile["material"] as ShaderMaterial
		if material:
			material.set_shader_parameter("alpha", alpha)
		var node := tile["node"] as MeshInstance3D
		if node:
			node.visible = alpha > 0.035


func _has_line_of_sight(origin: Vector3, target: Vector3) -> bool:
	var params := PhysicsRayQueryParameters3D.create(origin, target)
	var player := get_tree().get_first_node_in_group("player") as CollisionObject3D
	if player:
		params.exclude = [player.get_rid()]
	params.hit_from_inside = false
	var hit := get_world_3d().direct_space_state.intersect_ray(params)
	return hit.is_empty()


func _playable_bounds() -> Rect2:
	var has_bounds := false
	var min_x := 0.0
	var max_x := 0.0
	var min_z := 0.0
	var max_z := 0.0
	for room in _rooms:
		var rect: Rect2 = room.get("bounds")
		if rect.size == Vector2.ZERO:
			continue
		if not has_bounds:
			min_x = rect.position.x
			max_x = rect.position.x + rect.size.x
			min_z = rect.position.y
			max_z = rect.position.y + rect.size.y
			has_bounds = true
		else:
			min_x = min(min_x, rect.position.x)
			max_x = max(max_x, rect.position.x + rect.size.x)
			min_z = min(min_z, rect.position.y)
			max_z = max(max_z, rect.position.y + rect.size.y)
	if not has_bounds:
		return Rect2()
	return Rect2(Vector2(min_x, min_z), Vector2(max_x - min_x, max_z - min_z))
