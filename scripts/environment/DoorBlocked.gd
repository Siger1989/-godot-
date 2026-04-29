extends "res://scripts/environment/DoorBase.gd"
class_name DoorBlocked


func _ready() -> void:
	super._ready()
	prompt_text = "被封死"
	mat_door.albedo_color = Color(0.37, 0.32, 0.22)
	_add_boards()


func interact(_player: Node) -> void:
	_feedback("木板钉得很死，后面没有声音。")


func _add_boards() -> void:
	var board_mat := StandardMaterial3D.new()
	board_mat.albedo_color = Color(0.25, 0.18, 0.11)
	board_mat.roughness = 0.95
	for i in 3:
		var board := _add_box(self, "Board_%d" % i, Vector3(0.0, 0.85 + i * 0.42, -0.11), Vector3(door_width + 0.35, 0.12, 0.08), board_mat, true)
		board.rotation.z = deg_to_rad(-8.0 + i * 7.0)

