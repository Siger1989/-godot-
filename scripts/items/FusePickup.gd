extends Area3D
class_name FusePickup

@export var fuse_name := "保险丝"


func _ready() -> void:
	add_to_group("interactable")
	_build_visual()


func interact(_player: Node) -> void:
	var objective := get_tree().get_first_node_in_group("objective_manager")
	if objective:
		objective.collect_fuse(fuse_name)
	queue_free()


func get_interaction_text() -> String:
	return "拾取 %s" % fuse_name


func _build_visual() -> void:
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.75
	shape.shape = sphere
	shape.position = Vector3(0.0, 0.25, 0.0)
	add_child(shape)

	var body := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.12
	mesh.bottom_radius = 0.12
	mesh.height = 0.55
	body.mesh = mesh
	body.rotation.z = deg_to_rad(90.0)
	body.position = Vector3(0.0, 0.25, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.82, 0.76, 0.42)
	mat.metallic = 0.15
	mat.roughness = 0.38
	mat.emission_enabled = true
	mat.emission = Color(0.55, 0.45, 0.12)
	mat.emission_energy_multiplier = 0.35
	body.material_override = mat
	add_child(body)

	var cap_mat := StandardMaterial3D.new()
	cap_mat.albedo_color = Color(0.15, 0.14, 0.12)
	for x in [-0.31, 0.31]:
		var cap := MeshInstance3D.new()
		var cap_mesh := BoxMesh.new()
		cap_mesh.size = Vector3(0.06, 0.22, 0.22)
		cap.mesh = cap_mesh
		cap.material_override = cap_mat
		cap.position = Vector3(x, 0.25, 0.0)
		add_child(cap)

	var light := OmniLight3D.new()
	light.light_color = Color(0.9, 0.75, 0.35)
	light.light_energy = 0.25
	light.omni_range = 2.5
	light.position = Vector3(0.0, 0.6, 0.0)
	add_child(light)
