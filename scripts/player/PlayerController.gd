extends CharacterBody3D

const ACTOR_LIGHT_LAYER := 1 << 8
const PLAYER_FOOTSTEP_PATHS := [
	"res://assets/audio/player_footstep_01.wav",
	"res://assets/audio/player_footstep_02.wav",
]
const PLAYER_BREATH_PATH := "res://assets/audio/player_breath_loop.wav"
const KEY_PICKUP_PATH := "res://assets/audio/key_pickup.wav"
const MOBILE_PREFS_PATH := "user://mobile_controls.cfg"
const MOBILE_ACTION_BUTTON_BASE_SIZE := Vector2(166.0, 96.0)

@export var move_speed := 2.6
@export var sprint_multiplier := 1.65
@export var crouch_speed_multiplier := 0.48
@export var crouch_transition_speed := 9.0
@export var crouch_collision_height := 1.05
@export var crouch_hips_drop_units := 78.0
@export var crouch_hips_forward_units := 10.0
@export var crouch_hips_pitch_degrees := -6.0
@export var crouch_spine_pitch_degrees := 10.0
@export var crouch_upper_leg_pitch_degrees := 36.0
@export var crouch_lower_leg_pitch_degrees := -48.0
@export var crouch_foot_pitch_degrees := 16.0
@export var acceleration := 14.0
@export var rotation_smoothing := 14.0
@export var gravity := 24.0
@export var floor_snap_distance := 0.28
@export_node_path("Node3D") var visual_root_path: NodePath = ^"ModelRoot"
@export_node_path("Node3D") var camera_rig_path: NodePath = ^"../../CameraRig"
@export_node_path("AnimationPlayer") var animation_player_path: NodePath = ^"ModelRoot/zhujiao/AnimationPlayer"
@export var idle_animation := "idle_generated"
@export var walk_animation := "mixamo_com"
@export var run_animation := "mixamo_com"
@export var backpedal_animation := "mixamo_com"
@export var idle_source_animation := "mixamo_com"
@export var idle_pose_time := 1.55
@export var idle_cycle_length := 6.0
@export var idle_breath_degrees := 1.8
@export var idle_head_look_degrees := 9.0
@export var animation_blend_time := 0.15
@export var walk_animation_speed := 1.0
@export var run_animation_speed := 1.25
@export var backpedal_animation_speed := -0.8
@export var lock_animation_root_motion := true
@export var cast_model_shadows := true
@export var door_interact_distance := 1.35
@export var door_interact_facing_dot := 0.12
@export var hideable_interact_distance := 1.35
@export var hideable_interact_facing_dot := 0.08
@export var show_interaction_button := true
@export var show_mobile_controls := true
@export var mobile_joystick_radius := 108.0
@export var mobile_joystick_margin := Vector2(184.0, 158.0)
@export var mobile_joystick_start_radius_multiplier := 3.0
@export var mobile_action_button_size := Vector2(166.0, 96.0)
@export var mobile_action_button_right_margin := 150.0
@export var mobile_action_button_bottom_margin := 116.0
@export var mobile_action_button_gap := 18.0
@export var mobile_settings_button_size := Vector2(92.0, 64.0)
@export var mobile_settings_button_margin := Vector2(126.0, 42.0)
@export var mobile_control_drag_enabled := true
@export var escape_key_pickup_distance := 1.15
@export var walk_footstep_interval := 0.54
@export var run_footstep_interval := 0.38
@export var walk_footstep_noise_radius := 7.2
@export var run_footstep_noise_radius := 10.5
@export var crouch_footstep_noise_radius := 0.0
@export var footstep_noise_speed_threshold := 0.25
@export var footstep_sprint_speed_threshold := 3.1
@export var standing_detection_target_height := 0.8
@export var crouch_detection_target_height := 0.38
@export var max_health := 100.0
@export var start_health := 100.0
@export var show_health_bar := true
@export var max_stamina := 100.0
@export var start_stamina := 100.0
@export var sprint_stamina_drain_per_second := 23.0
@export var stamina_recover_per_second := 15.0
@export var stamina_recover_delay_after_sprint := 0.55
@export var stamina_exhausted_resume_ratio := 0.28
@export var show_stamina_bar := true

var _movement_velocity := Vector3.ZERO
var _facing_direction := Vector3.ZERO
var _has_facing_direction := false
var _has_escape_key := false
var _health := 100.0
var _dead := false
var _hidden_in_hideable := false
var _current_hideable: Node
var _interaction_locked := false
var _health_layer: CanvasLayer
var _health_bar: ProgressBar
var _health_label: Label
var _stamina := 100.0
var _stamina_bar: ProgressBar
var _stamina_label: Label
var _stamina_recover_delay_timer := 0.0
var _stamina_exhausted := false
var _sprinting_active := false
var _game_over_layer: CanvasLayer
var _interaction_prompt_layer: CanvasLayer
var _interaction_button: Button
var _mobile_controls_layer: CanvasLayer
var _mobile_stick_base: Panel
var _mobile_stick_knob: Panel
var _mobile_sprint_button: Button
var _mobile_crouch_button: Button
var _mobile_settings_button: Button
var _mobile_settings_panel: PanelContainer
var _mobile_settings_open := false
var _mobile_customize_controls := true
var _mobile_sprint_touch_index := -1
var _mobile_drag_touch_index := -1
var _mobile_drag_target := ""
var _mobile_drag_offset := Vector2.ZERO
var _mobile_sprint_button_position := Vector2.ZERO
var _mobile_crouch_button_position := Vector2.ZERO
var _mobile_settings_button_position := Vector2.ZERO
var _has_mobile_sprint_button_position := false
var _has_mobile_crouch_button_position := false
var _has_mobile_settings_button_position := false
var _has_mobile_stick_position := false
var _mobile_render_scale := 1.0
var _mobile_camera_distance := 1.8
var _mobile_touch_sensitivity_multiplier := 1.0
var _mobile_button_scale := 1.0
var _mobile_touch_index := -1
var _mobile_stick_center := Vector2.ZERO
var _mobile_move_vector := Vector2.ZERO
var _mobile_sprint_pressed := false
var _mobile_crouch_toggled := false
var _animation_player: AnimationPlayer
var _skeleton: Skeleton3D
var _collision_shape: CollisionShape3D
var _collision_capsule: CapsuleShape3D
var _current_animation := ""
var _current_animation_speed := 1.0
var _crouch_visual_amount := 0.0
var _standing_visual_scale := Vector3.ONE
var _standing_visual_rotation_x := 0.0
var _standing_collision_height := 1.6
var _standing_collision_center_y := 0.8
var _crouch_bone_indices: Dictionary = {}
var _crouch_bone_base_positions: Dictionary = {}
var _crouch_bone_base_rotations: Dictionary = {}
var _crouch_bone_base_scales: Dictionary = {}
var _footstep_streams: Array[AudioStream] = []
var _footstep_player: AudioStreamPlayer3D
var _breath_player: AudioStreamPlayer
var _key_pickup_player: AudioStreamPlayer
var _footstep_timer := 0.0
var _footstep_index := 0

func _ready() -> void:
	add_to_group("player")
	add_to_group("living_creature")
	floor_snap_length = floor_snap_distance
	max_health = maxf(max_health, 1.0)
	_health = clampf(start_health, 0.0, max_health)
	max_stamina = maxf(max_stamina, 1.0)
	_stamina = clampf(start_stamina, 0.0, max_stamina)
	_dead = _health <= 0.0
	set_meta("health", _health)
	set_meta("max_health", max_health)
	set_meta("stamina", _stamina)
	set_meta("max_stamina", max_stamina)
	set_meta("dead", _dead)
	set_meta("hidden_from_monsters", false)
	set_meta("game_over", false)
	_ensure_input_actions()
	_create_health_bar()
	_create_interaction_button()
	_create_mobile_controls()
	_create_player_audio()
	_animation_player = get_node_or_null(animation_player_path) as AnimationPlayer
	_skeleton = _find_skeleton(self)
	_cache_crouch_pose_nodes()
	_configure_model_shadows(self)
	_configure_animation_loop(walk_animation)
	_configure_animation_loop(run_animation)
	_configure_animation_loop(backpedal_animation)
	_ensure_generated_idle_animation()
	_configure_animation_loop(idle_animation)
	if _dead:
		_show_game_over(null)

func _input(event: InputEvent) -> void:
	if _handle_mobile_control_input(event):
		return

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"):
		return
	if event is InputEventKey and event.echo:
		return
	if _perform_interaction():
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	_update_health_bar()
	_update_interaction_button()
	_update_mobile_controls_visibility()
	_apply_crouch_visual_pose()

func _physics_process(delta: float) -> void:
	if _dead:
		_sprinting_active = false
		_update_crouch_pose(delta, false)
		_movement_velocity = Vector3.ZERO
		velocity = Vector3.ZERO
		_play_idle_or_stop()
		_update_player_audio(delta, Vector2.ZERO, false)
		return
	if _interaction_locked:
		_sprinting_active = false
		_update_crouch_pose(delta, false)
		_movement_velocity = Vector3.ZERO
		velocity = Vector3.ZERO
		_play_idle_or_stop()
		_update_player_audio(delta, Vector2.ZERO, false)
		return

	var input_vector := _get_input_vector()
	var desired_direction := _get_camera_relative_direction(input_vector)
	if desired_direction.length_squared() > 1.0:
		desired_direction = desired_direction.normalized()

	var current_speed := move_speed
	var crouching := _is_crouching()
	var wants_sprint := _wants_sprint()
	var sprinting := _can_sprint(wants_sprint, input_vector)
	_sprinting_active = sprinting
	if sprinting:
		current_speed *= sprint_multiplier
	elif crouching:
		current_speed *= crouch_speed_multiplier
	var desired_velocity := desired_direction * current_speed
	_movement_velocity = _movement_velocity.lerp(desired_velocity, clampf(acceleration * delta, 0.0, 1.0))

	velocity.x = _movement_velocity.x
	velocity.z = _movement_velocity.z
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= gravity * delta

	move_and_slide()
	_update_stamina(delta, sprinting)
	_update_visual_facing(_get_visual_facing_direction(input_vector, desired_direction), delta)
	_update_animation(input_vector, desired_direction)
	_update_crouch_pose(delta, crouching)
	_update_player_audio(delta, input_vector, sprinting)
	_try_collect_escape_key(false)

