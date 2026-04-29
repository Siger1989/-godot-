extends CharacterBody3D
class_name RoomPrototypePlayer

@export var walk_speed := 3.8


func _ready() -> void:
	add_to_group("player")
	_build_visible_body()


func _physics_process(_delta: float) -> void:
	var input_vector := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	)
	if input_vector.length() > 1.0:
		input_vector = input_vector.normalized()

	var direction := Vector3(input_vector.x, 0.0, input_vector.y)
	velocity = direction * walk_speed
	move_and_slide()

	if direction.length() > 0.05:
		rotation.y = atan2(direction.x, direction.z)


func _build_visible_body() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.52
	shape.shape = capsule
	shape.position = Vector3(0.0, 0.86, 0.0)
	add_child(shape)

	var body := MeshInstance3D.new()
	body.name = "Body"
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.35
	body_mesh.height = 1.52
	body.mesh = body_mesh
	body.position = Vector3(0.0, 0.86, 0.0)
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.36, 0.45, 0.34)
	body_mat.roughness = 0.9
	body.material_override = body_mat
	add_child(body)

	var head := MeshInstance3D.new()
	head.name = "Head"
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.27
	head.mesh = head_mesh
	head.position = Vector3(0.0, 1.72, 0.0)
	var head_mat := StandardMaterial3D.new()
	head_mat.albedo_color = Color(0.72, 0.55, 0.40)
	head_mat.roughness = 0.82
	head.material_override = head_mat
	add_child(head)
