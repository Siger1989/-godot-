extends Area3D

@export var activation_radius := 2.4
@export var attraction_radius := 28.0
@export var active_duration := 10.0
@export var linger_after_player_exit := 3.5
@export var cooldown_duration := 6.0
@export var light_pulse_multiplier := 1.65
@export var alarm_volume_db := -10.0
@export var alarm_max_distance := 24.0
@export var alarm_loop_seconds := 1.15
@export var active_light_energy := 2.85
@export var active_light_range := 8.2
@export var active_light_attenuation := 1.55
@export var inactive_panel_color := Color(0.055, 0.045, 0.038, 1.0)
@export var active_panel_color := Color(0.38, 0.025, 0.018, 1.0)

var _active_timer := 0.0
var _cooldown_timer := 0.0
var _player_overlap_count := 0
var _linked_lights: Array[Light3D] = []
var _linked_panels: Array[MeshInstance3D] = []
var _base_light_energy: Dictionary = {}
var _base_light_range: Dictionary = {}
var _base_light_attenuation: Dictionary = {}
var _active_light_energy_by_id: Dictionary = {}
var _active_light_range_by_id: Dictionary = {}
var _active_light_attenuation_by_id: Dictionary = {}
var _alarm_audio: AudioStreamPlayer3D

func _ready() -> void:
	add_to_group("red_alarm_attractor", true)
	monitoring = true
	monitorable = false
	collision_layer = 0
	collision_mask = 1
	if get_child_count() == 0:
		_create_activation_shape()
	_cache_linked_lights()
	_cache_linked_panels()
	_set_alarm_visual_active(false)
	_create_alarm_audio()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	set_meta("red_alarm_active", false)

func _process(delta: float) -> void:
	if _cooldown_timer > 0.0:
		_cooldown_timer = maxf(_cooldown_timer - delta, 0.0)
	if _active_timer > 0.0:
		if _player_overlap_count > 0:
			_active_timer = maxf(_active_timer, linger_after_player_exit)
		_active_timer = maxf(_active_timer - delta, 0.0)
		_update_light_pulse()
		if _active_timer <= 0.0:
			_deactivate()

func activate() -> void:
	if _active_timer <= 0.0 and _cooldown_timer > 0.0:
		return
	_active_timer = active_duration
	_cooldown_timer = active_duration + cooldown_duration
	set_meta("red_alarm_active", true)
	add_to_group("active_red_alarm_attractor", true)
	_set_alarm_visual_active(true)
	_play_alarm_audio()

func is_active() -> bool:
	return _active_timer > 0.0

func get_attract_position() -> Vector3:
	return global_position

func get_attraction_radius() -> float:
	return attraction_radius

func get_owner_module_id() -> String:
	return String(get_meta("owner_module_id", ""))

func debug_has_alarm_audio() -> bool:
	return _alarm_audio != null and _alarm_audio.stream != null

func debug_is_alarm_audio_playing() -> bool:
	return _alarm_audio != null and _alarm_audio.playing

func debug_linked_alarm_light_count() -> int:
	return _linked_lights.size()

func debug_any_alarm_light_visible() -> bool:
	for light in _linked_lights:
		if light != null and light.visible and light.light_energy > 0.01:
			return true
	return false

func debug_first_alarm_light_energy() -> float:
	for light in _linked_lights:
		if light != null:
			return light.light_energy
	return 0.0

func debug_first_alarm_light_range() -> float:
	for light in _linked_lights:
		if light != null:
			return light.omni_range
	return 0.0

func _create_activation_shape() -> void:
	var shape := SphereShape3D.new()
	shape.radius = activation_radius
	var collision := CollisionShape3D.new()
	collision.name = "ActivationRadius"
	collision.shape = shape
	add_child(collision)

func _create_alarm_audio() -> void:
	if _alarm_audio != null:
		return
	_alarm_audio = AudioStreamPlayer3D.new()
	_alarm_audio.name = "RedAlarmAudio"
	_alarm_audio.stream = _build_alarm_stream()
	_alarm_audio.volume_db = alarm_volume_db
	_alarm_audio.max_distance = alarm_max_distance
	_alarm_audio.unit_size = 3.0
	_alarm_audio.autoplay = false
	add_child(_alarm_audio)

