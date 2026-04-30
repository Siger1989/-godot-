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
var _mesh_live_weights: Dictionary = {}
var _mesh_seen_as_memory: Dictionary = {}
var _light_visibility_weights: Dictionary = {}
var _light_mesh_visibility_weights: Dictionary = {}
var _unknown_material: StandardMaterial3D
var _visited_material: StandardMaterial3D
var _last_delta := 0.016
var _section_light_target := 0.0
var _floor_light_target := 0.0
var _lamp_light_target := 0.0


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
	_last_delta = max(delta, 0.001)
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
		"average_reveal": last_average_reveal,
		"light_target": _section_light_target,
		"floor_light_target": _floor_light_target,
		"lamp_light_target": _lamp_light_target
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
	_visited_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED


func _capture_tree(node: Node) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			var mesh := child as MeshInstance3D
			if String(mesh.get_meta("visibility_role", "")) == "camera_cutline":
				continue
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
	_section_light_target = 0.0
	_floor_light_target = 0.0
	_lamp_light_target = 0.0
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
		var target_light_visible: float = max(_physical_visibility_for_structure(mesh, 0.18, role), reveal)
		_lamp_light_target = max(_lamp_light_target, target_light_visible)
		_section_light_target = max(_section_light_target, target_light_visible)
		var light_visible := _smooth_weight(_light_mesh_visibility_weights, mesh, target_light_visible, 0.16, 0.36)
		if light_visible > 0.02:
			var light_alpha: float = clamp(light_visible * 1.35, 0.0, 1.0)
			var light_brightness: float = lerp(0.25, 1.0, clamp(light_visible, 0.0, 1.0))
			_apply_original(mesh, light_brightness, light_alpha)
			mesh.visible = true
		else:
			mesh.visible = false
		return

	var raw_visible: float = max(_physical_visibility_for_mesh(mesh, role), reveal)
	if role == "floor":
		_floor_light_target = max(_floor_light_target, raw_visible)
		_section_light_target = max(_section_light_target, raw_visible)
	var live_weight := _smooth_weight(_mesh_live_weights, mesh, raw_visible, 0.12, 0.24)
	if live_weight > 0.035:
		_mesh_seen_as_memory[mesh] = true
	if _is_structure_role(role) and not _mesh_seen_as_memory.has(mesh) and _memory_visibility_for_mesh(mesh, role) > 0.015:
		_mesh_seen_as_memory[mesh] = true
	var current_memory: float = memory_weight * (1.0 - live_weight)
	if _is_structure_role(role):
		var can_show_memory: bool = _can_show_structure_memory(mesh, role, 1.0 - live_weight)
		if live_weight > 0.015:
			var live_mix: float = _live_mix_for_role(role, live_weight)
			var live_brightness: float = 1.0 if role == "floor" else max(0.38, _distance_brightness(mesh.global_position))
			var static_brightness: float = _static_brightness_for_role(role, false)
			var brightness: float = lerp(static_brightness, live_brightness, live_mix)
			var memory_amount: float = lerp(1.0, 0.0, live_mix)
			_apply_original_tinted(mesh, brightness, 1.0, _static_tint_for_role(role, false), memory_amount)
			mesh.visible = true
			return
		if can_show_memory:
			var static_brightness: float = _static_brightness_for_role(role, false)
			_apply_original_tinted(mesh, static_brightness, 1.0, _static_tint_for_role(role, false), 1.0)
			mesh.visible = true
			return
		mesh.visible = false
		return

	if live_weight > 0.025 and _target_state == LogicState.VISIBLE:
		var brightness: float = _distance_brightness(mesh.global_position) * lerp(0.58, 1.0, live_weight)
		_apply_original(mesh, brightness, clamp(live_weight, 0.0, 1.0))
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
	var target_weight: float = max(_section_light_target, door_reveal_weight * 0.35)
	var current_weight := _smooth_weight(_light_visibility_weights, light, target_weight, 0.18, 0.45)
	light.visible = current_weight > 0.025
	light.light_energy = original * current_weight


func _role_visible_in_memory(role: String) -> bool:
	return _is_structure_role(role) or role == "outline"


func _is_structure_role(role: String) -> bool:
	return role == "floor" or role == "wall" or role == "wall_trim" or role == "ceiling" or role == "baseboard"


