extends Area3D
class_name RoomVolume

@export var room_id: String = ""
@export var connected_rooms: Array[String] = []
@export var section_root: NodePath
@export var is_corridor: bool = false
@export var is_visited: bool = false
@export var is_visible: bool = false

var bounds := Rect2()


func _ready() -> void:
	add_to_group("room_volume")


func contains_world_point(point: Vector3) -> bool:
	if bounds.size == Vector2.ZERO:
		return false
	return bounds.has_point(Vector2(point.x, point.z))


func get_section() -> Node:
	if section_root.is_empty():
		return null
	return get_node_or_null(section_root)
