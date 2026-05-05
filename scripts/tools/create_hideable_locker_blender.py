from __future__ import annotations

import math
import os
import random
from pathlib import Path

import bpy
from mathutils import Vector


PROJECT_ROOT = Path(os.environ.get("BACKROOMS_PROJECT_ROOT", Path.cwd())).resolve()
SOURCE_ROOT = PROJECT_ROOT / "artifacts" / "blender_sources" / "hideables"
PROP_ROOT = PROJECT_ROOT / "assets" / "backrooms" / "props" / "furniture"
ASSET_NAME = "HideLocker_A"

MATERIALS: dict[str, bpy.types.Material] = {}


def ensure_dirs() -> None:
    SOURCE_ROOT.mkdir(parents=True, exist_ok=True)
    PROP_ROOT.mkdir(parents=True, exist_ok=True)


def reset_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()
    bpy.context.scene.unit_settings.system = "METRIC"
    bpy.context.scene.render.engine = "BLENDER_EEVEE"
    MATERIALS.clear()


def _clamp(value: float) -> float:
    return max(0.0, min(1.0, value))


def _set_input_if_present(node: bpy.types.Node, input_name: str, value: object) -> None:
    if input_name in node.inputs:
        node.inputs[input_name].default_value = value


def _make_albedo_texture(
    name: str,
    color: tuple[float, float, float, float],
    variation: float,
    vertical_streak: float,
    seed: int,
    size: int = 128,
) -> bpy.types.Image:
    rng = random.Random(seed)
    image = bpy.data.images.new(f"{name}_procedural_albedo", size, size, alpha=True)
    image.colorspace_settings.name = "sRGB"
    column_streaks = [rng.uniform(-variation, variation) for _x in range(size)]
    row_smudges = [rng.uniform(-variation * 0.55, variation * 0.55) for _y in range(size)]
    pixels: list[float] = []
    for y in range(size):
        bottom_dust = max(0.0, 1.0 - y / (size * 0.35)) * variation * 1.2
        for x in range(size):
            grain = rng.uniform(-variation, variation)
            streak = column_streaks[x] * vertical_streak
            smudge = row_smudges[y] * 0.25
            broad = (
                math.sin((x * 0.24 + seed) * 0.21)
                * math.sin((y * 0.31 + seed) * 0.17)
                * variation
                * 0.45
            )
            speck = -variation * 1.7 if rng.random() < 0.012 else 0.0
            value = grain + streak + smudge + broad - bottom_dust * 0.55 + speck
            pixels.extend([
                _clamp(color[0] + value),
                _clamp(color[1] + value),
                _clamp(color[2] + value),
                color[3],
            ])
    image.pixels.foreach_set(pixels)
    image.pack()
    return image


def mat(
    name: str,
    color: tuple[float, float, float, float],
    roughness: float = 0.86,
    metallic: float = 0.0,
) -> bpy.types.Material:
    if name in MATERIALS:
        return MATERIALS[name]
    material = bpy.data.materials.new(name)
    material.diffuse_color = color
    material.use_nodes = True
    bsdf = next((node for node in material.node_tree.nodes if node.type == "BSDF_PRINCIPLED"), None)
    if bsdf is not None:
        _set_input_if_present(bsdf, "Base Color", color)
        _set_input_if_present(bsdf, "Roughness", roughness)
        _set_input_if_present(bsdf, "Metallic", metallic)
    MATERIALS[name] = material
    return material


def textured_mat(
    name: str,
    color: tuple[float, float, float, float],
    roughness: float = 0.9,
    metallic: float = 0.35,
    variation: float = 0.035,
    vertical_streak: float = 0.45,
    seed: int = 1,
) -> bpy.types.Material:
    material = mat(name, color, roughness, metallic)
    bsdf = next((node for node in material.node_tree.nodes if node.type == "BSDF_PRINCIPLED"), None)
    if bsdf == None or "Base Color" not in bsdf.inputs:
        return material
    image = _make_albedo_texture(name, color, variation, vertical_streak, seed)
    tex = material.node_tree.nodes.new("ShaderNodeTexImage")
    tex.name = f"{name}_procedural_albedo"
    tex.image = image
    material.diffuse_color = (1.0, 1.0, 1.0, color[3])
    _set_input_if_present(bsdf, "Base Color", (1.0, 1.0, 1.0, color[3]))
    material.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    return material


def make_materials() -> None:
    textured_mat(
        "old_beige_gray_locker_metal",
        (0.49, 0.47, 0.38, 1.0),
        roughness=0.92,
        metallic=0.32,
        variation=0.030,
        vertical_streak=0.58,
        seed=741,
    )
    textured_mat(
        "slightly_darker_side_metal",
        (0.41, 0.40, 0.33, 1.0),
        roughness=0.93,
        metallic=0.28,
        variation=0.024,
        vertical_streak=0.45,
        seed=742,
    )
    mat("locker_edge_wear", (0.61, 0.58, 0.48, 1.0), 0.94, 0.22)
    mat("dull_handle_metal", (0.42, 0.40, 0.34, 1.0), 0.80, 0.48)
    mat("dark_locker_interior", (0.025, 0.024, 0.020, 1.0), 0.98, 0.0)
    mat("subtle_rust", (0.38, 0.22, 0.12, 1.0), 0.96, 0.0)
    mat("rubber_foot_dark", (0.055, 0.052, 0.046, 1.0), 0.92, 0.0)
    mat("panel_shadow", (0.18, 0.17, 0.14, 1.0), 0.98, 0.0)