func _is_wall_like_role(role: String) -> bool:
	return role == "wall" or role == "wall_trim" or role == "baseboard" or role == "ceiling"


func _live_threshold_for_role(role: String) -> float:
	if _is_wall_like_role(role):
		return 0.28
	return 0.015


func _live_mix_for_role(role: String, live_weight: float) -> float:
	if not _is_wall_like_role(role):
		return clamp(live_weight, 0.0, 1.0)
	var threshold := _live_threshold_for_role(role)
	return smoothstep(threshold * 0.48, threshold, live_weight)


func _can_show_structure_memory(mesh: MeshInstance3D, role: String, current_memory: float) -> bool:
	if not _is_structure_role(role):
		return false
	return current_memory > 0.025 and _mesh_seen_as_memory.has(mesh)


func _smooth_weight(store: Dictionary, key: Variant, target: float, rise_time: float, fall_time: float) -> float:
	target = clamp(target, 0.0, 1.0)
	var current: float = float(store.get(key, 0.0))
	var duration: float = rise_time if target > current else fall_time
	current = move_toward(current, target, _last_delta / max(duration, 0.001))
	if current < 0.001:
		current = 0.0
	store[key] = current
	return current


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
	if role == "wall" or role == "wall_trim" or role == "baseboard" or role == "ceiling" or role == "light_mesh":
		return _physical_visibility_for_structure(mesh, 0.18, role)
	if role == "floor":
		return _physical_visibility_for_structure(mesh, 0.03, role)
	return _physical_visibility_at(mesh.global_position)


func _memory_visibility_for_mesh(mesh: MeshInstance3D, role: String) -> float:
	if _is_wall_like_role(role):
		return _memory_visibility_for_wall_structure(mesh, 0.18, role)
	if role == "floor":
		return _physical_visibility_for_structure(mesh, 0.03, role)
	return 0.0


func _memory_visibility_for_wall_structure(mesh: MeshInstance3D, vertical_offset: float, role: String) -> float:
	var samples := _mesh_visibility_samples(mesh, vertical_offset, role)
	var probes := _wall_front_probe_samples(mesh, vertical_offset, role)
	var hit_tolerance := _visibility_hit_tolerance(role)
	var best := 0.0
	var sample_count: int = min(samples.size(), probes.size())
	for i in sample_count:
		var probe_visible := _physical_visibility_at(probes[i], 0.012)
		var surface_visible := _physical_visibility_at(samples[i], hit_tolerance)
		best = max(best, max(probe_visible, surface_visible))
	return best


func _physical_visibility_for_structure(mesh: MeshInstance3D, vertical_offset: float, role: String = "") -> float:
	if _is_wall_like_role(role):
		return _physical_visibility_for_wall_structure(mesh, vertical_offset, role)
	var samples := _mesh_visibility_samples(mesh, vertical_offset, role)
	var best := 0.0
	var hit_tolerance := _visibility_hit_tolerance(role)
	for sample in samples:
		best = max(best, _physical_visibility_at(sample, hit_tolerance))
	return best


func _physical_visibility_for_wall_structure(mesh: MeshInstance3D, vertical_offset: float, role: String) -> float:
	var samples := _mesh_visibility_samples(mesh, vertical_offset, role)
	var probes := _wall_front_probe_samples(mesh, vertical_offset, role)
	var hit_tolerance := _visibility_hit_tolerance(role)
	var total := 0.0
	var visible_count := 0
	var sample_count: int = min(samples.size(), probes.size())
	for i in sample_count:
		if _physical_visibility_at(probes[i], 0.012) <= 0.0:
			continue
		var sample_visible := _physical_visibility_at(samples[i], hit_tolerance)
		if sample_visible <= 0.0:
			continue
		total += sample_visible
		visible_count += 1
	if visible_count < min(3, sample_count):
		return 0.0
	return total / float(max(sample_count, 1))


func _visibility_hit_tolerance(role: String) -> float:
	if role == "wall" or role == "wall_trim" or role == "baseboard" or role == "ceiling":
		return 0.035
	return 0.012


