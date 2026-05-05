extends SceneTree

const SCENE_PATH := "res://scenes/mvp/FourRoomMVP.tscn"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene_resource := load(SCENE_PATH) as PackedScene
	if scene_resource == null:
		_fail("Failed to load %s." % SCENE_PATH)
		return

	var scene := scene_resource.instantiate() as Node3D
	root.add_child(scene)
	await process_frame
	await process_frame

	var lighting := scene.get_node_or_null("Systems/LightingController")
	if lighting == null:
		_fail("LightingController is missing.")
		return

	var default_chance := float(lighting.get("flicker_chance_per_second"))
	var default_interval_min := float(lighting.get("flicker_interval_min"))
	var default_bright_min := float(lighting.get("bright_energy_min"))
	var default_bright_max := float(lighting.get("bright_energy_max"))
	if default_chance > 0.02:
		_fail("Default flicker chance is too high: %.3f." % default_chance)
		return
	if default_interval_min < 25.0:
		_fail("Default flicker minimum interval is too short: %.3f." % default_interval_min)
		return
	if default_bright_min < 1.2 or default_bright_max < 1.6:
		_fail("Default bright flicker spike is too weak: min=%.3f max=%.3f." % [default_bright_min, default_bright_max])
		return

	lighting.set("startup_delay_min", 1000.0)
	lighting.set("startup_delay_max", 1000.0)
	lighting.set("flicker_step_min", 0.005)
	lighting.set("flicker_step_max", 0.005)
	lighting.set("flicker_steps_min", 4)
	lighting.set("flicker_steps_max", 4)
	lighting.set("dim_energy_min", 0.1)
	lighting.set("dim_energy_max", 0.1)
	lighting.set("bright_energy_min", 1.6)
	lighting.set("bright_energy_max", 1.6)
	await process_frame

	var light_count := int(lighting.call("debug_get_light_count"))
	if light_count != 4:
		_fail("Expected 4 managed ceiling lights, got %d." % light_count)
		return

	var base_light_energy := float(lighting.call("debug_get_base_light_energy", 0))
	var base_panel_energy := float(lighting.call("debug_get_panel_emission_energy", 0))
	if base_light_energy <= 0.0 or base_panel_energy <= 0.0:
		_fail("Base light or panel emission energy is invalid.")
		return
	if base_light_energy < 0.8:
		_fail("Base light energy is lower than the current brighter target: %.3f." % base_light_energy)
		return
	if base_panel_energy < 1.0:
		_fail("Base panel emission is lower than the current brighter target: %.3f." % base_panel_energy)
		return

	if not bool(lighting.call("debug_trigger_flicker", 0)):
		_fail("Failed to trigger test flicker.")
		return

	var dim_light_energy := float(lighting.call("debug_get_light_energy", 0))
	var dim_panel_energy := float(lighting.call("debug_get_panel_emission_energy", 0))
	if dim_light_energy >= base_light_energy * 0.5:
		_fail("Triggered flicker did not dim the real light: base=%.3f dim=%.3f." % [base_light_energy, dim_light_energy])
		return
	if dim_panel_energy >= base_panel_energy * 0.5:
		_fail("Triggered flicker did not dim the light panel emission: base=%.3f dim=%.3f." % [base_panel_energy, dim_panel_energy])
		return

	var bright_light_energy := -1.0
	var bright_panel_energy := -1.0
	for _frame_index in range(30):
		await process_frame
		var current_light_energy := float(lighting.call("debug_get_light_energy", 0))
		var current_panel_energy := float(lighting.call("debug_get_panel_emission_energy", 0))
		if current_light_energy > base_light_energy * 1.2:
			bright_light_energy = current_light_energy
			bright_panel_energy = current_panel_energy
			break

	if bright_light_energy <= base_light_energy * 1.2:
		_fail("Triggered flicker did not produce a bright light spike: base=%.3f bright=%.3f." % [base_light_energy, bright_light_energy])
		return
	if bright_panel_energy <= base_panel_energy * 1.2:
		_fail("Triggered flicker did not produce a bright panel spike: base=%.3f bright=%.3f." % [base_panel_energy, bright_panel_energy])
		return

	for _frame_index in range(120):
		await process_frame

	var restored_light_energy := float(lighting.call("debug_get_light_energy", 0))
	var restored_panel_energy := float(lighting.call("debug_get_panel_emission_energy", 0))
	if absf(restored_light_energy - base_light_energy) > 0.001:
		_fail("Real light did not restore after flicker: base=%.3f restored=%.3f." % [base_light_energy, restored_light_energy])
		return
	if absf(restored_panel_energy - base_panel_energy) > 0.001:
		_fail("Panel emission did not restore after flicker: base=%.3f restored=%.3f." % [base_panel_energy, restored_panel_energy])
		return

	print(
		"LIGHT_FLICKER_VALIDATION PASS lights=%d chance=%.3f min_interval=%.1f bright_range=%.2f-%.2f base=%.3f dim=%.3f bright=%.3f panel_base=%.3f panel_dim=%.3f panel_bright=%.3f"
		% [light_count, default_chance, default_interval_min, default_bright_min, default_bright_max, base_light_energy, dim_light_energy, bright_light_energy, base_panel_energy, dim_panel_energy, bright_panel_energy]
	)
	quit(0)

func _fail(message: String) -> void:
	push_error("LIGHT_FLICKER_VALIDATION FAIL: %s" % message)
	quit(1)
