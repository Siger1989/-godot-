extends Node

var known_area_ids: Dictionary = {}

func remember_area(area_id: StringName) -> void:
	known_area_ids[area_id] = true

func has_area(area_id: StringName) -> bool:
	return known_area_ids.has(area_id)
