extends Node3D
class_name VisibilityBlendSection

enum LogicState { UNKNOWN, VISITED, VISIBLE }

@export var section_id := ""

var logic_state: int = LogicState.UNKNOWN
var visible_weight := 0.0
var memory_weight := 0.0
var unknown_weight := 1.0
var door_reveal_weight := 0.0
var last_average_reveal := 0.0

var _target_state: int = LogicState.UNKNOWN
var _target_door_reveal := 0.0
var _door_point := Vector3.ZERO
var _door_radius := 0.0
var _player_eye := Vector3.ZERO
var _manager: Node

var _meshes: Array[MeshInstance3D] = []
var _lights: Array[Light3D] = []
var _base_materials: Dictionary = {}
var _runtime_materials: Dictionary = {}
var _base_light_energy: Dictionary = {}
var _unknown_material: StandardMaterial3D
var _visited_material: StandardMaterial3D


func _ready() -> void:
	add_to_group("visibility_blend_section")
	call_deferred("initialize")


func initialize() -> void:
	_build_state_materials()
	_capture_tree(self)
	_apply_render()


func set_manager(manager: Node) -> void:
	_manager = manager


func set_target_state(new_state: int) -> void:
	logic_state = new_state
	_target_state = new_state


func force_state(new_state: int) -> void:
	logic_state = new_state
	_target_state = new_state
	visible_weight = 1.0 if new_state == LogicState.VISIBLE else 0.0
	memory_weight = 1.0 if new_state == LogicState.VISITED else 0.0
	unknown_weight = 1.0 if new_state == LogicState.UNKNOWN else 0.0
	_apply_render()


func set_door_reveal(door_point: Vector3, target_amount: float, radius: float, player_eye: Vector3) -> void:
	_door_point = door_point
	_target_door_reveal = clamp(target_amount, 0.0, 1.0)
	_door_radius = max(radius, 0.0)
	_player_eye = player_eye


func tick(delta: float, player_eye: Vector3) -> void:
	_player_eye = player_eye
	var visible_target := 1.0 if _target_state == LogicState.VISIBLE else 0.0
	var memory_target := 1.0 if _target_state != LogicState.UNKNOWN else 0.0
	var unknown_target := 1.0 if _target_state == LogicState.UNKNOWN else 0.0
	visible_weight = move_toward(visible_weight, visible_target, delta / 0.34)
	memory_weight = move_toward(memory_weight, memory_target, delta / 0.42)
	unknown_weight = move_toward(unknown_weight, unknown_target, delta / 0.30)
	door_reveal_weight = move_toward(door_reveal_weight, _target_door_reveal, delta / 0.28)
	_apply_render()


func get_state_name() -> String:
	match logic_state:
		LogicState.VISIBLE:
			return "VISIBLE"
		LogicState.VISITED:
			return "VISITED"
	return "UNKNOWN"


func get_debug_weights() -> Dictionary:
	return {
		"state": get_state_name(),
		"visible": visible_weight,
		"memory": memory_weight,
		"unknown": unknown_weight,
		"door_reveal": door_reveal_weight,
		"average_reveal": last_average_reveal
	}


func _build_state_materials() -> void:
	if _unknown_material:
		return
	_unknown_material = StandardMaterial3D.new()
	_unknown_material.albedo_color = Color(0.045, 0.046, 0.043)
	_unknown_material.roughness = 1.0
	_unknown_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	_visited_material = StandardMaterial3D.new()
	_visited_material.albedo_color = Color(0.25, 0.26, 0.25)
	_visited_material.roughness = 1.0


func _capture_tree(node: Node) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			var mesh := child as MeshInstance3D
			if not _meshes.has(mesh):
				_meshes.append(mesh)
			if not _base_materials.has(mesh):
				var material := mesh.material_override as StandardMaterial3D
				if material:
					var base := material.duplicate() as StandardMaterial3D
					var runtime := material.duplicate() as StandardMaterial3D
					mesh.material_override = runtime
					_base_materials[mesh] = base
					_runtime_materials[mesh] = runtime
		elif child is Light3D:
			var light := child as Light3D
			if not _lights.has(light):
				_lights.append(light)
			if not _base_light_energy.has(light):
				_base_light_energy[light] = light.light_energy
		_capture_tree(child)


