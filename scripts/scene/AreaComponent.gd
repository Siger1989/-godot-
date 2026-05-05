extends Node3D

@export var area_id := ""
@export var bounds_center := Vector3.ZERO
@export var bounds_size := Vector3.ZERO

func get_area_id() -> String:
	return area_id
