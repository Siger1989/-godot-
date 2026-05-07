extends CharacterBody3D

const MonsterSizeSource = preload("res://scripts/monster/MonsterSizeSource.gd")
const ACTOR_LIGHT_LAYER := 1 << 8
const MONSTER_FOOTSTEP_PATHS := [
	"res://assets/audio/monster_footstep_01.wav",
	"res://assets/audio/monster_footstep_02.wav",
]
const MONSTER_ROAR_PATH := "res://assets/audio/monster_roar.wav"
const MONSTER_ATTACK_PATH := "res://assets/audio/monster_attack.wav"
const NIGHTMARE_SONAR_PATH := "res://assets/audio/nightmare_sonar_call.wav"

enum State { WANDER, IDLE_LOOK, FLEE, CHASE, INVESTIGATE, HEARING_ALERT, HEARING_CONFIRM, ATTACK, DEAD }
enum NightmareSurfaceMode { FLOOR, WALL, CEILING }

@export_enum("normal", "red", "nightmare") var monster_role := "normal"
@export var attach_escape_key := false
@export var wander_speed := 1.35
@export var flee_speed := 3.4
@export var chase_speed := 3.25
@export var acceleration := 8.0
@export var flee_acceleration := 40.0
@export var flee_start_speed := 3.1
@export var flee_start_boost_time := 0.4
@export var turn_speed := 7.0
@export var flee_turn_speed := 18.0
@export var gravity := 24.0
@export var vision_distance := 7.0
@export var vision_fov_degrees := 130.0
@export var panic_distance := 3.0
@export var flee_memory_time := 2.4
@export var flee_portal_reach_distance := 0.45
@export var flee_portal_exit_distance := 1.4
@export var flee_repath_interval := 0.45
@export var flee_stuck_repath_time := 0.35
@export var flee_stuck_min_frame_distance := 0.006
@export var eye_height := 0.35
@export var player_target_height := 0.8
@export var wander_min_time := 3.0
@export var wander_max_time := 6.0
@export var wander_cross_room_enabled := true
@export var wander_portal_reach_distance := 0.48
@export var idle_min_time := 0.25
@export var idle_max_time := 0.75
@export var idle_look_degrees := 28.0
@export var max_health := 100.0
@export var red_max_health := 110.0
@export var red_attack_damage := 34.0
@export var nightmare_attack_damage := 30.0
@export var normal_counter_damage := 62.0
@export var attack_range := 0.78
@export var attack_cooldown := 1.1
@export var attack_recovery_time := 0.78
@export var investigate_reach_distance := 0.55
@export var alarm_attraction_reach_distance := 1.05
@export var alarm_portal_reach_distance := 0.48
@export var alarm_repath_interval := 0.35
@export var alarm_stuck_repath_time := 0.32
@export var alarm_stuck_min_frame_distance := 0.006
@export var alarm_attraction_speed_multiplier := 1.08
@export var red_light_flicker_radius := 7.0
@export var red_light_flicker_interval := 0.7
@export var nightmare_walk_hearing_distance := 7.2
@export var nightmare_sprint_hearing_distance := 10.5
@export var nightmare_min_hearing_speed := 0.28
@export var nightmare_sprint_speed_threshold := 3.1
@export var nightmare_hearing_memory_time := 1.65
@export var nightmare_hearing_alert_time := 0.85
@export var nightmare_hearing_confirm_time := 0.65
@export var nightmare_hearing_retrigger_distance := 0.16
@export var nightmare_locked_investigate_speed := 3.35
@export var nightmare_attack_lock_radius := 2.0
@export var nightmare_ceiling_ambush_enabled := true
@export var nightmare_ceiling_trigger_distance := 5.2
@export var nightmare_ceiling_drop_distance := 1.35
@export var nightmare_ceiling_visual_height := 1.72
@export var nightmare_ceiling_visual_lerp_speed := 8.0
@export var nightmare_surface_crawl_enabled := true
@export var nightmare_surface_crawl_animation := "Creature_armature|crawl"
@export var nightmare_surface_crawl_speed := 1.08
@export var nightmare_wall_crawl_probe_distance := 0.82
@export var nightmare_wall_crawl_height := 1.15
@export var monster_walk_footstep_interval := 0.68
@export var monster_run_footstep_interval := 0.42
@export var monster_footstep_volume_db := -21.0
@export var monster_footstep_max_distance := 7.0
@export var monster_roar_volume_db := -8.0
@export var monster_attack_volume_db := -6.0
@export var nightmare_sonar_volume_db := -11.0
@export var nightmare_sonar_max_distance := 13.0
@export var nightmare_sonar_interval_min := 3.2
@export var nightmare_sonar_interval_max := 6.2
@export var animation_blend_time := 0.15
@export var walk_animation_speed := 1.0
@export var run_animation_speed := 1.7
@export var reverse_locomotion_when_backing := true
@export var reverse_locomotion_dot := -0.18
@export var locomotion_animation_speed_min := 0.05
@export var lock_animation_root_motion := true
@export var cast_model_shadows := true
@export var red_role_tint_visual := false
@export var collision_safe_margin := 0.07
@export var floor_snap_distance := 0.28
@export var fall_recover_y := -0.18
@export_node_path("Node3D") var player_path: NodePath = ^"../../PlayerRoot/Player"
@export_node_path("Node3D") var rooms_root_path: NodePath = ^"../../LevelRoot/Areas"
@export_node_path("Node3D") var portals_root_path: NodePath = ^"../../LevelRoot/Portals"
@export_node_path("Node") var lighting_controller_path: NodePath = ^"../../Systems/LightingController"
@export_node_path("AnimationPlayer") var animation_player_path: NodePath = ^"ModelRoot/guai1/AnimationPlayer"
@export var idle_animation := "road_creature_reference_skeleton|Idle"
@export var walk_animation := "road_creature_reference_skeleton|Walk"
@export var run_animation := "road_creature_reference_skeleton|Run"
@export var attack_animation := ""
@export var death_animation := ""

var _rng := RandomNumberGenerator.new()
var _player: Node3D
var _rooms_root: Node3D
var _portals_root: Node3D
var _lighting_controller: Node
var _animation_player: AnimationPlayer
var _state: State = State.WANDER
var _state_timer := 0.0
var _wander_direction := Vector3.FORWARD
var _wander_target_position := Vector3.ZERO
var _has_wander_target := false
var _idle_look_phase := 0.0
var _idle_look_base_yaw := 0.0
var _current_animation := ""
var _current_animation_base_speed := 1.0
var _last_locomotion_forward_dot := 1.0
var _has_flee_route := false
var _flee_route_stage := 0
var _flee_portal_position := Vector3.ZERO
var _flee_exit_position := Vector3.ZERO
var _flee_repath_timer := 0.0
var _flee_stuck_timer := 0.0
var _last_flee_position := Vector3.ZERO
var _has_last_flee_position := false
var _flee_boost_timer := 0.0
var _last_safe_floor_position := Vector3.ZERO
var _has_safe_floor_position := false
var _threat_target: Node3D
var _chase_target: Node3D
var _last_seen_position := Vector3.ZERO
var _has_last_seen_position := false
var _last_heard_position := Vector3.ZERO
var _has_last_heard_position := false
var _alarm_target_position := Vector3.ZERO
var _has_alarm_target := false
var _has_alarm_route := false
var _alarm_route_stage := 0
var _alarm_route_portal_position := Vector3.ZERO
var _alarm_route_exit_position := Vector3.ZERO
var _alarm_route_target_area := ""
var _alarm_repath_timer := 0.0
var _alarm_stuck_timer := 0.0
var _last_alarm_position := Vector3.ZERO
var _has_last_alarm_position := false
var _health := 100.0
var _attack_timer := 0.0
var _red_flicker_timer := 0.0
var _red_counter_attackers: Dictionary = {}
var _footstep_streams: Array[AudioStream] = []
var _footstep_player: AudioStreamPlayer3D
var _roar_player: AudioStreamPlayer3D
var _attack_player: AudioStreamPlayer3D
var _sonar_player: AudioStreamPlayer3D
var _sonar_timer := 0.0
var _footstep_timer := 0.0
var _footstep_index := 0
var _nightmare_model_root: Node3D
var _nightmare_model_base_y := 0.0
var _nightmare_ceiling_visual_offset := 0.0
var _nightmare_ceiling_mode := false
var _nightmare_surface_mode: NightmareSurfaceMode = NightmareSurfaceMode.FLOOR
var _nightmare_surface_normal := Vector3.UP
var _nightmare_surface_contact_position := Vector3.ZERO
var _nightmare_has_surface_contact := false

func _ready() -> void:
	add_to_group("monster")
	add_to_group("living_creature")
	safe_margin = collision_safe_margin
	floor_snap_length = floor_snap_distance
	_health = red_max_health if monster_role == "red" else max_health
	_rng.randomize()
	_remember_safe_floor_position()
	_resolve_player()
	_rooms_root = get_node_or_null(rooms_root_path) as Node3D
	_portals_root = get_node_or_null(portals_root_path) as Node3D
	_lighting_controller = get_node_or_null(lighting_controller_path)
	_animation_player = get_node_or_null(animation_player_path) as AnimationPlayer
	if _animation_player == null:
		_animation_player = _find_animation_player(self)
	_configure_model_shadows(self)
	_configure_role_visuals()
	_create_monster_audio()
	_configure_animations()
	_choose_wander()
	_cache_nightmare_model_root()

