extends SceneTree

const FORMAL_LAUNCHER := "res://run_game.bat"
const DIRECT_PROC_LAUNCHER := "res://run_proc_maze_test.bat"
const REMOVED_LAUNCHERS := [
	"res://run_feature_anchor_map.bat",
	"res://run_feature_room_preview.bat",
	"res://open_monster_size_source.bat",
	"res://open_mvp_monster_room.bat",
]

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	if not FileAccess.file_exists(FORMAL_LAUNCHER):
		_fail("missing formal launcher run_game.bat")
		return
	var run_game := FileAccess.get_file_as_string(FORMAL_LAUNCHER)
	if not run_game.contains("--path") or not run_game.contains("--log-file"):
		_fail("formal launcher does not run the project through Godot")
		return
	if run_game.contains("--scene"):
		_fail("formal launcher should use project.godot main_scene, not a debug scene override")
		return

	if not FileAccess.file_exists(DIRECT_PROC_LAUNCHER):
		_fail("missing direct proc-maze debug launcher")
		return
	var proc_debug := FileAccess.get_file_as_string(DIRECT_PROC_LAUNCHER)
	if not proc_debug.contains("res://scenes/tests/Test_ProcMazeMap.tscn"):
		_fail("direct proc-maze launcher no longer points at Test_ProcMazeMap")
		return

	for launcher in REMOVED_LAUNCHERS:
		if FileAccess.file_exists(launcher):
			_fail("removed debug launcher still exists: %s" % launcher)
			return

	print("PROJECT_LAUNCHERS_VALIDATION PASS formal=run_game.bat direct=run_proc_maze_test.bat removed=4")
	quit(0)

func _fail(message: String) -> void:
	push_error("PROJECT_LAUNCHERS_VALIDATION FAIL %s" % message)
	quit(1)
