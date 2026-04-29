extends Node
class_name WaypointPatrol

@export var points: Array[Vector3] = []


func get_point(index: int) -> Vector3:
	if points.is_empty():
		return Vector3.ZERO
	return points[index % points.size()]

