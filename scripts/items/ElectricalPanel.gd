extends Node3D
class_name ElectricalPanel

var indicator_material: StandardMaterial3D


func _ready() -> void:
	add_to_group("interactable")
	_build_panel()


func _process(_delta: float) -> void:
	var objective := get_tree().get_first_node_in_group("objective_manager")
	if not objective or not indicator_material:
		return
	if objective.power_restored:
		indicator_material.albedo_color = Color(0.22, 0.9, 0.32)
		indicator_material.emission = Color(0.08, 0.8, 0.18)
	elif objective.fuse_count >= objective.required_fuses:
		indicator_material.albedo_color = Color(0.9, 0.72, 0.18)
		indicator_material.emission = Color(0.9, 0.55, 0.08)
	else:
		indicator_material.albedo_color = Color(0.82, 0.12, 0.06)
		indicator_material.emission = Color(0.8, 0.05, 0.03)


func interact(_player: Node) -> void:
	var objective := get_tree().get_first_node_in_group("objective_manager")
	if not objective:
		return
	if objective.power_restored:
		_feedback("配电箱已经恢复供电。")
	elif objective.can_restore_power():
		objective.restore_power()
	else:
		_feedback("需要 3 个保险丝才能合上主闸。")


func get_interaction_text() -> String:
	var objective := get_tree().get_first_node_in_group("objective_manager")
	if objective and objective.can_restore_power():
		return "装入保险丝并合闸"
	return "检查配电箱"


func _feedback(text: String) -> void:
	var manager := get_tree().get_first_node_in_group("game_manager")
	if manager and manager.has_method("show_feedback"):
		manager.show_feedback(text)


func _build_panel() -> void:
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color(0.17, 0.19, 0.18)
	metal.metallic = 0.3
	metal.roughness = 0.7
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.04, 0.045, 0.04)
	indicator_material = StandardMaterial3D.new()
	indicator_material.albedo_color = Color(0.82, 0.12, 0.06)
	indicator_material.emission_enabled = true
	indicator_material.emission = Color(0.8, 0.05, 0.03)
	indicator_material.emission_energy_multiplier = 0.9

	_add_box("BackPlate", Vector3.ZERO, Vector3(1.1, 1.6, 0.16), metal, true)
	_add_box("Screen", Vector3(0.0, 0.28, -0.09), Vector3(0.62, 0.28, 0.035), dark, false)
	_add_box("Indicator", Vector3(0.35, 0.64, -0.1), Vector3(0.16, 0.16, 0.04), indicator_material, false)
	for i in 4:
		_add_box("FuseSlot_%d" % i, Vector3(-0.32 + i * 0.21, -0.25, -0.1), Vector3(0.08, 0.46, 0.045), dark, false)

	var area := Area3D.new()
	area.name = "InteractArea"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.4, 2.1, 2.2)
	shape.shape = box
	shape.position = Vector3(0.0, 0.2, 0.0)
	area.add_child(shape)
	add_child(area)


func _add_box(node_name: String, local_position: Vector3, size: Vector3, material: Material, collision: bool) -> Node3D:
	var container: Node3D = StaticBody3D.new() if collision else Node3D.new()
	container.name = node_name
	container.position = local_position
	add_child(container)
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
