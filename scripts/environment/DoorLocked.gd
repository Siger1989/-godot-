extends "res://scripts/environment/DoorBase.gd"
class_name DoorLocked


func _ready() -> void:
	super._ready()
	prompt_text = "锁住了"
	mat_door.albedo_color = Color(0.30, 0.28, 0.22)
	_add_indicator()


func interact(_player: Node) -> void:
	_feedback("旧锁牌晃了一下，门仍然锁着。")


func _add_indicator() -> void:
	var light_mesh := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.14, 0.08, 0.03)
	light_mesh.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.75, 0.16, 0.08)
	mat.emission_enabled = true
	mat.emission = Color(0.8, 0.08, 0.02)
	mat.emission_energy_multiplier = 0.8
	light_mesh.material_override = mat
	light_mesh.position = Vector3(0.0, 1.45, -0.09)
	add_child(light_mesh)

