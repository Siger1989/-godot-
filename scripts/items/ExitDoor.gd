extends Node3D
class_name ExitDoor

var is_open := false
var left_hinge: Node3D
var right_hinge: Node3D
var left_collision: CollisionShape3D
var right_collision: CollisionShape3D
var indicator_material: StandardMaterial3D


func _ready() -> void:
	add_to_group("interactable")
	_build_exit()


func _process(delta: float) -> void:
	var objective := get_tree().get_first_node_in_group("objective_manager")
	if objective and indicator_material:
		if objective.power_restored:
			indicator_material.albedo_color = Color(0.24, 0.95, 0.36)
			indicator_material.emission = Color(0.1, 0.9, 0.18)
		else:
			indicator_material.albedo_color = Color(0.85, 0.6, 0.16)
			indicator_material.emission = Color(0.8, 0.38, 0.06)
	if left_hinge:
		left_hinge.rotation.y = lerp_angle(left_hinge.rotation.y, deg_to_rad(-86.0) if is_open else 0.0, 1.0 - exp(-6.0 * delta))
	if right_hinge:
		right_hinge.rotation.y = lerp_angle(right_hinge.rotation.y, deg_to_rad(86.0) if is_open else 0.0, 1.0 - exp(-6.0 * delta))


func interact(_player: Node) -> void:
	var objective := get_tree().get_first_node_in_group("objective_manager")
	if not objective:
		return
	if not objective.can_open_exit():
		_feedback("出口门没有供电，控制面板只剩黄灯。")
		return
	if not is_open:
		is_open = true
		if left_collision:
			left_collision.disabled = true
		if right_collision:
			right_collision.disabled = true
		_feedback("远端金属门缓慢打开。")
	else:
		objective.win_game()


func get_interaction_text() -> String:
	var objective := get_tree().get_first_node_in_group("objective_manager")
	if objective and objective.power_restored:
		return "打开出口" if not is_open else "离开 Level 0"
	return "出口断电"


func _on_exit_body_entered(body: Node3D) -> void:
	if not is_open or not body.is_in_group("player"):
		return
	var objective := get_tree().get_first_node_in_group("objective_manager")
	if objective:
		objective.win_game()


func _feedback(text: String) -> void:
	var manager := get_tree().get_first_node_in_group("game_manager")
	if manager and manager.has_method("show_feedback"):
		manager.show_feedback(text)


func _build_exit() -> void:
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color(0.22, 0.24, 0.22)
	metal.metallic = 0.45
	metal.roughness = 0.62
	var frame := StandardMaterial3D.new()
	frame.albedo_color = Color(0.08, 0.09, 0.08)
	frame.metallic = 0.6
	frame.roughness = 0.5
	indicator_material = StandardMaterial3D.new()
	indicator_material.albedo_color = Color(0.85, 0.6, 0.16)
	indicator_material.emission_enabled = true
	indicator_material.emission = Color(0.8, 0.38, 0.06)
	indicator_material.emission_energy_multiplier = 1.2

	left_hinge = Node3D.new()
	left_hinge.name = "LeftHinge"
	left_hinge.position = Vector3(-1.2, 0.0, 0.0)
	add_child(left_hinge)
	right_hinge = Node3D.new()
	right_hinge.name = "RightHinge"
	right_hinge.position = Vector3(1.2, 0.0, 0.0)
	add_child(right_hinge)

	left_collision = _add_panel(left_hinge, "LeftDoor", Vector3(0.6, 1.2, 0.0), Vector3(1.2, 2.4, 0.18), metal)
	right_collision = _add_panel(right_hinge, "RightDoor", Vector3(-0.6, 1.2, 0.0), Vector3(1.2, 2.4, 0.18), metal)
	_add_box(self, "ExitFrameTop", Vector3(0.0, 2.55, 0.0), Vector3(2.8, 0.22, 0.34), frame, true)
	_add_box(self, "ExitFrameLeft", Vector3(-1.36, 1.2, 0.0), Vector3(0.18, 2.55, 0.34), frame, true)
	_add_box(self, "ExitFrameRight", Vector3(1.36, 1.2, 0.0), Vector3(0.18, 2.55, 0.34), frame, true)
	_add_box(self, "ControlLight", Vector3(1.75, 1.3, -0.12), Vector3(0.22, 0.22, 0.06), indicator_material, false)

	var interact_area := Area3D.new()
	interact_area.name = "InteractArea"
	var interact_shape := CollisionShape3D.new()
	var interact_box := BoxShape3D.new()
	interact_box.size = Vector3(4.0, 2.3, 2.6)
	interact_shape.shape = interact_box
	interact_shape.position = Vector3(0.0, 1.1, 0.0)
	interact_area.add_child(interact_shape)
	add_child(interact_area)

	var exit_area := Area3D.new()
	exit_area.name = "ExitTrigger"
	var exit_shape := CollisionShape3D.new()
	var exit_box := BoxShape3D.new()
	exit_box.size = Vector3(2.8, 2.2, 1.0)
	exit_shape.shape = exit_box
	exit_shape.position = Vector3(0.0, 1.1, 1.0)
	exit_area.add_child(exit_shape)
	add_child(exit_area)
	exit_area.body_entered.connect(_on_exit_body_entered)


func _add_panel(parent: Node, node_name: String, local_position: Vector3, size: Vector3, material: Material) -> CollisionShape3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = local_position
	parent.add_child(body)
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	body.add_child(mesh_instance)
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	collision.shape = box
	body.add_child(collision)
	return collision


func _add_box(parent: Node, node_name: String, local_position: Vector3, size: Vector3, material: Material, collision: bool) -> Node3D:
	var container: Node3D = StaticBody3D.new() if collision else Node3D.new()
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
