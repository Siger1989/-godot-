extends SceneTree

const ALBEDO_PATH := "res://materials/textures/backrooms_floor_albedo.png"
const NORMAL_PATH := "res://materials/textures/backrooms_floor_normal.png"
const SIZE := 1024
const TILE_COUNT := 4
const TILE_SIZE := 256
const GROUT_WIDTH := 10

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var albedo: Image = Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var normal: Image = Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)

	for y in range(SIZE):
		for x in range(SIZE):
			albedo.set_pixel(x, y, _floor_color(x, y))
			normal.set_pixel(x, y, _normal_color(x, y))

	var albedo_result: Error = albedo.save_png(ALBEDO_PATH)
	if albedo_result != OK:
		_fail("Failed to save %s code=%d" % [ALBEDO_PATH, albedo_result])
		return

	var normal_result: Error = normal.save_png(NORMAL_PATH)
	if normal_result != OK:
		_fail("Failed to save %s code=%d" % [NORMAL_PATH, normal_result])
		return

	print("UNIFORM_FLOOR_TEXTURES_PASS albedo=%s normal=%s" % [ALBEDO_PATH, NORMAL_PATH])
	quit(0)

func _floor_color(x: int, y: int) -> Color:
	var local_x: int = x % TILE_SIZE
	var local_y: int = y % TILE_SIZE
	var edge_distance: int = min(local_x, TILE_SIZE - 1 - local_x)
	edge_distance = min(edge_distance, local_y)
	edge_distance = min(edge_distance, TILE_SIZE - 1 - local_y)

	var noise: float = _value_noise(x, y)
	var broad_noise: float = _value_noise(x / 4, y / 4)
	var base := Color(0.93, 0.92, 0.86, 1.0)
	var variation: float = (noise - 0.5) * 0.035 + (broad_noise - 0.5) * 0.026
	var result := Color(
		clampf(base.r + variation, 0.0, 1.0),
		clampf(base.g + variation, 0.0, 1.0),
		clampf(base.b + variation * 0.8, 0.0, 1.0),
		1.0
	)

	if edge_distance < 14:
		var edge_mix: float = 1.0 - float(edge_distance) / 14.0
		result = result.lerp(Color(0.82, 0.80, 0.72, 1.0), edge_mix * 0.10)

	if edge_distance < GROUT_WIDTH:
		var grout_mix: float = 1.0 - float(edge_distance) / float(GROUT_WIDTH)
		result = result.lerp(Color(0.70, 0.68, 0.61, 1.0), grout_mix * 0.50)

	var scratch: float = _scratch_value(x, y)
	if scratch > 0.93 and edge_distance > GROUT_WIDTH + 3:
		result = result.darkened((scratch - 0.93) * 0.18)

	return result

func _normal_color(x: int, y: int) -> Color:
	var local_x: int = x % TILE_SIZE
	var local_y: int = y % TILE_SIZE
	var dx: int = min(local_x, TILE_SIZE - 1 - local_x)
	var dy: int = min(local_y, TILE_SIZE - 1 - local_y)
	var nx: float = 0.0
	var ny: float = 0.0
	if dx < GROUT_WIDTH:
		nx = 0.26 if local_x < TILE_SIZE * 0.5 else -0.26
	if dy < GROUT_WIDTH:
		ny = 0.26 if local_y < TILE_SIZE * 0.5 else -0.26
	var roughness: float = (_value_noise(x, y) - 0.5) * 0.035
	return Color(
		clampf(0.5 + nx + roughness, 0.0, 1.0),
		clampf(0.5 + ny + roughness, 0.0, 1.0),
		1.0,
		1.0
	)

func _value_noise(x: int, y: int) -> float:
	var xi: int = x % SIZE
	var yi: int = y % SIZE
	var n: int = int(xi * 374761393 + yi * 668265263 + 1442695041)
	n = (n ^ (n >> 13)) * 1274126177
	n = n ^ (n >> 16)
	return float(n & 0xffff) / 65535.0

func _scratch_value(x: int, y: int) -> float:
	var n: int = int((x / 3) * 1103515245 + (y / 11) * 12345)
	n = n ^ (n >> 15)
	return float(n & 0xffff) / 65535.0

func _fail(message: String) -> void:
	push_error("UNIFORM_FLOOR_TEXTURES_FAIL %s" % message)
	quit(1)