func _physics_process(delta: float) -> void:
	if _state == State.DEAD:
		velocity = Vector3.ZERO
		return

	if global_position.y < fall_recover_y:
		_recover_to_last_safe_floor()

	if _player == null:
		_resolve_player()

	_attack_timer = maxf(_attack_timer - delta, 0.0)
	var alarm_override := _update_red_alarm_attraction_state(delta)
	if alarm_override:
		pass
	elif monster_role == "red":
		_update_red_state(delta)
	elif monster_role == "nightmare":
		_update_nightmare_state(delta)
	else:
		_update_normal_state(delta)

	match _state:
		State.FLEE:
			_update_flee(delta)
		State.CHASE:
			_update_chase(delta)
		State.INVESTIGATE:
			_update_investigate(delta)
		State.HEARING_ALERT, State.HEARING_CONFIRM:
			_update_hearing_pause(delta)
		State.ATTACK:
			_update_attack(delta)
		State.WANDER:
			_update_wander(delta)
		State.IDLE_LOOK:
			_update_idle_look(delta)
		State.DEAD:
			velocity = Vector3.ZERO

	_apply_gravity(delta)
	move_and_slide()
	_update_locomotion_animation_direction()
	_update_nightmare_ceiling_ambush(delta)
	_update_monster_audio(delta)
	_update_ground_safety()

	if is_on_wall() and _state == State.WANDER:
		_choose_wander()
	elif _state == State.FLEE:
		_update_flee_stuck(delta)
	elif _has_alarm_target and _state == State.INVESTIGATE:
		_update_alarm_stuck(delta)

func debug_get_state_name() -> String:
	match _state:
		State.WANDER:
			return "WANDER"
		State.IDLE_LOOK:
			return "IDLE_LOOK"
		State.FLEE:
			return "FLEE"
		State.CHASE:
			return "CHASE"
		State.INVESTIGATE:
			return "INVESTIGATE"
		State.HEARING_ALERT:
			return "HEARING_ALERT"
		State.HEARING_CONFIRM:
			return "HEARING_CONFIRM"
		State.ATTACK:
			return "ATTACK"
		State.DEAD:
			return "DEAD"
	return "UNKNOWN"

func debug_can_see_player() -> bool:
	if monster_role == "nightmare":
		return false
	return _should_flee_from_player()

func debug_can_see_threat() -> bool:
	return _find_visible_threat() != null

func debug_can_hear_player() -> bool:
	return _find_audible_player() != null

func debug_get_last_heard_position() -> Vector3:
	return _last_heard_position if _has_last_heard_position else Vector3.ZERO

func debug_get_nightmare_surface_mode() -> String:
	match _nightmare_surface_mode:
		NightmareSurfaceMode.WALL:
			return "WALL"
		NightmareSurfaceMode.CEILING:
			return "CEILING"
	return "FLOOR"

func debug_get_nightmare_model_up() -> Vector3:
	if _nightmare_model_root == null:
		return Vector3.UP
	return _nightmare_model_root.global_transform.basis.y.normalized()

func debug_get_current_animation() -> String:
	return _current_animation

func debug_has_wander_target() -> bool:
	return _has_wander_target

func debug_get_wander_target() -> Vector3:
	return _wander_target_position if _has_wander_target else Vector3.ZERO

func debug_get_health() -> float:
	return _health

func debug_is_dead() -> bool:
	return _state == State.DEAD

func debug_get_chase_target_name() -> String:
	return _chase_target.name if _chase_target != null else ""

func debug_has_chase_target() -> bool:
	return _chase_target != null

func debug_has_alarm_target() -> bool:
	return _has_alarm_target

func debug_has_alarm_route() -> bool:
	return _has_alarm_route

func debug_get_alarm_route_target() -> Vector3:
	if _has_alarm_route:
		return _alarm_route_portal_position if _alarm_route_stage == 0 else _alarm_route_exit_position
	return _alarm_target_position if _has_alarm_target else Vector3.ZERO

func debug_get_alarm_navigation_target() -> Vector3:
	return _alarm_navigation_target() if _has_alarm_target else Vector3.ZERO

func debug_get_alarm_stuck_timer() -> float:
	return _alarm_stuck_timer

func debug_has_flee_route() -> bool:
	return _has_flee_route

func debug_get_flee_target() -> Vector3:
	if not _has_flee_route:
		return Vector3.ZERO
	if _flee_route_stage == 0:
		return _flee_portal_position
	return _flee_exit_position

func debug_get_animation_speed_scale() -> float:
	if _animation_player == null:
		return 0.0
	return _animation_player.speed_scale

func debug_get_locomotion_forward_dot() -> float:
	return _last_locomotion_forward_dot

func is_dead() -> bool:
	return _state == State.DEAD

func receive_damage(amount: float, attacker: Node = null) -> void:
	if _state == State.DEAD:
		return
	_health -= maxf(amount, 0.0)
	if _health <= 0.0:
		_die(attacker)

func forget_target(target: Node = null) -> void:
	var matches := target == null
	if not matches:
		matches = target == _player or target == _chase_target or target == _threat_target
	if not matches:
		return
	_chase_target = null
	_threat_target = null
	_has_last_seen_position = false
	_has_last_heard_position = false
	_clear_nightmare_surface_crawl()
	if _state in [State.FLEE, State.CHASE, State.INVESTIGATE, State.HEARING_ALERT, State.HEARING_CONFIRM, State.ATTACK]:
		_choose_wander()

func force_flee_from(threat: Node3D) -> void:
	if monster_role == "red" or monster_role == "nightmare" or _state == State.DEAD:
		return
	_threat_target = threat
	_start_flee()

func debug_test_locomotion_animation_speed(test_velocity: Vector3) -> float:
	_play_animation(run_animation, run_animation_speed)
	velocity = test_velocity
	_update_locomotion_animation_direction()
	return debug_get_animation_speed_scale()

func _resolve_player() -> void:
	_player = get_node_or_null(player_path) as Node3D
	if _player != null:
		return
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		_player = players[0] as Node3D

func _update_red_alarm_attraction_state(delta: float) -> bool:
	if _state == State.DEAD or _state == State.ATTACK:
		return false
	var alarm := _find_active_red_alarm_attractor()
	if alarm == null:
		_clear_alarm_target()
		return false
	var visible_player := _find_alarm_visible_player()
	if visible_player != null:
		_clear_alarm_target()
		_chase_target = visible_player
		_last_seen_position = visible_player.global_position
		_has_last_seen_position = true
		if _flat_distance(global_position, visible_player.global_position) <= attack_range:
			_start_attack()
		else:
			_start_chase()
		return true
	var alarm_position: Vector3 = alarm.call("get_attract_position")
	_alarm_target_position = alarm_position
	_has_alarm_target = true
	_last_seen_position = alarm_position
	_has_last_seen_position = true
	_chase_target = null
	if _flat_distance(global_position, alarm_position) <= alarm_attraction_reach_distance:
		if _state != State.IDLE_LOOK:
			_start_idle_look()
		_state_timer = minf(_state_timer, 0.35)
		return true
	_alarm_repath_timer = maxf(_alarm_repath_timer - delta, 0.0)
	_state = State.INVESTIGATE
	_state_timer = 0.75
	_play_animation(run_animation, run_animation_speed)
	return true

func _find_alarm_visible_player() -> Node3D:
	if _player == null or _is_target_dead(_player):
		return null
	if _can_sense_target(_player, player_target_height, false):
		return _player
	return null

func _clear_alarm_target() -> void:
	_has_alarm_target = false
	_has_alarm_route = false
	_alarm_route_stage = 0
	_alarm_route_target_area = ""
	_alarm_repath_timer = 0.0
	_alarm_stuck_timer = 0.0
	_has_last_alarm_position = false

func _find_active_red_alarm_attractor() -> Node:
	if get_tree() == null:
		return null
	var best_alarm: Node = null
	var best_distance := INF
	for node in get_tree().get_nodes_in_group("red_alarm_attractor"):
		if node == null or not node.has_method("is_active") or not bool(node.call("is_active")):
			continue
		if not node.has_method("get_attract_position") or not node.has_method("get_attraction_radius"):
			continue
		var alarm_position: Vector3 = node.call("get_attract_position")
		var radius := float(node.call("get_attraction_radius"))
		var distance := _flat_distance(global_position, alarm_position)
		if distance > radius or distance >= best_distance:
			continue
		best_alarm = node
		best_distance = distance
	return best_alarm

func _update_normal_state(delta: float) -> void:
	_threat_target = _find_visible_threat()
	if _threat_target != null:
		_start_flee()
	elif _state == State.FLEE:
		_state_timer -= delta
		if _state_timer <= 0.0:
			_choose_wander()
	elif _state == State.WANDER:
		_state_timer -= delta
		if _state_timer <= 0.0:
			_start_idle_look()
	elif _state == State.IDLE_LOOK:
		_state_timer -= delta
		if _state_timer <= 0.0:
			_choose_wander()

func _update_red_state(delta: float) -> void:
	_update_red_light_pressure(delta)
	var visible_target := _find_visible_chase_target()
	if visible_target != null:
		_chase_target = visible_target
		_last_seen_position = visible_target.global_position
		_has_last_seen_position = true
		if _flat_distance(global_position, visible_target.global_position) <= attack_range:
			_start_attack()
		else:
			_start_chase()
		return

	if _state == State.CHASE:
		_start_investigate()
	elif _state == State.INVESTIGATE:
		if _flat_distance(global_position, _last_seen_position) <= investigate_reach_distance:
			_choose_wander()
	elif _state == State.ATTACK:
		_state_timer -= delta
		if _state_timer <= 0.0:
			if _has_last_seen_position:
				_start_investigate()
			else:
				_choose_wander()
	elif _state == State.WANDER:
		_state_timer -= delta
		if _state_timer <= 0.0:
			_start_idle_look()
	elif _state == State.IDLE_LOOK:
		_state_timer -= delta
		if _state_timer <= 0.0:
			_choose_wander()