func _get_input_vector() -> Vector2:
	var keyboard_vector := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_forward") - Input.get_action_strength("move_back")
	)
	var input_vector := keyboard_vector + _mobile_move_vector
	if input_vector.length_squared() > 1.0:
		input_vector = input_vector.normalized()
	return input_vector

func _get_camera_relative_direction(input_vector: Vector2) -> Vector3:
	if input_vector.length_squared() <= 0.0001:
		return Vector3.ZERO

	var camera_rig := get_node_or_null(camera_rig_path) as Node3D
	if camera_rig == null:
		return Vector3(input_vector.x, 0.0, -input_vector.y)

	var forward := -camera_rig.global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() <= 0.0001:
		forward = Vector3.FORWARD
	else:
		forward = forward.normalized()

	var right := camera_rig.global_transform.basis.x
	right.y = 0.0
	if right.length_squared() <= 0.0001:
		right = Vector3.RIGHT
	else:
		right = right.normalized()

	return right * input_vector.x + forward * input_vector.y

func _get_visual_facing_direction(input_vector: Vector2, desired_direction: Vector3) -> Vector3:
	if desired_direction.length_squared() < 0.001:
		return Vector3.ZERO
	if input_vector.y < -0.15 and absf(input_vector.y) >= absf(input_vector.x):
		return -desired_direction
	return desired_direction

func _update_visual_facing(direction: Vector3, delta: float) -> void:
	if direction.length_squared() < 0.001:
		return
	var normalized_direction := direction.normalized()
	_facing_direction = normalized_direction
	_has_facing_direction = true
	var visual_root := get_node_or_null(visual_root_path) as Node3D
	if visual_root == null:
		return
	var target_yaw := atan2(normalized_direction.x, normalized_direction.z)
	visual_root.rotation.y = lerp_angle(visual_root.rotation.y, target_yaw, clampf(rotation_smoothing * delta, 0.0, 1.0))

func _update_animation(input_vector: Vector2, desired_direction: Vector3) -> void:
	if _animation_player == null:
		return
	if desired_direction.length_squared() < 0.001:
		_play_idle_or_stop()
		return

	if input_vector.y < -0.15 and absf(input_vector.y) >= absf(input_vector.x):
		_play_animation(backpedal_animation, backpedal_animation_speed)
	elif _is_sprinting():
		_play_animation(run_animation, run_animation_speed)
	elif _is_crouching():
		_play_animation(walk_animation, walk_animation_speed * 0.62)
	else:
		_play_animation(walk_animation, walk_animation_speed)

func _is_sprinting() -> bool:
	return _sprinting_active

func _wants_sprint() -> bool:
	return (Input.is_action_pressed("sprint") or _mobile_sprint_pressed) and not _is_crouching()

func _can_sprint(wants_sprint: bool, input_vector: Vector2) -> bool:
	if not wants_sprint:
		return false
	if _stamina_exhausted:
		return false
	if _stamina <= 0.1:
		return false
	if input_vector.length_squared() <= 0.02:
		return false
	return true

func _update_stamina(delta: float, sprinting: bool) -> void:
	if sprinting:
		_stamina = maxf(_stamina - sprint_stamina_drain_per_second * delta, 0.0)
		_stamina_recover_delay_timer = stamina_recover_delay_after_sprint
		if _stamina <= 0.0:
			_stamina_exhausted = true
			_mobile_sprint_pressed = false
	else:
		_stamina_recover_delay_timer = maxf(_stamina_recover_delay_timer - delta, 0.0)
		if _stamina_recover_delay_timer <= 0.0:
			_stamina = minf(_stamina + stamina_recover_per_second * delta, max_stamina)
		if _stamina_exhausted and _stamina >= max_stamina * stamina_exhausted_resume_ratio:
			_stamina_exhausted = false
	set_meta("stamina", _stamina)
	set_meta("stamina_exhausted", _stamina_exhausted)
	_update_stamina_bar()

func _is_crouching() -> bool:
	return Input.is_action_pressed("crouch") or _mobile_crouch_toggled

func _cache_crouch_pose_nodes() -> void:
	var visual_root := get_node_or_null(visual_root_path) as Node3D
	if visual_root != null:
		_standing_visual_scale = visual_root.scale
		_standing_visual_rotation_x = visual_root.rotation.x
	_cache_crouch_bones()
	_collision_shape = get_node_or_null("CollisionShape3D") as CollisionShape3D
	if _collision_shape == null:
		return
	_standing_collision_center_y = _collision_shape.position.y
	var capsule := _collision_shape.shape as CapsuleShape3D
	if capsule == null:
		return
	_collision_capsule = capsule.duplicate() as CapsuleShape3D
	_collision_shape.shape = _collision_capsule
	_standing_collision_height = _collision_capsule.height

func _cache_crouch_bones() -> void:
	_crouch_bone_indices.clear()
	_crouch_bone_base_positions.clear()
	_crouch_bone_base_rotations.clear()
	_crouch_bone_base_scales.clear()
	if _skeleton == null:
		return
	_cache_crouch_bone("hips", "Hips")
	_cache_crouch_bone("spine", "Spine_")
	_cache_crouch_bone("spine1", "Spine1")
	_cache_crouch_bone("spine2", "Spine2")
	_cache_crouch_bone("left_up_leg", "LeftUpLeg")
	_cache_crouch_bone("left_leg", "LeftLeg")
	_cache_crouch_bone("left_foot", "LeftFoot")
	_cache_crouch_bone("right_up_leg", "RightUpLeg")
	_cache_crouch_bone("right_leg", "RightLeg")
	_cache_crouch_bone("right_foot", "RightFoot")

func _cache_crouch_bone(key: String, name_part: String) -> void:
	if _skeleton == null:
		return
	var bone_index := _find_bone_index(name_part)
	if bone_index < 0:
		return
	_crouch_bone_indices[key] = bone_index
	_crouch_bone_base_positions[key] = _skeleton.get_bone_pose_position(bone_index)
	_crouch_bone_base_rotations[key] = _skeleton.get_bone_pose_rotation(bone_index)
	_crouch_bone_base_scales[key] = _skeleton.get_bone_pose_scale(bone_index)

func _find_bone_index(name_part: String) -> int:
	if _skeleton == null:
		return -1
	for bone_index in range(_skeleton.get_bone_count()):
		if _skeleton.get_bone_name(bone_index).contains(name_part):
			return bone_index
	return -1

func _update_crouch_pose(delta: float, crouching: bool) -> void:
	var target := 1.0 if crouching else 0.0
	_crouch_visual_amount = lerpf(
		_crouch_visual_amount,
		target,
		clampf(crouch_transition_speed * delta, 0.0, 1.0)
	)
	_apply_crouch_visual_pose()
	_apply_crouch_collision_pose()

func _apply_crouch_visual_pose() -> void:
	var visual_root := get_node_or_null(visual_root_path) as Node3D
	if visual_root != null:
		visual_root.scale = _standing_visual_scale
		visual_root.rotation.x = _standing_visual_rotation_x
	_apply_crouch_bone_pose()

func _apply_crouch_bone_pose() -> void:
	if _skeleton == null or _crouch_bone_indices.is_empty():
		return
	var amount := _crouch_visual_amount
	_set_crouch_bone_position("hips", Vector3(0.0, -crouch_hips_drop_units * amount, crouch_hips_forward_units * amount))
	_set_crouch_bone_rotation("hips", Vector3.RIGHT, crouch_hips_pitch_degrees * amount)
	_set_crouch_bone_rotation("spine", Vector3.RIGHT, crouch_spine_pitch_degrees * 0.45 * amount)
	_set_crouch_bone_rotation("spine1", Vector3.RIGHT, crouch_spine_pitch_degrees * 0.75 * amount)
	_set_crouch_bone_rotation("spine2", Vector3.RIGHT, crouch_spine_pitch_degrees * amount)
	_set_crouch_bone_rotation("left_up_leg", Vector3.RIGHT, crouch_upper_leg_pitch_degrees * amount)
	_set_crouch_bone_rotation("right_up_leg", Vector3.RIGHT, crouch_upper_leg_pitch_degrees * amount)
	_set_crouch_bone_rotation("left_leg", Vector3.RIGHT, crouch_lower_leg_pitch_degrees * amount)
	_set_crouch_bone_rotation("right_leg", Vector3.RIGHT, crouch_lower_leg_pitch_degrees * amount)
	_set_crouch_bone_rotation("left_foot", Vector3.RIGHT, crouch_foot_pitch_degrees * amount)
	_set_crouch_bone_rotation("right_foot", Vector3.RIGHT, crouch_foot_pitch_degrees * amount)

func _set_crouch_bone_position(key: String, offset: Vector3) -> void:
	if _skeleton == null or not _crouch_bone_indices.has(key):
		return
	var bone_index := int(_crouch_bone_indices[key])
	var base_position := _crouch_bone_base_positions[key] as Vector3
	_skeleton.set_bone_pose_position(bone_index, base_position + offset)
	if _crouch_bone_base_scales.has(key):
		_skeleton.set_bone_pose_scale(bone_index, _crouch_bone_base_scales[key] as Vector3)

func _set_crouch_bone_rotation(key: String, axis: Vector3, degrees: float) -> void:
	if _skeleton == null or not _crouch_bone_indices.has(key):
		return
	var bone_index := int(_crouch_bone_indices[key])
	var base_rotation := _crouch_bone_base_rotations[key] as Quaternion
	_skeleton.set_bone_pose_rotation(bone_index, base_rotation * Quaternion(axis.normalized(), deg_to_rad(degrees)))
	if _crouch_bone_base_scales.has(key):
		_skeleton.set_bone_pose_scale(bone_index, _crouch_bone_base_scales[key] as Vector3)

func _apply_crouch_collision_pose() -> void:
	if _collision_shape == null or _collision_capsule == null:
		return
	var target_height := clampf(crouch_collision_height, _collision_capsule.radius * 2.0, _standing_collision_height)
	var height := lerpf(_standing_collision_height, target_height, _crouch_visual_amount)
	_collision_capsule.height = height
	var center := _collision_shape.position
	center.y = lerpf(_standing_collision_center_y, height * 0.5, _crouch_visual_amount)
	_collision_shape.position = center