func _build_alarm_stream() -> AudioStreamWAV:
	var mix_rate := 22050
	var sample_count: int = maxi(1, int(float(mix_rate) * alarm_loop_seconds))
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for sample_index in range(sample_count):
		var t := float(sample_index) / float(mix_rate)
		var normalized := t / maxf(alarm_loop_seconds, 0.001)
		var gate := 0.48 + 0.52 * sin(normalized * TAU * 2.0)
		var sweep := 0.5 + 0.5 * sin(normalized * TAU)
		var frequency := lerpf(680.0, 980.0, sweep)
		var sample := sin(t * TAU * frequency) * gate * 0.72
		var sample_int := int(clampf(sample, -1.0, 1.0) * 32767.0)
		if sample_int < 0:
			sample_int += 65536
		var byte_index := sample_index * 2
		data[byte_index] = sample_int & 0xff
		data[byte_index + 1] = (sample_int >> 8) & 0xff
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = mix_rate
	stream.stereo = false
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = sample_count
	return stream

func _play_alarm_audio() -> void:
	if _alarm_audio == null:
		_create_alarm_audio()
	if _alarm_audio == null or _alarm_audio.stream == null or _alarm_audio.playing:
		return
	_alarm_audio.play()

func _cache_linked_lights() -> void:
	var module_id := String(get_meta("owner_module_id", ""))
	if module_id.is_empty() or get_tree() == null:
		return
	for node in get_tree().get_nodes_in_group("proc_red_alarm_light"):
		var light := node as Light3D
		if light == null:
			continue
		if String(light.get_meta("owner_module_id", "")) != module_id:
			continue
		_linked_lights.append(light)
		_base_light_energy[light.get_instance_id()] = light.light_energy
		_base_light_range[light.get_instance_id()] = light.omni_range
		_base_light_attenuation[light.get_instance_id()] = light.omni_attenuation
		_active_light_energy_by_id[light.get_instance_id()] = float(light.get_meta("active_red_alarm_energy", active_light_energy))
		_active_light_range_by_id[light.get_instance_id()] = float(light.get_meta("active_red_alarm_range", active_light_range))
		_active_light_attenuation_by_id[light.get_instance_id()] = float(light.get_meta("active_red_alarm_attenuation", active_light_attenuation))
		light.shadow_enabled = true
		light.visible = false
		light.light_energy = 0.0

func _cache_linked_panels() -> void:
	var module_id := String(get_meta("owner_module_id", ""))
	if module_id.is_empty() or get_tree() == null:
		return
	for node in get_tree().get_nodes_in_group("proc_red_alarm_panel"):
		var panel := node as MeshInstance3D
		if panel == null:
			continue
		if String(panel.get_meta("owner_module_id", "")) != module_id:
			continue
		_linked_panels.append(panel)
		panel.material_override = _make_panel_material(false)

func _on_body_entered(body: Node) -> void:
	if body == null:
		return
	if body.is_in_group("player"):
		_player_overlap_count += 1
		activate()

func _on_body_exited(body: Node) -> void:
	if body == null:
		return
	if not body.is_in_group("player"):
		return
	_player_overlap_count = max(_player_overlap_count - 1, 0)
	if _player_overlap_count <= 0 and _active_timer > linger_after_player_exit:
		_active_timer = linger_after_player_exit

func _deactivate() -> void:
	set_meta("red_alarm_active", false)
	remove_from_group("active_red_alarm_attractor")
	if _alarm_audio != null:
		_alarm_audio.stop()
	_set_alarm_visual_active(false)

func _set_alarm_visual_active(active: bool) -> void:
	for light in _linked_lights:
		if light == null:
			continue
		var key := light.get_instance_id()
		light.visible = active
		light.shadow_enabled = true
		if active:
			light.light_energy = float(_active_light_energy_by_id.get(key, active_light_energy))
			light.omni_range = float(_active_light_range_by_id.get(key, active_light_range))
			light.omni_attenuation = float(_active_light_attenuation_by_id.get(key, active_light_attenuation))
		else:
			light.light_energy = float(_base_light_energy.get(key, 0.0))
			light.omni_range = float(_base_light_range.get(key, light.omni_range))
			light.omni_attenuation = float(_base_light_attenuation.get(key, light.omni_attenuation))
			if light.light_energy <= 0.01:
				light.visible = false
	for panel in _linked_panels:
		if panel != null:
			panel.material_override = _make_panel_material(active)

func _update_light_pulse() -> void:
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.011)
	for light in _linked_lights:
		if light == null:
			continue
		var active_energy := float(_active_light_energy_by_id.get(light.get_instance_id(), active_light_energy))
		light.visible = true
		light.light_energy = active_energy * lerpf(0.74, light_pulse_multiplier, pulse)

func _make_panel_material(active: bool) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = active_panel_color if active else inactive_panel_color
	material.emission_enabled = active
	material.emission = Color(1.0, 0.08, 0.035) if active else Color.BLACK
	material.emission_energy_multiplier = 2.25 if active else 0.0
	material.roughness = 0.72
	return material
