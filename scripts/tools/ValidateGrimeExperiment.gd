extends SceneTree

const GrimeOverlayBuilder = preload("res://scripts/visual/GrimeOverlayBuilder.gd")

const SCENE_PATH := "res://scenes/mvp/experiments/FourRoomMVP_grime_experiment.tscn"
const TEXTURES := [
	"res://materials/textures/grime/ceiling_edge_grime_01.png",
	"res://materials/textures/grime/ceiling_edge_grime_02.png",
	"res://materials/textures/grime/ceiling_edge_grime_03.png",
	"res://materials/textures/grime/baseboard_dirt_01.png",
	"res://materials/textures/grime/baseboard_dirt_02.png",
	"res://materials/textures/grime/baseboard_dirt_03.png",
	"res://materials/textures/grime/corner_grime_01.png",
	"res://materials/textures/grime/corner_grime_02.png",
	"res://materials/textures/grime/corner_grime_03.png",
]

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	if not _validate_textures():
		return

	var packed := load(SCENE_PATH) as PackedScene
	if packed == null:
		_fail("Failed to load %s." % SCENE_PATH)
		return
	var scene := packed.instantiate() as Node3D
	if scene == null:
		_fail("Failed to instantiate %s." % SCENE_PATH)
		return

	scene.set("build_on_ready", false)
	root.add_child(scene)
	current_scene = scene
	await process_frame

	if scene.get_node_or_null("LevelRoot/Experiment_ContactAO") == null:
		_fail("Grime experiment must be layered on top of the contact AO experiment.")
		return
	if scene.get_node_or_null("LevelRoot/Experiment_Grime") == null:
		_fail("Grime experiment marker is missing.")
		return

	var overlay_root := scene.get_node_or_null("LevelRoot/Geometry/GrimeOverlays")
	if overlay_root == null:
		_fail("GrimeOverlays root is missing.")
		return

	var counts := {
		GrimeOverlayBuilder.TYPE_CEILING_EDGE: 0,
		GrimeOverlayBuilder.TYPE_BASEBOARD: 0,
		GrimeOverlayBuilder.TYPE_CORNER: 0,
	}
	for node in scene.get_tree().get_nodes_in_group("grime_overlay"):
		var mesh := node as MeshInstance3D
		if mesh == null:
			_fail("grime_overlay group contains a non-mesh node: %s." % node.get_path())
			return
		if mesh.get_parent() != overlay_root:
			_fail("Grime overlay is not under GrimeOverlays: %s." % mesh.get_path())
			return
		if mesh.get_child_count() != 0:
			_fail("Grime overlay must not own collision or child nodes: %s." % mesh.get_path())
			return
		if mesh.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			_fail("Grime overlay must not cast shadows: %s." % mesh.get_path())
			return
		if not _validate_overlay_material(mesh):
			return
		if not _validate_overlay_size(mesh):
			return
		var grime_type := String(mesh.get_meta("grime_type", ""))
		if not counts.has(grime_type):
			_fail("Unexpected grime type: %s at %s." % [grime_type, mesh.get_path()])
			return
		counts[grime_type] = int(counts[grime_type]) + 1

	if int(counts[GrimeOverlayBuilder.TYPE_BASEBOARD]) < 6:
		_fail("Baseboard_Dirt should be common but light; found %d." % int(counts[GrimeOverlayBuilder.TYPE_BASEBOARD]))
		return
	if int(counts[GrimeOverlayBuilder.TYPE_CEILING_EDGE]) < 3:
		_fail("CeilingEdge_Grime should be present but subtle; found %d." % int(counts[GrimeOverlayBuilder.TYPE_CEILING_EDGE]))
		return
	if int(counts[GrimeOverlayBuilder.TYPE_CORNER]) < 2:
		_fail("Corner_Grime should exist in only some corners; found %d." % int(counts[GrimeOverlayBuilder.TYPE_CORNER]))
		return
	if int(counts[GrimeOverlayBuilder.TYPE_CORNER]) > 12:
		_fail("Corner_Grime is too dense for first pass: %d." % int(counts[GrimeOverlayBuilder.TYPE_CORNER]))
		return

	print("GRIME_EXPERIMENT_VALIDATION PASS ceiling=%d baseboard=%d corner=%d" % [
		int(counts[GrimeOverlayBuilder.TYPE_CEILING_EDGE]),
		int(counts[GrimeOverlayBuilder.TYPE_BASEBOARD]),
		int(counts[GrimeOverlayBuilder.TYPE_CORNER]),
	])
	quit(0)