func _play_idle_or_stop() -> void:
	if idle_animation != "" and _animation_player.has_animation(idle_animation):
		_play_animation(idle_animation, 1.0)
		return
	if _animation_player.is_playing():
		_animation_player.stop(true)
	_current_animation = ""
	_current_animation_speed = 1.0

func _play_animation(animation_name: String, playback_speed: float) -> void:
	if animation_name == "" or not _animation_player.has_animation(animation_name):
		_play_idle_or_stop()
		return
	var should_restart := (
		not _animation_player.is_playing()
		or _current_animation != animation_name
		or not is_equal_approx(_current_animation_speed, playback_speed)
	)
	if should_restart:
		_animation_player.play(animation_name, animation_blend_time, playback_speed, playback_speed < 0.0)
		_current_animation = animation_name
		_current_animation_speed = playback_speed

func _configure_animation_loop(animation_name: String) -> void:
	if _animation_player == null or animation_name == "" or not _animation_player.has_animation(animation_name):
		return
	var animation := _animation_player.get_animation(animation_name)
	if animation != null:
		animation.loop_mode = Animation.LOOP_LINEAR
		_disable_root_motion_tracks(animation)

func _disable_root_motion_tracks(animation: Animation) -> void:
	if not lock_animation_root_motion:
		return
	for track_index in range(animation.get_track_count()):
		if animation.track_get_type(track_index) == Animation.TYPE_POSITION_3D:
			animation.track_set_enabled(track_index, false)

func _ensure_generated_idle_animation() -> void:
	if _animation_player == null or idle_animation == "" or _animation_player.has_animation(idle_animation):
		return
	var source_name := idle_source_animation
	if source_name == "":
		source_name = walk_animation
	if source_name == "" or not _animation_player.has_animation(source_name):
		return
	var source_animation := _animation_player.get_animation(source_name)
	if source_animation == null:
		return
	var idle_pose_animation := _build_idle_pose_animation(source_animation, _skeleton)
	if idle_pose_animation == null:
		return
	var default_library := _animation_player.get_animation_library(&"")
	if default_library == null:
		default_library = AnimationLibrary.new()
		_animation_player.add_animation_library(&"", default_library)
	if default_library.has_animation(idle_animation):
		default_library.remove_animation(idle_animation)
	default_library.add_animation(idle_animation, idle_pose_animation)

func _build_idle_pose_animation(source_animation: Animation, skeleton: Skeleton3D) -> Animation:
	var idle_pose_animation := Animation.new()
	idle_pose_animation.length = idle_cycle_length
	idle_pose_animation.loop_mode = Animation.LOOP_LINEAR

	for source_track_index in range(source_animation.get_track_count()):
		var track_type := source_animation.track_get_type(source_track_index)
		if track_type == Animation.TYPE_POSITION_3D:
			continue
		if (
			track_type != Animation.TYPE_ROTATION_3D
			and track_type != Animation.TYPE_SCALE_3D
			and track_type != Animation.TYPE_VALUE
		):
			continue
		var key_count := source_animation.track_get_key_count(source_track_index)
		if key_count <= 0:
			continue
		var track_path := source_animation.track_get_path(source_track_index)
		var idle_value: Variant = _get_idle_base_value(source_animation, source_track_index, track_path, skeleton)
		var idle_track_index := idle_pose_animation.add_track(track_type)
		idle_pose_animation.track_set_path(idle_track_index, track_path)
		_insert_idle_keys(
			idle_pose_animation,
			idle_track_index,
			track_path,
			idle_value
		)

	return idle_pose_animation

func _get_idle_base_value(animation: Animation, track_index: int, track_path: NodePath, skeleton: Skeleton3D) -> Variant:
	if animation.track_get_type(track_index) == Animation.TYPE_ROTATION_3D:
		var bone_name := _get_bone_name_from_track_path(track_path)
		if _should_use_rest_pose_for_idle(bone_name) and skeleton != null:
			var rest_rotation: Variant = _get_rest_rotation_for_bone(skeleton, bone_name)
			if rest_rotation != null:
				return rest_rotation
		return animation.rotation_track_interpolate(track_index, idle_pose_time)
	return _get_track_value_at_time(animation, track_index, idle_pose_time)

func _insert_idle_keys(animation: Animation, track_index: int, track_path: NodePath, idle_value: Variant) -> void:
	if not (idle_value is Quaternion):
		animation.track_insert_key(track_index, 0.0, idle_value)
		animation.track_insert_key(track_index, animation.length, idle_value)
		return

	var key_times := [
		0.0,
		animation.length * 0.18,
		animation.length * 0.36,
		animation.length * 0.48,
		animation.length * 0.70,
		animation.length * 0.83,
		animation.length,
	]
	for key_time in key_times:
		var normalized_time := 0.0
		if animation.length > 0.0:
			normalized_time = key_time / animation.length
		animation.track_insert_key(
			track_index,
			key_time,
			_get_idle_motion_value(track_path, idle_value, normalized_time)
		)

func _get_idle_motion_value(track_path: NodePath, idle_value: Variant, normalized_time: float) -> Variant:
	if not (idle_value is Quaternion):
		return idle_value
	var result: Quaternion = idle_value

	var influence := _get_idle_breath_influence(str(track_path))
	if idle_breath_degrees > 0.0 and influence > 0.0:
		var breath_amount := sin(normalized_time * TAU * 3.0) * idle_breath_degrees * influence
		result *= Quaternion(Vector3.RIGHT, deg_to_rad(breath_amount))

	var head_look_influence := _get_idle_head_look_influence(str(track_path))
	if idle_head_look_degrees > 0.0 and head_look_influence > 0.0:
		var look_amount := _get_idle_head_look_amount(normalized_time) * idle_head_look_degrees * head_look_influence
		result *= Quaternion(Vector3.UP, deg_to_rad(look_amount))

	return result

func _get_idle_breath_influence(track_path: String) -> float:
	if track_path.contains("Spine2"):
		return 1.0
	if track_path.contains("Spine1"):
		return 0.7
	if track_path.contains("Spine_"):
		return 0.45
	if track_path.contains("Neck") or track_path.contains("Head"):
		return 0.35
	if track_path.contains("Shoulder"):
		return 0.25
	return 0.0

func _get_idle_head_look_influence(track_path: String) -> float:
	if track_path.contains("Head"):
		return 1.0
	if track_path.contains("Neck"):
		return 0.7
	if track_path.contains("Spine2"):
		return 0.2
	return 0.0

func _get_idle_head_look_amount(normalized_time: float) -> float:
	if normalized_time < 0.28:
		return 0.0
	if normalized_time < 0.36:
		return smoothstep(0.28, 0.36, normalized_time)
	if normalized_time < 0.46:
		return 1.0
	if normalized_time < 0.54:
		return 1.0 - smoothstep(0.46, 0.54, normalized_time)
	if normalized_time < 0.63:
		return 0.0
	if normalized_time < 0.71:
		return -smoothstep(0.63, 0.71, normalized_time)
	if normalized_time < 0.80:
		return -1.0
	if normalized_time < 0.88:
		return -1.0 + smoothstep(0.80, 0.88, normalized_time)
	return 0.0

func _get_track_value_at_time(animation: Animation, track_index: int, time: float) -> Variant:
	match animation.track_get_type(track_index):
		Animation.TYPE_ROTATION_3D:
			return animation.rotation_track_interpolate(track_index, time)
		Animation.TYPE_SCALE_3D:
			return animation.scale_track_interpolate(track_index, time)
		Animation.TYPE_VALUE:
			return animation.value_track_interpolate(track_index, time)

	var key_count := animation.track_get_key_count(track_index)
	var selected_key_index := 0
	for key_index in range(key_count):
		if animation.track_get_key_time(track_index, key_index) <= time:
			selected_key_index = key_index
		else:
			break
	return animation.track_get_key_value(track_index, selected_key_index)

func _get_bone_name_from_track_path(track_path: NodePath) -> String:
	var track_path_text := str(track_path)
	var separator_index := track_path_text.rfind(":")
	if separator_index < 0:
		return track_path_text
	return track_path_text.substr(separator_index + 1)

func _should_use_rest_pose_for_idle(bone_name: String) -> bool:
	return (
		bone_name.contains("Hips")
		or bone_name.contains("UpLeg")
		or bone_name.contains("LeftLeg")
		or bone_name.contains("RightLeg")
		or bone_name.contains("Foot")
		or bone_name.contains("Toe")
	)

func _get_rest_rotation_for_bone(skeleton: Skeleton3D, bone_name: String) -> Variant:
	for bone_index in range(skeleton.get_bone_count()):
		if skeleton.get_bone_name(bone_index) == bone_name:
			return skeleton.get_bone_rest(bone_index).basis.get_rotation_quaternion()
	return null

func _find_skeleton(node: Node) -> Skeleton3D:
	var skeleton := node as Skeleton3D
	if skeleton != null:
		return skeleton
	for child in node.get_children():
		var result := _find_skeleton(child)
		if result != null:
			return result
	return null

func _configure_model_shadows(node: Node) -> void:
	if not cast_model_shadows:
		return
	var mesh_instance := node as MeshInstance3D
	if mesh_instance != null:
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		mesh_instance.layers = ACTOR_LIGHT_LAYER
	for child in node.get_children():
		_configure_model_shadows(child)

func get_camera_heading_direction() -> Vector3:
	if not _has_facing_direction:
		return Vector3.ZERO
	return _facing_direction

func debug_mobile_controls_visible() -> bool:
	return _mobile_controls_layer != null and _mobile_controls_layer.visible

func debug_set_mobile_move_vector(value: Vector2) -> void:
	_mobile_move_vector = value
	if _mobile_move_vector.length_squared() > 1.0:
		_mobile_move_vector = _mobile_move_vector.normalized()
	_update_mobile_stick_knob()

func debug_get_input_vector() -> Vector2:
	return _get_input_vector()

func debug_get_mobile_stick_center() -> Vector2:
	return _mobile_stick_center

func debug_get_mobile_joystick_radius() -> float:
	return mobile_joystick_radius

func debug_mobile_stick_accepts_start(position: Vector2) -> bool:
	return _is_mobile_stick_start(position)

func debug_mobile_vector_from_screen_position(position: Vector2) -> Vector2:
	return _get_mobile_move_vector_for_position(position)

