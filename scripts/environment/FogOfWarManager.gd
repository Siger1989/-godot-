extends Node3D
class_name FogOfWarManager

@export var cell_size := 3.0
@export var visible_radius := 8.5
@export var fade_radius := 17.0
@export var update_interval := 0.08
@export var unknown_alpha := 0.68
@export var visited_alpha := 0.30
@export var visible_edge_alpha := 0.42
@export var void_alpha := 0.76
@export var transition_speed := 8.0

var rooms: Array[Node] = []
var tiles: Array[Dictionary] = []
var detail_nodes: Array[Node3D] = []
var light_nodes: Array[Light3D] = []
var light_mesh_nodes: Array[Node3D] = []
var original_light_energy: Dictionary = {}
var tile_root: Node3D
var fog_shader: Shader
var update_timer := 0.0


func _ready() -> void:
	add_to_group("fog_of_war")
	call_deferred("_initialize_fog")


func _process(delta: float) -> void:
	if tiles.is_empty():
		return
	update_timer -= delta
	if update_timer <= 0.0:
		update_timer = update_interval
		_update_targets()
	_update_tile_alpha(delta)
	_update_detail_visibility()
	_update_light_visibility()


func _initialize_fog() -> void:
	rooms.clear()
	for room in get_tree().get_nodes_in_group("room_volume"):
		if room is Node and (room as Node).has_method("contains_world_point"):
			rooms.append(room as Node)

	for section in get_tree().get_nodes_in_group("level_section"):
		if section is Node and (section as Node).has_method("apply_visibility"):
			(section as Node).call("apply_visibility", 2)

	detail_nodes.clear()
	for detail in get_tree().get_nodes_in_group("fog_detail"):
		if detail is Node3D:
			detail_nodes.append(detail as Node3D)

	light_nodes.clear()
	original_light_energy.clear()
	for light in get_tree().get_nodes_in_group("fluorescent_light"):
		if light is Light3D:
			light_nodes.append(light as Light3D)
			original_light_energy[light] = (light as Light3D).light_energy

	light_mesh_nodes.clear()
	for light_mesh in get_tree().get_nodes_in_group("fog_light"):
		if light_mesh is Node3D:
			light_mesh_nodes.append(light_mesh as Node3D)

	_build_shader()
	_build_tiles()
	_update_targets()
	_update_tile_alpha(1.0)


func _build_shader() -> void:
	fog_shader = Shader.new()
	fog_shader.code = """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;
uniform vec4 fog_color : source_color = vec4(0.130, 0.126, 0.092, 1.0);
uniform float alpha = 0.8;
uniform float noise_seed = 0.0;
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}
void fragment() {
	float n = noise(UV * 6.0 + vec2(noise_seed, noise_seed * 0.37));
	float soft_edge = smoothstep(0.0, 0.34, UV.x) * smoothstep(0.0, 0.34, UV.y);
	soft_edge *= (1.0 - smoothstep(0.66, 1.0, UV.x)) * (1.0 - smoothstep(0.66, 1.0, UV.y));
	ALBEDO = fog_color.rgb;
	ALPHA = alpha * mix(0.72, 1.0, n) * soft_edge;
}
"""


func _build_tiles() -> void:
	if tile_root:
		tile_root.queue_free()
	tile_root = Node3D.new()
	tile_root.name = "LineOfSightFogTiles"
	add_child(tile_root)
	tiles.clear()

	var bounds := _get_playable_bounds()
	if bounds.size == Vector2.ZERO:
		return
	var x_start: int = int(floor(bounds.position.x / cell_size)) - 2
	var x_end: int = int(ceil((bounds.position.x + bounds.size.x) / cell_size)) + 2
	var z_start: int = int(floor(bounds.position.y / cell_size)) - 2
	var z_end: int = int(ceil((bounds.position.y + bounds.size.y) / cell_size)) + 2

	for xi in range(x_start, x_end):
		for zi in range(z_start, z_end):
			var center := Vector3((float(xi) + 0.5) * cell_size, 2.86, (float(zi) + 0.5) * cell_size)
			var in_room := _point_in_any_room(center)
			var mesh_instance := MeshInstance3D.new()
			mesh_instance.name = "FogTile"
			mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var plane := PlaneMesh.new()
			plane.size = Vector2(cell_size * 2.05, cell_size * 2.05)
			mesh_instance.mesh = plane
			mesh_instance.position = center
			var material := ShaderMaterial.new()
			material.shader = fog_shader
			material.render_priority = 2
			material.set_shader_parameter("alpha", unknown_alpha if in_room else void_alpha)
			material.set_shader_parameter("noise_seed", randf() * 50.0)
			mesh_instance.material_override = material
			tile_root.add_child(mesh_instance)
			tiles.append({
				"node": mesh_instance,
				"material": material,
				"center": center,
				"alpha": unknown_alpha if in_room else void_alpha,
				"target_alpha": unknown_alpha if in_room else void_alpha,
				"in_room": in_room,
				"visited": false
			})


