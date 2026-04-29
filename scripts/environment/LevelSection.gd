extends Node3D
class_name LevelSection

enum VisibilityState { UNKNOWN, VISITED, VISIBLE }

@export var section_id := ""
@export var transition_speed := 5.2

var state := VisibilityState.UNKNOWN
var target_visibility := 0.0
var current_visibility := 0.0
var target_fog_alpha := 0.62
var current_fog_alpha := 0.62
var visited_material: StandardMaterial3D
var unknown_material: StandardMaterial3D
var original_materials: Dictionary = {}
var original_light_energy: Dictionary = {}


func _ready() -> void:
	add_to_group("level_section")
	visited_material = StandardMaterial3D.new()
	visited_material.albedo_color = Color(0.24, 0.25, 0.23, 1.0)
	visited_material.roughness = 1.0
	unknown_material = StandardMaterial3D.new()
	unknown_material.albedo_color = Color(0.12, 0.125, 0.105, 1.0)
	unknown_material.roughness = 1.0
	unknown_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_apply_to_tree(self)


func _process(delta: float) -> void:
	current_visibility = lerp(current_visibility, target_visibility, 1.0 - exp(-transition_speed * delta))
	current_fog_alpha = lerp(current_fog_alpha, target_fog_alpha, 1.0 - exp(-transition_speed * delta))
	_apply_to_tree(self)


func apply_visibility(new_state: int) -> void:
	state = new_state
	match state:
		VisibilityState.UNKNOWN:
			target_visibility = 0.0
			target_fog_alpha = 0.66
		VisibilityState.VISITED:
			target_visibility = 0.34
			target_fog_alpha = 0.28
		VisibilityState.VISIBLE:
			target_visibility = 1.0
			target_fog_alpha = 0.0


func _apply_to_tree(node: Node) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			_apply_mesh(child as MeshInstance3D)
		elif child is Light3D:
			_apply_light(child as Light3D)
		elif child is Node3D:
			_apply_visibility_flag(child as Node3D)
		_apply_to_tree(child)


func _apply_visibility_flag(node: Node3D) -> void:
	var role := String(node.get_meta("fog_role", "structure"))
	if role == "detail":
		node.visible = current_visibility > 0.82
	elif role == "mask":
		node.visible = current_fog_alpha > 0.035
	else:
		node.visible = true


func _apply_mesh(mesh: MeshInstance3D) -> void:
	if not original_materials.has(mesh):
		original_materials[mesh] = mesh.material_override

	var role := String(mesh.get_meta("fog_role", "structure"))
	if role == "mask":
		mesh.visible = current_fog_alpha > 0.035
		var mask_material := mesh.material_override as ShaderMaterial
		if mask_material:
			mask_material.set_shader_parameter("alpha", current_fog_alpha)
			mask_material.set_shader_parameter("noise_shift", Time.get_ticks_msec() * 0.00008)
		return

	if role == "detail":
		mesh.visible = current_visibility > 0.82
		if mesh.visible:
			mesh.material_override = original_materials[mesh]
		return

	if role == "floor" and state == VisibilityState.UNKNOWN:
		mesh.visible = current_visibility > 0.08
	else:
		mesh.visible = true

	if current_visibility >= 0.82:
		mesh.material_override = original_materials[mesh]
	elif current_visibility > 0.12:
		mesh.material_override = visited_material
	else:
		mesh.material_override = unknown_material


func _apply_light(light: Light3D) -> void:
	if not original_light_energy.has(light):
		original_light_energy[light] = light.light_energy
	var energy_factor: float = clamp(current_visibility, 0.0, 1.0)
	if state == VisibilityState.VISITED:
		energy_factor = min(energy_factor, 0.32)
	light.visible = energy_factor > 0.05
	light.light_energy = float(original_light_energy[light]) * energy_factor
