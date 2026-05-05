extends Node3D

@export var build_on_ready := false
@export_node_path("Node") var scene_builder_path: NodePath = ^"Systems/SceneBuilder"
@export_node_path("Node3D") var player_path: NodePath = ^"PlayerRoot/Player"
@export_node_path("Node3D") var player_spawn_path: NodePath = ^"LevelRoot/Markers/Spawn_Player_A"
@export_node_path("Node3D") var monster_path: NodePath = ^"MonsterRoot/Monster"
@export_node_path("Node3D") var monster_spawn_path: NodePath = ^"LevelRoot/Markers/Spawn_Monster_D"
@export_node_path("Node3D") var camera_rig_path: NodePath = ^"CameraRig"

func _ready() -> void:
	if build_on_ready:
		var scene_builder := get_node_or_null(scene_builder_path)
		if scene_builder != null and scene_builder.has_method("build"):
			scene_builder.build()
	_place_player_at_spawn()
	_place_monster_at_spawn()
	_snap_camera_to_player()

func _place_player_at_spawn() -> void:
	var player := get_node_or_null(player_path) as Node3D
	var spawn := get_node_or_null(player_spawn_path) as Node3D
	if player == null or spawn == null:
		return
	player.global_position = spawn.global_position

func _place_monster_at_spawn() -> void:
	var monster := get_node_or_null(monster_path) as Node3D
	var spawn := get_node_or_null(monster_spawn_path) as Node3D
	if monster == null or spawn == null:
		return
	monster.global_position = spawn.global_position

func _snap_camera_to_player() -> void:
	var camera_rig := get_node_or_null(camera_rig_path)
	if camera_rig != null and camera_rig.has_method("snap_to_target"):
		camera_rig.snap_to_target()