func _get_playable_bounds() -> Rect2:
	var has_bounds := false
	var min_x := 0.0
	var max_x := 0.0
	var min_z := 0.0
	var max_z := 0.0
	for room in rooms:
		var rect: Rect2 = room.get("bounds")
		if rect.size == Vector2.ZERO:
			continue
		if not has_bounds:
			min_x = rect.position.x
			max_x = rect.position.x + rect.size.x
			min_z = rect.position.y
			max_z = rect.position.y + rect.size.y
			has_bounds = true
		else:
			min_x = min(min_x, rect.position.x)
			max_x = max(max_x, rect.position.x + rect.size.x)
			min_z = min(min_z, rect.position.y)
			max_z = max(max_z, rect.position.y + rect.size.y)
	if not has_bounds:
		return Rect2()
	return Rect2(Vector2(min_x, min_z), Vector2(max_x - min_x, max_z - min_z))


func _point_in_any_room(point: Vector3) -> bool:
	for room in rooms:
		if bool(room.call("contains_world_point", point)):
			return true
	return false


func _update_targets() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if not player:
		return
	var origin := player.global_position + Vector3(0.0, 1.15, 0.0)
	for i in tiles.size():
		var tile := tiles[i]
		var center: Vector3 = tile["center"]
		if not bool(tile["in_room"]):
			tile["target_alpha"] = void_alpha
			tiles[i] = tile
			continue
		var distance := Vector2(origin.x, origin.z).distance_to(Vector2(center.x, center.z))
		var los_target := Vector3(center.x, origin.y, center.z)
		var has_los := distance <= fade_radius and _has_line_of_sight(origin, los_target)
		var target := unknown_alpha
		if has_los:
			var clear_radius := visible_radius * 0.48
			var t: float = clamp((distance - clear_radius) / max(visible_radius - clear_radius, 0.01), 0.0, 1.0)
			var falloff: float = smoothstep(0.0, 1.0, t)
			target = lerp(0.0, visible_edge_alpha, falloff)
			if distance > visible_radius:
				var fade_t: float = clamp((distance - visible_radius) / max(fade_radius - visible_radius, 0.01), 0.0, 1.0)
				target = lerp(visible_edge_alpha, unknown_alpha, fade_t)
			if distance <= fade_radius:
				tile["visited"] = true
		elif bool(tile["visited"]):
			target = visited_alpha
		tile["target_alpha"] = target
		tiles[i] = tile


func _update_tile_alpha(delta: float) -> void:
	var blend := 1.0 - exp(-transition_speed * delta)
	for i in tiles.size():
		var tile := tiles[i]
		var alpha: float = lerp(float(tile["alpha"]), float(tile["target_alpha"]), blend)
		tile["alpha"] = alpha
		var material := tile["material"] as ShaderMaterial
		if material:
			material.set_shader_parameter("alpha", alpha)
		var node := tile["node"] as MeshInstance3D
		if node:
			node.visible = alpha > 0.03
		tiles[i] = tile


func _update_detail_visibility() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if not player:
		return
	var origin := player.global_position + Vector3(0.0, 1.15, 0.0)
	for node in detail_nodes:
		if not is_instance_valid(node):
			continue
		node.visible = _visibility_factor_for_point(origin, node.global_position + Vector3(0.0, 0.8, 0.0)) > 0.55


func _update_light_visibility() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if not player:
		return
	var origin := player.global_position + Vector3(0.0, 1.15, 0.0)
	for light in light_nodes:
		if not is_instance_valid(light):
			continue
		var factor := _visibility_factor_for_point(origin, light.global_position)
		light.visible = factor > 0.08
		light.light_energy = float(original_light_energy.get(light, light.light_energy)) * factor
	for light_mesh in light_mesh_nodes:
		if not is_instance_valid(light_mesh):
			continue
		light_mesh.visible = _visibility_factor_for_point(origin, light_mesh.global_position + Vector3(0.0, -0.6, 0.0)) > 0.18


func _visibility_factor_for_point(origin: Vector3, point: Vector3) -> float:
	var distance := Vector2(origin.x, origin.z).distance_to(Vector2(point.x, point.z))
	if distance > fade_radius:
		return 0.0
	var los_target := Vector3(point.x, origin.y, point.z)
	if not _has_line_of_sight(origin, los_target):
		return 0.0
	var clear_radius := visible_radius * 0.48
	if distance <= clear_radius:
		return 1.0
	if distance <= visible_radius:
		var t: float = clamp((distance - clear_radius) / max(visible_radius - clear_radius, 0.01), 0.0, 1.0)
		return lerp(1.0, 0.45, smoothstep(0.0, 1.0, t))
	var fade_t: float = clamp((distance - visible_radius) / max(fade_radius - visible_radius, 0.01), 0.0, 1.0)
	return lerp(0.45, 0.0, smoothstep(0.0, 1.0, fade_t))


func _has_line_of_sight(origin: Vector3, target: Vector3) -> bool:
	var space := get_world_3d().direct_space_state
	var params := PhysicsRayQueryParameters3D.create(origin, target)
	var player := get_tree().get_first_node_in_group("player") as CollisionObject3D
	if player:
		params.exclude = [player.get_rid()]
	params.hit_from_inside = false
	var hit := space.intersect_ray(params)
	if hit.is_empty():
		return true
	var collider := hit.get("collider") as Node
	if not collider:
		return true
	if collider.is_in_group("camera_fade_wall"):
		return false
	return collider.name.contains("DoorPanel") == false and collider.name.contains("Frame") == false
