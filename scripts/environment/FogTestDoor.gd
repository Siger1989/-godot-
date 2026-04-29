extends Node3D
class_name FogTestDoor

@export var room_a := ""
@export var room_b := ""
@export var door_width := 1.25
@export var door_height := 2.25
@export var open_angle_degrees := 92.0

var is_open := false
var _hinge: Node3D
var _panel_collision: CollisionShape3D
var _player_near := false
var _target_angle := 0.0


func _ready() -> void:
	add_to_group("fog_test_door")
	_build_door()
	_build_interaction_area()


func _process(delta: float) -> void:
	if _player_near and Input.is_action_just_pressed("interact"):
		toggle()
	if _hinge:
		_hinge.rotation.y = lerp_angle(_hinge.rotation.y, _target_angle, 1.0 - exp(-10.0 * delta))


func toggle() -> void:
	is_open = not is_open
	_target_angle = deg_to_rad(open_angle_degrees) if is_open else 0.0
	if _panel_collision:
		_panel_collision.disabled = is_open


func connects(a: String, b: String) -> bool:
	return (room_a == a and room_b == b) or (room_a == b and room_b == a)


func _build_door() -> void:
	var mat_door := StandardMaterial3D.new()
	mat_door.albedo_color = Color(0.36, 0.28, 0.17)
	mat_door.roughness = 0.9
	var mat_frame := StandardMaterial3D.new()
	mat_frame.albedo_color = Color(0.18, 0.16, 0.11)
	mat_frame.roughness = 0.95

	_hinge = Node3D.new()
	_hinge.name = "Hinge"
	_hinge.position = Vector3(-door_width * 0.5, 0.0, 0.0)
	add_child(_hinge)

	var panel := StaticBody3D.new()
	panel.name = "DoorPanel"
	panel.position = Vector3(door_width * 0.5, door_height * 0.5, 0.0)
	_hinge.add_child(panel)
	_add_box(panel, "PanelMesh", Vector3.ZERO, Vector3(door_width, door_height, 0.12), mat_door, true, "wall")
	_panel_collision = panel.get_node_or_null("PanelMesh/CollisionShape3D") as CollisionShape3D

	_add_box(self, "FrameLeft", Vector3(-door_width * 0.62, door_height * 0.5, 0.0), Vector3(0.14, door_height + 0.15, 0.28), mat_frame, true, "wall")
	_add_box(self, "FrameRight", Vector3(door_width * 0.62, door_height * 0.5, 0.0), Vector3(0.14, door_height + 0.15, 0.28), mat_frame, true, "wall")
	_add_box(self, "FrameTop", Vector3(0.0, door_height + 0.08, 0.0), Vector3(door_width + 0.38, 0.16, 0.30), mat_frame, true, "wall")


func _build_interaction_area() -> void:
	var area := Area3D.new()
	area.name = "InteractionArea"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(3.0, 2.2, 3.0)
	shape.shape = box
	shape.position = Vector3(0.0, 1.0, 0.0)
	area.add_child(shape)
	add_child(area)
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_near = true


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_near = false


func _add_box(parent: Node, node_name: String, local_position: Vector3, size: Vector3, material: Material, collision: bool, role: String) -> Node3D:
	var container: Node3D = StaticBody3D.new() if collision else Node3D.new()
	container.name = node_name
	container.position = local_position
	container.set_meta("fog_role", role)
	parent.add_child(container)

	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	mesh_instance.set_meta("fog_role", role)
	container.add_child(mesh_instance)

	if collision:
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size
		shape.shape = box
		container.add_child(shape)
	return container