func debug_simulate_mobile_touch_path(start_position: Vector2, drag_position: Vector2) -> Vector2:
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.position = start_position
	touch.pressed = true
	_handle_mobile_control_input(touch)
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = drag_position
	_handle_mobile_control_input(drag)
	var result := _mobile_move_vector
	touch.pressed = false
	_handle_mobile_control_input(touch)
	return result

func debug_mobile_sprint_button_visible() -> bool:
	return _mobile_sprint_button != null and _mobile_sprint_button.visible

func debug_mobile_crouch_button_visible() -> bool:
	return _mobile_crouch_button != null and _mobile_crouch_button.visible

func debug_mobile_settings_button_visible() -> bool:
	return _mobile_settings_button != null and _mobile_settings_button.visible

func debug_toggle_mobile_settings() -> void:
	_toggle_mobile_settings_panel()

func debug_mobile_settings_panel_visible() -> bool:
	return _mobile_settings_panel != null and _mobile_settings_panel.visible

func debug_get_mobile_sprint_button_rect() -> Rect2:
	return _mobile_sprint_button.get_global_rect() if _mobile_sprint_button != null else Rect2()

func debug_get_mobile_crouch_button_rect() -> Rect2:
	return _mobile_crouch_button.get_global_rect() if _mobile_crouch_button != null else Rect2()

func debug_get_mobile_settings_button_rect() -> Rect2:
	return _mobile_settings_button.get_global_rect() if _mobile_settings_button != null else Rect2()

func debug_mobile_touch_handled(event: InputEvent) -> bool:
	return _handle_mobile_control_input(event)

func debug_is_mobile_sprint_pressed() -> bool:
	return _mobile_sprint_pressed

func debug_toggle_mobile_crouch() -> void:
	_toggle_mobile_crouch()

func debug_set_mobile_crouch(value: bool) -> void:
	_mobile_crouch_toggled = value
	if _mobile_crouch_button != null:
		_mobile_crouch_button.text = "站起" if _mobile_crouch_toggled else "蹲下"

	if _mobile_crouch_button != null:
		_mobile_crouch_button.text = "站起" if _mobile_crouch_toggled else "蹲下"

func debug_set_escape_key(value: bool) -> void:
	_has_escape_key = value
	set_meta("has_escape_key", _has_escape_key)

func debug_has_escape_key() -> bool:
	return _has_escape_key

func debug_get_health() -> float:
	return _health

func debug_get_max_health() -> float:
	return max_health

func debug_get_stamina() -> float:
	return _stamina

func debug_set_stamina(value: float) -> void:
	_stamina = clampf(value, 0.0, max_stamina)
	_stamina_exhausted = _stamina <= 0.0
	set_meta("stamina", _stamina)
	_update_stamina_bar()

func debug_update_stamina(delta: float, sprinting: bool) -> void:
	_update_stamina(delta, sprinting)

func debug_is_sprinting() -> bool:
	return _is_sprinting()

func debug_has_stamina_bar() -> bool:
	return _stamina_bar != null and _stamina_label != null

func debug_has_health_bar() -> bool:
	return _health_bar != null and _health_label != null

func debug_has_game_over() -> bool:
	return _game_over_layer != null and bool(get_meta("game_over", false))

func debug_is_hidden_from_monsters() -> bool:
	return is_hidden_from_monsters()

func debug_set_health(value: float) -> void:
	var was_dead := _dead
	_health = clampf(value, 0.0, max_health)
	_dead = _health <= 0.0
	set_meta("health", _health)
	set_meta("dead", _dead)
	_update_health_bar()
	if _dead:
		_die(null)
	elif was_dead:
		_hide_game_over()

func has_escape_key() -> bool:
	return _has_escape_key

func receive_damage(amount: float, attacker: Node = null) -> void:
	if _dead:
		return
	if _hidden_in_hideable:
		set_meta("blocked_damage_while_hidden_count", int(get_meta("blocked_damage_while_hidden_count", 0)) + 1)
		return
	if bool(get_meta("mvp_player_immortal", false)) or bool(get_meta("debug_immortal", false)):
		set_meta("blocked_damage_count", int(get_meta("blocked_damage_count", 0)) + 1)
		set_meta("last_blocked_damage", maxf(amount, 0.0))
		if attacker != null:
			set_meta("last_damage_attacker", attacker.name)
		return
	_health = maxf(_health - maxf(amount, 0.0), 0.0)
	set_meta("health", _health)
	if attacker != null:
		set_meta("last_damage_attacker", attacker.name)
	_update_health_bar()
	if _health <= 0.0:
		_die(attacker)

func heal(amount: float) -> void:
	if amount <= 0.0 or _dead:
		return
	_health = minf(_health + amount, max_health)
	set_meta("health", _health)
	_update_health_bar()

func is_dead() -> bool:
	return _dead

func set_hidden_in_hideable(hidden: bool, hideable: Node = null) -> void:
	var changed := _hidden_in_hideable != hidden or _current_hideable != hideable
	_hidden_in_hideable = hidden
	_current_hideable = hideable if hidden else null
	set_meta("hidden_from_monsters", _hidden_in_hideable)
	if _hidden_in_hideable:
		_movement_velocity = Vector3.ZERO
		velocity = Vector3.ZERO
		_mobile_sprint_pressed = false
		_notify_monsters_forget_player()
	elif changed:
		set_meta("hidden_from_monsters", false)

func is_hidden_from_monsters() -> bool:
	return _hidden_in_hideable

func get_current_hideable() -> Node:
	return _current_hideable

func is_making_footstep_noise() -> bool:
	return _is_making_footstep_noise()

func get_footstep_noise_radius() -> float:
	if _hidden_in_hideable:
		return 0.0
	if _is_crouching():
		return crouch_footstep_noise_radius
	if not _is_making_footstep_noise():
		return 0.0
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	return run_footstep_noise_radius if horizontal_speed >= footstep_sprint_speed_threshold else walk_footstep_noise_radius

func is_crouching() -> bool:
	return _is_crouching()

func get_detection_target_height() -> float:
	if _hidden_in_hideable:
		return 0.05
	return crouch_detection_target_height if _is_crouching() else standing_detection_target_height

func debug_is_making_footstep_noise() -> bool:
	return is_making_footstep_noise()

func debug_get_footstep_noise_radius() -> float:
	return get_footstep_noise_radius()

func debug_is_crouching() -> bool:
	return _is_crouching()

func debug_get_crouch_visual_amount() -> float:
	return _crouch_visual_amount

func debug_get_visual_root_scale() -> Vector3:
	var visual_root := get_node_or_null(visual_root_path) as Node3D
	if visual_root == null:
		return Vector3.ZERO
	return visual_root.scale

func debug_get_visual_root_rotation_x() -> float:
	var visual_root := get_node_or_null(visual_root_path) as Node3D
	if visual_root == null:
		return 0.0
	return visual_root.rotation.x

func debug_get_crouch_bone_pose_summary() -> Dictionary:
	var result := {
		"has_skeleton": _skeleton != null,
		"bone_count": _crouch_bone_indices.size(),
	}
	for key in _crouch_bone_indices.keys():
		if _skeleton == null:
			continue
		var bone_index := int(_crouch_bone_indices[key])
		result["%s_position" % key] = _skeleton.get_bone_pose_position(bone_index)
		result["%s_rotation" % key] = _skeleton.get_bone_pose_rotation(bone_index)
	return result

func debug_get_collision_height() -> float:
	return _collision_capsule.height if _collision_capsule != null else 0.0

func debug_get_collision_center_y() -> float:
	return _collision_shape.position.y if _collision_shape != null else 0.0

func collect_escape_key(source: Node = null) -> void:
	if _has_escape_key:
		return
	_has_escape_key = true
	set_meta("has_escape_key", true)
	_play_one_shot(_key_pickup_player)
	if source != null and source.is_inside_tree():
		source.set_meta("collected", true)
		source.queue_free()

func _die(attacker: Node = null) -> void:
	_dead = true
	_health = 0.0
	_movement_velocity = Vector3.ZERO
	velocity = Vector3.ZERO
	set_meta("dead", true)
	set_meta("health", _health)
	set_meta("game_over", true)
	if attacker != null:
		set_meta("killed_by", attacker.name)
	_play_idle_or_stop()
	_update_health_bar()
	_notify_monsters_forget_player()
	_show_game_over(attacker)

func set_interaction_locked(locked: bool) -> void:
	_interaction_locked = locked
	if locked:
		_movement_velocity = Vector3.ZERO
		velocity = Vector3.ZERO
		_play_idle_or_stop()

func is_interaction_locked() -> bool:
	return _interaction_locked

func _perform_interaction() -> bool:
	if _dead:
		return false
	if _interaction_locked:
		return false
	if _try_collect_escape_key(true):
		_update_interaction_button()
		return true
	if _try_interact_with_hideable():
		_update_interaction_button()
		return true
	if _try_interact_with_door():
		_update_interaction_button()
		return true
	return false

func _try_collect_escape_key(require_prompt_range: bool) -> bool:
	var key := _find_best_escape_key()
	if key == null:
		return false
	if require_prompt_range:
		var to_key := key.global_position - global_position
		to_key.y = 0.0
		if to_key.length() > escape_key_pickup_distance:
			return false
	collect_escape_key(key)
	return true

func _find_best_escape_key() -> Node3D:
	if _has_escape_key:
		return null
	var best_key: Node3D = null
	var best_distance := INF
	for node in get_tree().get_nodes_in_group("escape_key_pickup"):
		var key := node as Node3D
		if key == null or bool(key.get_meta("collected", false)):
			continue
		var distance := global_position.distance_to(key.global_position)
		if distance > escape_key_pickup_distance:
			continue
		if distance < best_distance:
			best_distance = distance
			best_key = key
	return best_key

func _try_interact_with_hideable() -> bool:
	var best_hideable := _find_best_hideable()
	if best_hideable == null:
		return false
	best_hideable.call("interact_from", self, _get_interaction_facing_direction())
	return true

