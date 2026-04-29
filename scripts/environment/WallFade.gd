extends Node3D
class_name WallFade

@export var fade_alpha := 0.32
@export var check_interval := 0.05

var faded_meshes: Array[MeshInstance3D] = []
var original_materials: Dictionary = {}
var timer := 0.0


func _process(delta: float) -> void:
	timer -= delta
	if timer > 0.0:
		return
	timer = check_interval
	_restore()
	var player := get_tree().get_first_node_in_group("player") as Node3D
	var camera := get_viewport().get_camera_3d()
	if not player or not camera:
		return
	var space := get_world_3d().direct_space_state
	var from := camera.global_position
	var to := player.global_position + Vector3(0.0, 1.0, 0.0)
	var params := PhysicsRayQueryParameters3D.create(from, to)
	params.exclude = [player.get_rid()]
	params.hit_from_inside = false
	var hit := space.intersect_ray(params)
	if hit.is_empty():
		return
	var collider := hit.get("collider") as Node
	if not collider or not collider.is_in_group("camera_fade_wall"):
		return
	for child in collider.get_children():
		if child is MeshInstance3D:
			_fade_mesh(child as MeshInstance3D)


func _fade_mesh(mesh: MeshInstance3D) -> void:
	if not original_materials.has(mesh):
		original_materials[mesh] = mesh.material_override
	var source := original_materials[mesh] as Material
	var mat := source.duplicate() as StandardMaterial3D
	if mat:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		var color := mat.albedo_color
		color.a = fade_alpha
		mat.albedo_color = color
		mesh.material_override = mat
		faded_meshes.append(mesh)


func _restore() -> void:
	for mesh in faded_meshes:
		if is_instance_valid(mesh) and original_materials.has(mesh):
			mesh.material_override = original_materials[mesh]
	faded_meshes.clear()
