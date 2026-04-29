extends Node3D
class_name CeilingCutaway

@export var cutaway_radius := 20.0
@export var fade_radius := 30.0
@export var near_alpha := 0.0
@export var far_alpha := 0.18

var pieces: Array[MeshInstance3D] = []
var update_time := 0.0


func _ready() -> void:
	add_to_group("ceiling_cutaway")
	call_deferred("_scan_pieces")


func _process(delta: float) -> void:
	update_time -= delta
	if update_time > 0.0:
		return
	update_time = 0.12
	if pieces.is_empty():
		_scan_pieces()
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if not player:
		return
	for piece in pieces:
		if not is_instance_valid(piece):
			continue
		var distance := Vector2(piece.global_position.x, piece.global_position.z).distance_to(Vector2(player.global_position.x, player.global_position.z))
		var alpha := far_alpha
		if distance < cutaway_radius:
			alpha = near_alpha
		elif distance < fade_radius:
			alpha = lerp(near_alpha, far_alpha, (distance - cutaway_radius) / (fade_radius - cutaway_radius))
		var mat := piece.material_override as StandardMaterial3D
		if mat:
			var color := mat.albedo_color
			color.a = alpha
			mat.albedo_color = color


func _scan_pieces() -> void:
	pieces.clear()
	for node in get_tree().get_nodes_in_group("ceiling_piece"):
		if node is MeshInstance3D:
			pieces.append(node as MeshInstance3D)
