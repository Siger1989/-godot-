extends Node

@export var enabled := true
@export var startup_delay_min := 18.0
@export var startup_delay_max := 45.0
@export var flicker_interval_min := 28.0
@export var flicker_interval_max := 70.0
@export var flicker_chance_per_second := 0.018
@export var flicker_step_min := 0.045
@export var flicker_step_max := 0.13
@export var flicker_steps_min := 4
@export var flicker_steps_max := 8
@export var dim_energy_min := 0.08
@export var dim_energy_max := 0.34
@export var bright_energy_min := 1.25
@export var bright_energy_max := 1.85

var light_components: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _lights: Array[Dictionary] = []
var _global_cooldown := 0.0

func register_light_component(light_id: StringName, node: Node) -> void:
	light_components[light_id] = node

func _ready() -> void:
	_rng.randomize()
	_global_cooldown = _rng.randf_range(startup_delay_min, startup_delay_max)
	call_deferred("_collect_lights")

func _process(delta: float) -> void:
	if not enabled:
		_restore_all_lights()
		return
	if _lights.is_empty():
		_collect_lights()
		return

	if _has_active_flicker():
		for light_data in _lights:
			if bool(light_data["active"]):
				_update_active_flicker(light_data, delta)
		return

	_global_cooldown = maxf(_global_cooldown - delta, 0.0)
	if _global_cooldown > 0.0:
		return
	if _rng.randf() > flicker_chance_per_second * delta:
		return

	var light_data := _pick_random_idle_light()
	if light_data.is_empty():
		return
	_start_flicker(light_data)

func debug_get_light_count() -> int:
	if _lights.is_empty():
		_collect_lights()
	return _lights.size()

func debug_trigger_flicker(light_index := 0) -> bool:
	if _lights.is_empty():
		_collect_lights()
	if light_index < 0 or light_index >= _lights.size():
		return false
	_start_flicker(_lights[light_index])
	return true

func debug_get_light_energy(light_index := 0) -> float:
	if _lights.is_empty():
		_collect_lights()
	if light_index < 0 or light_index >= _lights.size():
		return -1.0
	var light := _lights[light_index]["light"] as Light3D
	return light.light_energy if light != null else -1.0

func debug_get_panel_emission_energy(light_index := 0) -> float:
	if _lights.is_empty():
		_collect_lights()
	if light_index < 0 or light_index >= _lights.size():
		return -1.0
	var material := _lights[light_index]["panel_material"] as StandardMaterial3D
	return material.emission_energy_multiplier if material != null else -1.0

func debug_get_base_light_energy(light_index := 0) -> float:
	if _lights.is_empty():
		_collect_lights()
	if light_index < 0 or light_index >= _lights.size():
		return -1.0
	return float(_lights[light_index]["base_energy"])

func debug_get_global_cooldown() -> float:
	return _global_cooldown

func trigger_red_monster_flicker(world_position: Vector3, radius := 7.0) -> int:
	if not enabled:
		return 0
	if _lights.is_empty():
		_collect_lights()
	var affected := 0
	var candidates: Array[Dictionary] = []
	for light_data in _lights:
		var light_variant: Variant = light_data.get("light")
		if not is_instance_valid(light_variant):
			continue
		var light := light_variant as Light3D
		if light == null:
			continue
		var distance := light.global_position.distance_to(world_position)
		if distance > radius:
			continue
		var candidate := light_data.duplicate()
		candidate["distance_to_red_monster"] = distance
		candidates.append(candidate)
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("distance_to_red_monster", 0.0)) < float(b.get("distance_to_red_monster", 0.0))
	)
	for candidate in candidates:
		if affected >= 4:
			break
		var source_variant: Variant = candidate.get("light")
		if not is_instance_valid(source_variant):
			continue
		var source_light := source_variant as Light3D
		if source_light == null:
			continue
		for light_data in _lights:
			if light_data.get("light") == source_light:
				_start_flicker(light_data)
				_set_light_multiplier(light_data, 0.06)
				light_data["steps_left"] = maxi(int(light_data.get("steps_left", 0)), 8)
				light_data["step_timer"] = flicker_step_min
				affected += 1
				break
	return affected

func refresh_light_cache() -> void:
	for light_data in _lights:
		light_data["active"] = false
	_collect_lights()

func _collect_lights() -> void:
	_lights.clear()
	var scene_tree := get_tree()
	if scene_tree == null:
		return
	var fixtures := {}
	var fixture_order: Array[String] = []
	var panel_materials := {}
	for node in scene_tree.get_nodes_in_group("ceiling_light"):
		var light := node as Light3D
		if light == null:
			continue
		var fixture_id := _fixture_id_for_light(light)
		var panel := _find_matching_panel(light)
		var panel_material: StandardMaterial3D = null
		if panel != null:
			var panel_key := panel.get_instance_id()
			if not panel_materials.has(panel_key):
				panel_materials[panel_key] = _prepare_panel_material(panel)
			panel_material = panel_materials[panel_key] as StandardMaterial3D
		var base_panel_energy := 0.0
		if panel_material != null:
			base_panel_energy = panel_material.emission_energy_multiplier
		if not fixtures.has(fixture_id):
			fixtures[fixture_id] = {
				"light": light,
				"sources": [],
				"base_energies": [],
				"panel": panel,
				"panel_material": panel_material,
				"base_energy": light.light_energy,
				"base_panel_energy": base_panel_energy,
				"active": false,
				"step_timer": 0.0,
				"steps_left": 0,
			}
			fixture_order.append(fixture_id)
		var fixture: Dictionary = fixtures[fixture_id]
		var sources: Array = fixture["sources"]
		var base_energies: Array = fixture["base_energies"]
		sources.append(light)
		base_energies.append(light.light_energy)
		fixture["sources"] = sources
		fixture["base_energies"] = base_energies
		fixtures[fixture_id] = fixture
	for fixture_id in fixture_order:
		_lights.append(fixtures[fixture_id])