func _update_nightmare_state(delta: float) -> void:
	if _state == State.ATTACK:
		_state_timer -= delta
		if _state_timer <= 0.0:
			if _has_last_heard_position:
				_last_seen_position = _last_heard_position
				_has_last_seen_position = true
				_start_investigate()
			else:
				_choose_wander()
		return

	var audible_target := _find_audible_player()
	if audible_target != null:
		if _flat_distance(global_position, audible_target.global_position) <= attack_range:
			_record_heard_sound(audible_target.global_position)
			_chase_target = audible_target
			_start_attack()
		else:
			_handle_nightmare_sound(audible_target.global_position, audible_target)
		return

	if _state == State.CHASE:
		if _has_last_heard_position:
			_last_seen_position = _last_heard_position
			_has_last_seen_position = true
			_start_investigate()
		else:
			_choose_wander()
	elif _state == State.INVESTIGATE:
		_state_timer -= delta
		if (
			not _has_last_heard_position
			or _state_timer <= 0.0
			or _flat_distance(global_position, _last_heard_position) <= investigate_reach_distance
		):
			_choose_wander()
	elif _state == State.HEARING_ALERT:
		pass
	elif _state == State.HEARING_CONFIRM:
		pass
	elif _state == State.WANDER:
		_state_timer -= delta
		if _state_timer <= 0.0:
			_start_idle_look()
	elif _state == State.IDLE_LOOK:
		_state_timer -= delta
		if _state_timer <= 0.0:
			_choose_wander()

func _start_flee() -> void:
	var was_fleeing := _state == State.FLEE
	_state = State.FLEE
	_state_timer = flee_memory_time
	if not was_fleeing or not _has_flee_route:
		_select_flee_route()
	_play_animation(run_animation, run_animation_speed)
	if not was_fleeing:
		_flee_boost_timer = flee_start_boost_time
		_apply_flee_start_impulse()

func _start_chase() -> void:
	var was_chasing := _state == State.CHASE
	_state = State.CHASE
	_state_timer = nightmare_hearing_memory_time if monster_role == "nightmare" else flee_memory_time
	_play_animation(run_animation, run_animation_speed)
	if not was_chasing and monster_role != "nightmare":
		_play_one_shot(_roar_player)

func _start_investigate() -> void:
	if not _has_last_seen_position:
		_choose_wander()
		return
	_state = State.INVESTIGATE
	_state_timer = nightmare_hearing_memory_time if monster_role == "nightmare" else flee_memory_time
	_play_animation(walk_animation, walk_animation_speed)

func _record_heard_sound(sound_position: Vector3) -> void:
	_last_heard_position = sound_position
	_has_last_heard_position = true
	_last_seen_position = _last_heard_position
	_has_last_seen_position = true

func _handle_nightmare_sound(sound_position: Vector3, sound_source: Node3D = null) -> void:
	if monster_role != "nightmare":
		return
	var previous_position := _last_heard_position
	var had_previous := _has_last_heard_position
	_record_heard_sound(sound_position)
	if _state == State.CHASE:
		if sound_source != null and not _is_target_dead(sound_source):
			_chase_target = sound_source
		return
	if _state == State.INVESTIGATE:
		return
	if _state == State.ATTACK:
		return
	if _state == State.HEARING_CONFIRM:
		_face_heard_position(0.016)
		return
	if _state == State.HEARING_ALERT:
		var sound_moved := had_previous and _flat_distance(previous_position, sound_position) >= nightmare_hearing_retrigger_distance
		if sound_moved or _state_timer <= nightmare_hearing_alert_time * 0.35:
			_start_hearing_confirm()
		else:
			_face_heard_position(0.016)
		return
	_start_hearing_alert()

func _start_hearing_alert() -> void:
	_state = State.HEARING_ALERT
	_state_timer = nightmare_hearing_alert_time
	_chase_target = null
	velocity.x = move_toward(velocity.x, 0.0, acceleration * 0.08)
	velocity.z = move_toward(velocity.z, 0.0, acceleration * 0.08)
	_play_animation(idle_animation, 1.0)
	_face_heard_position(0.016)

func _start_hearing_confirm() -> void:
	_state = State.HEARING_CONFIRM
	_state_timer = nightmare_hearing_confirm_time
	_chase_target = null
	_play_animation(idle_animation, 1.0)
	_face_heard_position(0.016)

func _face_heard_position(delta: float) -> void:
	if not _has_last_heard_position:
		return
	var to_sound := _last_heard_position - global_position
	to_sound.y = 0.0
	if to_sound.length_squared() <= 0.0001:
		return
	_face_direction(to_sound.normalized(), delta, flee_turn_speed)

func _start_attack() -> void:
	if _chase_target == null or _is_target_dead(_chase_target):
		_choose_wander()
		return
	_clear_nightmare_surface_crawl()
	_state = State.ATTACK
	_state_timer = attack_recovery_time
	velocity.x = 0.0
	velocity.z = 0.0
	_snap_face_target(_chase_target)
	_play_animation(_animation_or_fallback(attack_animation, idle_animation), 1.0)
	if _attack_timer <= 0.0:
		_perform_attack()
		_attack_timer = attack_cooldown

func _choose_wander() -> void:
	_state = State.WANDER
	_state_timer = _rng.randf_range(wander_min_time, wander_max_time)
	_has_flee_route = false
	_has_last_flee_position = false
	_flee_stuck_timer = 0.0
	_chase_target = null
	_threat_target = null
	_has_last_seen_position = false
	_has_last_heard_position = false
	_clear_alarm_target()
	_clear_nightmare_surface_crawl()
	var angle := _rng.randf_range(0.0, TAU)
	_wander_direction = Vector3(sin(angle), 0.0, cos(angle)).normalized()
	_select_wander_target()
	_play_animation(walk_animation, walk_animation_speed)

func _start_idle_look() -> void:
	_state = State.IDLE_LOOK
	_state_timer = _rng.randf_range(idle_min_time, idle_max_time)
	_idle_look_phase = 0.0
	_idle_look_base_yaw = rotation.y
	_play_animation(idle_animation, 1.0)

func _update_flee(delta: float) -> void:
	if _threat_target == null and _player == null:
		_choose_wander()
		return

	_flee_repath_timer -= delta
	if _flee_repath_timer <= 0.0 or not _has_flee_route:
		_select_flee_route()

	var flee_direction := _get_flee_direction()
	_move_horizontal(flee_direction, flee_speed, delta, flee_acceleration, flee_turn_speed)
	_apply_flee_boost(flee_direction, delta)

func _update_chase(delta: float) -> void:
	if _chase_target == null or _is_target_dead(_chase_target):
		_choose_wander()
		return
	var to_target := _chase_target.global_position - global_position
	to_target.y = 0.0
	if to_target.length() <= attack_range:
		_start_attack()
		return
	_move_horizontal(to_target.normalized(), chase_speed, delta, flee_acceleration, flee_turn_speed)

func _update_investigate(delta: float) -> void:
	if not _has_last_seen_position:
		_choose_wander()
		return
	if _has_alarm_target and _flat_distance(global_position, _alarm_target_position) <= alarm_attraction_reach_distance:
		_has_alarm_route = false
		_start_idle_look()
		return
	var target_position := _last_seen_position
	if _has_alarm_target:
		target_position = _alarm_navigation_target()
	var to_target := target_position - global_position
	to_target.y = 0.0
	if to_target.length() <= investigate_reach_distance:
		if _has_alarm_target:
			_has_alarm_route = false
			return
		_choose_wander()
		return
	var investigate_speed := nightmare_locked_investigate_speed if monster_role == "nightmare" else wander_speed * 1.25
	if _has_alarm_target:
		investigate_speed = maxf(investigate_speed, chase_speed * alarm_attraction_speed_multiplier)
	_move_horizontal(to_target.normalized(), investigate_speed, delta)

func _update_hearing_pause(delta: float) -> void:
	_state_timer -= delta
	velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
	velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)
	_face_heard_position(delta)
	if _state_timer > 0.0:
		return
	if _state == State.HEARING_CONFIRM:
		_finish_nightmare_sound_lock()
	elif _has_last_heard_position:
		_start_hearing_confirm()
	else:
		_choose_wander()

func _alarm_navigation_target() -> Vector3:
	if not _has_alarm_target:
		return _last_seen_position
	if _portals_root == null:
		return _alarm_target_position
	var current_area := _find_area_id_for_position(global_position)
	var target_area := _find_area_id_for_position(_alarm_target_position)
	if target_area.is_empty() or current_area.is_empty():
		_has_alarm_route = false
		return _alarm_target_position
	if current_area == target_area:
		_has_alarm_route = false
		return _resolve_internal_waypoint(current_area, _alarm_target_position)
	if (
		not _has_alarm_route
		or _alarm_repath_timer <= 0.0
		or _alarm_route_target_area != target_area
	):
		_select_alarm_route(current_area, target_area)
	if not _has_alarm_route:
		return _alarm_target_position

	var target_position := _alarm_route_portal_position if _alarm_route_stage == 0 else _alarm_route_exit_position
	target_position = _resolve_internal_waypoint(current_area, target_position)
	if _flat_distance(global_position, target_position) <= alarm_portal_reach_distance:
		if _alarm_route_stage == 0:
			_alarm_route_stage = 1
			target_position = _alarm_route_exit_position
			target_position = _resolve_internal_waypoint(current_area, target_position)
		else:
			_has_alarm_route = false
			return _alarm_target_position
	return target_position

func _resolve_internal_waypoint(area_id: String, target_position: Vector3) -> Vector3:
	if area_id.is_empty() or get_tree() == null:
		return target_position
	if _has_clear_escape_line(target_position):
		return target_position
	var best_position := Vector3.ZERO
	var best_score := INF
	for node in get_tree().get_nodes_in_group("proc_internal_navigation_waypoint"):
		var waypoint := node as Node3D
		if waypoint == null:
			continue
		if String(waypoint.get_meta("owner_module_id", "")) != area_id:
			continue
		var waypoint_position := waypoint.global_position
		waypoint_position.y = global_position.y
		if not _has_clear_line_between(global_position, waypoint_position):
			continue
		if not _has_clear_line_between(waypoint_position, target_position):
			continue
		var score := _flat_distance(global_position, waypoint_position) + _flat_distance(waypoint_position, target_position) * 0.25
		if score < best_score:
			best_score = score
			best_position = waypoint_position
	if best_score >= INF * 0.5:
		return target_position
	if _flat_distance(global_position, best_position) <= alarm_portal_reach_distance:
		return target_position
	return best_position

