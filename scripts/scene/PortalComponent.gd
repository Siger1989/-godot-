extends Node3D

@export var portal_id := ""
@export var area_a := ""
@export var area_b := ""
@export var opening_width := 1.0
@export var opening_height := 2.1
@export var initial_state := "open"
@export var blocks_vision_when_closed := true
@export var blocks_movement_when_closed := true
@export_node_path("Node") var door_node_path: NodePath

func is_open() -> bool:
	var door_node := get_node_or_null(door_node_path)
	if door_node != null and door_node.has_method("is_open"):
		return door_node.is_open()
	return true

func get_connected_areas() -> PackedStringArray:
	return PackedStringArray([area_a, area_b])