func _find_best_hideable() -> Node3D:
	var facing_direction := _get_interaction_facing_direction()
	if facing_direction.length_squared() <= 0.0001:
		return null
	var best_hideable: Node3D = null
	var best_distance := INF
	for node in get_tree().get_nodes_in_group("interactive_hideable"):
		var hideable := node as Node3D
		if hideable == null or not hideable.has_method("interact_from"):
			continue
		if hideable.has_method("can_interact_from"):
			if bool(hideable.call("can_interact_from", self, facing_direction, hideable_interact_distance)):
				var component_distance := global_position.distance_to(hideable.global_position)
				if component_distance < best_distance:
					best_distance = component_distance
					best_hideable = hideable
			continue
		var interaction_position := hideable.global_position
		if hideable.has_method("get_interaction_position"):
			var value: Variant = hideable.call("get_interaction_position")
			if value is Vector3:
				interaction_position = value
		var to_hideable := interaction_position - global_position
		to_hideable.y = 0.0
		var distance := to_hideable.length()
		if distance > hideable_interact_distance:
			continue
		if distance > 0.15 and to_hideable.normalized().dot(facing_direction) < hideable_interact_facing_dot:
			continue
		if distance < best_distance:
			best_distance = distance
			best_hideable = hideable
	return best_hideable

func _try_interact_with_door() -> bool:
	var best_door := _find_best_door()
	if best_door == null:
		return false
	best_door.call("interact_from", self, _get_interaction_facing_direction())
	return true

func _find_best_door() -> Node3D:
	var facing_direction := _get_interaction_facing_direction()
	if facing_direction.length_squared() <= 0.0001:
		return null
	var best_door: Node3D = null
	var best_distance := INF
	for node in get_tree().get_nodes_in_group("interactive_door"):
		var door := node as Node3D
		if door == null or not door.has_method("interact_from"):
			continue
		var to_door := door.global_position - global_position
		to_door.y = 0.0
		var distance := to_door.length()
		if distance > door_interact_distance:
			continue
		if distance > 0.15 and to_door.normalized().dot(facing_direction) < door_interact_facing_dot:
			continue
		if distance < best_distance:
			best_distance = distance
			best_door = door
	return best_door

func _create_health_bar() -> void:
	if not show_health_bar or _health_layer != null:
		return
	_health_layer = CanvasLayer.new()
	_health_layer.name = "PlayerHealthLayer"
	_health_layer.layer = 85
	add_child(_health_layer)

	var panel := PanelContainer.new()
	panel.name = "HealthPanel"
	panel.anchor_left = 0.0
	panel.anchor_top = 0.0
	panel.anchor_right = 0.0
	panel.anchor_bottom = 0.0
	panel.offset_left = 16.0
	panel.offset_top = 14.0
	panel.offset_right = 236.0
	panel.offset_bottom = 86.0 if show_stamina_bar else 62.0
	panel.add_theme_stylebox_override("panel", _make_interaction_button_style(Color(0.045, 0.040, 0.032, 0.78), Color(0.45, 0.36, 0.22, 0.88)))
	_health_layer.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	margin.add_child(box)

	_health_label = Label.new()
	_health_label.text = "生命 100/100"
	_health_label.add_theme_font_size_override("font_size", 14)
	_health_label.add_theme_color_override("font_color", Color(0.98, 0.91, 0.76, 1.0))
	box.add_child(_health_label)

	_health_bar = ProgressBar.new()
	_health_bar.min_value = 0.0
	_health_bar.max_value = max_health
	_health_bar.value = _health
	_health_bar.show_percentage = false
	_health_bar.custom_minimum_size = Vector2(198.0, 14.0)
	_health_bar.add_theme_stylebox_override("background", _make_health_bar_style(Color(0.12, 0.025, 0.022, 0.92), Color(0.34, 0.16, 0.10, 0.95)))
	_health_bar.add_theme_stylebox_override("fill", _make_health_bar_style(Color(0.78, 0.08, 0.055, 0.96), Color(0.95, 0.36, 0.22, 1.0)))
	box.add_child(_health_bar)
	if show_stamina_bar:
		_stamina_label = Label.new()
		_stamina_label.text = "体力 100/100"
		_stamina_label.add_theme_font_size_override("font_size", 13)
		_stamina_label.add_theme_color_override("font_color", Color(0.82, 0.91, 1.0, 1.0))
		box.add_child(_stamina_label)

		_stamina_bar = ProgressBar.new()
		_stamina_bar.min_value = 0.0
		_stamina_bar.max_value = max_stamina
		_stamina_bar.value = _stamina
		_stamina_bar.show_percentage = false
		_stamina_bar.custom_minimum_size = Vector2(198.0, 12.0)
		_stamina_bar.add_theme_stylebox_override("background", _make_health_bar_style(Color(0.020, 0.036, 0.050, 0.92), Color(0.10, 0.18, 0.24, 0.95)))
		_stamina_bar.add_theme_stylebox_override("fill", _make_health_bar_style(Color(0.08, 0.48, 0.88, 0.96), Color(0.36, 0.72, 1.0, 1.0)))
		box.add_child(_stamina_bar)
	_update_health_bar()

func _make_health_bar_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	return style

func _update_health_bar() -> void:
	if _health_bar == null or _health_label == null:
		return
	_health_bar.max_value = max_health
	_health_bar.value = clampf(_health, 0.0, max_health)
	_health_label.text = "生命 %.0f/%.0f" % [_health, max_health]
	if _health <= max_health * 0.25:
		_health_bar.add_theme_stylebox_override("fill", _make_health_bar_style(Color(0.92, 0.05, 0.035, 0.98), Color(1.0, 0.25, 0.18, 1.0)))
	elif _health <= max_health * 0.55:
		_health_bar.add_theme_stylebox_override("fill", _make_health_bar_style(Color(0.86, 0.42, 0.08, 0.98), Color(1.0, 0.68, 0.24, 1.0)))
	else:
		_health_bar.add_theme_stylebox_override("fill", _make_health_bar_style(Color(0.78, 0.08, 0.055, 0.96), Color(0.95, 0.36, 0.22, 1.0)))
	_update_stamina_bar()

func _update_stamina_bar() -> void:
	if _stamina_bar == null or _stamina_label == null:
		return
	_stamina_bar.max_value = max_stamina
	_stamina_bar.value = clampf(_stamina, 0.0, max_stamina)
	_stamina_label.text = "体力 %.0f/%.0f" % [_stamina, max_stamina]
	if _stamina_exhausted:
		_stamina_bar.add_theme_stylebox_override("fill", _make_health_bar_style(Color(0.46, 0.48, 0.50, 0.96), Color(0.72, 0.76, 0.80, 1.0)))
	elif _stamina <= max_stamina * 0.25:
		_stamina_bar.add_theme_stylebox_override("fill", _make_health_bar_style(Color(0.10, 0.34, 0.62, 0.96), Color(0.30, 0.58, 0.86, 1.0)))
	else:
		_stamina_bar.add_theme_stylebox_override("fill", _make_health_bar_style(Color(0.08, 0.48, 0.88, 0.96), Color(0.36, 0.72, 1.0, 1.0)))

func _create_interaction_button() -> void:
	if not show_interaction_button or _interaction_prompt_layer != null:
		return
	_interaction_prompt_layer = CanvasLayer.new()
	_interaction_prompt_layer.name = "InteractionPromptLayer"
	_interaction_prompt_layer.layer = 70
	add_child(_interaction_prompt_layer)

	_interaction_button = Button.new()
	_interaction_button.name = "InteractButton"
	_interaction_button.text = "E 互动"
	_interaction_button.visible = false
	_interaction_button.focus_mode = Control.FOCUS_NONE
	_interaction_button.custom_minimum_size = Vector2(136.0, 52.0)
	_interaction_button.anchor_left = 0.5
	_interaction_button.anchor_top = 1.0
	_interaction_button.anchor_right = 0.5
	_interaction_button.anchor_bottom = 1.0
	_interaction_button.offset_left = -68.0
	_interaction_button.offset_top = -92.0
	_interaction_button.offset_right = 68.0
	_interaction_button.offset_bottom = -40.0
	_interaction_button.add_theme_font_size_override("font_size", 20)
	_interaction_button.add_theme_color_override("font_color", Color(0.96, 0.90, 0.72, 1.0))
	_interaction_button.add_theme_color_override("font_hover_color", Color(1.0, 0.96, 0.80, 1.0))
	_interaction_button.add_theme_color_override("font_pressed_color", Color(1.0, 0.88, 0.52, 1.0))
	_interaction_button.add_theme_stylebox_override("normal", _make_interaction_button_style(Color(0.075, 0.070, 0.052, 0.86), Color(0.62, 0.53, 0.28, 0.90)))
	_interaction_button.add_theme_stylebox_override("hover", _make_interaction_button_style(Color(0.105, 0.095, 0.065, 0.92), Color(0.78, 0.66, 0.34, 1.0)))
	_interaction_button.add_theme_stylebox_override("pressed", _make_interaction_button_style(Color(0.145, 0.118, 0.058, 0.95), Color(0.92, 0.73, 0.28, 1.0)))
	_interaction_button.pressed.connect(_on_interaction_button_pressed)
	_interaction_prompt_layer.add_child(_interaction_button)

func _make_interaction_button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style

