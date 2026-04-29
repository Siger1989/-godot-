extends Node3D
class_name RoomPrototypeSection

enum VisibilityState { UNKNOWN, VISITED, PARTIAL_VISIBLE, VISIBLE }

@export var section_id := ""

var state: int = VisibilityState.UNKNOWN
var partial_source := ""
var _meshes: Array[MeshInstance3D] = []
var _lights: Array[Light3D] = []
var _base_materials: Dictionary = {}
var _base_light_energy: Dictionary = {}
var _visited_material: StandardMaterial3D
var _unknown_material: StandardMaterial3D
var _partial_material: StandardMaterial3D


func _ready() -> void:
	add_to_group("room_prototype_section")
	call_deferred("initialize")


func initialize() -> void:
	_build_state_materials()
	_capture_tree(self)
	_apply_without_distance()


func update_visibility(new_state: int, origin: Vector3, manager: Node, clear_radius: float, dim_radius: float, black_radius: float, source_room := "") -> void:
	state = new_state
	partial_source = source_room
	_apply_tree(self, origin, manager, clear_radius, dim_radius, black_radius)


func get_state_name() -> String:
	match state:
		VisibilityState.VISIBLE:
			return "VISIBLE"
		VisibilityState.PARTIAL_VISIBLE:
			return "PARTIAL_VISIBLE"
		VisibilityState.VISITED:
			return "VISITED"
	return "UNKNOWN"


func _build_state_materials() -> void:
	if _visited_material:
		return
	_visited_material = _make_material(Color(0.28, 0.29, 0.28), false)
	_unknown_material = _make_material(Color(0.055, 0.055, 0.050), true)
	_partial_material = _make_material(Color(0.20, 0.20, 0.17), true)


func _make_material(color: Color, unshaded: bool) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	if unshaded:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material


func _capture_tree(node: Node) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			var mesh := child as MeshInstance3D
			if not _meshes.has(mesh):
				_meshes.append(mesh)
			if not _base_materials.has(mesh):
				var material := mesh.material_override
				if material:
					material = material.duplicate()
					mesh.material_override = material
				_base_materials[mesh] = material
		elif child is Light3D:
			var light := child as Light3D
			if not _lights.has(light):
				_lights.append(light)
			if not _base_light_energy.has(light):
				_base_light_energy[light] = light.light_energy
		_capture_tree(child)


func _apply_without_distance() -> void:
	_apply_tree(self, Vector3.ZERO, null, 8.0, 14.0, 20.0)


func _apply_tree(node: Node, origin: Vector3, manager: Node, clear_radius: float, dim_radius: float, black_radius: float) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			_apply_mesh(child as MeshInstance3D, origin, manager, clear_radius, dim_radius, black_radius)
		elif child is Light3D:
			_apply_light(child as Light3D)
		elif child is Node3D:
			_apply_node_visibility(child as Node3D)
		_apply_tree(child, origin, manager, clear_radius, dim_radius, black_radius)


func _apply_node_visibility(node: Node3D) -> void:
	var role := String(node.get_meta("fog_role", "structure"))
	if role == "detail" or role == "dynamic":
		node.visible = state == VisibilityState.VISIBLE
	elif role == "partial_reveal":
		node.visible = _partial_reveal_matches(node)
	else:
		node.visible = _structure_visible_for_state(role)


func _apply_mesh(mesh: MeshInstance3D, origin: Vector3, manager: Node, clear_radius: float, dim_radius: float, black_radius: float) -> void:
	var role := String(mesh.get_meta("fog_role", "structure"))
	if role == "partial_reveal":
		mesh.visible = _partial_reveal_matches(mesh)
		if mesh.visible:
			_apply_darkened_original(mesh, 0.48)
		return

	if role == "detail" or role == "dynamic":
		mesh.visible = state == VisibilityState.VISIBLE
		if mesh.visible:
			_apply_darkened_original(mesh, _distance_brightness(mesh.global_position, origin, manager, clear_radius, dim_radius, black_radius))
		return

	if not _structure_visible_for_state(role):
		mesh.visible = false
		return

	mesh.visible = true
	match state:
		VisibilityState.VISIBLE:
			if role == "floor":
				_apply_darkened_original(mesh, 1.0)
				return
			var brightness := _distance_brightness(mesh.global_position, origin, manager, clear_radius, dim_radius, black_radius)
			if role == "wall" or role == "baseboard" or role == "ceiling" or role == "light_mesh":
				brightness = max(brightness, 0.34)
			_apply_darkened_original(mesh, brightness)
		VisibilityState.VISITED:
			mesh.material_override = _visited_material
		VisibilityState.PARTIAL_VISIBLE:
			mesh.visible = false
		VisibilityState.UNKNOWN:
			if role == "wall" or role == "outline":
				mesh.material_override = _unknown_material
			else:
				mesh.visible = false


func _structure_visible_for_state(role: String) -> bool:
	match state:
		VisibilityState.VISIBLE:
			return role != "partial_reveal"
		VisibilityState.VISITED:
			return role == "wall" or role == "floor" or role == "ceiling" or role == "baseboard" or role == "outline"
		VisibilityState.PARTIAL_VISIBLE:
			return role == "partial_reveal"
		VisibilityState.UNKNOWN:
			return role == "wall" or role == "outline"
	return false


func _partial_reveal_matches(node: Node) -> bool:
	if state != VisibilityState.PARTIAL_VISIBLE:
		return false
	var source := String(node.get_meta("partial_from", ""))
	return source.is_empty() or source == partial_source


func _apply_light(light: Light3D) -> void:
	var original: float = float(_base_light_energy.get(light, light.light_energy))
	match state:
		VisibilityState.VISIBLE:
			light.visible = true
			light.light_energy = original
		VisibilityState.VISITED:
			light.visible = false
			light.light_energy = 0.0
		_:
			light.visible = false
			light.light_energy = 0.0


func _distance_brightness(position: Vector3, origin: Vector3, manager: Node, clear_radius: float, dim_radius: float, black_radius: float) -> float:
	if not manager:
		return 1.0
	var target := Vector3(position.x, origin.y, position.z)
	if manager.has_method("has_line_of_sight") and not bool(manager.call("has_line_of_sight", origin, target)):
		return 0.04
	var distance := Vector2(origin.x, origin.z).distance_to(Vector2(position.x, position.z))
	if distance <= clear_radius:
		return 1.0
	if distance <= dim_radius:
		var t: float = clamp((distance - clear_radius) / max(dim_radius - clear_radius, 0.01), 0.0, 1.0)
		return lerp(1.0, 0.56, smoothstep(0.0, 1.0, t))
	if distance <= black_radius:
		var t: float = clamp((distance - dim_radius) / max(black_radius - dim_radius, 0.01), 0.0, 1.0)
		return lerp(0.56, 0.10, smoothstep(0.0, 1.0, t))
	return 0.04


func _apply_darkened_original(mesh: MeshInstance3D, brightness: float) -> void:
	var material := _base_materials.get(mesh) as Material
	if not material:
		return
	var duplicate := material.duplicate()
	if duplicate is StandardMaterial3D:
		var standard := duplicate as StandardMaterial3D
		standard.albedo_color = standard.albedo_color.darkened(1.0 - brightness)
		if standard.emission_enabled:
			standard.emission_energy_multiplier *= brightness
	mesh.material_override = duplicate