func _fixture_id_for_light(light: Light3D) -> String:
	var owner_id := String(light.get_meta("owner_module_id", ""))
	if owner_id != "":
		return owner_id
	return String(light.name).trim_prefix("CeilingLight_")

func _find_matching_panel(light: Light3D) -> MeshInstance3D:
	var panel_name := String(light.get_meta("fixture_panel_name", ""))
	var owner_id := String(light.get_meta("owner_module_id", ""))
	for node in get_tree().get_nodes_in_group("ceiling_light_panel"):
		var panel := node as MeshInstance3D
		if panel == null:
			continue
		if panel_name != "" and panel.name == panel_name:
			return panel
		if owner_id != "" and String(panel.get_meta("owner_module_id", "")) == owner_id:
			return panel
	var suffix := light.name.trim_prefix("CeilingLight_")
	var expected_panel_name := "CeilingLightPanel_%s" % suffix
	for node in get_tree().get_nodes_in_group("ceiling_light_panel"):
		var panel := node as MeshInstance3D
		if panel != null and panel.name == expected_panel_name:
			return panel
	return null

func _prepare_panel_material(panel: MeshInstance3D) -> StandardMaterial3D:
	if panel == null:
		return null
	if bool(panel.get_meta("runtime_unique_light_material", false)):
		var existing_material := panel.material_override as StandardMaterial3D
		if existing_material != null:
			return existing_material
	var source_material := panel.material_override
	if source_material == null and panel.mesh != null:
		source_material = panel.mesh.surface_get_material(0)
	var standard_material := source_material as StandardMaterial3D
	if standard_material == null:
		return null
	var unique_material := standard_material.duplicate(true) as StandardMaterial3D
	panel.material_override = unique_material
	panel.set_meta("runtime_unique_light_material", true)
	return unique_material

func _has_active_flicker() -> bool:
	for light_data in _lights:
		if bool(light_data["active"]):
			return true
	return false

func _pick_random_idle_light() -> Dictionary:
	var idle_lights: Array[Dictionary] = []
	for light_data in _lights:
		if not bool(light_data["active"]):
			idle_lights.append(light_data)
	if idle_lights.is_empty():
		return {}
	return idle_lights[_rng.randi_range(0, idle_lights.size() - 1)]

func _start_flicker(light_data: Dictionary) -> void:
	light_data["active"] = true
	light_data["steps_left"] = _rng.randi_range(flicker_steps_min, flicker_steps_max)
	light_data["step_timer"] = 0.0
	_apply_next_flicker_step(light_data)

func _update_active_flicker(light_data: Dictionary, delta: float) -> void:
	light_data["step_timer"] = float(light_data["step_timer"]) - delta
	if float(light_data["step_timer"]) > 0.0:
		return
	_apply_next_flicker_step(light_data)

func _apply_next_flicker_step(light_data: Dictionary) -> void:
	var steps_left := int(light_data["steps_left"])
	if steps_left <= 0:
		_restore_light(light_data)
		light_data["active"] = false
		_global_cooldown = _rng.randf_range(flicker_interval_min, flicker_interval_max)
		return

	var use_dim_step := steps_left % 2 == 0
	var multiplier := _rng.randf_range(dim_energy_min, dim_energy_max)
	if not use_dim_step:
		multiplier = _rng.randf_range(bright_energy_min, bright_energy_max)
	_set_light_multiplier(light_data, multiplier)
	light_data["steps_left"] = steps_left - 1
	light_data["step_timer"] = _rng.randf_range(flicker_step_min, flicker_step_max)

func _set_light_multiplier(light_data: Dictionary, multiplier: float) -> void:
	var sources: Array = light_data.get("sources", [])
	var base_energies: Array = light_data.get("base_energies", [])
	for source_index in range(sources.size()):
		var source = sources[source_index]
		if not is_instance_valid(source):
			continue
		var light := source as Light3D
		if light == null:
			continue
		var base_energy := float(light_data["base_energy"])
		if source_index < base_energies.size():
			base_energy = float(base_energies[source_index])
		light.light_energy = base_energy * multiplier
	var panel_material := light_data["panel_material"] as StandardMaterial3D
	if panel_material != null:
		panel_material.emission_energy_multiplier = float(light_data["base_panel_energy"]) * clampf(multiplier, 0.12, 1.85)

func _restore_all_lights() -> void:
	for light_data in _lights:
		_restore_light(light_data)
		light_data["active"] = false

func _restore_light(light_data: Dictionary) -> void:
	var sources: Array = light_data.get("sources", [])
	var base_energies: Array = light_data.get("base_energies", [])
	for source_index in range(sources.size()):
		var source = sources[source_index]
		if not is_instance_valid(source):
			continue
		var light := source as Light3D
		if light == null:
			continue
		var base_energy := float(light_data["base_energy"])
		if source_index < base_energies.size():
			base_energy = float(base_energies[source_index])
		light.light_energy = base_energy
	var panel_material := light_data["panel_material"] as StandardMaterial3D
	if panel_material != null:
		panel_material.emission_energy_multiplier = float(light_data["base_panel_energy"])
