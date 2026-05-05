extends Node3D

@export var room_id := ""
@export var area_id := ""
@export var room_type := ""
@export var bounds_size := Vector3.ZERO
@export var portal_ids: PackedStringArray = []
@export var light_ids: PackedStringArray = []
@export var marker_ids: PackedStringArray = []

func get_area_id() -> String:
	return area_id
