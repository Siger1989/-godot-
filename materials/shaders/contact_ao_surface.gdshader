shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D albedo_texture : source_color, repeat_enable;
uniform sampler2D normal_texture : hint_normal, repeat_enable;
uniform sampler2D random_grime_texture : source_color, repeat_disable;
uniform bool use_texture = true;
uniform bool use_normal = true;
uniform bool use_random_grime = false;
uniform vec2 uv_scale = vec2(1.0, 1.0);
uniform vec2 uv_offset = vec2(0.0, 0.0);
uniform vec4 albedo_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec3 contact_color : source_color = vec3(0.44, 0.36, 0.20);
uniform float roughness_value = 0.85;
uniform float normal_depth = 0.2;
uniform int surface_mode = 0;
uniform vec2 random_grime_atlas_grid = vec2(4.0, 4.0);
uniform float random_grime_seed = 1.0;
uniform float random_grime_strength = 0.48;
uniform float random_grime_density = 0.72;
uniform float random_grime_top_weight = 1.0;
uniform float random_grime_bottom_weight = 1.0;
uniform float random_grime_top_band = 0.28;
uniform float random_grime_bottom_band = 0.28;
uniform bool random_grime_rotation_enabled = false;
uniform float random_grime_rotation_degrees = 0.0;
uniform float random_grime_size_x_scale = 1.0;
uniform float random_grime_size_y_scale = 1.0;
uniform float random_grime_top_offset = 0.0;
uniform float random_grime_bottom_offset = 0.0;

uniform float floor_y = 0.0;
uniform float ceiling_y = 2.55;
uniform float base_height = 0.16;
uniform float ceiling_height = 0.12;
uniform float grid_band = 0.26;
uniform float door_edge_width = 0.055;

uniform float floor_contact_strength = 0.12;
uniform float ceiling_contact_strength = 0.08;
uniform float corner_contact_strength = 0.10;
uniform float door_edge_strength = 0.08;
uniform float max_shadow = 0.22;

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float grid_distance(float value) {
	float d0 = abs(value + 3.0);
	float d1 = abs(value - 3.0);
	float d2 = abs(value - 9.0);
	return min(d0, min(d1, d2));
}

float proximity(float distance_value, float width) {
	return 1.0 - smoothstep(0.0, width, distance_value);
}

float hash11(float value) {
	return fract(sin(value * 91.3458) * 47453.5453);
}

vec4 sample_grime_tile(vec2 local_uv, float tile_index) {
	vec2 grid = max(random_grime_atlas_grid, vec2(1.0));
	float tile_count = max(1.0, grid.x * grid.y);
	float tile = mod(floor(tile_index), tile_count);
	vec2 cell = vec2(mod(tile, grid.x), floor(tile / grid.x));
	vec2 atlas_uv = (cell + clamp(local_uv, vec2(0.001), vec2(0.999))) / grid;
	return texture(random_grime_texture, atlas_uv);
}

vec2 rotate_grime_uv(vec2 local_uv, float angle) {
	float sine_value = sin(angle);
	float cosine_value = cos(angle);
	vec2 centered = local_uv - vec2(0.5);
	return vec2(
		centered.x * cosine_value - centered.y * sine_value,
		centered.x * sine_value + centered.y * cosine_value
	) + vec2(0.5);
}

