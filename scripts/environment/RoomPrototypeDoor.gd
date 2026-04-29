extends Node3D
class_name RoomPrototypeDoor

@export var room_a := ""
@export var room_b := ""
@export var door_width := 1.25
@export var door_height := 2.22
@export var open_angle_degrees := 92.0

var is_open := false
var _target_angle := 0.0
var _hinge: Node3D
var _panel_collision: CollisionShape3D
var _player_near := false


func _ready() -> void:
	add_to_group("room_prototype_door")
	_build_door()
	_build_interaction_area()


func _process(delta: float) -> void:
	if _player_near and Input.is_action_just_pressed("interact"):
		toggle()
	if _hinge:
		_hinge.rotation.y = lerp_angle(_hinge.rotation.y, _target_angle, 1.0 - exp(-9.0 * delta))


func toggle() -> void:
	is_open = not is_open
	_target_angle = deg_to_rad(open_angle_degrees) if is_open else 0.0
	if _panel_collision:
		_panel_collision.disabled = is_open


func connects(a: String, b: String) -> bool:
	return (room_a == a and room_b == b) or (room_a == b and room_b == a)


func _build_door() -> void:
	var mat_door := _mat(Color(0.34, 0.26, 0.15), false)
	var mat_frame := _mat(Color(0.17, 0.135, 0.075), false)

	_hinge = Node3D.new()
	_hinge.name = "Hinge"
	_hinge.position = Vector3(-door_width * 0.5, 0.0, 0.0)
	add_child(_hinge)

	var panel := StaticBody3D.new()
	panel.name = "DoorPanel"
	panel.position = Vector3(door_width * 0.5, door_height * 0.5, 0.0)
	panel.add_to_group("prototype_los_blocker")
	_hinge.add_child(panel)
	_add_box(panel, "DoorSlab", Vector3.ZERO, Vector3(door_width, door_height, 0.12), mat_door, true, "door")
	_panel_collision = panel.get_node_or_null("DoorSlab/CollisionShape3D") as CollisionShape3D

	_add_box(self, "FrameLeft", Vector3(-door_width * 0.62, door_height * 0.5, 0.0), Vector3(0.16, door_height + 0.22, 0.34), mat_frame, true, "wall")
	_add_box(self, "FrameRight", Vector3(door_width * 0.62, door_height * 0.5, 0.0), Vector3(0.16, door_height + 0.22, 0.34), mat_frame, true, "wall")
	_add_box(self, "FrameTop", Vector3(0.0, door_height + 0.08, 0.0), Vector3(door_width + 0.42, 0.18, 0.34), mat_frame, true, "wall")


func _build_interaction_area() -> void:
	var area := Area3D.new()
	area.name = "InteractionArea"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.8, 2.1, 2.8)
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


func _mat(color: Color, unshaded: bool) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	if unshaded:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material


func _add_box(parent: Node, node_name: String, local_position: Vector3, size: Vector3, material: Material, collision: bool, role: String) -> Node3D:
	var container: Node3D = StaticBody3D.new() if collision else Node3D.new()
	container.name = node_name
	container.position = local_position
	container.set_meta("fog_role", role)
	if role == "wall":
		container.add_to_group("prototype_foreground_wall")
		container.add_to_group("prototype_los_blocker")
	parent.add_child(container)

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name + "Mesh"
	mesh_instance.set_meta("fog_role", role)
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	container.add_child(mesh_instance)

	if collision:
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size
		shape.shape = box
		container.add_child(shape)
	return container