func _apply_render() -> void:
	var reveal_sum := 0.0
	var reveal_count := 0
	for mesh in _meshes:
		if not is_instance_valid(mesh):
			continue
		var role := String(mesh.get_meta("visibility_role", "structure"))
		if role == "visibility_floor":
			role = "floor"
		var reveal := _door_reveal_for_mesh(mesh, role)
		reveal_sum += reveal
		reveal_count += 1
		_apply_mesh(mesh, role, reveal)

	last_average_reveal = reveal_sum / float(max(reveal_count, 1))
	for light in _lights:
		_apply_light(light)


func _apply_mesh(mesh: MeshInstance3D, role: String, reveal: float) -> void:
	if role == "light_mesh":
		var light_visible: float = max(_physical_visibility_at(mesh.global_position), reveal)
		if light_visible > 0.02 and _target_state == LogicState.VISIBLE:
			_apply_original(mesh, max(0.75, light_visible), 1.0)
			mesh.visible = true
		else:
			mesh.visible = false
		return

	var physical_visible := _physical_visibility_for_mesh(mesh, role)
	var current_visible: float = max(physical_visible, reveal)
	var current_memory: float = memory_weight * (1.0 - current_visible)
	if role == "wall" or role == "baseboard" or role == "ceiling" or role == "floor":
		if current_visible > 0.025 and _target_state == LogicState.VISIBLE:
			var structural_brightness: float = 1.0 if role == "floor" else max(0.38, _distance_brightness(mesh.global_position))
			_apply_original(mesh, structural_brightness, 1.0)
			mesh.visible = true
			return
		if current_memory > 0.025 and _role_visible_in_memory(role):
			_apply_flat_material(mesh, _visited_material, clamp(current_memory, 0.0, 1.0))
			mesh.visible = true
			return
		if unknown_weight > 0.025 and (role == "wall" or role == "outline"):
			_apply_flat_material(mesh, _unknown_material, clamp(unknown_weight, 0.0, 1.0))
			mesh.visible = true
			return
		mesh.visible = false
		return

	if current_visible > 0.025 and _target_state == LogicState.VISIBLE:
		var brightness: float = _distance_brightness(mesh.global_position) * lerp(0.58, 1.0, current_visible)
		_apply_original(mesh, brightness, clamp(current_visible, 0.0, 1.0))
		mesh.visible = true
		return

	if current_memory > 0.025 and _role_visible_in_memory(role):
		_apply_flat_material(mesh, _visited_material, clamp(current_memory, 0.0, 1.0))
		mesh.visible = true
		return

	if unknown_weight > 0.025 and (role == "wall" or role == "outline"):
		_apply_flat_material(mesh, _unknown_material, clamp(unknown_weight, 0.0, 1.0))
		mesh.visible = true
		return

	mesh.visible = false


func _apply_light(light: Light3D) -> void:
	var original: float = float(_base_light_energy.get(light, light.light_energy))
	var light_weight: float = max(_physical_visibility_at(light.global_position), door_reveal_weight * 0.35)
	if _target_state != LogicState.VISIBLE:
		light_weight = 0.0
	light.visible = light_weight > 0.03
	light.light_energy = original * clamp(light_weight, 0.0, 1.0)


func _role_visible_in_memory(role: String) -> bool:
	return role == "floor" or role == "wall" or role == "ceiling" or role == "baseboard" or role == "outline"


func _door_reveal_for_mesh(mesh: MeshInstance3D, role: String) -> float:
	if door_reveal_weight <= 0.01 or _door_radius <= 0.01:
		return 0.0
	if role == "detail" or role == "dynamic":
		return 0.0

	var sample := mesh.global_position
	var flat_sample := Vector2(sample.x, sample.z)
	var flat_door := Vector2(_door_point.x, _door_point.z)
	var distance := flat_sample.distance_to(flat_door)
	if distance >= _door_radius:
		return 0.0
	if _manager and _manager.has_method("has_line_of_sight") and not bool(_manager.call("has_line_of_sight", _player_eye, sample + Vector3(0.0, 0.18, 0.0))):
		return 0.0

	var radial: float = 1.0 - smoothstep(_door_radius * 0.42, _door_radius, distance)
	var lateral: float = 1.0 - smoothstep(1.35, 4.8, abs(sample.z - _door_point.z))
	return clamp(radial * lateral * door_reveal_weight, 0.0, 1.0)