func _select_alarm_route(current_area: String, target_area: String) -> void:
	_has_alarm_route = false
	_alarm_route_stage = 0
	_alarm_route_target_area = target_area
	_alarm_repath_timer = alarm_repath_interval
	var route := _find_portal_route(current_area, target_area)
	if route.is_empty():
		return
	var portal := route.get("portal") as Node3D
	var next_area := String(route.get("next_area", ""))
	if portal == null or next_area.is_empty():
		return
	_alarm_route_portal_position = portal.global_position
	_alarm_route_portal_position.y = global_position.y
	_alarm_route_exit_position = _get_portal_exit_position(_alarm_route_portal_position, next_area)
	_alarm_route_exit_position.y = global_position.y
	_has_alarm_route = true

func _find_portal_route(start_area: String, target_area: String) -> Dictionary:
	if _portals_root == null or start_area.is_empty() or target_area.is_empty():
		return {}
	var queue: Array[String] = [start_area]
	var visited := {start_area: true}
	var parent_area := {}
	var parent_portal := {}
	var found := false
	while not queue.is_empty():
		var area: String = queue.pop_front()
		if area == target_area:
			found = true
			break
		for portal_node in _portals_root.get_children():
			var portal := portal_node as Node3D
			if portal == null:
				continue
			if portal.has_method("is_open") and not bool(portal.call("is_open")):
				continue
			var area_a := String(portal.get("area_a"))
			var area_b := String(portal.get("area_b"))
			var next_area := ""
			if area_a == area:
				next_area = area_b
			elif area_b == area:
				next_area = area_a
			if next_area.is_empty() or visited.has(next_area):
				continue
			visited[next_area] = true
			parent_area[next_area] = area
			parent_portal[next_area] = portal
			queue.append(next_area)
	if not found:
		return {}
	var step_area := target_area
	while parent_area.has(step_area) and String(parent_area[step_area]) != start_area:
		step_area = String(parent_area[step_area])
	if not parent_portal.has(step_area):
		return {}
	return {
		"next_area": step_area,
		"portal": parent_portal[step_area],
	}

func _finish_nightmare_sound_lock() -> void:
	if monster_role != "nightmare" or not _has_last_heard_position:
		_choose_wander()
		return
	if _player != null and not _is_target_dead(_player):
		var player_distance_to_sound := _flat_distance(_player.global_position, _last_heard_position)
		if player_distance_to_sound <= nightmare_attack_lock_radius:
			_chase_target = _player
			_start_chase()
			return
	_last_seen_position = _last_heard_position
	_has_last_seen_position = true
	_start_investigate()

func _cache_nightmare_model_root() -> void:
	if monster_role != "nightmare":
		return
	_nightmare_model_root = get_node_or_null("ModelRoot") as Node3D
	if _nightmare_model_root == null:
		_nightmare_model_root = self
	var ground_offset := float(get_meta(MonsterSizeSource.ANIMATION_GROUND_OFFSET_META, 0.0))
	_nightmare_model_base_y = _nightmare_model_root.position.y - ground_offset
	set_meta("nightmare_ceiling_ambush_active", false)
	set_meta("nightmare_surface_crawl_active", false)
	set_meta("nightmare_surface_mode", "FLOOR")

func _update_nightmare_ceiling_ambush(delta: float) -> void:
	if monster_role != "nightmare":
		return
	if _nightmare_model_root == null:
		_cache_nightmare_model_root()
	if _nightmare_model_root == null:
		return
	var surface := _choose_nightmare_surface()
	var target_mode: NightmareSurfaceMode = surface["mode"]
	if target_mode == NightmareSurfaceMode.CEILING and _chase_target != null:
		var distance := _flat_distance(global_position, _chase_target.global_position)
		if distance <= nightmare_ceiling_drop_distance:
			_clear_nightmare_surface_crawl()
			_start_attack()
			return
	_set_nightmare_surface(
		target_mode,
		surface["normal"],
		surface["contact_position"],
		bool(surface["has_contact"])
	)
	_update_nightmare_surface_animation()
	_apply_nightmare_surface_visual_transform()

func _choose_nightmare_surface() -> Dictionary:
	var floor_result := _nightmare_surface_result(NightmareSurfaceMode.FLOOR, Vector3.UP, global_position, false)
	if not nightmare_surface_crawl_enabled:
		return floor_result
	if _state != State.CHASE and _state != State.INVESTIGATE:
		return floor_result
	if _state == State.CHASE and _chase_target != null and not _is_target_dead(_chase_target):
		var distance := _flat_distance(global_position, _chase_target.global_position)
		if nightmare_ceiling_ambush_enabled and distance <= nightmare_ceiling_trigger_distance:
			var ceiling := _find_nightmare_ceiling_surface()
			if not ceiling.is_empty():
				return ceiling
	var wall := _find_nightmare_wall_surface()
	if not wall.is_empty():
		return wall
	return floor_result

func _nightmare_surface_result(mode: NightmareSurfaceMode, normal: Vector3, contact_position: Vector3, has_contact: bool) -> Dictionary:
	return {
		"mode": mode,
		"normal": normal,
		"contact_position": contact_position,
		"has_contact": has_contact,
	}

func _set_nightmare_surface(mode: NightmareSurfaceMode, normal: Vector3, contact_position: Vector3, has_contact: bool) -> void:
	_nightmare_surface_mode = mode
	_nightmare_surface_normal = normal.normalized() if normal.length_squared() > 0.0001 else Vector3.UP
	_nightmare_surface_contact_position = contact_position
	_nightmare_has_surface_contact = has_contact
	_nightmare_ceiling_mode = mode == NightmareSurfaceMode.CEILING
	_nightmare_ceiling_visual_offset = nightmare_ceiling_visual_height if _nightmare_ceiling_mode else 0.0
	set_meta("nightmare_surface_crawl_active", mode != NightmareSurfaceMode.FLOOR)
	set_meta("nightmare_ceiling_ambush_active", mode == NightmareSurfaceMode.CEILING)
	set_meta("nightmare_surface_mode", debug_get_nightmare_surface_mode())

func _clear_nightmare_surface_crawl() -> void:
	if monster_role != "nightmare":
		return
	_set_nightmare_surface(NightmareSurfaceMode.FLOOR, Vector3.UP, global_position, false)
	_apply_nightmare_surface_visual_transform()

func _update_nightmare_surface_animation() -> void:
	if monster_role != "nightmare" or _state == State.DEAD or _state == State.ATTACK:
		return
	if _nightmare_surface_mode != NightmareSurfaceMode.FLOOR:
		_play_animation(_animation_or_fallback(nightmare_surface_crawl_animation, walk_animation), nightmare_surface_crawl_speed)
		return
	if _current_animation == nightmare_surface_crawl_animation:
		if _state == State.CHASE:
			_play_animation(run_animation, run_animation_speed)
		elif _state == State.INVESTIGATE:
			_play_animation(walk_animation, walk_animation_speed)

func _apply_nightmare_surface_visual_transform() -> void:
	if _nightmare_model_root == null:
		return
	var base_transform := _nightmare_base_model_transform()
	if _nightmare_surface_mode == NightmareSurfaceMode.FLOOR:
		_nightmare_model_root.transform = base_transform
		return
	var contact_local := global_transform.affine_inverse() * _nightmare_surface_contact_position if _nightmare_has_surface_contact else Vector3.ZERO
	var surface_basis := _nightmare_surface_basis(_nightmare_surface_normal, _nightmare_surface_forward())
	_nightmare_model_root.transform = Transform3D(surface_basis * base_transform.basis, contact_local + surface_basis * base_transform.origin)

func _apply_nightmare_ceiling_visual_offset() -> void:
	_apply_nightmare_surface_visual_transform()

func _nightmare_base_model_transform() -> Transform3D:
	var base_transform := _nightmare_model_root.transform
	if _nightmare_model_root.has_meta(MonsterSizeSource.VISUAL_YAW_BASE_META):
		var stored_base = _nightmare_model_root.get_meta(MonsterSizeSource.VISUAL_YAW_BASE_META)
		if typeof(stored_base) == TYPE_TRANSFORM3D:
			base_transform = stored_base
	var ground_offset := 0.0
	if has_meta(MonsterSizeSource.ANIMATION_GROUND_OFFSET_META):
		var ground_value = get_meta(MonsterSizeSource.ANIMATION_GROUND_OFFSET_META)
		if typeof(ground_value) == TYPE_FLOAT or typeof(ground_value) == TYPE_INT:
			ground_offset = float(ground_value)
	var visual_yaw := 0.0
	if has_meta(MonsterSizeSource.VISUAL_YAW_META):
		var yaw_value = get_meta(MonsterSizeSource.VISUAL_YAW_META)
		if typeof(yaw_value) == TYPE_FLOAT or typeof(yaw_value) == TYPE_INT:
			visual_yaw = float(yaw_value)
	var yaw_basis := Basis.from_euler(Vector3(0.0, deg_to_rad(visual_yaw), 0.0))
	return Transform3D(yaw_basis * base_transform.basis, base_transform.origin + Vector3(0.0, ground_offset, 0.0))

func _nightmare_surface_forward() -> Vector3:
	var horizontal_velocity := Vector3(velocity.x, 0.0, velocity.z)
	if horizontal_velocity.length_squared() > 0.0025:
		return horizontal_velocity.normalized()
	if _chase_target != null and not _is_target_dead(_chase_target):
		var to_target := _chase_target.global_position - global_position
		to_target.y = 0.0
		if to_target.length_squared() > 0.0001:
			return to_target.normalized()
	if _has_last_seen_position:
		var to_seen := _last_seen_position - global_position
		to_seen.y = 0.0
		if to_seen.length_squared() > 0.0001:
			return to_seen.normalized()
	return -global_transform.basis.z.normalized()

