extends Node3D

const MonsterSizeSource = preload("res://scripts/monster/MonsterSizeSource.gd")

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var handles := get_node_or_null("EditorSelectHandles")
	if handles != null:
		handles.queue_free()
	for child in get_children():
		var monster := child as Node3D
		if monster != null:
			MonsterSizeSource.apply_metadata_visual_yaw_offset(monster)
			MonsterSizeSource.apply_metadata_collision_override(monster)
