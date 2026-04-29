extends Node3D
class_name RoomPrototypeManager

enum VisibilityState { UNKNOWN, VISITED, PARTIAL_VISIBLE, VISIBLE }

@export var clear_radius := 8.0
@export var dim_radius := 14.0
@export var black_radius := 20.0

var rooms: Array[Node] = []
var sections: Dictionary = {}
var doors: Array[Node] = []
var visited: Dictionary = {}
var current_room := ""
var _initialized := false
var _faded_walls: Dictionary = {}


func _ready() -> void:
	add_to_group("room_prototype_manager")
	call_deferred("_initialize")


func _process(_delta: float) -> void:
	if not _initialized:
		return
	_update_room_visibility()
	_update_foreground_wall_fade()


func _initialize() -> void:
	rooms.clear()
	sections.clear()
	doors.clear()

	for room in get_tree().get_nodes_in_group("room_volume"):
		if room is Node and (room as Node).has_method("contains_world_point"):
			rooms.append(room as Node)
			var room_id := String((room as Node).get("room_id"))
			var section := (room as Node).call("get_section") as Node
			if section:
				sections[room_id] = section

	for door in get_tree().get_nodes_in_group("room_prototype_door"):
		if door is Node:
			doors.append(door as Node)
	for door in get_tree().get_nodes_in_group("fog_connection_door"):
		if door is Node and not doors.has(door):
			doors.append(door as Node)

	_initialized = true
	_update_room_visibility()


func _update_room_visibility() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if not player:
		return

	current_room = _find_room_at(player.global_position)
	if not current_room.is_empty():
		visited[current_room] = true

	var origin := player.global_position + Vector3(0.0, 1.15, 0.0)
	for room in rooms:
		var room_id := String(room.get("room_id"))
		var target_state: int = VisibilityState.UNKNOWN
		if room_id == current_room:
			target_state = VisibilityState.VISIBLE
		elif _is_open_neighbor(current_room, room_id):
			target_state = VisibilityState.PARTIAL_VISIBLE
		elif visited.has(room_id):
			target_state = VisibilityState.VISITED

		var section := sections.get(room_id) as Node
		if section and section.has_method("update_visibility"):
			var partial_source := current_room if target_state == VisibilityState.PARTIAL_VISIBLE else ""
			section.call("update_visibility", target_state, origin, self, clear_radius, dim_radius, black_radius, partial_source)


func _find_room_at(world_position: Vector3) -> String:
	for room in rooms:
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
	for room in rooms:
		if String(room.get("room_id")) == room_id:
			return room
	return null


func _connection_open(room_a: String, room_b: String) -> bool:
	var has_door := false
	for door in doors:
		if _door_connects(door, room_a, room_b):
			has_door = true
			return _door_is_open(door)
	return not has_door


func _door_connects(door: Node, room_a: String, room_b: String) -> bool:
	if door.has_method("connects"):
		return bool(door.call("connects", room_a, room_b))
	var a := String(door.get_meta("room_a", ""))
	var b := String(door.get_meta("room_b", ""))
	return (a == room_a and b == room_b) or (a == room_b and b == room_a)


func _door_is_open(door: Node) -> bool:
	var value: Variant = door.get("is_open")
	if value is bool:
		return bool(value)
	return bool(door.get_meta("is_open", false))


func has_line_of_sight(origin: Vector3, target: Vector3) -> bool:
	var params := PhysicsRayQueryParameters3D.create(origin, target)
	var player := get_tree().get_first_node_in_group("player") as CollisionObject3D
	if player:
		params.exclude = [player.get_rid()]
	params.hit_from_inside = false
	var hit := get_world_3d().direct_space_state.intersect_ray(params)
	return hit.is_empty()


func _update_foreground_wall_fade() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	var camera := get_viewport().get_camera_3d()
	if not player or not camera:
		return

	var active_walls: Dictionary = {}
	var from := camera.global_position
	var to := player.global_position + Vector3(0.0, 1.0, 0.0)
	var exclude: Array[RID] = []
	var player_collision := player as CollisionObject3D
	if player_collision:
		exclude.append(player_collision.get_rid())

	for i in 4:
		var params := PhysicsRayQueryParameters3D.create(from, to)
		params.exclude = exclude
		params.hit_from_inside = false
		var hit := get_world_3d().direct_space_state.intersect_ray(params)
		if hit.is_empty():
			break
		var collider := hit.get("collider") as Node
		if not collider:
			break
		if collider.is_in_group("prototype_foreground_wall"):
			active_walls[collider] = true
			_set_wall_alpha(collider, 0.32)
		if collider is CollisionObject3D:
			exclude.append((collider as CollisionObject3D).get_rid())
		else:
			break

	for wall in _faded_walls.keys():
		if not active_walls.has(wall):
			_set_wall_alpha(wall as Node, 1.0)


func _set_wall_alpha(wall: Node, alpha: float) -> void:
	if not is_instance_valid(wall):
		return
	for child in wall.get_children():
		if child is MeshInstance3D:
			var mesh := child as MeshInstance3D
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