func _mesh_visibility_samples(mesh: MeshInstance3D, vertical_offset: float, role: String = "") -> Array[Vector3]:
	var samples: Array[Vector3] = []
	var local_center := Vector3.ZERO
	var local_min := Vector3.ZERO
	var local_max := Vector3.ZERO
	if mesh.mesh:
		var bounds := mesh.mesh.get_aabb()
		local_center = bounds.get_center()
		local_min = bounds.position
		local_max = bounds.position + bounds.size

	var local_size := local_max - local_min
	var local_eye := mesh.global_transform.affine_inverse() * _player_eye
	if role == "wall" or role == "wall_trim" or role == "baseboard":
		var sample_y := local_center.y
		if role == "wall" or role == "wall_trim":
			sample_y = clamp(local_eye.y, local_min.y + 0.35, local_max.y - 0.18)
		if local_size.x >= local_size.z:
			var face_z := local_min.z if local_eye.z < local_center.z else local_max.z
			samples.append(mesh.global_transform * Vector3(local_center.x, sample_y, face_z))
			samples.append(mesh.global_transform * Vector3(local_min.x + 0.02, sample_y, face_z))
			samples.append(mesh.global_transform * Vector3(local_max.x - 0.02, sample_y, face_z))
			samples.append(mesh.global_transform * Vector3(lerp(local_min.x, local_max.x, 0.33), sample_y, face_z))
			samples.append(mesh.global_transform * Vector3(lerp(local_min.x, local_max.x, 0.67), sample_y, face_z))
		else:
			var face_x := local_min.x if local_eye.x < local_center.x else local_max.x
			samples.append(mesh.global_transform * Vector3(face_x, sample_y, local_center.z))
			samples.append(mesh.global_transform * Vector3(face_x, sample_y, local_min.z + 0.02))
			samples.append(mesh.global_transform * Vector3(face_x, sample_y, local_max.z - 0.02))
			samples.append(mesh.global_transform * Vector3(face_x, sample_y, lerp(local_min.z, local_max.z, 0.33)))
			samples.append(mesh.global_transform * Vector3(face_x, sample_y, lerp(local_min.z, local_max.z, 0.67)))
		return samples

	if role == "floor":
		var top_y := local_max.y + vertical_offset
		var inset_x: float = min(0.18, max(0.03, local_size.x * 0.25))
		var inset_z: float = min(0.18, max(0.03, local_size.z * 0.25))
		inset_x = min(inset_x, local_size.x * 0.45)
		inset_z = min(inset_z, local_size.z * 0.45)
		samples.append(mesh.global_transform * Vector3(local_center.x, top_y, local_center.z))
		samples.append(mesh.global_transform * Vector3(local_min.x + inset_x, top_y, local_min.z + inset_z))
		samples.append(mesh.global_transform * Vector3(local_max.x - inset_x, top_y, local_min.z + inset_z))
		samples.append(mesh.global_transform * Vector3(local_min.x + inset_x, top_y, local_max.z - inset_z))
		samples.append(mesh.global_transform * Vector3(local_max.x - inset_x, top_y, local_max.z - inset_z))
		return samples

	samples.append(mesh.global_transform * local_center + Vector3(0.0, vertical_offset, 0.0))
	if local_size.x >= local_size.z:
		samples.append(mesh.global_transform * Vector3(local_min.x, local_center.y, local_center.z) + Vector3(0.0, vertical_offset, 0.0))
		samples.append(mesh.global_transform * Vector3(local_max.x, local_center.y, local_center.z) + Vector3(0.0, vertical_offset, 0.0))
	else:
		samples.append(mesh.global_transform * Vector3(local_center.x, local_center.y, local_min.z) + Vector3(0.0, vertical_offset, 0.0))
		samples.append(mesh.global_transform * Vector3(local_center.x, local_center.y, local_max.z) + Vector3(0.0, vertical_offset, 0.0))
	return samples


