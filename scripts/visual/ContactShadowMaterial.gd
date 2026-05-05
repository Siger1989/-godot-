extends RefCounted

const ContactShader := preload("res://materials/shaders/contact_ao_surface.gdshader")
const RuntimeWallGrimeAtlas := preload("res://materials/textures/backrooms_wall_runtime_grime_atlas.png")
const RuntimeWallGrimeConfigPath := "res://materials/textures/backrooms_wall_runtime_grime_config.json"

static func make_wall(base: Material) -> ShaderMaterial:
	return _make_material(base, 0, 0.13, 0.08, 0.10, 0.00, 0.24)

static func make_wall_instance(base: Material, grime_seed: float) -> ShaderMaterial:
	var material := make_wall(base)
	apply_random_wall_grime(material, grime_seed)
	return material

static func make_floor(base: Material) -> ShaderMaterial:
	return _make_material(base, 1, 0.08, 0.00, 0.08, 0.00, 0.16)

static func make_ceiling(base: Material) -> ShaderMaterial:
	return _make_material(base, 2, 0.00, 0.08, 0.08, 0.00, 0.16)

static func make_door_frame(base: Material) -> ShaderMaterial:
	return _make_material(base, 3, 0.08, 0.06, 0.00, 0.09, 0.19)

static func is_contact_material(material: Material) -> bool:
	var shader_material := material as ShaderMaterial
	return shader_material != null and shader_material.shader == ContactShader

static func apply_random_wall_grime(material: ShaderMaterial, grime_seed: float) -> void:
	if material == null or material.shader != ContactShader:
		return
	var config := _runtime_wall_grime_config()
	material.set_shader_parameter("use_random_grime", true)
	material.set_shader_parameter("random_grime_texture", RuntimeWallGrimeAtlas)
	material.set_shader_parameter("random_grime_atlas_grid", Vector2(4.0, 4.0))
	material.set_shader_parameter("random_grime_seed", grime_seed)
	material.set_shader_parameter("random_grime_strength", float(config.get("strength", 0.50)))
	material.set_shader_parameter("random_grime_density", float(config.get("density", 0.72)))
	material.set_shader_parameter("random_grime_top_weight", float(config.get("top_weight", 1.0)))
	material.set_shader_parameter("random_grime_bottom_weight", float(config.get("bottom_weight", 1.0)))
	material.set_shader_parameter("random_grime_top_band", float(config.get("top_band", 0.28)))
	material.set_shader_parameter("random_grime_bottom_band", float(config.get("bottom_band", 0.28)))
	material.set_shader_parameter("random_grime_rotation_enabled", bool(config.get("random_rotation", false)))
	material.set_shader_parameter("random_grime_rotation_degrees", float(config.get("rotation_degrees", 0.0)))
	material.set_shader_parameter("random_grime_size_x_scale", float(config.get("size_x_scale", 1.0)))
	material.set_shader_parameter("random_grime_size_y_scale", float(config.get("size_y_scale", 1.0)))
	material.set_shader_parameter("random_grime_top_offset", float(config.get("top_offset", 0.0)))
	material.set_shader_parameter("random_grime_bottom_offset", float(config.get("bottom_offset", 0.0)))

static func _runtime_wall_grime_config() -> Dictionary:
	if not FileAccess.file_exists(RuntimeWallGrimeConfigPath):
		return {}
	var file := FileAccess.open(RuntimeWallGrimeConfigPath, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed

static func apply_runtime_tuning(material: ShaderMaterial, multiplier: float, max_shadow_value: float) -> void:
	if material == null or material.shader != ContactShader:
		return
	var safe_multiplier := clampf(multiplier, 0.0, 3.0)
	material.set_shader_parameter("floor_contact_strength", float(material.get_meta("base_floor_contact_strength", 0.0)) * safe_multiplier)
	material.set_shader_parameter("ceiling_contact_strength", float(material.get_meta("base_ceiling_contact_strength", 0.0)) * safe_multiplier)
	material.set_shader_parameter("corner_contact_strength", float(material.get_meta("base_corner_contact_strength", 0.0)) * safe_multiplier)
	material.set_shader_parameter("door_edge_strength", float(material.get_meta("base_door_edge_strength", 0.0)) * safe_multiplier)
	material.set_shader_parameter("max_shadow", clampf(max_shadow_value, 0.0, 0.5))

static func _make_material(
	base: Material,
	surface_mode: int,
	floor_strength: float,
	ceiling_strength: float,
	corner_strength: float,
	door_edge_strength: float,
	max_shadow_value: float
) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = ContactShader
	material.resource_local_to_scene = true
	material.set_meta("contact_shadow_material", true)
	material.set_meta("base_floor_contact_strength", floor_strength)
	material.set_meta("base_ceiling_contact_strength", ceiling_strength)
	material.set_meta("base_corner_contact_strength", corner_strength)
	material.set_meta("base_door_edge_strength", door_edge_strength)
	material.set_meta("base_max_shadow", max_shadow_value)
	material.set_shader_parameter("surface_mode", surface_mode)
	material.set_shader_parameter("floor_contact_strength", floor_strength)
	material.set_shader_parameter("ceiling_contact_strength", ceiling_strength)
	material.set_shader_parameter("corner_contact_strength", corner_strength)
	material.set_shader_parameter("door_edge_strength", door_edge_strength)
	material.set_shader_parameter("max_shadow", max_shadow_value)

	var standard := base as StandardMaterial3D
	if standard == null:
		material.set_shader_parameter("use_texture", false)
		material.set_shader_parameter("use_normal", false)
		material.set_shader_parameter("albedo_tint", Color(1.0, 1.0, 1.0, 1.0))
		material.set_shader_parameter("uv_scale", Vector2.ONE)
		material.set_shader_parameter("uv_offset", Vector2.ZERO)
		material.set_shader_parameter("roughness_value", 0.85)
		material.set_shader_parameter("normal_depth", 0.0)
		return material

	material.set_shader_parameter("albedo_tint", standard.albedo_color)
	material.set_shader_parameter("roughness_value", standard.roughness)
	material.set_shader_parameter("uv_scale", Vector2(standard.uv1_scale.x, standard.uv1_scale.y))
	material.set_shader_parameter("uv_offset", Vector2(standard.uv1_offset.x, standard.uv1_offset.y))
	if standard.albedo_texture != null:
		material.set_shader_parameter("use_texture", true)
		material.set_shader_parameter("albedo_texture", standard.albedo_texture)
	else:
		material.set_shader_parameter("use_texture", false)
	if standard.normal_enabled and standard.normal_texture != null:
		material.set_shader_parameter("use_normal", true)
		material.set_shader_parameter("normal_texture", standard.normal_texture)
		material.set_shader_parameter("normal_depth", standard.normal_scale)
	else:
		material.set_shader_parameter("use_normal", false)
		material.set_shader_parameter("normal_depth", 0.0)
	return material