func _create_mobile_controls() -> void:
	if _mobile_controls_layer != null or not _should_show_mobile_controls():
		return
	_mobile_controls_layer = CanvasLayer.new()
	_mobile_controls_layer.name = "MobileControlsLayer"
	_mobile_controls_layer.layer = 60
	add_child(_mobile_controls_layer)
	_load_mobile_preferences()

	_mobile_stick_base = Panel.new()
	_mobile_stick_base.name = "MoveStickBase"
	_mobile_stick_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mobile_stick_base.add_theme_stylebox_override("panel", _make_round_panel_style(Color(0.04, 0.04, 0.035, 0.42), Color(0.96, 0.90, 0.72, 0.48), mobile_joystick_radius))
	_mobile_controls_layer.add_child(_mobile_stick_base)

	_mobile_stick_knob = Panel.new()
	_mobile_stick_knob.name = "MoveStickKnob"
	_mobile_stick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mobile_stick_knob.add_theme_stylebox_override("panel", _make_round_panel_style(Color(0.92, 0.86, 0.65, 0.62), Color(1.0, 0.94, 0.72, 0.72), mobile_joystick_radius * 0.36))
	_mobile_controls_layer.add_child(_mobile_stick_knob)

	_mobile_sprint_button = Button.new()
	_mobile_sprint_button.name = "SprintButton"
	_mobile_sprint_button.text = "跑步"
	_mobile_sprint_button.focus_mode = Control.FOCUS_NONE
	_mobile_sprint_button.text = "跑步"
	_mobile_sprint_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mobile_sprint_button.custom_minimum_size = _current_mobile_action_button_size()
	_mobile_sprint_button.add_theme_font_size_override("font_size", 28)
	_mobile_sprint_button.add_theme_color_override("font_color", Color(0.98, 0.92, 0.72, 1.0))
	_mobile_sprint_button.add_theme_stylebox_override("normal", _make_interaction_button_style(Color(0.075, 0.070, 0.052, 0.72), Color(0.62, 0.53, 0.28, 0.82)))
	_mobile_sprint_button.add_theme_stylebox_override("hover", _make_interaction_button_style(Color(0.105, 0.095, 0.065, 0.86), Color(0.78, 0.66, 0.34, 0.96)))
	_mobile_sprint_button.add_theme_stylebox_override("pressed", _make_interaction_button_style(Color(0.16, 0.11, 0.045, 0.94), Color(0.94, 0.73, 0.24, 1.0)))
	_mobile_sprint_button.button_down.connect(func() -> void: _mobile_sprint_pressed = true)
	_mobile_sprint_button.button_up.connect(func() -> void: _mobile_sprint_pressed = false)
	_mobile_controls_layer.add_child(_mobile_sprint_button)

	_mobile_crouch_button = Button.new()
	_mobile_crouch_button.name = "CrouchButton"
	_mobile_crouch_button.text = "蹲下"
	_mobile_crouch_button.focus_mode = Control.FOCUS_NONE
	_mobile_crouch_button.text = "蹲下"
	_mobile_crouch_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mobile_crouch_button.custom_minimum_size = _current_mobile_action_button_size()
	_mobile_crouch_button.add_theme_font_size_override("font_size", 28)
	_mobile_crouch_button.add_theme_color_override("font_color", Color(0.82, 0.95, 0.88, 1.0))
	_mobile_crouch_button.add_theme_stylebox_override("normal", _make_interaction_button_style(Color(0.045, 0.070, 0.058, 0.72), Color(0.30, 0.58, 0.42, 0.82)))
	_mobile_crouch_button.add_theme_stylebox_override("hover", _make_interaction_button_style(Color(0.060, 0.096, 0.075, 0.86), Color(0.42, 0.72, 0.54, 0.96)))
	_mobile_crouch_button.add_theme_stylebox_override("pressed", _make_interaction_button_style(Color(0.035, 0.130, 0.083, 0.94), Color(0.46, 0.90, 0.60, 1.0)))
	_mobile_crouch_button.pressed.connect(_toggle_mobile_crouch)
	_mobile_controls_layer.add_child(_mobile_crouch_button)

	_mobile_settings_button = Button.new()
	_mobile_settings_button.name = "MobileSettingsButton"
	_mobile_settings_button.text = "设置"
	_mobile_settings_button.focus_mode = Control.FOCUS_NONE
	_mobile_settings_button.custom_minimum_size = mobile_settings_button_size
	_mobile_settings_button.add_theme_font_size_override("font_size", 22)
	_mobile_settings_button.add_theme_color_override("font_color", Color(0.96, 0.90, 0.72, 1.0))
	_mobile_settings_button.add_theme_stylebox_override("normal", _make_interaction_button_style(Color(0.050, 0.047, 0.038, 0.78), Color(0.52, 0.46, 0.30, 0.88)))
	_mobile_settings_button.add_theme_stylebox_override("hover", _make_interaction_button_style(Color(0.075, 0.070, 0.052, 0.90), Color(0.70, 0.60, 0.36, 0.96)))
	_mobile_settings_button.add_theme_stylebox_override("pressed", _make_interaction_button_style(Color(0.110, 0.090, 0.048, 0.96), Color(0.92, 0.73, 0.28, 1.0)))
	_mobile_settings_button.pressed.connect(_toggle_mobile_settings_panel)
	_mobile_controls_layer.add_child(_mobile_settings_button)

	_create_mobile_settings_panel()
	_apply_mobile_graphics_preferences()

	if not get_viewport().size_changed.is_connected(_position_mobile_controls):
		get_viewport().size_changed.connect(_position_mobile_controls)
	_position_mobile_controls()
	_update_mobile_controls_visibility()

func _make_round_panel_style(fill: Color, border: Color, radius: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(int(radius))
	return style

func _current_mobile_action_button_size() -> Vector2:
	return mobile_action_button_size * clampf(_mobile_button_scale, 0.75, 1.35)

func _create_mobile_settings_panel() -> void:
	if _mobile_controls_layer == null or _mobile_settings_panel != null:
		return
	_mobile_settings_panel = PanelContainer.new()
	_mobile_settings_panel.name = "MobileSettingsPanel"
	_mobile_settings_panel.visible = false
	_mobile_settings_panel.custom_minimum_size = Vector2(430.0, 350.0)
	_mobile_settings_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_mobile_settings_panel.add_theme_stylebox_override("panel", _make_interaction_button_style(Color(0.035, 0.033, 0.027, 0.94), Color(0.58, 0.50, 0.30, 0.95)))
	_mobile_controls_layer.add_child(_mobile_settings_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	_mobile_settings_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	var title := Label.new()
	title.text = "手机设置"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.98, 0.92, 0.72, 1.0))
	box.add_child(title)

	_add_mobile_settings_slider(box, "画质", 65.0, 100.0, 5.0, _mobile_render_scale * 100.0, "%", func(value: float) -> void:
		_mobile_render_scale = clampf(value / 100.0, 0.65, 1.0)
		_apply_mobile_graphics_preferences()
		_save_mobile_preferences()
	)
	_add_mobile_settings_slider(box, "视角灵敏度", 50.0, 180.0, 5.0, _mobile_touch_sensitivity_multiplier * 100.0, "%", func(value: float) -> void:
		_mobile_touch_sensitivity_multiplier = clampf(value / 100.0, 0.5, 1.8)
		_apply_mobile_graphics_preferences()
		_save_mobile_preferences()
	)
	_add_mobile_settings_slider(box, "镜头距离", 140.0, 240.0, 5.0, _mobile_camera_distance * 100.0, "%", func(value: float) -> void:
		_mobile_camera_distance = clampf(value / 100.0, 1.4, 2.4)
		_apply_mobile_graphics_preferences()
		_save_mobile_preferences()
	)
	_add_mobile_settings_slider(box, "按钮大小", 85.0, 125.0, 5.0, _mobile_button_scale * 100.0, "%", func(value: float) -> void:
		_mobile_button_scale = clampf(value / 100.0, 0.85, 1.25)
		_position_mobile_controls()
		_save_mobile_preferences()
	)

	var hint := Label.new()
	hint.text = "打开本面板时，可直接拖动摇杆、跑步、蹲下按钮。"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(0.84, 0.82, 0.70, 1.0))
	box.add_child(hint)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)

	var reset_button := _make_mobile_settings_panel_button("重置按钮")
	reset_button.pressed.connect(_reset_mobile_control_positions)
	row.add_child(reset_button)

	var close_button := _make_mobile_settings_panel_button("关闭")
	close_button.pressed.connect(_toggle_mobile_settings_panel)
	row.add_child(close_button)

	_position_mobile_settings_panel()

func _make_mobile_settings_panel_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(138.0, 48.0)
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color(0.96, 0.90, 0.72, 1.0))
	button.add_theme_stylebox_override("normal", _make_interaction_button_style(Color(0.060, 0.055, 0.045, 0.88), Color(0.52, 0.46, 0.30, 0.96)))
	button.add_theme_stylebox_override("pressed", _make_interaction_button_style(Color(0.110, 0.090, 0.048, 0.96), Color(0.92, 0.73, 0.28, 1.0)))
	return button

func _add_mobile_settings_slider(parent: Control, title: String, min_value: float, max_value: float, step: float, value: float, suffix: String, callback: Callable) -> void:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	parent.add_child(row)

	var label := Label.new()
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.92, 0.88, 0.72, 1.0))
	row.add_child(label)

	var slider := HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.value = clampf(value, min_value, max_value)
	slider.custom_minimum_size = Vector2(380.0, 28.0)
	row.add_child(slider)

	var update_label := func(current: float) -> void:
		label.text = "%s %.0f%s" % [title, current, suffix]
	update_label.call(slider.value)
	slider.value_changed.connect(func(current: float) -> void:
		update_label.call(current)
		callback.call(current)
	)

func _toggle_mobile_settings_panel() -> void:
	_mobile_settings_open = not _mobile_settings_open
	if _mobile_settings_panel != null:
		_mobile_settings_panel.visible = _mobile_settings_open and _mobile_controls_layer != null and _mobile_controls_layer.visible
	_mobile_customize_controls = _mobile_settings_open
	if _mobile_settings_button != null:
		_mobile_settings_button.text = "关闭" if _mobile_settings_open else "设置"
	_position_mobile_settings_panel()

func _position_mobile_settings_panel() -> void:
	if _mobile_settings_panel == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var panel_size := Vector2(430.0, 350.0)
	_mobile_settings_panel.size = panel_size
	_mobile_settings_panel.position = Vector2(
		clampf(viewport_size.x * 0.5 - panel_size.x * 0.5, 24.0, maxf(24.0, viewport_size.x - panel_size.x - 24.0)),
		clampf(78.0, 24.0, maxf(24.0, viewport_size.y - panel_size.y - 24.0))
	)

func _apply_mobile_graphics_preferences() -> void:
	var viewport := get_viewport()
	if viewport != null:
		viewport.scaling_3d_scale = clampf(_mobile_render_scale, 0.65, 1.0)
	var camera_rig := get_node_or_null(camera_rig_path)
	if camera_rig != null:
		camera_rig.set("distance", _mobile_camera_distance)
		camera_rig.set("touch_sensitivity", 0.004 * _mobile_touch_sensitivity_multiplier)

