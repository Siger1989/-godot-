extends CharacterBody3D
class_name VisibilityBlendPlayer

@export var walk_speed := 3.7

var camera_yaw := 0.0
var _walk_phase := 0.0
var _visual_root: Node3D
var _head: Node3D
var _torso: Node3D
var _left_arm: Node3D
var _right_arm: Node3D
var _left_leg: Node3D
var _right_leg: Node3D


func _ready() -> void:
	add_to_group("player")
	_build_body()


func _physics_process(delta: float) -> void:
	var input_vector := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_forward") - Input.get_action_strength("move_back")
	)
	if input_vector.length() > 1.0:
		input_vector = input_vector.normalized()

	var forward := Vector3(-sin(camera_yaw), 0.0, -cos(camera_yaw))
	var right := Vector3(cos(camera_yaw), 0.0, -sin(camera_yaw))
	var direction := right * input_vector.x + forward * input_vector.y
	if direction.length() > 1.0:
		direction = direction.normalized()

	velocity = direction * walk_speed
	move_and_slide()

	if direction.length() > 0.05:
		rotation.y = atan2(direction.x, direction.z)
	_animate_body(delta, min(direction.length(), 1.0))


func _build_body() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.23
	capsule.height = 1.12
	shape.shape = capsule
	shape.position = Vector3(0.0, 0.62, 0.0)
	add_child(shape)

	_visual_root = Node3D.new()
	_visual_root.name = "LittlePerson"
	add_child(_visual_root)

	var shirt := _material(Color(0.30, 0.40, 0.28), 0.9)
	var skin := _material(Color(0.70, 0.54, 0.40), 0.82)
	var pants := _material(Color(0.12, 0.15, 0.11), 0.92)

	_torso = _add_box_part("Torso", Vector3(0.0, 0.72, 0.0), Vector3(0.42, 0.56, 0.26), shirt)
	_head = _add_sphere_part("Head", Vector3(0.0, 1.18, 0.0), 0.19, skin)
	_add_box_part("Neck", Vector3(0.0, 1.00, 0.0), Vector3(0.13, 0.12, 0.12), skin)

	_left_arm = _add_limb("LeftArm", Vector3(-0.29, 0.92, 0.0), Vector3(-0.03, -0.22, 0.0), Vector3(0.12, 0.45, 0.12), skin)
	_right_arm = _add_limb("RightArm", Vector3(0.29, 0.92, 0.0), Vector3(0.03, -0.22, 0.0), Vector3(0.12, 0.45, 0.12), skin)
	_left_leg = _add_limb("LeftLeg", Vector3(-0.13, 0.43, 0.0), Vector3(0.0, -0.23, 0.0), Vector3(0.13, 0.48, 0.13), pants)
	_right_leg = _add_limb("RightLeg", Vector3(0.13, 0.43, 0.0), Vector3(0.0, -0.23, 0.0), Vector3(0.13, 0.48, 0.13), pants)

	_add_box_part("LeftFoot", Vector3(-0.13, 0.06, 0.06), Vector3(0.16, 0.10, 0.25), pants)
	_add_box_part("RightFoot", Vector3(0.13, 0.06, 0.06), Vector3(0.16, 0.10, 0.25), pants)


func _animate_body(delta: float, move_amount: float) -> void:
	if not _visual_root:
		return
	var moving: float = clamp(move_amount, 0.0, 1.0)
	_walk_phase += delta * lerp(2.0, 9.0, moving)
	var swing: float = sin(_walk_phase) * 0.55 * moving
	var counter: float = cos(_walk_phase * 2.0) * 0.035 * moving
	_visual_root.position.y = counter
	if _head:
		_head.rotation.z = sin(_walk_phase * 0.5) * 0.04 * moving
	if _torso:
		_torso.rotation.z = -sin(_walk_phase * 0.5) * 0.035 * moving
	if _left_arm:
		_left_arm.rotation.x = swing
	if _right_arm:
		_right_arm.rotation.x = -swing
	if _left_leg:
		_left_leg.rotation.x = -swing * 0.78
	if _right_leg:
		_right_leg.rotation.x = swing * 0.78


func _add_box_part(node_name: String, local_position: Vector3, size: Vector3, material: Material) -> Node3D:
	var part := MeshInstance3D.new()
	part.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	part.mesh = mesh
	part.position = local_position
	part.material_override = material
	_visual_root.add_child(part)
	return part


func _add_sphere_part(node_name: String, local_position: Vector3, radius: float, material: Material) -> Node3D:
	var part := MeshInstance3D.new()
	part.name = node_name
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	part.mesh = mesh
	part.position = local_position
	part.material_override = material
	_visual_root.add_child(part)
	return part


func _add_limb(node_name: String, pivot_position: Vector3, mesh_offset: Vector3, size: Vector3, material: Material) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = node_name
	pivot.position = pivot_position
	_visual_root.add_child(pivot)

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name + "Mesh"
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = mesh_offset
	mesh_instance.material_override = material
	pivot.add_child(mesh_instance)
	return pivot


func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material