func _validate_textures() -> bool:
	for path in TEXTURES:
		var image := Image.load_from_file(path)
		if image == null:
			_fail("Failed to load grime PNG: %s." % path)
			return false
		if image.get_format() != Image.FORMAT_RGBA8:
			_fail("Grime PNG must be RGBA8 true-alpha: %s format=%d." % [path, image.get_format()])
			return false
		var max_alpha := 0.0
		var opaque_pixels := 0
		var colored_pixels := 0
		for y in range(image.get_height()):
			for x in range(image.get_width()):
				var color := image.get_pixel(x, y)
				max_alpha = maxf(max_alpha, color.a)
				if color.a > 0.98:
					opaque_pixels += 1
				if color.a > 0.02:
					colored_pixels += 1
		if max_alpha <= 0.05:
			_fail("Grime PNG has no visible alpha body: %s." % path)
			return false
		if max_alpha < 0.35 or max_alpha > 0.55:
			_fail("Grime PNG max alpha should stay near the requested 50%% pass: %s max=%.3f." % [path, max_alpha])
			return false
		if opaque_pixels > 0:
			_fail("Grime PNG must not contain opaque background pixels: %s." % path)
			return false
		if colored_pixels <= 6:
			_fail("Grime PNG has too few stain pixels: %s." % path)
			return false
		if image.get_pixel(0, 0).a > 0.01 or image.get_pixel(image.get_width() - 1, image.get_height() - 1).a > 0.01:
			_fail("Grime PNG corners must be transparent: %s." % path)
			return false
	return true

func _validate_overlay_material(mesh: MeshInstance3D) -> bool:
	var material := mesh.material_override as StandardMaterial3D
	if material == null:
		_fail("Grime overlay does not use StandardMaterial3D: %s." % mesh.get_path())
		return false
	if material.transparency != BaseMaterial3D.TRANSPARENCY_ALPHA:
		_fail("Grime overlay must use alpha transparency: %s." % mesh.get_path())
		return false
	if material.shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED:
		_fail("Grime overlay should be unshaded subtle stain color: %s." % mesh.get_path())
		return false
	if absf(material.albedo_color.a - 1.00) > 0.01:
		_fail("Grime overlay material must not multiply down the 50%% texture alpha: %.3f at %s." % [material.albedo_color.a, mesh.get_path()])
		return false
	if material.albedo_texture == null:
		_fail("Grime overlay has no alpha PNG texture: %s." % mesh.get_path())
		return false
	if not TEXTURES.has(material.albedo_texture.resource_path):
		_fail("Grime overlay texture is not one of the approved grime variants: %s." % material.albedo_texture.resource_path)
		return false
	return true

func _validate_overlay_size(mesh: MeshInstance3D) -> bool:
	var length_variant: Variant = mesh.get_meta("length", 0.0)
	var height_variant: Variant = mesh.get_meta("height", 0.0)
	var length := float(length_variant)
	var height := float(height_variant)
	var grime_type := String(mesh.get_meta("grime_type", ""))
	if length <= 0.0 or height <= 0.0:
		_fail("Grime overlay has invalid size metadata: %s." % mesh.get_path())
		return false
	if grime_type == GrimeOverlayBuilder.TYPE_CORNER:
		if length > 0.42 or height > 1.70:
			_fail("Corner_Grime must stay narrow/local: %s length=%.3f height=%.3f." % [mesh.get_path(), length, height])
			return false
	else:
		if length > 3.50 or height > 0.30:
			_fail("Edge grime must stay as a thin structural strip: %s length=%.3f height=%.3f." % [mesh.get_path(), length, height])
			return false
	return true

func _fail(message: String) -> void:
	push_error("GRIME_EXPERIMENT_VALIDATION FAIL: %s" % message)
	quit(1)
