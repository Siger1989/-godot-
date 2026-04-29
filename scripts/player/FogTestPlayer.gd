extends CharacterBody3D
class_name FogTestPlayer

@export var walk_speed := 4.0


func _ready() -> void:
	add_to_group("player")
	_build_body()


func _physics_process(_delta: float) -> void:
	var input_vector := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	)
	if input_vector.length() > 1.0:
		input_vector = input_vector.normalized()

	var direction := Vector3(input_vector.x, 0.0, input_vector.y)
	velocity.x = direction.x * walk_speed
	velocity.z = direction.z * walk_speed
	velocity.y = 0.0
	move_and_slide()

	if direction.length() > 0.05:
		rotation.y = atan2(direction.x, direction.z)


func _build_body() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.36
	capsule.height = 1.55
	shape.shape = capsule
	shape.position = Vector3(0.0, 0.92, 0.0)
	add_child(shape)

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "PlayerBody"
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.36
	mesh.height = 1.55
	mesh_instance.mesh = mesh
	mesh_instance.position = Vector3(0.0, 0.92, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.42, 0.50, 0.38)
	mat.roughness = 0.9
	mesh_instance.material_override = mat
	add_child(mesh_instance)

	var head := MeshInstance3D.new()
	head.name = "PlayerHead"
	var sphere := SphereMesh.new()
	sphere.radius = 0.28
	head.mesh = sphere
	head.position = Vector3(0.0, 1.85, 0.0)
	var head_mat := StandardMaterial3D.new()
	head_mat.albedo_color = Color(0.74, 0.56, 0.40)
	head_mat.roughness = 0.82
	head.material_override = head_mat
	add_child(head)
