extends Node3D

@export var light_id := ""
@export var area_id := ""
@export var panel_node_path: NodePath
@export var light_node_path: NodePath

func get_light_id() -> String:
	return light_id