func _nightmare_surface_basis(global_normal: Vector3, global_forward: Vector3) -> Basis:
	var local_up := global_transform.basis.inverse() * global_normal
	if local_up.length_squared() <= 0.0001:
		local_up = Vector3.UP
	local_up = local_up.normalized()
	var local_forward := global_transform.basis.inverse() * global_forward
	local_forward -= local_up * local_forward.dot(local_up)
	if local_forward.length_squared() <= 0.0001:
		local_forward = _nightmare_surface_forward_fallback(local_up)
	else:
		local_forward = local_forward.normalized()
	var right := local_forward.cross(local_up)
	if right.length_squared() <= 0.0001:
		right = Vector3.RIGHT
	else:
		right = right.normalized()
	var forward := local_up.cross(right).normalized()
	return Basis(right, local_up, -forward).orthonormalized()

func _nightmare_surface_forward_fallback(local_up: Vector3) -> Vector3:
	var candidate := Vector3.UP
	if absf(candidate.dot(local_up)) > 0.92:
		candidate = Vector3.FORWARD
	candidate -= local_up * candidate.dot(local_up)
	if candidate.length_squared() <= 0.0001:
		return Vector3.FORWARD
	return candidate.normalized()

func _find_nightmare_ceiling_surface() -> Dictionary:
	var from_position := global_position + Vector3.UP * 0.35
	var to_position := from_position + Vector3.UP * maxf(nightmare_ceiling_visual_height + 1.4, 2.4)
	var hit := _nightmare_surface_raycast(from_position, to_position)
	if hit.is_empty():
		return {}
	var normal: Vector3 = hit.get("normal", Vector3.DOWN)
	if normal.dot(Vector3.DOWN) < 0.45:
		normal = Vector3.DOWN
	return _nightmare_surface_result(NightmareSurfaceMode.CEILING, normal, hit["position"], true)

func _find_nightmare_wall_surface() -> Dictionary:
	var directions: Array[Vector3] = []
	var forward := _nightmare_surface_forward()
	directions.append(forward)
	directions.append(-global_transform.basis.x.normalized())
	directions.append(global_transform.basis.x.normalized())
	directions.append(-forward)
	var from_position := global_position + Vector3.UP * nightmare_wall_crawl_height
	for direction in directions:
		direction.y = 0.0
		if direction.length_squared() <= 0.0001:
			continue
		direction = direction.normalized()
		var hit := _nightmare_surface_raycast(from_position, from_position + direction * nightmare_wall_crawl_probe_distance)
		if hit.is_empty():
			continue
		var normal: Vector3 = hit.get("normal", -direction)
		normal.y = 0.0
		if normal.length_squared() <= 0.0001:
			continue
		return _nightmare_surface_result(NightmareSurfaceMode.WALL, normal.normalized(), hit["position"], true)
	return {}

func _nightmare_surface_raycast(from_position: Vector3, to_position: Vector3) -> Dictionary:
	if not is_inside_tree():
		return {}
	var query := PhysicsRayQueryParameters3D.create(from_position, to_position)
	var exclude: Array[RID] = [get_rid()]
	var player_body := _player as CollisionObject3D
	if player_body != null:
		exclude.append(player_body.get_rid())
	query.exclude = exclude
	query.collide_with_areas = false
	return get_world_3d().direct_space_state.intersect_ray(query)

func _find_audible_player() -> Node3D:
	if monster_role != "nightmare" or _player == null or _is_target_dead(_player):
		return null
	var horizontal_speed := _target_horizontal_speed(_player)
	if horizontal_speed < nightmare_min_hearing_speed:
		return null
	var hearing_distance := _target_footstep_noise_radius(_player, horizontal_speed)
	if _flat_distance(global_position, _player.global_position) > hearing_distance:
		return null
	return _player

func _target_horizontal_speed(target: Node3D) -> float:
	var body := target as CharacterBody3D
	if body != null:
		return Vector2(body.velocity.x, body.velocity.z).length()
	var velocity_variant: Variant = target.get("velocity")
	if velocity_variant is Vector3:
		var target_velocity: Vector3 = velocity_variant
		return Vector2(target_velocity.x, target_velocity.z).length()
	return 0.0

func _target_footstep_noise_radius(target: Node3D, horizontal_speed: float) -> float:
	if target.has_method("get_footstep_noise_radius"):
		var radius := float(target.call("get_footstep_noise_radius"))
		if radius > 0.0:
			return radius
	if target.has_method("debug_get_footstep_noise_radius"):
		var debug_radius := float(target.call("debug_get_footstep_noise_radius"))
		if debug_radius > 0.0:
			return debug_radius
	return nightmare_sprint_hearing_distance if horizontal_speed >= nightmare_sprint_speed_threshold else nightmare_walk_hearing_distance

func _update_attack(_delta: float) -> void:
	if _chase_target == null or _is_target_dead(_chase_target):
		_choose_wander()
		return
	velocity.x = move_toward(velocity.x, 0.0, acceleration * _delta)
	velocity.z = move_toward(velocity.z, 0.0, acceleration * _delta)
	_snap_face_target(_chase_target)

func _perform_attack() -> void:
	if (monster_role != "red" and monster_role != "nightmare") or _chase_target == null or _is_target_dead(_chase_target) or _state == State.DEAD:
		return
	_play_one_shot(_attack_player)
	if monster_role == "nightmare":
		if bool(_chase_target.get_meta("mvp_player_immortal", false)):
			_chase_target.set_meta("nightmare_monster_hit_count", int(_chase_target.get_meta("nightmare_monster_hit_count", 0)) + 1)
			_chase_target.set_meta("mvp_nightmare_attack_was_nonlethal", true)
			return
		if _chase_target.has_method("receive_damage"):
			_chase_target.call("receive_damage", nightmare_attack_damage, self)
			return
		_chase_target.set_meta("nightmare_monster_hit_count", int(_chase_target.get_meta("nightmare_monster_hit_count", 0)) + 1)
		return
	if bool(_chase_target.get_meta("mvp_player_immortal", false)):
		_chase_target.set_meta("red_monster_hit_count", int(_chase_target.get_meta("red_monster_hit_count", 0)) + 1)
		_chase_target.set_meta("mvp_red_attack_was_nonlethal", true)
		return
	if _chase_target.has_method("receive_damage"):
		_chase_target.call("receive_damage", red_attack_damage, self)
		return
	_chase_target.set_meta("red_monster_hit_count", int(_chase_target.get_meta("red_monster_hit_count", 0)) + 1)

func _update_wander(delta: float) -> void:
	if _has_wander_target:
		var to_target := _wander_target_position - global_position
		to_target.y = 0.0
		if to_target.length() <= wander_portal_reach_distance:
			_select_wander_target()
		elif to_target.length_squared() > 0.0001:
			_move_horizontal(to_target.normalized(), wander_speed, delta)
			return
	_move_horizontal(_wander_direction, wander_speed, delta)

func _select_wander_target() -> void:
	_has_wander_target = false
	if not wander_cross_room_enabled or _portals_root == null:
		return
	var current_area := _find_area_id_for_position(global_position)
	var candidates: Array[Dictionary] = []
	for portal in _portals_root.get_children():
		var portal_node := portal as Node3D
		if portal_node == null:
			continue
		var area_a_variant: Variant = portal.get("area_a")
		var area_b_variant: Variant = portal.get("area_b")
		if area_a_variant == null or area_b_variant == null:
			continue
		var area_a := String(area_a_variant)
		var area_b := String(area_b_variant)
		if area_a.is_empty() or area_b.is_empty():
			continue
		if not current_area.is_empty() and area_a != current_area and area_b != current_area:
			continue
		var portal_position := portal_node.global_position
		portal_position.y = global_position.y
		var other_area := _get_portal_escape_area(area_a, area_b, current_area, portal_position)
		var exit_position := _get_portal_exit_position(portal_position, other_area)
		var score := 1.0 + portal_position.distance_to(global_position) * 0.15
		if not current_area.is_empty() and other_area != current_area:
			score += 2.0
		candidates.append({
			"portal": portal_position,
			"exit": exit_position,
			"score": score,
		})
	if candidates.is_empty():
		return
	var total_weight := 0.0
	for candidate in candidates:
		total_weight += maxf(float(candidate["score"]), 0.1)
	var pick := _rng.randf_range(0.0, total_weight)
	for candidate in candidates:
		pick -= maxf(float(candidate["score"]), 0.1)
		if pick <= 0.0:
			_wander_target_position = candidate["portal"]
			if _flat_distance(global_position, _wander_target_position) <= wander_portal_reach_distance * 1.4:
				_wander_target_position = candidate["exit"]
			_has_wander_target = true
			_update_wander_direction_to_target()
			return

func _update_wander_direction_to_target() -> void:
	if not _has_wander_target:
		return
	var to_target := _wander_target_position - global_position
	to_target.y = 0.0
	if to_target.length_squared() > 0.0001:
		_wander_direction = to_target.normalized()

func _update_idle_look(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
	velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)
	_idle_look_phase += delta
	var look_offset := sin(_idle_look_phase * TAU * 0.45) * deg_to_rad(idle_look_degrees)
	rotation.y = lerp_angle(rotation.y, _idle_look_base_yaw + look_offset, clampf(turn_speed * delta, 0.0, 1.0))

func _move_horizontal(direction: Vector3, speed: float, delta: float, horizontal_acceleration := -1.0, horizontal_turn_speed := -1.0) -> void:
	var flat_direction := direction
	flat_direction.y = 0.0
	if flat_direction.length_squared() <= 0.0001:
		return
	flat_direction = flat_direction.normalized()
	var target_velocity := flat_direction * speed
	var applied_acceleration := acceleration
	if horizontal_acceleration > 0.0:
		applied_acceleration = horizontal_acceleration
	velocity.x = move_toward(velocity.x, target_velocity.x, applied_acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, applied_acceleration * delta)
	_face_direction(flat_direction, delta, horizontal_turn_speed)

func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= gravity * delta