func _distance_brightness(position: Vector3) -> float:
	return lerp(0.08, 1.0, _distance_visibility(position))


func _distance_visibility(position: Vector3) -> float:
	var distance: float = Vector2(_player_eye.x, _player_eye.z).distance_to(Vector2(position.x, position.z))
	if distance <= 7.5:
		return 1.0
	if distance <= 13.0:
		var t: float = clamp((distance - 7.5) / 5.5, 0.0, 1.0)
		return lerp(1.0, 0.58, smoothstep(0.0, 1.0, t))
	if distance <= 19.0:
		var t: float = clamp((distance - 13.0) / 6.0, 0.0, 1.0)
		return lerp(0.58, 0.0, smoothstep(0.0, 1.0, t))
	return 0.0


func _physical_visibility_for_mesh(mesh: MeshInstance3D, role: String) -> float:
	if role == "detail" or role == "dynamic":
		return _physical_visibility_at(mesh.global_position)
	if role == "wall" or role == "baseboard" or role == "ceiling" or role == "light_mesh":
		return _physical_visibility_at(mesh.global_position + Vector3(0.0, 0.18, 0.0))
	return _physical_visibility_at(mesh.global_position)


func _physical_visibility_at(position: Vector3) -> float:
	if not _manager:
		return _distance_visibility(position)
	if _manager.has_method("has_line_of_sight") and not bool(_manager.call("has_line_of_sight", _player_eye, position)):
		return 0.0
	return _distance_visibility(position)


func _apply_original(mesh: MeshInstance3D, brightness: float, alpha: float) -> void:
	var base := _base_materials.get(mesh) as StandardMaterial3D
	var runtime := _runtime_materials.get(mesh) as StandardMaterial3D
	if not base or not runtime:
		return
	runtime.albedo_color = base.albedo_color.darkened(1.0 - clamp(brightness, 0.0, 1.0))
	runtime.albedo_color.a = alpha
	runtime.albedo_texture = base.albedo_texture
	runtime.uv1_scale = base.uv1_scale
	runtime.texture_repeat = base.texture_repeat
	runtime.roughness = base.roughness
	runtime.roughness_texture = base.roughness_texture
	runtime.shading_mode = base.shading_mode
	runtime.emission_enabled = base.emission_enabled
	if base.emission_enabled:
		runtime.emission = base.emission.darkened(1.0 - clamp(brightness, 0.0, 1.0))
		runtime.emission_energy_multiplier = base.emission_energy_multiplier * alpha
	runtime.normal_enabled = base.normal_enabled
	runtime.normal_texture = base.normal_texture
	runtime.normal_scale = base.normal_scale
	runtime.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if alpha < 0.985 else BaseMaterial3D.TRANSPARENCY_DISABLED
	mesh.material_override = runtime


func _apply_flat_material(mesh: MeshInstance3D, material: StandardMaterial3D, alpha: float) -> void:
	var runtime := _runtime_materials.get(mesh) as StandardMaterial3D
	if not runtime:
		runtime = material.duplicate() as StandardMaterial3D
		_runtime_materials[mesh] = runtime
	runtime.albedo_color = material.albedo_color
	runtime.albedo_color.a = alpha
	runtime.albedo_texture = null
	runtime.roughness = material.roughness
	runtime.roughness_texture = null
	runtime.shading_mode = material.shading_mode
	runtime.emission_enabled = false
	runtime.normal_enabled = false
	runtime.normal_texture = null
	runtime.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if alpha < 0.985 else BaseMaterial3D.TRANSPARENCY_DISABLED
	mesh.material_override = runtime
