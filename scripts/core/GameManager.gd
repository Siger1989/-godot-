extends Node
class_name GameManager

var level: Node
var ui: Node
var objective_manager: Node


func _ready() -> void:
	add_to_group("game_manager")
	level = get_node_or_null("Level0_Demo")
	ui = get_node_or_null("UIRoot")
	objective_manager = get_tree().get_first_node_in_group("objective_manager")
	if objective_manager:
		objective_manager.objective_changed.connect(_on_objective_changed)
		objective_manager.feedback.connect(show_feedback)
		objective_manager.game_won.connect(_on_game_won)
		objective_manager.game_lost.connect(_on_game_lost)
	if ui and ui.has_method("set_game_manager"):
		ui.set_game_manager(self)
	if objective_manager:
		_on_objective_changed(
			objective_manager.get_objective_text(),
			objective_manager.fuse_count,
			objective_manager.required_fuses,
			objective_manager.power_restored
		)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		restart_demo()


func show_feedback(text: String) -> void:
	if ui and ui.has_method("show_feedback"):
		ui.show_feedback(text)


func lose_game(reason: String) -> void:
	if objective_manager:
		objective_manager.lose_game(reason)


func win_game() -> void:
	if objective_manager:
		objective_manager.win_game()


func restart_demo() -> void:
	get_tree().reload_current_scene()


func _on_objective_changed(text: String, fuse_count: int, required_fuses: int, power_restored: bool) -> void:
	if ui and ui.has_method("set_objective"):
		ui.set_objective(text, fuse_count, required_fuses, power_restored)


func _on_game_won() -> void:
	if ui and ui.has_method("show_result"):
		ui.show_result("ESCAPED", "出口门后的灯光吞掉了旧地毯的颜色。")


func _on_game_lost(reason: String) -> void:
	if ui and ui.has_method("show_result"):
		ui.show_result("LOST", reason)