func _face_direction(direction: Vector3, delta: float, horizontal_turn_speed := -1.0) -> void:
	if direction.length_squared() <= 0.0001:
		return
	var target_yaw := atan2(-direction.x, -direction.z)
	var applied_turn_speed := turn_speed
	if horizontal_turn_speed > 0.0:
		applied_turn_speed = horizontal_turn_speed
	rotation.y = lerp_angle(rotation.y, target_yaw, clampf(applied_turn_speed * delta, 0.0, 1.0))

func _snap_face_target(target: Node3D) -> void:
	if target == null:
		return
	var to_target := target.global_position - global_position
	to_target.y = 0.0
	if to_target.length_squared() <= 0.0001:
		return
	rotation.y = atan2(-to_target.normalized().x, -to_target.normalized().z)

func _get_flee_direction() -> Vector3:
	if _has_flee_route:
		var target_position := _flee_portal_position
		if _flee_route_stage == 1:
			target_position = _flee_exit_position

		var to_target := target_position - global_position
		to_target.y = 0.0
		if to_target.length() <= flee_portal_reach_distance:
			if _flee_route_stage == 0:
				_flee_route_stage = 1
				to_target = _flee_exit_position - global_position
				to_target.y = 0.0
			else:
				_select_flee_route()
				to_target = _flee_portal_position - global_position
				to_target.y = 0.0
		if to_target.length_squared() > 0.0001:
			return to_target.normalized()

	var threat_position := _threat_position()
	var away := global_position - threat_position
	away.y = 0.0
	if away.length_squared() <= 0.0001:
		away = -global_transform.basis.z
		away.y = 0.0
	if away.length_squared() <= 0.0001:
		return Vector3.FORWARD
	return away.normalized()

func _apply_flee_start_impulse() -> void:
	var flee_direction := _get_flee_direction()
	flee_direction.y = 0.0
	if flee_direction.length_squared() <= 0.0001:
		return
	flee_direction = flee_direction.normalized()
	velocity.x = flee_direction.x * flee_start_speed
	velocity.z = flee_direction.z * flee_start_speed

func _apply_flee_boost(flee_direction: Vector3, delta: float) -> void:
	if _flee_boost_timer <= 0.0:
		return
	_flee_boost_timer = maxf(_flee_boost_timer - delta, 0.0)
	flee_direction.y = 0.0
	if flee_direction.length_squared() <= 0.0001:
		return
	flee_direction = flee_direction.normalized()
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	if horizontal_speed < flee_start_speed:
		velocity.x = flee_direction.x * flee_start_speed
		velocity.z = flee_direction.z * flee_start_speed

func _select_flee_route() -> void:
	_has_flee_route = false
	_flee_route_stage = 0
	_flee_repath_timer = flee_repath_interval
	if _portals_root == null:
		return

	var current_area := _find_area_id_for_position(global_position)
	var threat_position := _threat_position()
	var threat_area := _find_area_id_for_position(threat_position)
	var best_score := -INF
	var best_portal_position := Vector3.ZERO
	var best_exit_position := Vector3.ZERO

	for portal in _portals_root.get_children():
		var portal_node := portal as Node3D
		if portal_node == null:
			continue
		var area_a_variant: Variant = portal.get("area_a")
		var area_b_variant: Variant = portal.get("area_b")
		if area_a_variant == null or area_b_variant == null:
			continue
		var area_a := String(area_a_variant)
		var area_b := String(area_b_variant)
		if area_a.is_empty() or area_b.is_empty():
			continue
		if not current_area.is_empty() and area_a != current_area and area_b != current_area:
			continue

		var portal_position := portal_node.global_position
		portal_position.y = global_position.y
		var other_area := _get_portal_escape_area(area_a, area_b, current_area, portal_position)
		var exit_position := _get_portal_exit_position(portal_position, other_area)
		var score := _score_flee_route(portal_position, exit_position, other_area, threat_area)
		if score > best_score:
			best_score = score
			best_portal_position = portal_position
			best_exit_position = exit_position

	if best_score <= -INF * 0.5:
		return

	_flee_portal_position = best_portal_position
	_flee_exit_position = best_exit_position
	_has_flee_route = true

func _get_portal_escape_area(area_a: String, area_b: String, current_area: String, portal_position: Vector3) -> String:
	if current_area == area_a:
		return area_b
	if current_area == area_b:
		return area_a

	var center_a := _find_room_center_for_area(area_a)
	var center_b := _find_room_center_for_area(area_b)
	var threat_position := _threat_position()
	var score_a := center_a.distance_to(threat_position) + center_a.distance_to(global_position) * 0.25
	var score_b := center_b.distance_to(threat_position) + center_b.distance_to(global_position) * 0.25
	if score_a >= score_b:
		return area_a
	return area_b

func _get_portal_exit_position(portal_position: Vector3, other_area: String) -> Vector3:
	var other_center := _find_room_center_for_area(other_area)
	var exit_direction := other_center - portal_position
	exit_direction.y = 0.0
	if exit_direction.length_squared() <= 0.0001:
		exit_direction = portal_position - _threat_position()
		exit_direction.y = 0.0
	if exit_direction.length_squared() <= 0.0001:
		exit_direction = -global_transform.basis.z
		exit_direction.y = 0.0
	return portal_position + exit_direction.normalized() * flee_portal_exit_distance

func _score_flee_route(portal_position: Vector3, exit_position: Vector3, other_area: String, player_area: String) -> float:
	var player_position := _threat_position()
	var score := 0.0
	score += exit_position.distance_to(player_position) * 1.75
	score += portal_position.distance_to(player_position) * 0.85
	score -= portal_position.distance_to(global_position) * 0.45
	if not other_area.is_empty() and other_area != player_area:
		score += 5.0
	else:
		score -= 4.0

	var to_portal := portal_position - global_position
	to_portal.y = 0.0
	var away := global_position - player_position
	away.y = 0.0
	if to_portal.length_squared() > 0.0001 and away.length_squared() > 0.0001:
		score += to_portal.normalized().dot(away.normalized()) * 2.0

	if _has_clear_escape_line(portal_position):
		score += 3.0
	else:
		score -= 5.0
	return score

func _find_area_id_for_position(position: Vector3) -> String:
	if _rooms_root == null:
		return ""
	for room in _rooms_root.get_children():
		var room_node := room as Node3D
		if room_node == null:
			continue
		var area_variant: Variant = room.get("area_id")
		var bounds_variant: Variant = room.get("bounds_size")
		if area_variant == null or not (bounds_variant is Vector3):
			continue
		var bounds_size: Vector3 = bounds_variant
		if bounds_size == Vector3.ZERO:
			continue
		var room_center := room_node.global_position
		var half_x := bounds_size.x * 0.5 + 0.08
		var half_z := bounds_size.z * 0.5 + 0.08
		if (
			position.x >= room_center.x - half_x
			and position.x <= room_center.x + half_x
			and position.z >= room_center.z - half_z
			and position.z <= room_center.z + half_z
		):
			var room_id := String(room.get("room_id"))
			if _portal_area_exists(room_id):
				return room_id
			return String(area_variant)
	return ""

func _portal_area_exists(area_id: String) -> bool:
	if area_id.is_empty() or _portals_root == null:
		return false
	for portal in _portals_root.get_children():
		var portal_node := portal as Node3D
		if portal_node == null:
			continue
		if String(portal.get("area_a")) == area_id or String(portal.get("area_b")) == area_id:
			return true
	return false

func _find_room_center_for_area(area_id: String) -> Vector3:
	if _rooms_root == null:
		return global_position
	for room in _rooms_root.get_children():
		var room_node := room as Node3D
		if room_node == null:
			continue
		var area_variant: Variant = room.get("area_id")
		var room_id := String(room.get("room_id"))
		if (area_variant == null or String(area_variant) != area_id) and room_id != area_id:
			continue
		var center := room_node.global_position
		center.y = global_position.y
		return center
	return global_position

func _has_clear_escape_line(target_position: Vector3) -> bool:
	return _has_clear_line_between(global_position, target_position)

func _has_clear_line_between(from_position: Vector3, target_position: Vector3) -> bool:
	if not is_inside_tree():
		return false
	var ray_from := from_position + Vector3.UP * eye_height
	var ray_to := target_position + Vector3.UP * eye_height
	var query := PhysicsRayQueryParameters3D.create(ray_from, ray_to)
	var exclude: Array[RID] = []
	exclude.append(get_rid())
	query.exclude = exclude
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty()

func _update_flee_stuck(delta: float) -> void:
	if is_on_wall():
		_select_flee_route()
		_flee_stuck_timer = 0.0
		_last_flee_position = global_position
		_has_last_flee_position = true
		return
	if not _has_last_flee_position:
		_last_flee_position = global_position
		_has_last_flee_position = true
		return

	var moved_distance := global_position.distance_to(_last_flee_position)
	_last_flee_position = global_position
	if moved_distance < flee_stuck_min_frame_distance:
		_flee_stuck_timer += delta
	else:
		_flee_stuck_timer = 0.0
	if _flee_stuck_timer >= flee_stuck_repath_time:
		_select_flee_route()
		_flee_stuck_timer = 0.0

func _update_alarm_stuck(delta: float) -> void:
	if is_on_wall():
		_force_alarm_repath()
		return
	if not _has_last_alarm_position:
		_last_alarm_position = global_position
		_has_last_alarm_position = true
		return

	var moved_distance := global_position.distance_to(_last_alarm_position)
	_last_alarm_position = global_position
	if moved_distance < alarm_stuck_min_frame_distance:
		_alarm_stuck_timer += delta
	else:
		_alarm_stuck_timer = 0.0
	if _alarm_stuck_timer >= alarm_stuck_repath_time:
		_force_alarm_repath()

func _force_alarm_repath() -> void:
	_alarm_stuck_timer = 0.0
	_last_alarm_position = global_position
	_has_last_alarm_position = true
	_has_alarm_route = false
	_alarm_route_stage = 0
	_alarm_repath_timer = 0.0

