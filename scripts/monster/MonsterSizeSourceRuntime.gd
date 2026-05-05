extends Node3D

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var handles := get_node_or_null("EditorSelectHandles")
	if handles != null:
		handles.queue_free()
