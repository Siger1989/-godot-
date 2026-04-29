extends Node3D
class_name DoorBase

@export var door_width := 1.15
@export var door_height := 2.25
@export var prompt_text := "按 E 开门"

var hinge: Node3D
var door_body: StaticBody3D
var door_collision: CollisionShape3D
var mat_door: StandardMaterial3D
var mat_frame: StandardMaterial3D


func _ready() -> void:
	add_to_group("interactable")
	_build_materials()
	_build_door()
	_build_interaction_area()


func interact(_player: Node) -> void:
	_feedback("没有反应。")


func get_interaction_text() -> String:
	return prompt_text


func _feedback(text: String) -> void:
	var manager := get_tree().get_first_node_in_group("game_manager")
	if manager and manager.has_method("show_feedback"):
		manager.show_feedback(text)


func _build_materials() -> void:
	mat_door = StandardMaterial3D.new()
	mat_door.albedo_color = Color(0.42, 0.34, 0.23)
	mat_door.roughness = 0.85
	mat_frame = StandardMaterial3D.new()
	mat_frame.albedo_color = Color(0.28, 0.24, 0.18)
	mat_frame.roughness = 0.9


func _build_door() -> void:
	hinge = Node3D.new()
	hinge.name = "Hinge"
	hinge.position = Vector3(-door_width * 0.5, 0.0, 0.0)
	add_child(hinge)

	door_body = StaticBody3D.new()
	door_body.name = "DoorPanel"
	door_body.position = Vector3(door_width * 0.5, door_height * 0.5, 0.0)
	hinge.add_child(door_body)
	_add_box(door_body, "PanelMesh", Vector3.ZERO, Vector3(door_width, door_height, 0.13), mat_door, true)

	_add_box(self, "FrameLeft", Vector3(-door_width * 0.62, door_height * 0.5, 0.0), Vector3(0.14, door_height + 0.15, 0.28), mat_frame, true)
	_add_box(self, "FrameRight", Vector3(door_width * 0.62, door_height * 0.5, 0.0), Vector3(0.14, door_height + 0.15, 0.28), mat_frame, true)
	_add_box(self, "FrameTop", Vector3(0.0, door_height + 0.08, 0.0), Vector3(door_width + 0.38, 0.16, 0.3), mat_frame, true)


func _build_interaction_area() -> void:
	var area := Area3D.new()
	area.name = "InteractArea"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.4, 2.0, 2.4)
	shape.shape = box
	shape.position = Vector3(0.0, 1.0, 0.0)
	area.add_child(shape)
	add_child(area)


func _add_box(parent: Node, node_name: String, local_position: Vector3, size: Vector3, material: Material, collision: bool) -> Node3D:
	var container: Node3D
	if collision:
		container = StaticBody3D.new()
	else:
		container = Node3D.new()
	container.name = node_name
	container.position = local_position
	parent.add_child(container)

	var mesh_instance := MeshInstance3D.new()
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

