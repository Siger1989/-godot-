extends Node3D
class_name FogTestSection

enum VisibilityState { UNKNOWN, VISITED, PARTIAL_VISIBLE, VISIBLE }

@export var section_id := ""

var state := VisibilityState.UNKNOWN

var _original_materials: Dictionary = {}
var _original_light_energy: Dictionary = {}
var _visited_material: StandardMaterial3D
var _unknown_material: StandardMaterial3D
var _partial_material: StandardMaterial3D
var _mask_unknown_material: StandardMaterial3D
var _mask_partial_material: StandardMaterial3D


func _ready() -> void:
	add_to_group("fog_test_section")
	call_deferred("initialize")


func initialize() -> void:
	_build_state_materials()
	_capture_originals(self)
	_apply_state()


func apply_visibility(new_state: int) -> void:
	state = new_state
	_apply_state()


func _build_state_materials() -> void:
	if _visited_material:
		return
	_visited_material = _make_material(Color(0.30, 0.31, 0.30), 1.0, false)
	_unknown_material = _make_material(Color(0.045, 0.047, 0.044), 1.0, true)
	_partial_material = _make_material(Color(0.13, 0.13, 0.12), 1.0, true)
	_mask_unknown_material = _make_material(Color(0.0, 0.0, 0.0), 0.98, true)
	_mask_partial_material = _make_material(Color(0.01, 0.012, 0.012), 0.76, true)


func _make_material(color: Color, alpha: float, unshaded: bool) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	color.a = alpha
	material.albedo_color = color
	material.roughness = 1.0
	if alpha < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
	if unshaded:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material


func _capture_originals(node: Node) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			var mesh := child as MeshInstance3D
			if not _original_materials.has(mesh):
				_original_materials[mesh] = mesh.material_override
		elif child is Light3D:
			var light := child as Light3D
			if not _original_light_energy.has(light):
				_original_light_energy[light] = light.light_energy
		_capture_originals(child)


func _apply_state() -> void:
	_apply_node(self)


func _apply_node(node: Node) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			_apply_mesh(child as MeshInstance3D)
		elif child is Light3D:
			_apply_light(child as Light3D)
		elif child is Node3D:
			_apply_node_visibility(child as Node3D)
		_apply_node(child)


func _apply_node_visibility(node: Node3D) -> void:
	var role := String(node.get_meta("fog_role", "structure"))
	if role == "detail" or role == "dynamic":
		node.visible = state == VisibilityState.VISIBLE
	elif role == "unknown_mask":
		node.visible = state == VisibilityState.UNKNOWN or state == VisibilityState.PARTIAL_VISIBLE
	else:
		node.visible = true


func _apply_mesh(mesh: MeshInstance3D) -> void:
	var role := String(mesh.get_meta("fog_role", "structure"))

	if role == "unknown_mask":
		mesh.visible = state == VisibilityState.UNKNOWN or state == VisibilityState.PARTIAL_VISIBLE
		mesh.material_override = _mask_unknown_material if state == VisibilityState.UNKNOWN else _mask_partial_material
		return

	if role == "detail" or role == "dynamic":
		mesh.visible = state == VisibilityState.VISIBLE
		if mesh.visible:
			mesh.material_override = _original_materials.get(mesh)
		return

	match state:
		VisibilityState.VISIBLE:
			mesh.visible = true
			mesh.material_override = _original_materials.get(mesh)
		VisibilityState.VISITED:
			mesh.visible = role != "floor" or true
			mesh.material_override = _visited_material
		VisibilityState.PARTIAL_VISIBLE:
			mesh.visible = role != "detail"
			mesh.material_override = _partial_material
		VisibilityState.UNKNOWN:
			mesh.visible = role == "wall" or role == "ceiling" or role == "structure"
			mesh.material_override = _unknown_material


func _apply_light(light: Light3D) -> void:
	var original: float = float(_original_light_energy.get(light, light.light_energy))
	match state:
		VisibilityState.VISIBLE:
			light.visible = true
			light.light_energy = original
		VisibilityState.VISITED:
			light.visible = true
			light.light_energy = original * 0.24
		VisibilityState.PARTIAL_VISIBLE:
			light.visible = true
			light.light_energy = original * 0.06
		VisibilityState.UNKNOWN:
			light.visible = false
			light.light_energy = 0.0
