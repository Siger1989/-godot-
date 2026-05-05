extends Marker3D

@export var marker_id := ""
@export var marker_type := ""
@export var room_id := ""
@export var area_id := ""

func get_marker_id() -> String:
	return marker_id
