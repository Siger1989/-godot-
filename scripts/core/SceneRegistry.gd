extends Node

var areas: Dictionary = {}
var portals: Dictionary = {}
var lights: Dictionary = {}
var markers: Dictionary = {}

func clear() -> void:
	areas.clear()
	portals.clear()
	lights.clear()
	markers.clear()

func register_area(area_id: StringName, node: Node) -> void:
	areas[area_id] = node

func register_portal(portal_id: StringName, node: Node) -> void:
	portals[portal_id] = node

func register_light(light_id: StringName, node: Node) -> void:
	lights[light_id] = node

func register_marker(marker_id: StringName, node: Node) -> void:
	markers[marker_id] = node