func _load_mobile_preferences() -> void:
	var config := ConfigFile.new()
	if config.load(MOBILE_PREFS_PATH) != OK:
		_mobile_render_scale = 1.0
		_mobile_camera_distance = 1.8
		_mobile_touch_sensitivity_multiplier = 1.0
		_mobile_button_scale = 1.0
		return
	_mobile_render_scale = clampf(float(config.get_value("graphics", "render_scale", 1.0)), 0.65, 1.0)
	_mobile_camera_distance = clampf(float(config.get_value("graphics", "camera_distance", 1.8)), 1.4, 2.4)
	_mobile_touch_sensitivity_multiplier = clampf(float(config.get_value("graphics", "touch_sensitivity_multiplier", 1.0)), 0.5, 1.8)
	_mobile_button_scale = clampf(float(config.get_value("controls", "button_scale", 1.0)), 0.85, 1.25)
	if bool(config.get_value("controls", "has_stick_center", false)):
		_mobile_stick_center = config.get_value("controls", "stick_center", _mobile_stick_center) as Vector2
		_has_mobile_stick_position = true
	if bool(config.get_value("controls", "has_sprint_position", false)):
		_mobile_sprint_button_position = config.get_value("controls", "sprint_position", _mobile_sprint_button_position) as Vector2
		_has_mobile_sprint_button_position = true
	if bool(config.get_value("controls", "has_crouch_position", false)):
		_mobile_crouch_button_position = config.get_value("controls", "crouch_position", _mobile_crouch_button_position) as Vector2
		_has_mobile_crouch_button_position = true
	if bool(config.get_value("controls", "has_settings_position", false)):
		_mobile_settings_button_position = config.get_value("controls", "settings_position", _mobile_settings_button_position) as Vector2
		_has_mobile_settings_button_position = true

func _save_mobile_preferences() -> void:
	var config := ConfigFile.new()
	config.set_value("graphics", "render_scale", _mobile_render_scale)
	config.set_value("graphics", "camera_distance", _mobile_camera_distance)
	config.set_value("graphics", "touch_sensitivity_multiplier", _mobile_touch_sensitivity_multiplier)
	config.set_value("controls", "button_scale", _mobile_button_scale)
	config.set_value("controls", "has_stick_center", _has_mobile_stick_position)
	config.set_value("controls", "stick_center", _mobile_stick_center)
	config.set_value("controls", "has_sprint_position", _has_mobile_sprint_button_position)
	config.set_value("controls", "sprint_position", _mobile_sprint_button_position)
	config.set_value("controls", "has_crouch_position", _has_mobile_crouch_button_position)
	config.set_value("controls", "crouch_position", _mobile_crouch_button_position)
	config.set_value("controls", "has_settings_position", _has_mobile_settings_button_position)
	config.set_value("controls", "settings_position", _mobile_settings_button_position)
	config.save(MOBILE_PREFS_PATH)

func _reset_mobile_control_positions() -> void:
	_has_mobile_stick_position = false
	_has_mobile_sprint_button_position = false
	_has_mobile_crouch_button_position = false
	_has_mobile_settings_button_position = false
	_mobile_button_scale = 1.0
	_position_mobile_controls()
	_save_mobile_preferences()

func _clamp_mobile_control_position(position: Vector2, size: Vector2) -> Vector2:
	var viewport_size := get_viewport().get_visible_rect().size
	return Vector2(
		clampf(position.x, 20.0, maxf(20.0, viewport_size.x - size.x - 20.0)),
		clampf(position.y, 20.0, maxf(20.0, viewport_size.y - size.y - 20.0))
	)

func _clamp_mobile_point(position: Vector2, margin: Vector2) -> Vector2:
	var viewport_size := get_viewport().get_visible_rect().size
	return Vector2(
		clampf(position.x, margin.x, maxf(margin.x, viewport_size.x - margin.x)),
		clampf(position.y, margin.y, maxf(margin.y, viewport_size.y - margin.y))
	)

func _should_show_mobile_controls() -> bool:
	if not show_mobile_controls:
		return false
	if OS.get_environment("FORCE_MOBILE_CONTROLS") == "1":
		return true
	if OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios"):
		return true
	if DisplayServer.is_touchscreen_available():
		return true
	return false

func _update_mobile_controls_visibility() -> void:
	if _mobile_controls_layer == null:
		return
	_mobile_controls_layer.visible = _should_show_mobile_controls() and not _interaction_locked and visible
	if _mobile_sprint_button != null:
		_mobile_sprint_button.visible = _mobile_controls_layer.visible
	if _mobile_crouch_button != null:
		_mobile_crouch_button.visible = _mobile_controls_layer.visible
	if _mobile_settings_button != null:
		_mobile_settings_button.visible = _mobile_controls_layer.visible
	if _mobile_settings_panel != null:
		_mobile_settings_panel.visible = _mobile_controls_layer.visible and _mobile_settings_open

func _position_mobile_controls() -> void:
	if _mobile_stick_base == null or _mobile_stick_knob == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	if not _has_mobile_stick_position:
		_mobile_stick_center = Vector2(
			mobile_joystick_margin.x + mobile_joystick_radius,
			viewport_size.y - mobile_joystick_margin.y - mobile_joystick_radius
		)
	_mobile_stick_center = _clamp_mobile_point(_mobile_stick_center, Vector2.ONE * mobile_joystick_radius)
	var base_size := Vector2.ONE * mobile_joystick_radius * 2.0
	_mobile_stick_base.position = _mobile_stick_center - base_size * 0.5
	_mobile_stick_base.size = base_size
	if _mobile_sprint_button != null:
		var button_size := _current_mobile_action_button_size()
		_mobile_sprint_button.size = button_size
		if not _has_mobile_sprint_button_position:
			_mobile_sprint_button_position = Vector2(
				viewport_size.x - button_size.x - mobile_action_button_right_margin,
				viewport_size.y - button_size.y - mobile_action_button_bottom_margin - button_size.y - mobile_action_button_gap
			)
		_mobile_sprint_button_position = _clamp_mobile_control_position(_mobile_sprint_button_position, button_size)
		_mobile_sprint_button.position = _mobile_sprint_button_position
	if _mobile_crouch_button != null:
		var button_size := _current_mobile_action_button_size()
		_mobile_crouch_button.size = button_size
		if not _has_mobile_crouch_button_position:
			_mobile_crouch_button_position = Vector2(
				viewport_size.x - button_size.x - mobile_action_button_right_margin,
				viewport_size.y - button_size.y - mobile_action_button_bottom_margin
			)
		_mobile_crouch_button_position = _clamp_mobile_control_position(_mobile_crouch_button_position, button_size)
		_mobile_crouch_button.position = _mobile_crouch_button_position
	if _mobile_settings_button != null:
		var settings_size := mobile_settings_button_size
		_mobile_settings_button.size = settings_size
		if not _has_mobile_settings_button_position:
			_mobile_settings_button_position = Vector2(
				viewport_size.x - settings_size.x - mobile_settings_button_margin.x,
				mobile_settings_button_margin.y
			)
		_mobile_settings_button_position = _clamp_mobile_control_position(_mobile_settings_button_position, settings_size)
		_mobile_settings_button.position = _mobile_settings_button_position
	_position_mobile_settings_panel()
	_update_mobile_stick_knob()

func _handle_mobile_control_input(event: InputEvent) -> bool:
	if not _should_show_mobile_controls() or _interaction_locked:
		return false
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and _mobile_settings_open and mobile_control_drag_enabled and _try_begin_mobile_control_drag(touch.index, touch.position):
			get_viewport().set_input_as_handled()
			return true
		if not touch.pressed and touch.index == _mobile_drag_touch_index:
			_finish_mobile_control_drag()
			get_viewport().set_input_as_handled()
			return true
		if _mobile_settings_open and _is_point_in_control(_mobile_settings_panel, touch.position):
			return false
		if touch.pressed and _is_point_in_control(_mobile_sprint_button, touch.position):
			_mobile_sprint_touch_index = touch.index
			_mobile_sprint_pressed = true
			return false
		if not touch.pressed and touch.index == _mobile_sprint_touch_index:
			_mobile_sprint_touch_index = -1
			_mobile_sprint_pressed = false
			return false
		if touch.pressed and _is_point_in_control(_mobile_crouch_button, touch.position):
			_toggle_mobile_crouch()
			get_viewport().set_input_as_handled()
			return true
		if touch.pressed and _mobile_touch_index == -1 and _is_mobile_stick_start(touch.position):
			_mobile_touch_index = touch.index
			_update_mobile_move_vector(touch.position)
			get_viewport().set_input_as_handled()
			return true
		if not touch.pressed and touch.index == _mobile_touch_index:
			_mobile_touch_index = -1
			_mobile_move_vector = Vector2.ZERO
			_update_mobile_stick_knob()
			get_viewport().set_input_as_handled()
			return true
	if event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _mobile_drag_touch_index:
			_update_mobile_control_drag(drag.position)
			get_viewport().set_input_as_handled()
			return true
		if _mobile_settings_open and _is_point_in_control(_mobile_settings_panel, drag.position):
			return false
		if drag.index == _mobile_sprint_touch_index:
			_mobile_sprint_pressed = true
			return false
		if drag.index == _mobile_touch_index:
			_update_mobile_move_vector(drag.position)
			get_viewport().set_input_as_handled()
			return true
	return false

func _is_point_in_control(control: Control, position: Vector2) -> bool:
	if control == null or not control.visible:
		return false
	return control.get_global_rect().has_point(position)

func _try_begin_mobile_control_drag(touch_index: int, position: Vector2) -> bool:
	if _is_point_in_control(_mobile_sprint_button, position):
		_mobile_drag_touch_index = touch_index
		_mobile_drag_target = "sprint"
		_mobile_drag_offset = _mobile_sprint_button.position - position
		return true
	if _is_point_in_control(_mobile_crouch_button, position):
		_mobile_drag_touch_index = touch_index
		_mobile_drag_target = "crouch"
		_mobile_drag_offset = _mobile_crouch_button.position - position
		return true
	if position.distance_to(_mobile_stick_center) <= mobile_joystick_radius * 1.45:
		_mobile_drag_touch_index = touch_index
		_mobile_drag_target = "stick"
		_mobile_drag_offset = _mobile_stick_center - position
		return true
	return false

func _update_mobile_control_drag(position: Vector2) -> void:
	match _mobile_drag_target:
		"sprint":
			_mobile_sprint_button_position = _clamp_mobile_control_position(position + _mobile_drag_offset, _current_mobile_action_button_size())
			_has_mobile_sprint_button_position = true
		"crouch":
			_mobile_crouch_button_position = _clamp_mobile_control_position(position + _mobile_drag_offset, _current_mobile_action_button_size())
			_has_mobile_crouch_button_position = true
		"stick":
			_mobile_stick_center = _clamp_mobile_point(position + _mobile_drag_offset, Vector2.ONE * mobile_joystick_radius)
			_has_mobile_stick_position = true
	_position_mobile_controls()

