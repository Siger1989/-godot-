extends RefCounted

const REQUIRED_FIELDS := [
	"id",
	"scene_path",
	"type",
	"footprint",
	"connectors",
	"allowed_rotations",
	"theme_tags",
	"can_be_main_path",
	"can_be_hub",
	"can_be_dead_end",
	"can_be_special",
]
const REQUIRED_SIDES := ["north", "east", "south", "west"]

var registry_path = ""
var registry_version = ""
var cell_size = 2.5
var modules = {}
var errors: Array[String] = []

func load_from_path(path: String) -> bool:
	registry_path = path
	registry_version = ""
	cell_size = 2.5
	modules.clear()
	errors.clear()

	if not FileAccess.file_exists(path):
		errors.append("Module registry not found: %s" % path)
		return false

	var text = FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		errors.append("Module registry is not a JSON object: %s" % path)
		return false

	registry_version = String(parsed.get("registry_version", ""))
	cell_size = float(parsed.get("cell_size", 2.5))
	var module_list = parsed.get("modules", [])
	if typeof(module_list) != TYPE_ARRAY or module_list.is_empty():
		errors.append("Module registry has no modules.")
		return false

	for module in module_list:
		if typeof(module) != TYPE_DICTIONARY:
			errors.append("Module entry is not an object.")
			continue
		_validate_and_add_module(module)

	return errors.is_empty()

func has_module(module_id: String) -> bool:
	return modules.has(module_id)

func get_module(module_id: String) -> Dictionary:
	return modules.get(module_id, {})

func get_module_ids() -> PackedStringArray:
	var ids = PackedStringArray()
	for module_id in modules.keys():
		ids.append(String(module_id))
	ids.sort()
	return ids

func module_supports_side(module_id: String, side: String, offset: int) -> bool:
	var module = get_module(module_id)
	if module.is_empty():
		return false
	var connector_list: Array = module.get("connectors", [])
	for connector in connector_list:
		if String(connector.get("side", "")) != side:
			continue
		var offsets: Array = connector.get("offsets", [])
		for connector_offset in offsets:
			if int(connector_offset) == offset:
				return true
	return false

func get_footprint_size(module_id: String) -> Vector2i:
	var module = get_module(module_id)
	var footprint: Dictionary = module.get("footprint", {})
	return Vector2i(int(footprint.get("w", 1)), int(footprint.get("h", 1)))

func _validate_and_add_module(module: Dictionary) -> void:
	for field in REQUIRED_FIELDS:
		if not module.has(field):
			errors.append("Module is missing required field `%s`: %s" % [field, String(module.get("id", "<unknown>"))])
			return

	var module_id = String(module["id"])
	if module_id.is_empty():
		errors.append("Module has empty id.")
		return
	if modules.has(module_id):
		errors.append("Duplicate module id: %s" % module_id)
		return

	var scene_path = String(module["scene_path"])
	if not ResourceLoader.exists(scene_path):
		errors.append("Module `%s` scene_path does not exist: %s" % [module_id, scene_path])

	var footprint = module["footprint"]
	if typeof(footprint) != TYPE_DICTIONARY:
		errors.append("Module `%s` footprint must be an object." % module_id)
	else:
		var w = int(footprint.get("w", 0))
		var h = int(footprint.get("h", 0))
		if w <= 0 or h <= 0:
			errors.append("Module `%s` footprint must be positive." % module_id)

	var rotations: Array = module.get("allowed_rotations", [])
	for rotation_value in rotations:
		var rotation = int(rotation_value)
		if rotation not in [0, 90, 180, 270]:
			errors.append("Module `%s` has invalid rotation: %s" % [module_id, str(rotation)])

	var sides = {}
	var connector_list: Array = module.get("connectors", [])
	for connector in connector_list:
		if typeof(connector) != TYPE_DICTIONARY:
			errors.append("Module `%s` connector is not an object." % module_id)
			continue
		var side = String(connector.get("side", ""))
		if side not in REQUIRED_SIDES:
			errors.append("Module `%s` has invalid connector side: %s" % [module_id, side])
			continue
		sides[side] = true
		if typeof(connector.get("offsets", [])) != TYPE_ARRAY:
			errors.append("Module `%s` connector `%s` offsets must be an array." % [module_id, side])
	for side_name in REQUIRED_SIDES:
		if not sides.has(side_name):
			errors.append("Module `%s` missing connector side: %s" % [module_id, side_name])

	modules[module_id] = module.duplicate(true)
