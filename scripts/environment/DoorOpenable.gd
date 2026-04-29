extends "res://scripts/environment/DoorBase.gd"
class_name DoorOpenable

@export var open_angle_degrees := 92.0

var is_open := false
var target_angle := 0.0


func _ready() -> void:
	super._ready()
	prompt_text = "按 E 开门"


func _process(delta: float) -> void:
	if hinge:
		hinge.rotation.y = lerp_angle(hinge.rotation.y, target_angle, 1.0 - exp(-8.0 * delta))


func interact(_player: Node) -> void:
	is_open = not is_open
	target_angle = deg_to_rad(open_angle_degrees) if is_open else 0.0
	if door_collision:
		door_collision.disabled = is_open
	prompt_text = "按 E 关门" if is_open else "按 E 开门"
	_feedback("门轴发出潮湿的摩擦声。")


func _build_door() -> void:
	super._build_door()
	door_collision = door_body.get_node_or_null("PanelMesh/CollisionShape3D") as CollisionShape3D

