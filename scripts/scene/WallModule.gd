extends StaticBody3D

@export var wall_id := ""
@export var area_id := ""
@export var is_foreground_occluder := true
@export var has_void_outer_side := false

func _ready() -> void:
	if is_foreground_occluder:
		add_to_group("foreground_occluder", true)

func get_area_id() -> String:
	return area_id