def assign(obj: bpy.types.Object, material_name: str) -> bpy.types.Object:
    obj.data.materials.append(MATERIALS[material_name])
    return obj


def bevel(obj: bpy.types.Object, width: float, segments: int = 1) -> None:
    if width <= 0.0:
        return
    modifier = obj.modifiers.new("small_soft_bevel", "BEVEL")
    modifier.width = width
    modifier.segments = segments
    modifier.affect = "EDGES"
    obj.modifiers.new("weighted_normals", "WEIGHTED_NORMAL")


def cube_obj(
    name: str,
    loc: tuple[float, float, float],
    size: tuple[float, float, float],
    material_name: str,
    bevel_width: float = 0.008,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    assign(obj, material_name)
    bevel(obj, bevel_width)
    return obj


def cylinder_between(
    name: str,
    p0: tuple[float, float, float],
    p1: tuple[float, float, float],
    radius: float,
    material_name: str,
    vertices: int = 12,
) -> bpy.types.Object:
    start = Vector(p0)
    end = Vector(p1)
    direction = end - start
    midpoint = (start + end) * 0.5
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=direction.length, location=midpoint)
    obj = bpy.context.object
    obj.name = name
    obj.rotation_euler = direction.to_track_quat("Z", "Y").to_euler()
    assign(obj, material_name)
    bevel(obj, radius * 0.10)
    return obj


def add_u_handle() -> None:
    front_y = -0.307
    x = -0.275
    z_low = 0.78
    z_high = 1.16
    y_outer = front_y - 0.035
    cylinder_between("HideLocker_A_front_pull_left_mount", (x, front_y, z_low), (x, y_outer, z_low), 0.013, "dull_handle_metal", 12)
    cylinder_between("HideLocker_A_front_pull_right_mount", (x, front_y, z_high), (x, y_outer, z_high), 0.013, "dull_handle_metal", 12)
    cylinder_between("HideLocker_A_front_pull_vertical_grip", (x, y_outer, z_low), (x, y_outer, z_high), 0.018, "dull_handle_metal", 14)
    cube_obj("HideLocker_A_handle_shadow", (x + 0.010, front_y + 0.002, 0.97), (0.030, 0.004, 0.44), "panel_shadow", 0.002)


def add_hinges() -> None:
    front_y = -0.300
    for index, z in enumerate((0.42, 1.04, 1.66)):
        cube_obj(f"HideLocker_A_right_hinge_leaf_{index}", (0.386, front_y - 0.008, z), (0.045, 0.020, 0.145), "dull_handle_metal", 0.004)
        cylinder_between(
            f"HideLocker_A_right_hinge_pin_{index}",
            (0.415, front_y - 0.012, z - 0.078),
            (0.415, front_y - 0.012, z + 0.078),
            0.014,
            "dull_handle_metal",
            12,
        )


def add_surface_wear() -> None:
    front_y = -0.319
    cube_obj("HideLocker_A_bottom_dust_band", (0.02, front_y, 0.185), (0.54, 0.006, 0.070), "panel_shadow", 0.002)
    cube_obj("HideLocker_A_front_low_scuff_left", (-0.130, front_y - 0.002, 0.390), (0.165, 0.006, 0.030), "locker_edge_wear", 0.002)
    cube_obj("HideLocker_A_front_low_scuff_right", (0.145, front_y - 0.002, 0.535), (0.120, 0.006, 0.026), "locker_edge_wear", 0.002)
    cube_obj("HideLocker_A_top_corner_wear_left", (-0.330, front_y - 0.002, 1.850), (0.065, 0.006, 0.120), "locker_edge_wear", 0.002)
    cube_obj("HideLocker_A_vertical_dirt_streak_a", (-0.055, front_y - 0.003, 1.310), (0.022, 0.005, 0.310), "panel_shadow", 0.001)
    cube_obj("HideLocker_A_vertical_dirt_streak_b", (0.210, front_y - 0.003, 1.020), (0.018, 0.005, 0.230), "panel_shadow", 0.001)
    cube_obj("HideLocker_A_small_rust_patch", (0.315, front_y - 0.003, 0.225), (0.048, 0.005, 0.030), "subtle_rust", 0.001)
    cube_obj("HideLocker_A_side_floor_rust", (0.393, -0.030, 0.130), (0.005, 0.185, 0.035), "subtle_rust", 0.001)


