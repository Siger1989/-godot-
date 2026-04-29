extends Node
class_name InteractionManager


static func resolve_interactable(node: Node) -> Node:
	var current := node
	while current:
		if current.is_in_group("interactable"):
			return current
		current = current.get_parent()
	return null