func _wall_front_probe_samples(mesh: MeshInstance3D, vertical_offset: float, role: String = "") -> Array[Vector3]:
	var probes: Array[Vector3] = []
	var local_center := Vector3.ZERO
	var local_min := Vector3.ZERO
	var local_max := Vector3.ZERO
	if mesh.mesh:
		var bounds := mesh.mesh.get_aabb()
		local_center = bounds.get_center()
		local_min = bounds.position
		local_max = bounds.position + bounds.size

	var local_size := local_max - local_min
	var local_eye := mesh.global_transform.affine_inverse() * _player_eye
	var sample_y := local_center.y
	if role == "wall" or role == "wall_trim":
		sample_y = clamp(local_eye.y, local_min.y + 0.35, local_max.y - 0.18)
	var probe_offset := 0.26
	if local_size.x >= local_size.z:
		var face_z := local_min.z if local_eye.z < local_center.z else local_max.z
		var probe_z := face_z - probe_offset if local_eye.z < local_center.z else face_z + probe_offset
		probes.append(mesh.global_transform * Vector3(local_center.x, sample_y, probe_z))
		probes.append(mesh.global_transform * Vector3(local_min.x + 0.02, sample_y, probe_z))
		probes.append(mesh.global_transform * Vector3(local_max.x - 0.02, sample_y, probe_z))
		probes.append(mesh.global_transform * Vector3(lerp(local_min.x, local_max.x, 0.33), sample_y, probe_z))
		probes.append(mesh.global_transform * Vector3(lerp(local_min.x, local_max.x, 0.67), sample_y, probe_z))
	else:
		var face_x := local_min.x if local_eye.x < local_center.x else local_max.x
		var probe_x := face_x - probe_offset if local_eye.x < local_center.x else face_x + probe_offset
		probes.append(mesh.global_transform * Vector3(probe_x, sample_y, local_center.z))
		probes.append(mesh.global_transform * Vector3(probe_x, sample_y, local_min.z + 0.02))
		probes.append(mesh.global_transform * Vector3(probe_x, sample_y, local_max.z - 0.02))
		probes.append(mesh.global_transform * Vector3(probe_x, sample_y, lerp(local_min.z, local_max.z, 0.33)))
		probes.append(mesh.global_transform * Vector3(probe_x, sample_y, lerp(local_min.z, local_max.z, 0.67)))
	return probes


func _physical_visibility_at(position: Vector3, hit_tolerance: float = 0.02) -> float:
	if not _manager:
		return _distance_visibility(position)
	if _manager.has_method("has_line_of_sight") and not bool(_manager.call("has_line_of_sight", _player_eye, position, hit_tolerance)):
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


func _apply_original_tinted(mesh: MeshInstance3D, brightness: float, alpha: float, tint: Color, tint_amount: float) -> void:
	var base := _base_materials.get(mesh) as StandardMaterial3D
	var runtime := _runtime_materials.get(mesh) as StandardMaterial3D
	if not base or not runtime:
		return
	var color := base.albedo_color.lerp(tint, clamp(tint_amount, 0.0, 1.0))
	runtime.albedo_color = color.darkened(1.0 - clamp(brightness, 0.0, 1.0))
	runtime.albedo_color.a = alpha
	runtime.albedo_texture = base.albedo_texture
	runtime.uv1_scale = base.uv1_scale
	runtime.texture_repeat = base.texture_repeat
	runtime.roughness = base.roughness
	runtime.roughness_texture = base.roughness_texture
	runtime.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED if tint_amount > 0.55 else base.shading_mode
	runtime.emission_enabled = base.emission_enabled
	if base.emission_enabled:
		runtime.emission = base.emission.lerp(tint, clamp(tint_amount, 0.0, 1.0)).darkened(1.0 - clamp(brightness, 0.0, 1.0))
		runtime.emission_energy_multiplier = base.emission_energy_multiplier * alpha
	runtime.normal_enabled = base.normal_enabled
	runtime.normal_texture = base.normal_texture
	runtime.normal_scale = base.normal_scale
	runtime.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if alpha < 0.985 else BaseMaterial3D.TRANSPARENCY_DISABLED
	mesh.material_override = runtime


func _static_brightness_for_role(role: String, is_unseen_unknown: bool) -> float:
	if role == "floor":
		return 0.54 if is_unseen_unknown else 0.86
	if role == "baseboard":
		return 0.42 if is_unseen_unknown else 0.68
	return 0.58 if is_unseen_unknown else 0.84


func _static_tint_for_role(role: String, is_unseen_unknown: bool) -> Color:
	if role == "floor":
		return Color(0.44, 0.44, 0.39) if is_unseen_unknown else Color(0.64, 0.64, 0.58)
	if role == "baseboard":
		return Color(0.27, 0.27, 0.23) if is_unseen_unknown else Color(0.40, 0.40, 0.34)
	return Color(0.50, 0.51, 0.46) if is_unseen_unknown else Color(0.66, 0.66, 0.58)


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