func _find_visible_threat() -> Node3D:
	var best: Node3D = null
	var best_distance := INF
	if _player != null and _can_sense_target(_player, player_target_height, true):
		best = _player
		best_distance = _flat_distance(global_position, _player.global_position)
	for node in get_tree().get_nodes_in_group("monster"):
		var monster := node as Node3D
		if monster == null or monster == self or _is_target_dead(monster):
			continue
		if String(monster.get_meta("monster_role", monster.get("monster_role"))) == "nightmare":
			continue
		if not _can_sense_target(monster, 0.55, true):
			continue
		var distance := _flat_distance(global_position, monster.global_position)
		if distance < best_distance:
			best_distance = distance
			best = monster
	return best

func _find_visible_chase_target() -> Node3D:
	var best: Node3D = null
	var best_distance := INF
	var candidates: Array[Node] = []
	if _player != null:
		candidates.append(_player)
	candidates.append_array(get_tree().get_nodes_in_group("monster"))
	candidates.append_array(get_tree().get_nodes_in_group("living_creature"))
	var seen_candidates: Dictionary = {}
	for node in candidates:
		var target := node as Node3D
		if target == null or target == self or _is_target_dead(target):
			continue
		var target_id := target.get_instance_id()
		if seen_candidates.has(target_id):
			continue
		seen_candidates[target_id] = true
		var target_height := player_target_height if target == _player else 0.55
		if not _can_sense_target(target, target_height, false):
			continue
		var distance := _flat_distance(global_position, target.global_position)
		if distance < best_distance:
			best_distance = distance
			best = target
	return best

func _can_sense_target(target: Node3D, target_height: float, allow_panic: bool) -> bool:
	if target == null or not is_inside_tree():
		return false
	if _is_target_dead(target):
		return false
	var effective_target_height := _target_detection_height(target, target_height)
	var to_target := target.global_position - global_position
	to_target.y = 0.0
	var distance := to_target.length()
	if allow_panic and distance <= panic_distance and _has_clear_line_to_node(target, effective_target_height):
		return true
	if distance <= 0.0001 or distance > vision_distance:
		return false
	var forward := -global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() <= 0.0001:
		return false
	forward = forward.normalized()
	var direction := to_target.normalized()
	var minimum_dot := cos(deg_to_rad(vision_fov_degrees) * 0.5)
	if forward.dot(direction) < minimum_dot:
		return false
	return _has_clear_line_to_node(target, effective_target_height)

func _target_detection_height(target: Node3D, fallback_height: float) -> float:
	if target != null and target.has_method("get_detection_target_height"):
		return maxf(float(target.call("get_detection_target_height")), 0.05)
	return fallback_height

func _has_clear_line_to_node(target: Node3D, target_height: float) -> bool:
	if target == null or not is_inside_tree():
		return false
	var ray_from := global_position + Vector3.UP * eye_height
	var ray_to := target.global_position + Vector3.UP * target_height
	var query := PhysicsRayQueryParameters3D.create(ray_from, ray_to)
	var exclude: Array[RID] = []
	exclude.append(get_rid())
	query.exclude = exclude
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return true
	var collider: Variant = hit.get("collider")
	return _is_target_collider(collider, target)

func _threat_position() -> Vector3:
	if _threat_target != null:
		return _threat_target.global_position
	if _player != null:
		return _player.global_position
	return global_position - global_transform.basis.z

func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))

func _is_target_dead(target: Node3D) -> bool:
	if target == null:
		return true
	if target.has_method("is_dead"):
		if bool(target.call("is_dead")):
			return true
	if _is_target_hidden(target):
		return true
	return bool(target.get_meta("dead", false))

func _is_target_hidden(target: Node3D) -> bool:
	if target == null:
		return false
	if target.has_method("is_hidden_from_monsters"):
		return bool(target.call("is_hidden_from_monsters"))
	return bool(target.get_meta("hidden_from_monsters", false))

func _update_red_light_pressure(delta: float) -> void:
	if monster_role != "red" or _state == State.DEAD:
		return
	_red_flicker_timer -= delta
	if _red_flicker_timer > 0.0:
		return
	_red_flicker_timer = red_light_flicker_interval
	if _lighting_controller == null:
		_lighting_controller = get_node_or_null(lighting_controller_path)
	if _lighting_controller != null and _lighting_controller.has_method("trigger_red_monster_flicker"):
		_lighting_controller.call("trigger_red_monster_flicker", global_position, red_light_flicker_radius)

func _should_flee_from_player() -> bool:
	if _player == null or not is_inside_tree() or _is_target_dead(_player):
		return false

	var to_player := _player.global_position - global_position
	to_player.y = 0.0
	var distance := to_player.length()
	if distance <= panic_distance and _has_clear_line_to_player():
		return true

	return _can_see_player()

func _can_see_player() -> bool:
	if _player == null or not is_inside_tree() or _is_target_dead(_player):
		return false

	var to_player := _player.global_position - global_position
	to_player.y = 0.0
	var distance := to_player.length()
	if distance <= 0.0001 or distance > vision_distance:
		return false

	var forward := -global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() <= 0.0001:
		return false
	forward = forward.normalized()

	var direction := to_player.normalized()
	var minimum_dot := cos(deg_to_rad(vision_fov_degrees) * 0.5)
	if forward.dot(direction) < minimum_dot:
		return false

	return _has_clear_line_to_player()

func _has_clear_line_to_player() -> bool:
	if _player == null or not is_inside_tree() or _is_target_dead(_player):
		return false
	var ray_from := global_position + Vector3.UP * eye_height
	var ray_to := _player.global_position + Vector3.UP * _target_detection_height(_player, player_target_height)
	var query := PhysicsRayQueryParameters3D.create(ray_from, ray_to)
	var exclude: Array[RID] = []
	exclude.append(get_rid())
	query.exclude = exclude
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return true

	var collider: Variant = hit.get("collider")
	return _is_player_collider(collider)

func _update_ground_safety() -> void:
	if is_on_floor() and global_position.y > fall_recover_y:
		_remember_safe_floor_position()
	elif global_position.y < fall_recover_y:
		_recover_to_last_safe_floor()

func _remember_safe_floor_position() -> void:
	_last_safe_floor_position = global_position
	if _last_safe_floor_position.y < 0.05:
		_last_safe_floor_position.y = 0.05
	_has_safe_floor_position = true

func _recover_to_last_safe_floor() -> void:
	if not _has_safe_floor_position:
		_last_safe_floor_position = global_position
		_last_safe_floor_position.y = 0.05
		_has_safe_floor_position = true
	global_position = _last_safe_floor_position
	velocity = Vector3.ZERO
	_has_last_flee_position = false
	_flee_stuck_timer = 0.0

func _is_player_collider(collider: Variant) -> bool:
	if _player == null or not (collider is Node):
		return false
	var collider_node := collider as Node
	return collider_node == _player or _player.is_ancestor_of(collider_node)

func _is_target_collider(collider: Variant, target: Node3D) -> bool:
	if target == null or not (collider is Node):
		return false
	var collider_node := collider as Node
	return collider_node == target or target.is_ancestor_of(collider_node)

func _configure_model_shadows(node: Node) -> void:
	if not cast_model_shadows:
		return
	var mesh_instance := node as MeshInstance3D
	if mesh_instance != null:
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		mesh_instance.layers = ACTOR_LIGHT_LAYER
	for child in node.get_children():
		_configure_model_shadows(child)

func _configure_role_visuals() -> void:
	set_meta("monster_role", monster_role)
	if monster_role == "nightmare":
		add_to_group("nightmare_monster", true)
		return
	if monster_role != "red":
		return
	add_to_group("red_monster", true)
	if red_role_tint_visual:
		var model_root := get_node_or_null("ModelRoot") as Node
		if model_root == null:
			model_root = self
		_apply_material_to_meshes(model_root, _make_red_monster_material())
	if attach_escape_key:
		set_meta("has_escape_key", true)
		_ensure_escape_key_visual()

func _apply_material_to_meshes(node: Node, material: Material) -> void:
	var mesh_instance := node as MeshInstance3D
	if mesh_instance != null:
		mesh_instance.material_override = material
	for child in node.get_children():
		_apply_material_to_meshes(child, material)

func _make_red_monster_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.resource_name = "RedMonsterBody"
	material.albedo_color = Color(0.82, 0.055, 0.035, 1.0)
	material.roughness = 0.88
	material.emission_enabled = true
	material.emission = Color(0.36, 0.015, 0.01, 1.0)
	material.emission_energy_multiplier = 0.22
	return material

func _ensure_escape_key_visual() -> void:
	if get_node_or_null("ChestEscapeKey") != null:
		return
	var key_root := Node3D.new()
	key_root.name = "ChestEscapeKey"
	key_root.position = Vector3(0.0, 1.18, 0.52)
	key_root.rotation_degrees = Vector3(0.0, 0.0, -7.0)
	key_root.scale = Vector3(0.84, 0.84, 0.84)
	key_root.add_to_group("escape_key_visual", true)
	key_root.set_meta("escape_key_owner", "red_monster")
	add_child(key_root)

	var gold := _make_escape_key_material()
	var dark := _make_escape_key_cord_material()
	_add_key_box(key_root, "CordLeft", Vector3(-0.045, 0.19, 0.0), Vector3(0.018, 0.18, 0.014), dark)
	_add_key_box(key_root, "CordRight", Vector3(0.045, 0.19, 0.0), Vector3(0.018, 0.18, 0.014), dark)
	_add_key_box(key_root, "BowTop", Vector3(0.0, 0.105, -0.006), Vector3(0.18, 0.032, 0.03), gold)
	_add_key_box(key_root, "BowBottom", Vector3(0.0, 0.025, -0.006), Vector3(0.18, 0.032, 0.03), gold)
	_add_key_box(key_root, "BowLeft", Vector3(-0.074, 0.065, -0.006), Vector3(0.032, 0.105, 0.03), gold)
	_add_key_box(key_root, "BowRight", Vector3(0.074, 0.065, -0.006), Vector3(0.032, 0.105, 0.03), gold)
	_add_key_box(key_root, "Shaft", Vector3(0.0, -0.105, -0.006), Vector3(0.046, 0.28, 0.03), gold)
	_add_key_box(key_root, "ToothA", Vector3(0.055, -0.22, -0.006), Vector3(0.11, 0.046, 0.03), gold)
	_add_key_box(key_root, "ToothB", Vector3(0.086, -0.168, -0.006), Vector3(0.048, 0.07, 0.03), gold)

