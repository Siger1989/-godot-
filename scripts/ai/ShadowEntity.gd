extends CharacterBody3D
class_name ShadowEntity

enum State { PATROL, INVESTIGATE, STALK, CHASE, LOSE_SIGHT, RETURN }

@export var patrol_points: Array[Vector3] = [
	Vector3(64.5, 0.0, 8.0),
	Vector3(65.0, 0.0, 22.0),
	Vector3(45.0, 0.0, 18.0),
	Vector3(34.0, 0.0, 12.0),
]
@export var patrol_speed := 1.35
@export var stalk_speed := 1.85
@export var chase_speed := 2.55
@export var burst_speed := 3.2
@export var far_pressure_distance := 35.0
@export var stalk_distance := 24.0
@export var chase_distance := 14.0
@export var danger_distance := 7.0

var state := State.PATROL
var patrol_index := 0
var gravity := 22.0
var catch_timer := 0.0
var burst_timer := 0.0
var flicker_timer := 0.0


func _ready() -> void:
	add_to_group("shadow_entity")
	_build_visual()


func _physics_process(delta: float) -> void:
	var objective := get_tree().get_first_node_in_group("objective_manager")
	if objective and bool(objective.get("ended")):
		velocity = Vector3.ZERO
		move_and_slide()
		return

	var player := get_tree().get_first_node_in_group("player") as Node3D
	var target_position := _get_patrol_target()
	var speed := patrol_speed
	if player:
		var distance := global_position.distance_to(player.global_position)
		_update_state(distance)
		_apply_pressure(distance, delta)
		match state:
			State.PATROL, State.RETURN:
				target_position = _get_patrol_target()
				speed = patrol_speed
			State.STALK:
				target_position = player.global_position
				speed = stalk_speed
			State.CHASE:
				target_position = player.global_position
				speed = burst_speed if burst_timer > 0.0 else chase_speed
			State.LOSE_SIGHT:
				target_position = _get_patrol_target()
				speed = stalk_speed
		if distance < 1.35:
			catch_timer += delta
			if catch_timer > 1.25:
				var manager := get_tree().get_first_node_in_group("game_manager")
				if manager and manager.has_method("lose_game"):
					manager.lose_game("远处的人影贴近时，荧光灯忽然安静了。")
		else:
			catch_timer = max(catch_timer - delta * 0.8, 0.0)

	_move_towards(target_position, speed, delta)


func _update_state(distance: float) -> void:
	if distance > far_pressure_distance + 8.0:
		state = State.PATROL
	elif distance > stalk_distance:
		state = State.PATROL
	elif distance > chase_distance:
		state = State.STALK
	elif distance > danger_distance:
		state = State.CHASE
		burst_timer = max(burst_timer - get_physics_process_delta_time(), 0.0)
	else:
		state = State.CHASE
		if burst_timer <= 0.0:
			burst_timer = 1.0
		burst_timer = max(burst_timer - get_physics_process_delta_time(), 0.0)


func _apply_pressure(distance: float, delta: float) -> void:
	flicker_timer -= delta
	if distance < far_pressure_distance and flicker_timer <= 0.0:
		flicker_timer = 0.16
		var amount: float = clamp(1.0 - distance / far_pressure_distance, 0.0, 1.0)
		for light in get_tree().get_nodes_in_group("fluorescent_light"):
			if light is Light3D and randf() < 0.22 + amount * 0.35:
				(light as Light3D).light_energy *= randf_range(0.72, 0.96)
	var ui := get_tree().get_first_node_in_group("ui_root") as Node
	if ui and ui.has_method("set_threat_level"):
		ui.set_threat_level(clamp(1.0 - distance / far_pressure_distance, 0.0, 1.0))


func _move_towards(target_position: Vector3, speed: float, delta: float) -> void:
	var direction := target_position - global_position
	direction.y = 0.0
	if direction.length() > 0.25:
		direction = direction.normalized()
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		look_at(global_position + direction, Vector3.UP)
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		if patrol_points.size() > 0:
			patrol_index = (patrol_index + 1) % patrol_points.size()
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = -0.1
	move_and_slide()


func _get_patrol_target() -> Vector3:
	if patrol_points.is_empty():
		return global_position
	return patrol_points[patrol_index]


func _build_visual() -> void:
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.28
	capsule.height = 1.8
	collision.shape = capsule
	collision.position = Vector3(0.0, 0.9, 0.0)
	add_child(collision)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.005, 0.005, 0.004, 0.82)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.roughness = 1.0

	var body := MeshInstance3D.new()
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.30
	body_mesh.height = 1.72
	body.mesh = body_mesh
	body.material_override = mat
	body.position = Vector3(0.0, 0.88, 0.0)
	add_child(body)

	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.24
	head.mesh = head_mesh
	head.material_override = mat
	head.position = Vector3(0.0, 1.78, 0.0)
	add_child(head)

	var haze := OmniLight3D.new()
	haze.light_color = Color(0.025, 0.025, 0.022)
	haze.light_energy = 0.35
	haze.omni_range = 4.0
	haze.position = Vector3(0.0, 1.3, 0.0)
	add_child(haze)
