extends Node
class_name ObjectiveManager

signal objective_changed(text: String, fuse_count: int, required_fuses: int, power_restored: bool)
signal feedback(text: String)
signal game_won
signal game_lost(reason: String)

@export var required_fuses := 3

var fuse_count := 0
var power_restored := false
var ended := false


func _ready() -> void:
	add_to_group("objective_manager")
	call_deferred("_emit_objective")


func collect_fuse(label: String) -> void:
	if ended:
		return
	if fuse_count >= required_fuses:
		return
	fuse_count += 1
	feedback.emit("%s 已取得  (%d/%d)" % [label, fuse_count, required_fuses])
	_emit_objective()


func can_restore_power() -> bool:
	return fuse_count >= required_fuses and not power_restored


func restore_power() -> void:
	if ended:
		return
	if not can_restore_power():
		feedback.emit("电箱缺少保险丝：%d/%d" % [fuse_count, required_fuses])
		return
	power_restored = true
	feedback.emit("配电箱已恢复，出口区通电。")
	_emit_objective()


func can_open_exit() -> bool:
	return power_restored and not ended


func win_game() -> void:
	if ended:
		return
	ended = true
	feedback.emit("EXIT OPENED")
	game_won.emit()
	_emit_objective()


func lose_game(reason: String) -> void:
	if ended:
		return
	ended = true
	game_lost.emit(reason)
	_emit_objective()


func get_objective_text() -> String:
	if ended and power_restored:
		return "已逃离 Level 0"
	if ended:
		return "信号丢失"
	if not power_restored:
		if fuse_count < required_fuses:
			return "寻找保险丝 %d/%d" % [fuse_count, required_fuses]
		return "前往电气间修复配电箱"
	return "前往远端出口并打开金属门"


func _emit_objective() -> void:
	objective_changed.emit(get_objective_text(), fuse_count, required_fuses, power_restored)

