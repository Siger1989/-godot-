shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_back, diffuse_lambert_wrap, specular_schlick_ggx;

uniform vec4 albedo_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D albedo_texture : source_color, repeat_enable;
uniform bool use_albedo_texture = false;
uniform sampler2D normal_texture : hint_normal, repeat_enable;
uniform bool use_normal_texture = false;
uniform float roughness_value : hint_range(0.0, 1.0) = 0.85;
uniform float normal_strength : hint_range(0.0, 2.0) = 1.0;
uniform vec2 uv_scale = vec2(1.0, 1.0);
uniform vec2 uv_offset = vec2(0.0, 0.0);

uniform vec3 cutout_center_world = vec3(0.0, 1.0, 0.0);
uniform vec3 cutout_axis_u_world = vec3(1.0, 0.0, 0.0);
uniform vec3 cutout_axis_v_world = vec3(0.0, 1.0, 0.0);
uniform float cutout_radius_u = 0.75;
uniform float cutout_radius_v = 1.1;
uniform float cutout_feather = 0.35;
uniform float cutout_strength : hint_range(0.0, 1.0) = 1.0;

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 scaled_uv = UV * uv_scale + uv_offset;
	vec4 base_color = albedo_color;
	if (use_albedo_texture) {
		base_color *= texture(albedo_texture, scaled_uv);
	}

	vec3 delta = world_position - cutout_center_world;
	float u = dot(delta, normalize(cutout_axis_u_world)) / max(cutout_radius_u, 0.001);
	float v = dot(delta, normalize(cutout_axis_v_world)) / max(cutout_radius_v, 0.001);
	float distance_from_center = sqrt(u * u + v * v);
	float feather_width = clamp(cutout_feather, 0.001, 0.95);
	float keep_alpha = smoothstep(1.0 - feather_width, 1.0, distance_from_center);

	ALBEDO = base_color.rgb;
	ROUGHNESS = roughness_value;
	ALPHA = base_color.a * mix(1.0, keep_alpha, cutout_strength);

	if (use_normal_texture) {
		NORMAL_MAP = texture(normal_texture, scaled_uv).rgb;
		NORMAL_MAP_DEPTH = normal_strength;
	}
}