func _finish_mobile_control_drag() -> void:
	_mobile_drag_touch_index = -1
	_mobile_drag_target = ""
	_mobile_drag_offset = Vector2.ZERO
	_save_mobile_preferences()

func _toggle_mobile_crouch() -> void:
	_mobile_crouch_toggled = not _mobile_crouch_toggled
	if _mobile_crouch_toggled:
		_mobile_sprint_pressed = false
	if _mobile_crouch_button != null:
		_mobile_crouch_button.text = "站起" if _mobile_crouch_toggled else "蹲下"

	if _mobile_crouch_button != null:
		_mobile_crouch_button.text = "站起" if _mobile_crouch_toggled else "蹲下"

func _is_mobile_stick_start(position: Vector2) -> bool:
	var viewport_size := get_viewport().get_visible_rect().size
	var start_radius := maxf(mobile_joystick_radius * mobile_joystick_start_radius_multiplier, 240.0)
	if position.distance_to(_mobile_stick_center) > start_radius:
		return false
	var right_limit := maxf(viewport_size.x * 0.48, _mobile_stick_center.x + start_radius)
	if position.x > right_limit:
		return false
	var top_limit := minf(viewport_size.y * 0.40, _mobile_stick_center.y - start_radius)
	if position.y < top_limit:
		return false
	return true

func _update_mobile_move_vector(position: Vector2) -> void:
	_mobile_move_vector = _get_mobile_move_vector_for_position(position)
	_update_mobile_stick_knob()

func _get_mobile_move_vector_for_position(position: Vector2) -> Vector2:
	var raw := position - _mobile_stick_center
	if raw.length() > mobile_joystick_radius:
		raw = raw.normalized() * mobile_joystick_radius
	return Vector2(raw.x / mobile_joystick_radius, -raw.y / mobile_joystick_radius)

func _update_mobile_stick_knob() -> void:
	if _mobile_stick_knob == null:
		return
	var knob_radius := mobile_joystick_radius * 0.36
	var knob_size := Vector2.ONE * knob_radius * 2.0
	var screen_offset := Vector2(_mobile_move_vector.x, -_mobile_move_vector.y) * mobile_joystick_radius
	_mobile_stick_knob.position = _mobile_stick_center + screen_offset - knob_size * 0.5
	_mobile_stick_knob.size = knob_size

func _update_interaction_button() -> void:
	if _interaction_button == null:
		return
	if _dead or _interaction_locked or not visible:
		_interaction_button.visible = false
		return
	var prompt := _get_interaction_prompt()
	if prompt.is_empty():
		_interaction_button.visible = false
		return
	_interaction_button.text = String(prompt["text"])
	_interaction_button.visible = true

func _get_interaction_prompt() -> Dictionary:
	var key := _find_best_escape_key()
	if key != null:
		return {"node": key, "text": "E 拾钥匙"}
	var hideable := _find_best_hideable()
	if hideable != null:
		return {"node": hideable, "text": "E 进入"}
	var door := _find_best_door()
	if door == null:
		return {}
	if door.has_method("get_interaction_text_for_actor"):
		var text := String(door.call("get_interaction_text_for_actor", self))
		if not text.is_empty():
			return {"node": door, "text": text}
	if door.has_method("is_open") and bool(door.call("is_open")):
		return {"node": door, "text": "E 关门"}
	return {"node": door, "text": "E 开门"}

func _create_player_audio() -> void:
	for path in PLAYER_FOOTSTEP_PATHS:
		var stream := _load_audio_stream(path)
		if stream != null:
			_footstep_streams.append(stream)

	_footstep_player = AudioStreamPlayer3D.new()
	_footstep_player.name = "PlayerFootstepAudio"
	_footstep_player.volume_db = -24.0
	_footstep_player.max_distance = 5.6
	add_child(_footstep_player)

	_breath_player = AudioStreamPlayer.new()
	_breath_player.name = "PlayerBreathAudio"
	_breath_player.stream = _load_audio_stream(PLAYER_BREATH_PATH)
	_breath_player.volume_db = -28.0
	add_child(_breath_player)
	if _breath_player.stream != null:
		_breath_player.play()

	_key_pickup_player = AudioStreamPlayer.new()
	_key_pickup_player.name = "KeyPickupAudio"
	_key_pickup_player.stream = _load_audio_stream(KEY_PICKUP_PATH)
	_key_pickup_player.volume_db = -6.0
	add_child(_key_pickup_player)

func _load_audio_stream(path: String) -> AudioStream:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as AudioStream

func _update_player_audio(delta: float, input_vector: Vector2, sprinting: bool) -> void:
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var moving := input_vector.length_squared() > 0.02 and horizontal_speed > 0.2 and is_on_floor()
	if moving and not _hidden_in_hideable and not _is_crouching() and not _footstep_streams.is_empty():
		_footstep_timer -= delta
		if _footstep_timer <= 0.0:
			_footstep_player.stream = _footstep_streams[_footstep_index % _footstep_streams.size()]
			_footstep_index += 1
			_footstep_player.pitch_scale = 1.01 if sprinting else 0.98
			_play_one_shot(_footstep_player)
			_footstep_timer = run_footstep_interval if sprinting else walk_footstep_interval
	else:
		_footstep_timer = minf(_footstep_timer, 0.05)

	if _breath_player != null:
		var target_volume := -16.0 if sprinting and moving else -28.0
		_breath_player.volume_db = lerpf(_breath_player.volume_db, target_volume, clampf(delta * 2.5, 0.0, 1.0))

func _is_making_footstep_noise() -> bool:
	if _hidden_in_hideable:
		return false
	if _is_crouching():
		return false
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	return horizontal_speed >= footstep_noise_speed_threshold and is_on_floor() and not _interaction_locked

func _notify_monsters_forget_player() -> void:
	if get_tree() == null:
		return
	for node in get_tree().get_nodes_in_group("monster"):
		if node != null and node.has_method("forget_target"):
			node.call("forget_target", self)

func _show_game_over(attacker: Node = null) -> void:
	set_meta("game_over", true)
	if _game_over_layer != null:
		return
	_game_over_layer = CanvasLayer.new()
	_game_over_layer.name = "GameOverLayer"
	_game_over_layer.layer = 120
	_game_over_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_game_over_layer)

	var root_control := Control.new()
	root_control.name = "GameOverRoot"
	root_control.mouse_filter = Control.MOUSE_FILTER_STOP
	root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	_game_over_layer.add_child(root_control)

	var dim := ColorRect.new()
	dim.name = "DimBackground"
	dim.color = Color(0.0, 0.0, 0.0, 0.68)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_control.add_child(dim)

	var panel := PanelContainer.new()
	panel.name = "GameOverPanel"
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -170.0
	panel.offset_top = -96.0
	panel.offset_right = 170.0
	panel.offset_bottom = 96.0
	panel.add_theme_stylebox_override("panel", _make_interaction_button_style(Color(0.045, 0.038, 0.030, 0.94), Color(0.62, 0.46, 0.24, 0.95)))
	root_control.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	var title := Label.new()
	title.name = "Title"
	title.text = "GAME OVER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(1.0, 0.84, 0.56, 1.0))
	box.add_child(title)

	var detail := Label.new()
	detail.name = "Detail"
	detail.text = "Health depleted"
	if attacker != null:
		detail.text = "Killed by %s" % attacker.name
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.add_theme_font_size_override("font_size", 16)
	detail.add_theme_color_override("font_color", Color(0.94, 0.88, 0.72, 1.0))
	box.add_child(detail)

	var restart_button := Button.new()
	restart_button.name = "RestartButton"
	restart_button.text = "Restart"
	restart_button.focus_mode = Control.FOCUS_NONE
	restart_button.custom_minimum_size = Vector2(150.0, 46.0)
	restart_button.add_theme_font_size_override("font_size", 18)
	restart_button.add_theme_color_override("font_color", Color(0.98, 0.92, 0.72, 1.0))
	restart_button.add_theme_stylebox_override("normal", _make_interaction_button_style(Color(0.075, 0.070, 0.052, 0.92), Color(0.62, 0.53, 0.28, 0.96)))
	restart_button.add_theme_stylebox_override("hover", _make_interaction_button_style(Color(0.105, 0.095, 0.065, 0.96), Color(0.78, 0.66, 0.34, 1.0)))
	restart_button.add_theme_stylebox_override("pressed", _make_interaction_button_style(Color(0.145, 0.118, 0.058, 0.98), Color(0.92, 0.73, 0.28, 1.0)))
	restart_button.pressed.connect(_restart_current_scene)
	box.add_child(restart_button)

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _hide_game_over() -> void:
	set_meta("game_over", false)
	if _game_over_layer != null:
		_game_over_layer.queue_free()
		_game_over_layer = null

func _restart_current_scene() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().reload_current_scene()

func _play_one_shot(player: Node) -> void:
	var audio2d := player as AudioStreamPlayer
	if audio2d != null and audio2d.stream != null:
		audio2d.stop()
		audio2d.play()
		return
	var audio3d := player as AudioStreamPlayer3D
	if audio3d != null and audio3d.stream != null:
		audio3d.stop()
		audio3d.play()

func _on_interaction_button_pressed() -> void:
	_perform_interaction()

func _get_interaction_facing_direction() -> Vector3:
	if _has_facing_direction and _facing_direction.length_squared() > 0.0001:
		return _facing_direction.normalized()
	var camera_rig := get_node_or_null(camera_rig_path) as Node3D
	if camera_rig != null:
		var camera_forward := -camera_rig.global_transform.basis.z
		camera_forward.y = 0.0
		if camera_forward.length_squared() > 0.0001:
			return camera_forward.normalized()
	return Vector3.ZERO

func _ensure_input_actions() -> void:
	_add_action_keys("move_forward", [KEY_W, KEY_UP])
	_add_action_keys("move_back", [KEY_S, KEY_DOWN])
	_add_action_keys("move_left", [KEY_A, KEY_LEFT])
	_add_action_keys("move_right", [KEY_D, KEY_RIGHT])
	_add_action_keys("sprint", [KEY_SHIFT])
	_add_action_keys("crouch", [KEY_C])
	_add_action_keys("interact", [KEY_E])

func _add_action_keys(action_name: StringName, keys: Array[int]) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	if not InputMap.action_get_events(action_name).is_empty():
		return
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key as Key
		InputMap.action_add_event(action_name, event)