vec4 random_wall_grime(vec2 wall_uv) {
	vec4 result = vec4(0.0);
	float wall_u = wall_uv.x;
	float wall_v = clamp(wall_uv.y, 0.0, 1.0);
	float top_weight = max(random_grime_top_weight, 0.0);
	float bottom_weight = max(random_grime_bottom_weight, 0.0);
	float total_weight = top_weight + bottom_weight;
	if (total_weight <= 0.0001) {
		return result;
	}
	float top_probability = top_weight / total_weight;
	float top_band_max = clamp(random_grime_top_band, 0.06, 0.48);
	float bottom_band_min = 1.0 - clamp(random_grime_bottom_band, 0.06, 0.48);
	for (int i = 0; i < 8; i++) {
		float index = float(i);
		float seed = random_grime_seed + index * 17.731;
		float active = step(hash11(seed + 3.17), random_grime_density);
		float top_band = 1.0 - step(top_probability, hash11(seed + 9.43));
		float center_x = hash11(seed + 15.91);
		float size_x = min(mix(0.16, 0.52, hash11(seed + 31.77)) * clamp(random_grime_size_x_scale, 0.05, 4.0), 0.95);
		float band_limit = mix(1.0 - bottom_band_min, top_band_max, top_band);
		float size_y = min(mix(0.06, 0.22, hash11(seed + 43.23)) * clamp(random_grime_size_y_scale, 0.05, 4.0), max(0.025, band_limit * 0.72));
		float edge_offset = size_y * mix(0.02, 0.28, hash11(seed + 22.61));
		float center_y = mix(1.0 - edge_offset, edge_offset, top_band);
		float configured_y_offset = mix(random_grime_bottom_offset, random_grime_top_offset, top_band);
		float edge_shift_limit = mix(clamp(random_grime_bottom_band, 0.06, 0.48), clamp(random_grime_top_band, 0.06, 0.48), top_band);
		center_y += clamp(configured_y_offset, -1.0, 1.0) * edge_shift_limit;
		float repeat_u = fract(wall_u + hash11(seed + 55.83));
		float dx = abs(repeat_u - center_x);
		dx = min(dx, 1.0 - dx);
		float dy = abs(wall_v - center_y);
		float shape = smoothstep(1.0, 0.0, max(dx / max(size_x, 0.001), dy / max(size_y, 0.001)));
		vec2 local_uv = vec2(0.5 + (repeat_u - center_x) / max(size_x, 0.001) * 0.5, 0.5 + (wall_v - center_y) / max(size_y, 0.001) * 0.5);
		float horizontal_edge = smoothstep(0.0, 0.18, local_uv.x) * (1.0 - smoothstep(0.82, 1.0, local_uv.x));
		vec2 sample_uv = local_uv;
		if (random_grime_rotation_enabled) {
			float max_angle = radians(clamp(random_grime_rotation_degrees, 0.0, 180.0));
			float angle = mix(-max_angle, max_angle, hash11(seed + 88.41));
			sample_uv = rotate_grime_uv(local_uv, angle);
		}
		vec4 grime = sample_grime_tile(sample_uv, hash11(seed + 71.19) * random_grime_atlas_grid.x * random_grime_atlas_grid.y);
		float alpha = grime.a * shape * horizontal_edge * active;
		if (alpha > result.a) {
			result = vec4(grime.rgb, alpha);
		}
	}
	return result;
}

void fragment() {
	vec2 sample_uv = UV * uv_scale + uv_offset;
	vec4 tex_color = vec4(1.0);
	if (use_texture) {
		tex_color = texture(albedo_texture, sample_uv);
	}

	vec3 base_color = tex_color.rgb * albedo_tint.rgb;
	if (use_random_grime && surface_mode == 0) {
		vec4 grime = random_wall_grime(sample_uv);
		vec3 darkened = min(base_color, base_color * grime.rgb);
		base_color = mix(base_color, darkened, clamp(grime.a * random_grime_strength, 0.0, 1.0));
	}

	float floor_contact = proximity(max(world_position.y - floor_y, 0.0), base_height);
	float ceiling_contact = proximity(abs(ceiling_y - world_position.y), ceiling_height);
	float x_line = proximity(grid_distance(world_position.x), grid_band);
	float z_line = proximity(grid_distance(world_position.z), grid_band);
	float corner_contact = x_line * z_line;
	float boundary_contact = max(x_line, z_line);

	float shadow = 0.0;
	if (surface_mode == 0) {
		shadow += floor_contact * floor_contact_strength;
		shadow += ceiling_contact * ceiling_contact_strength;
		shadow += corner_contact * corner_contact_strength;
	} else if (surface_mode == 1) {
		shadow += boundary_contact * floor_contact_strength * 0.45;
		shadow += corner_contact * corner_contact_strength * 0.85;
	} else if (surface_mode == 2) {
		shadow += boundary_contact * ceiling_contact_strength * 0.70;
		shadow += corner_contact * corner_contact_strength;
	} else if (surface_mode == 3) {
		float uv_edge = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y));
		shadow += proximity(uv_edge, door_edge_width) * door_edge_strength;
		shadow += floor_contact * floor_contact_strength * 0.65;
		shadow += ceiling_contact * ceiling_contact_strength * 0.55;
	}

	shadow = clamp(shadow, 0.0, max_shadow);
	ALBEDO = mix(base_color, contact_color, shadow);
	ROUGHNESS = roughness_value;

	if (use_normal) {
		NORMAL_MAP = texture(normal_texture, sample_uv).rgb;
		NORMAL_MAP_DEPTH = normal_depth;
	}
}
