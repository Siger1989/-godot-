extends Node3D
class_name PlayerAnimationController

var motion_speed := 0.0
var sprinting := false
var time := 0.0

@onready var body: Node3D = get_node_or_null("Body") as Node3D
@onready var head: Node3D = get_node_or_null("Head") as Node3D
@onready var left_arm: Node3D = get_node_or_null("LeftArm") as Node3D
@onready var right_arm: Node3D = get_node_or_null("RightArm") as Node3D
@onready var left_leg: Node3D = get_node_or_null("LeftLeg") as Node3D
@onready var right_leg: Node3D = get_node_or_null("RightLeg") as Node3D
@onready var imported_model_root: Node3D = get_node_or_null("ImportedModelRoot") as Node3D

var _base_y: Dictionary = {}


func _ready() -> void:
	for node in [body, head, left_arm, right_arm, left_leg, right_leg, imported_model_root]:
		if node:
			_base_y[node] = (node as Node3D).position.y


func set_motion_state(speed: float, is_sprinting: bool) -> void:
	motion_speed = speed
	sprinting = is_sprinting
	if imported_model_root and imported_model_root.has_method("set_motion_state"):
		imported_model_root.call("set_motion_state", speed, is_sprinting)


func _process(delta: float) -> void:
	time += delta * (7.0 if sprinting else 5.0)
	var amount: float = clamp(motion_speed / 6.2, 0.0, 1.0)
	var bob: float = sin(time * 2.0) * 0.025 * amount
	var idle_amount := 1.0 - amount
	var idle_bob := sin(time * 0.42) * 0.006 * idle_amount
	if imported_model_root:
		imported_model_root.position.y = float(_base_y.get(imported_model_root, imported_model_root.position.y)) + bob + idle_bob
		imported_model_root.rotation.z = sin(time * 0.5) * 0.018 * amount + sin(time * 0.33) * 0.006 * idle_amount
	if body:
		body.position.y = float(_base_y.get(body, body.position.y)) + bob
	if head:
		head.position.y = float(_base_y.get(head, head.position.y)) + bob * 0.5
	var swing: float = sin(time) * 0.45 * amount
	if left_arm:
		left_arm.rotation.x = swing
	if right_arm:
		right_arm.rotation.x = -swing
	if left_leg:
		left_leg.rotation.x = -swing * 0.6
	if right_leg:
		right_leg.rotation.x = swing * 0.6
