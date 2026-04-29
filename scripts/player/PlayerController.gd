extends CharacterBody3D
class_name PlayerController

@export var walk_speed := 3.0
@export var sprint_speed := 5.0
@export var acceleration := 16.0
@export var gravity := 22.0

var current_interactable: Node
var nearby_interactables: Array[Node] = []
var animation_controller: Node

@onready var interaction_area: Area3D = $InteractionArea


func _ready() -> void:
	add_to_group("player")
	animation_controller = get_node_or_null("Visual")
	interaction_area.area_entered.connect(_on_interaction_area_entered)
	interaction_area.area_exited.connect(_on_interaction_area_exited)


func _physics_process(delta: float) -> void:
	var objective := get_tree().get_first_node_in_group("objective_manager")
	if objective and objective.ended:
		velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)
		move_and_slide()
		return

	_update_current_interactable()
	var input_vector := _get_input_vector()
	var direction := _camera_relative_direction(input_vector)
	var is_sprinting := Input.is_action_pressed("sprint") and direction.length() > 0.1
	var target_speed := sprint_speed if is_sprinting else walk_speed
	var target_velocity := direction * target_speed

	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = -0.1

	if direction.length() > 0.05:
		var look_target := global_position + direction
		look_target.y = global_position.y
		look_at(look_target, Vector3.UP)

	move_and_slide()

	if animation_controller and animation_controller.has_method("set_motion_state"):
		animation_controller.set_motion_state(Vector2(velocity.x, velocity.z).length(), is_sprinting)

	if Input.is_action_just_pressed("interact"):
		try_interact()


func try_interact() -> void:
	_update_current_interactable()
	if not current_interactable:
		return
	if current_interactable.has_method("interact"):
		current_interactable.interact(self)


func get_interaction_text() -> String:
	if not is_instance_valid(current_interactable):
		return ""
	if current_interactable.has_method("get_interaction_text"):
		return current_interactable.get_interaction_text()
	return "按 E 互动"


func _get_input_vector() -> Vector2:
	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var mobile_controls := get_tree().get_first_node_in_group("mobile_controls")
	if mobile_controls and mobile_controls.has_method("get_move_vector"):
		var mobile_vector: Vector2 = mobile_controls.get_move_vector()
		if mobile_vector.length() > input_vector.length():
			input_vector = mobile_vector
	return input_vector.limit_length(1.0)


func _camera_relative_direction(input_vector: Vector2) -> Vector3:
	if input_vector.length() < 0.05:
		return Vector3.ZERO
	var camera := get_viewport().get_camera_3d()
	if not camera:
		return Vector3(input_vector.x, 0.0, input_vector.y).normalized()
	var right := camera.global_basis.x
	var forward := -camera.global_basis.z
	right.y = 0.0
	forward.y = 0.0
	right = right.normalized()
	forward = forward.normalized()
	return (right * input_vector.x + forward * -input_vector.y).normalized()


func _update_current_interactable() -> void:
	var best: Node = null
	var best_distance := INF
	var still_valid: Array[Node] = []
	for item in nearby_interactables:
		if not is_instance_valid(item):
			continue
		still_valid.append(item)
		var distance := global_position.distance_to((item as Node3D).global_position)
		if distance < best_distance:
			best_distance = distance
			best = item
	nearby_interactables = still_valid
	current_interactable = best


func _on_interaction_area_entered(area: Area3D) -> void:
	var interactable := _resolve_interactable(area)
	if interactable and not nearby_interactables.has(interactable):
		nearby_interactables.append(interactable)


func _on_interaction_area_exited(area: Area3D) -> void:
	var interactable := _resolve_interactable(area)
	if interactable:
		nearby_interactables.erase(interactable)


func _resolve_interactable(node: Node) -> Node:
	var current := node
	while current:
		if current.is_in_group("interactable"):
			return current
		current = current.get_parent()
	return null
