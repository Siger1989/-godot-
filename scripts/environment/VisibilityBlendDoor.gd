extends Node3D
class_name VisibilityBlendDoor

@export var door_width := 1.56
@export var door_height := 2.18
@export var open_angle_degrees := 92.0

var is_open := false
var open_amount := 0.0

var _target_open_amount := 0.0
var _hinge: Node3D
var _panel_collision: CollisionShape3D
var _player_near := false


func _ready() -> void:
	add_to_group("visibility_blend_door")
	_build_door()
	_build_interaction_area()


func _process(delta: float) -> void:
	if _player_near and Input.is_action_just_pressed("interact"):
		toggle()
	open_amount = move_toward(open_amount, _target_open_amount, delta / 0.32)
	if _hinge:
		_hinge.rotation.y = deg_to_rad(open_angle_degrees) * _smooth(open_amount)
	if _panel_collision:
		_panel_collision.disabled = open_amount > 0.58


func toggle() -> void:
	is_open = not is_open
	_target_open_amount = 1.0 if is_open else 0.0
	if not is_open and _panel_collision:
		_panel_collision.disabled = false


func force_open(value: bool) -> void:
	is_open = value
	_target_open_amount = 1.0 if value else 0.0


func get_open_amount() -> float:
	return open_amount


func _build_door() -> void:
	var mat_door := _material(Color(0.34, 0.25, 0.14), 0.88)
	var mat_frame := _material(Color(0.18, 0.14, 0.08), 0.92)

	_hinge = Node3D.new()
	_hinge.name = "DoorHinge"
	_hinge.position = Vector3(-door_width * 0.5, 0.0, 0.0)
	add_child(_hinge)

	var panel := StaticBody3D.new()
	panel.name = "DoorPanel"
	panel.position = Vector3(door_width * 0.5, door_height * 0.5, 0.0)
	panel.add_to_group("visibility_blend_los_blocker")
	_hinge.add_child(panel)
	_add_box(panel, "DoorSlab", Vector3.ZERO, Vector3(door_width, door_height, 0.11), mat_door, true, "door")
	_panel_collision = panel.get_node_or_null("DoorSlab/CollisionShape3D") as CollisionShape3D

	_add_box(self, "FrameLeft", Vector3(-door_width * 0.62, door_height * 0.5, 0.0), Vector3(0.18, door_height + 0.24, 0.34), mat_frame, true, "wall")
	_add_box(self, "FrameRight", Vector3(door_width * 0.62, door_height * 0.5, 0.0), Vector3(0.18, door_height + 0.24, 0.34), mat_frame, true, "wall")
	_add_box(self, "FrameTop", Vector3(0.0, door_height + 0.10, 0.0), Vector3(door_width + 0.48, 0.14, 0.30), mat_frame, true, "wall")


func _build_interaction_area() -> void:
	var area := Area3D.new()
	area.name = "InteractionArea"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(3.0, 2.1, 3.0)
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


func _smooth(value: float) -> float:
	return smoothstep(0.0, 1.0, clamp(value, 0.0, 1.0))


func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material


func _add_box(parent: Node, node_name: String, local_position: Vector3, size: Vector3, material: Material, collision: bool, role: String) -> Node3D:
	var container: Node3D = StaticBody3D.new() if collision else Node3D.new()
	container.name = node_name
	container.position = local_position
	container.set_meta("visibility_role", role)
	if role == "wall" or role == "door":
		container.add_to_group("visibility_blend_foreground_wall")
		container.add_to_group("visibility_blend_los_blocker")
	parent.add_child(container)

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name + "Mesh"
	mesh_instance.set_meta("visibility_role", role)
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