def add_view_slits() -> None:
    front_y = -0.315
    x_center = 0.030
    slot_width = 0.475
    slot_height = 0.030
    rail_height = 0.024
    first_z = 1.475
    slot_gap = 0.074

    cube_obj("HideLocker_A_upper_slit_left_stile", (-0.280, front_y, 1.640), (0.070, 0.036, 0.410), "old_beige_gray_locker_metal", 0.006)
    cube_obj("HideLocker_A_upper_slit_right_stile", (0.340, front_y, 1.640), (0.070, 0.036, 0.410), "old_beige_gray_locker_metal", 0.006)
    cube_obj("HideLocker_A_view_slit_top_rail", (x_center, front_y, 1.835), (0.620, 0.036, rail_height), "old_beige_gray_locker_metal", 0.005)
    cube_obj("HideLocker_A_view_slit_bottom_rail", (x_center, front_y, 1.435), (0.620, 0.036, rail_height), "old_beige_gray_locker_metal", 0.005)

    for index in range(6):
        z = first_z + index * slot_gap
        if index < 5:
            cube_obj(
                f"HideLocker_A_view_slit_divider_rail_{index:02d}",
                (x_center, front_y, z + slot_gap * 0.5),
                (0.590, 0.036, rail_height),
                "old_beige_gray_locker_metal",
                0.005,
            )


def create_hide_locker() -> None:
    width = 0.78
    depth = 0.56
    height = 1.95
    leg_height = 0.085
    wall = 0.045
    body_height = height - leg_height
    body_center_z = leg_height + body_height * 0.5

    cube_obj("HideLocker_A_left_side_panel", (-width * 0.5 + wall * 0.5, 0.0, body_center_z), (wall, depth, body_height), "slightly_darker_side_metal", 0.014)
    cube_obj("HideLocker_A_right_side_panel", (width * 0.5 - wall * 0.5, 0.0, body_center_z), (wall, depth, body_height), "slightly_darker_side_metal", 0.014)
    cube_obj("HideLocker_A_back_panel", (0.0, depth * 0.5 - wall * 0.5, body_center_z), (width, wall, body_height), "slightly_darker_side_metal", 0.014)
    cube_obj("HideLocker_A_top_cap", (0.0, 0.0, height - 0.035), (width + 0.060, depth + 0.055, 0.070), "old_beige_gray_locker_metal", 0.014)
    cube_obj("HideLocker_A_bottom_frame", (0.0, -0.010, leg_height + 0.030), (width, depth + 0.020, 0.060), "old_beige_gray_locker_metal", 0.010)

    for x in (-0.330, 0.330):
        for y in (-0.225, 0.225):
            cube_obj(f"HideLocker_A_recessed_foot_{x}_{y}", (x, y, leg_height * 0.5), (0.070, 0.070, leg_height), "rubber_foot_dark", 0.008)

    front_y = -depth * 0.5 - 0.018
    door_face_y = -depth * 0.5 - 0.035
    cube_obj("HideLocker_A_front_door_one_piece_panel", (0.030, door_face_y, 0.790), (0.675, 0.040, 1.280), "old_beige_gray_locker_metal", 0.018)
    cube_obj("HideLocker_A_front_door_left_seam", (-0.330, front_y - 0.002, 0.980), (0.018, 0.006, 1.680), "panel_shadow", 0.002)
    cube_obj("HideLocker_A_front_door_right_seam", (0.365, front_y - 0.002, 0.980), (0.018, 0.006, 1.680), "panel_shadow", 0.002)
    cube_obj("HideLocker_A_front_bottom_seam", (0.020, front_y - 0.002, 0.150), (0.635, 0.006, 0.018), "panel_shadow", 0.002)
    cube_obj("HideLocker_A_front_top_seam", (0.020, front_y - 0.002, 1.870), (0.635, 0.006, 0.018), "panel_shadow", 0.002)
    cube_obj("HideLocker_A_inner_dark_back_seen_through_slits", (0.030, 0.150, 1.640), (0.545, 0.014, 0.470), "dark_locker_interior", 0.002)

    add_view_slits()
    add_u_handle()
    add_hinges()
    add_surface_wear()

    bpy.ops.object.empty_add(type="PLAIN_AXES", location=(0.0, 0.0, 0.0))
    empty = bpy.context.object
    empty.name = "HideLocker_A_origin_floor_center"


def export_asset() -> None:
    reset_scene()
    make_materials()
    create_hide_locker()
    glb_path = PROP_ROOT / f"{ASSET_NAME}.glb"
    blend_path = SOURCE_ROOT / f"{ASSET_NAME}.blend"
    bpy.ops.wm.save_as_mainfile(filepath=str(blend_path))
    bpy.ops.export_scene.gltf(
        filepath=str(glb_path),
        export_format="GLB",
        export_apply=True,
        export_lights=False,
        export_cameras=False,
    )
    print(f"HIDEABLE_LOCKER_EXPORT glb={glb_path.relative_to(PROJECT_ROOT)} blend={blend_path.relative_to(PROJECT_ROOT)}")


def main() -> int:
    ensure_dirs()
    export_asset()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
