shader_type spatial;
render_mode unshaded, cull_back;

uniform float debug_tiles = 6.0;
uniform vec3 base_color = vec3(0.14, 0.13, 0.11);
uniform vec3 grid_color = vec3(0.03, 0.03, 0.03);
uniform vec3 u_color = vec3(1.0, 0.08, 0.04);
uniform vec3 v_color = vec3(0.08, 0.95, 0.18);

float band(float value, float center, float width) {
	return 1.0 - step(width, abs(value - center));
}

void fragment() {
	vec2 tiled_uv = UV * debug_tiles;
	vec2 cell = fract(tiled_uv);
	vec3 color = mix(base_color, vec3(cell.x, cell.y, 0.18), 0.65);

	float grid = max(
		max(1.0 - step(0.035, cell.x), step(0.965, cell.x)),
		max(1.0 - step(0.035, cell.y), step(0.965, cell.y))
	);
	color = mix(color, grid_color, grid);

	float u_shaft = band(cell.y, 0.28, 0.035) * step(0.16, cell.x) * (1.0 - step(0.72, cell.x));
	float u_head = step(0.68, cell.x) * (1.0 - step(0.88, cell.x)) * (1.0 - step((0.88 - cell.x) * 0.75, abs(cell.y - 0.28)));
	float v_shaft = band(cell.x, 0.28, 0.035) * step(0.16, cell.y) * (1.0 - step(0.72, cell.y));
	float v_head = step(0.68, cell.y) * (1.0 - step(0.88, cell.y)) * (1.0 - step((0.88 - cell.y) * 0.75, abs(cell.x - 0.28)));

	color = mix(color, u_color, clamp(u_shaft + u_head, 0.0, 1.0));
	color = mix(color, v_color, clamp(v_shaft + v_head, 0.0, 1.0));

	ALBEDO = color;
	EMISSION = color * 0.25;
	ROUGHNESS = 1.0;
}