func _make_escape_key_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.resource_name = "RedMonsterChestKeyGold"
	material.albedo_color = Color(1.0, 0.74, 0.18, 1.0)
	material.roughness = 0.36
	material.metallic = 0.65
	material.emission_enabled = true
	material.emission = Color(1.0, 0.58, 0.08, 1.0)
	material.emission_energy_multiplier = 0.55
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material

func _make_escape_key_cord_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.resource_name = "RedMonsterChestKeyCord"
	material.albedo_color = Color(0.035, 0.027, 0.018, 1.0)
	material.roughness = 0.95
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material

func _add_key_box(parent: Node3D, node_name: String, local_position: Vector3, size: Vector3, material: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.position = local_position
	parent.add_child(instance)

func _drop_escape_key_pickup() -> void:
	if monster_role != "red" or not bool(get_meta("has_escape_key", false)):
		return
	set_meta("has_escape_key", false)
	var visual := get_node_or_null("ChestEscapeKey")
	if visual != null:
		visual.queue_free()
	var parent_node := get_parent() as Node3D
	if parent_node == null:
		return
	var key_root := Node3D.new()
	key_root.name = "EscapeKeyPickup"
	key_root.rotation_degrees = Vector3(-18.0, 0.0, 8.0)
	key_root.scale = Vector3(1.35, 1.35, 1.35)
	key_root.add_to_group("escape_key_pickup", true)
	key_root.set_meta("escape_key_owner", "red_monster")
	key_root.set_meta("collected", false)
	parent_node.add_child(key_root)
	key_root.global_position = global_position + Vector3(0.0, 0.28, 0.0)
	var gold := _make_escape_key_material()
	_add_key_box(key_root, "PickupBowTop", Vector3(0.0, 0.105, 0.0), Vector3(0.18, 0.032, 0.03), gold)
	_add_key_box(key_root, "PickupBowBottom", Vector3(0.0, 0.025, 0.0), Vector3(0.18, 0.032, 0.03), gold)
	_add_key_box(key_root, "PickupBowLeft", Vector3(-0.074, 0.065, 0.0), Vector3(0.032, 0.105, 0.03), gold)
	_add_key_box(key_root, "PickupBowRight", Vector3(0.074, 0.065, 0.0), Vector3(0.032, 0.105, 0.03), gold)
	_add_key_box(key_root, "PickupShaft", Vector3(0.0, -0.105, 0.0), Vector3(0.046, 0.28, 0.03), gold)
	_add_key_box(key_root, "PickupToothA", Vector3(0.055, -0.22, 0.0), Vector3(0.11, 0.046, 0.03), gold)
	_add_key_box(key_root, "PickupToothB", Vector3(0.086, -0.168, 0.0), Vector3(0.048, 0.07, 0.03), gold)

func _die(attacker: Node = null) -> void:
	_state = State.DEAD
	_health = 0.0
	velocity = Vector3.ZERO
	set_meta("dead", true)
	set_meta("killed_by", attacker.name if attacker != null else "")
	_drop_escape_key_pickup()
	_play_animation(_animation_or_fallback(death_animation, idle_animation), 1.0)
	for child in get_children():
		var collision := child as CollisionShape3D
		if collision != null:
			collision.disabled = true

func _create_monster_audio() -> void:
	for path in MONSTER_FOOTSTEP_PATHS:
		var stream := _load_audio_stream(path)
		if stream != null:
			_footstep_streams.append(stream)

	_footstep_player = AudioStreamPlayer3D.new()
	_footstep_player.name = "MonsterFootstepAudio"
	_footstep_player.volume_db = monster_footstep_volume_db
	_footstep_player.max_distance = monster_footstep_max_distance
	add_child(_footstep_player)

	_roar_player = AudioStreamPlayer3D.new()
	_roar_player.name = "MonsterRoarAudio"
	_roar_player.stream = _load_audio_stream(MONSTER_ROAR_PATH)
	_roar_player.volume_db = monster_roar_volume_db
	_roar_player.max_distance = 18.0
	add_child(_roar_player)

	_attack_player = AudioStreamPlayer3D.new()
	_attack_player.name = "MonsterAttackAudio"
	_attack_player.stream = _load_audio_stream(MONSTER_ATTACK_PATH)
	_attack_player.volume_db = monster_attack_volume_db
	_attack_player.max_distance = 12.0
	add_child(_attack_player)

	if monster_role == "nightmare":
		_sonar_player = AudioStreamPlayer3D.new()
		_sonar_player.name = "NightmareSonarAudio"
		_sonar_player.stream = _load_audio_stream(NIGHTMARE_SONAR_PATH)
		_sonar_player.volume_db = nightmare_sonar_volume_db
		_sonar_player.max_distance = nightmare_sonar_max_distance
		add_child(_sonar_player)
		_reset_nightmare_sonar_timer()

func _update_monster_audio(delta: float) -> void:
	if _state == State.DEAD:
		return
	_update_nightmare_sonar(delta)
	if _footstep_streams.is_empty() or _footstep_player == null:
		return
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	if horizontal_speed <= 0.16 or not is_on_floor():
		_footstep_timer = minf(_footstep_timer, 0.05)
		return
	_footstep_timer -= delta
	if _footstep_timer > 0.0:
		return
	var fast := _state == State.FLEE or _state == State.CHASE
	_footstep_player.stream = _footstep_streams[_footstep_index % _footstep_streams.size()]
	if monster_role == "red":
		_footstep_player.pitch_scale = 0.92
	elif monster_role == "nightmare":
		_footstep_player.pitch_scale = 0.88
	else:
		_footstep_player.pitch_scale = 0.96
	_footstep_index += 1
	_play_one_shot(_footstep_player)
	_footstep_timer = monster_run_footstep_interval if fast else monster_walk_footstep_interval

func _update_nightmare_sonar(delta: float) -> void:
	if monster_role != "nightmare" or _sonar_player == null or _sonar_player.stream == null:
		return
	_sonar_timer -= delta
	if _sonar_timer > 0.0:
		return
	_sonar_player.pitch_scale = _rng.randf_range(0.88, 1.06)
	_play_one_shot(_sonar_player)
	_reset_nightmare_sonar_timer()

func _reset_nightmare_sonar_timer() -> void:
	_sonar_timer = _rng.randf_range(nightmare_sonar_interval_min, nightmare_sonar_interval_max)

func _play_one_shot(player: Node) -> void:
	var audio3d := player as AudioStreamPlayer3D
	if audio3d != null and audio3d.stream != null:
		audio3d.stop()
		audio3d.play()

func _load_audio_stream(path: String) -> AudioStream:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as AudioStream

func _find_animation_player(node: Node) -> AnimationPlayer:
	var player := node as AnimationPlayer
	if player != null:
		return player
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null

func _configure_animations() -> void:
	if _animation_player == null:
		return
	for animation_name_variant in _animation_player.get_animation_list():
		var animation_name := String(animation_name_variant)
		var animation: Animation = _animation_player.get_animation(StringName(animation_name))
		if animation == null:
			continue
		animation.loop_mode = Animation.LOOP_LINEAR
		if animation_name == attack_animation or animation_name == death_animation:
			animation.loop_mode = Animation.LOOP_NONE
		if lock_animation_root_motion:
			_disable_position_tracks(animation)
	_play_animation(idle_animation, 1.0)

func _disable_position_tracks(animation: Animation) -> void:
	for track_index in range(animation.get_track_count()):
		if animation.track_get_type(track_index) == Animation.TYPE_POSITION_3D:
			var track_path := String(animation.track_get_path(track_index))
			if track_path.contains("Skeleton3D:"):
				continue
			animation.track_set_enabled(track_index, false)

func _animation_or_fallback(animation_name: String, fallback_animation: String) -> String:
	if animation_name.is_empty():
		return fallback_animation
	if _animation_player == null or not _animation_player.has_animation(animation_name):
		return fallback_animation
	return animation_name

func _play_animation(animation_name: String, custom_speed: float) -> void:
	if _animation_player == null or animation_name.is_empty():
		return
	if not _animation_player.has_animation(animation_name):
		return
	MonsterSizeSource.apply_animation_ground_offset(self, monster_role, animation_name)
	if monster_role == "nightmare":
		_apply_nightmare_surface_visual_transform()
	_current_animation_base_speed = absf(custom_speed)
	if _current_animation == animation_name and _animation_player.is_playing():
		_set_animation_playback_speed(custom_speed)
		return
	_current_animation = animation_name
	_set_animation_playback_speed(custom_speed)
	_animation_player.play(animation_name, animation_blend_time, custom_speed, custom_speed < 0.0)

func _set_animation_playback_speed(playback_speed: float) -> void:
	if _animation_player == null:
		return
	_animation_player.speed_scale = playback_speed

func _update_locomotion_animation_direction() -> void:
	if _animation_player == null or not reverse_locomotion_when_backing:
		return
	if _current_animation != walk_animation and _current_animation != run_animation:
		return

	var horizontal_velocity := Vector3(velocity.x, 0.0, velocity.z)
	if horizontal_velocity.length_squared() <= locomotion_animation_speed_min * locomotion_animation_speed_min:
		return

	var forward := -global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() <= 0.0001:
		return
	forward = forward.normalized()

	var movement_direction := horizontal_velocity.normalized()
	_last_locomotion_forward_dot = forward.dot(movement_direction)
	var desired_speed := absf(_current_animation_base_speed)
	if _last_locomotion_forward_dot < reverse_locomotion_dot:
		desired_speed = -desired_speed
	if not is_equal_approx(_animation_player.speed_scale, desired_speed):
		_set_animation_playback_speed(desired_speed)
