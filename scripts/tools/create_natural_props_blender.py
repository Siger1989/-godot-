from __future__ import annotations

import math
import os
import random
import sys
from pathlib import Path

import bpy
from mathutils import Vector


PROJECT_ROOT = Path(os.environ.get("BACKROOMS_PROJECT_ROOT", Path.cwd())).resolve()
SOURCE_ROOT = PROJECT_ROOT / "artifacts" / "blender_sources" / "natural_props"
PROP_ROOT = PROJECT_ROOT / "assets" / "backrooms" / "props"


ASSET_DIRS = {
    "Box_Small_A": "boxes",
    "Box_Medium_A": "boxes",
    "Box_Large_A": "boxes",
    "Box_Stack_2_A": "boxes",
    "Box_Stack_3_A": "boxes",
    "Bucket_A": "cleaning",
    "Mop_A": "cleaning",
    "CleaningClothPile_A": "cleaning",
    "Chair_Old_A": "furniture",
    "SmallCabinet_A": "furniture",
    "MetalShelf_A": "furniture",
    "ElectricBox_A": "industrial",
    "Vent_Wall_A": "industrial",
    "Pipe_Straight_A": "industrial",
    "Pipe_Corner_A": "industrial",
}


MATERIALS: dict[str, bpy.types.Material] = {}


def ensure_dirs() -> None:
    SOURCE_ROOT.mkdir(parents=True, exist_ok=True)
    for directory in set(ASSET_DIRS.values()):
        (PROP_ROOT / directory).mkdir(parents=True, exist_ok=True)


def reset_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()
    bpy.context.scene.unit_settings.system = "METRIC"
    bpy.context.scene.render.engine = "BLENDER_EEVEE"
    MATERIALS.clear()


def mat(name: str, color: tuple[float, float, float, float], roughness: float = 0.82, metallic: float = 0.0) -> bpy.types.Material:
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
    roughness: float = 0.82,
    metallic: float = 0.0,
    variation: float = 0.045,
    vertical_streak: float = 0.25,
    seed: int = 1,
) -> bpy.types.Material:
    material = mat(name, color, roughness, metallic)
    bsdf = next((node for node in material.node_tree.nodes if node.type == "BSDF_PRINCIPLED"), None)
    if bsdf is None or "Base Color" not in bsdf.inputs:
        return material
    image = _make_albedo_texture(name, color, variation, vertical_streak, seed)
    tex = material.node_tree.nodes.new("ShaderNodeTexImage")
    tex.name = f"{name}_procedural_albedo"
    tex.image = image
    material.diffuse_color = (1.0, 1.0, 1.0, color[3])
    _set_input_if_present(bsdf, "Base Color", (1.0, 1.0, 1.0, color[3]))
    material.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    return material


def _make_albedo_texture(
    name: str,
    color: tuple[float, float, float, float],
    variation: float,
    vertical_streak: float,
    seed: int,
    size: int = 64,
) -> bpy.types.Image:
    rng = random.Random(seed)
    image = bpy.data.images.new(f"{name}_procedural_albedo", size, size, alpha=True)
    image.colorspace_settings.name = "sRGB"
    column_streaks = [rng.uniform(-variation, variation) for _x in range(size)]
    row_smudges = [rng.uniform(-variation * 0.55, variation * 0.55) for _y in range(size)]
    pixels: list[float] = []
    for y in range(size):
        for x in range(size):
            grain = rng.uniform(-variation, variation)
            streak = column_streaks[x] * vertical_streak
            smudge = row_smudges[y] * 0.25
            broad = math.sin((x * 0.33 + seed) * 0.23) * math.sin((y * 0.28 + seed) * 0.19) * variation * 0.45
            value = grain + streak + smudge + broad
            pixels.extend([
                _clamp(color[0] + value),
                _clamp(color[1] + value),
                _clamp(color[2] + value),
                color[3],
            ])
    image.pixels.foreach_set(pixels)
    image.pack()
    return image


def _clamp(value: float) -> float:
    return max(0.0, min(1.0, value))


def _set_input_if_present(node: bpy.types.Node, input_name: str, value: object) -> None:
    if input_name in node.inputs:
        node.inputs[input_name].default_value = value


def make_materials() -> None:
    mat("old_kraft_cardboard", (0.58, 0.43, 0.23, 1.0), 0.93)
    mat("cardboard_edge_wear", (0.72, 0.57, 0.34, 1.0), 0.94)
    mat("old_packing_tape", (0.55, 0.42, 0.23, 1.0), 0.78)
    mat("dust_dark", (0.22, 0.19, 0.14, 1.0), 0.96)
    textured_mat("old_blue_gray_plastic", (0.36, 0.45, 0.42, 1.0), 0.9, variation=0.022, vertical_streak=0.35, seed=201)
    mat("plastic_edge_wear", (0.39, 0.45, 0.42, 1.0), 0.92)
    mat("bucket_inner_shadow", (0.09, 0.11, 0.10, 1.0), 0.98)
    mat("aged_plastic_stain", (0.16, 0.18, 0.15, 1.0), 0.97)
    textured_mat("old_gray_cloth", (0.50, 0.48, 0.42, 1.0), 0.94, variation=0.035, vertical_streak=0.20, seed=301)
    textured_mat("old_offwhite_fabric", (0.55, 0.52, 0.45, 1.0), 0.95, variation=0.030, vertical_streak=0.16, seed=302)
    textured_mat("old_tan_vinyl", (0.52, 0.48, 0.39, 1.0), 0.9, variation=0.028, vertical_streak=0.18, seed=401)
    mat("vinyl_edge_wear", (0.63, 0.58, 0.46, 1.0), 0.93)
    mat("fabric_shadow", (0.29, 0.27, 0.22, 1.0), 0.96)
    mat("dull_metal_gray", (0.46, 0.44, 0.38, 1.0), 0.74, 0.45)
    mat("old_dark_metal", (0.25, 0.24, 0.22, 1.0), 0.78, 0.5)
    mat("old_wood", (0.48, 0.35, 0.22, 1.0), 0.86)
    textured_mat("old_beige_furniture", (0.55, 0.53, 0.46, 1.0), 0.9, variation=0.020, vertical_streak=0.22, seed=501)
    mat("cabinet_panel_shadow", (0.36, 0.35, 0.30, 1.0), 0.92)
    mat("subtle_rust", (0.42, 0.24, 0.13, 1.0), 0.94)
    mat("pipe_inner_dark", (0.05, 0.05, 0.045, 1.0), 0.96)


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


def cube_obj(name: str, loc: tuple[float, float, float], size: tuple[float, float, float], material_name: str, bevel_width: float = 0.01) -> bpy.types.Object:
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
    bevel(obj, radius * 0.12)
    return obj


def curve_poly(name: str, points: list[tuple[float, float, float]], radius: float, material_name: str) -> bpy.types.Object:
    curve = bpy.data.curves.new(name, "CURVE")
    curve.dimensions = "3D"
    curve.resolution_u = 2
    curve.bevel_depth = radius
    curve.bevel_resolution = 2
    spline = curve.splines.new("POLY")
    spline.points.add(len(points) - 1)
    for point, coords in zip(spline.points, points):
        point.co = (coords[0], coords[1], coords[2], 1.0)
    obj = bpy.data.objects.new(name, curve)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(MATERIALS[material_name])
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.convert(target="MESH")
    obj = bpy.context.object
    obj.name = name
    return obj


def add_cardboard_detail(prefix: str, dims: tuple[float, float, float], offset: tuple[float, float, float] = (0, 0, 0)) -> None:
    x, y, z = dims
    ox, oy, oz = offset
    top = oz + z
    cube_obj(f"{prefix}_top_tape_long", (ox, oy, top + 0.003), (x * 0.18, y * 0.96, 0.006), "old_packing_tape", 0.002)
    cube_obj(f"{prefix}_top_tape_cross", (ox, oy, top + 0.006), (x * 0.96, y * 0.055, 0.006), "old_packing_tape", 0.002)
    cube_obj(f"{prefix}_front_bottom_wear", (ox - x * 0.16, oy - y * 0.502, oz + z * 0.09), (x * 0.34, 0.004, z * 0.025), "cardboard_edge_wear", 0.001)
    cube_obj(f"{prefix}_side_edge_wear", (ox + x * 0.502, oy + y * 0.15, oz + z * 0.56), (0.004, y * 0.35, z * 0.035), "cardboard_edge_wear", 0.001)
    cube_obj(f"{prefix}_small_scuff", (ox + x * 0.18, oy - y * 0.503, oz + z * 0.42), (x * 0.18, 0.004, z * 0.035), "dust_dark", 0.001)


def create_box(prefix: str, dims: tuple[float, float, float], offset: tuple[float, float, float] = (0, 0, 0)) -> None:
    x, y, z = dims
    ox, oy, oz = offset
    cube_obj(f"{prefix}_body", (ox, oy, oz + z * 0.5), dims, "old_kraft_cardboard", 0.018)
    add_cardboard_detail(prefix, dims, offset)


def asset_box_small() -> None:
    create_box("Box_Small_A", (0.35, 0.35, 0.30))


def asset_box_medium() -> None:
    create_box("Box_Medium_A", (0.50, 0.40, 0.40))


def asset_box_large() -> None:
    create_box("Box_Large_A", (0.70, 0.50, 0.50))


def asset_box_stack_2() -> None:
    create_box("Box_Stack_2_A_bottom", (0.60, 0.44, 0.38), (0.00, 0.00, 0.00))
    create_box("Box_Stack_2_A_top", (0.45, 0.36, 0.32), (-0.07, 0.04, 0.38))


def asset_box_stack_3() -> None:
    create_box("Box_Stack_3_A_bottom", (0.70, 0.50, 0.42), (0.00, 0.00, 0.00))
    create_box("Box_Stack_3_A_mid", (0.55, 0.42, 0.36), (0.05, -0.02, 0.42))
    create_box("Box_Stack_3_A_top", (0.38, 0.34, 0.28), (-0.10, 0.05, 0.78))


def asset_bucket() -> None:
    height = 0.35
    bpy.ops.mesh.primitive_cone_add(vertices=24, radius1=0.16, radius2=0.20, depth=height, location=(0, 0, height * 0.5))
    body = bpy.context.object
    body.name = "Bucket_A_body"
    assign(body, "old_blue_gray_plastic")
    bevel(body, 0.006)
    bpy.ops.mesh.primitive_torus_add(major_radius=0.20, minor_radius=0.012, major_segments=24, minor_segments=6, location=(0, 0, height + 0.005))
    rim = bpy.context.object
    rim.name = "Bucket_A_rolled_rim"
    assign(rim, "old_blue_gray_plastic")
    bpy.ops.mesh.primitive_cylinder_add(vertices=24, radius=0.145, depth=0.008, location=(0, 0, height + 0.004))
    inner = bpy.context.object
    inner.name = "Bucket_A_dark_inner"
    assign(inner, "bucket_inner_shadow")
    bevel(inner, 0.002)
    curve_poly("Bucket_A_handle", [(-0.19, -0.01, 0.25), (-0.14, -0.14, 0.39), (0.0, -0.20, 0.43), (0.14, -0.14, 0.39), (0.19, -0.01, 0.25)], 0.006, "dull_metal_gray")
    cube_obj("Bucket_A_front_rim_wear", (-0.055, -0.194, 0.350), (0.11, 0.006, 0.014), "plastic_edge_wear", 0.002)
    cube_obj("Bucket_A_side_rim_wear", (0.185, 0.045, 0.348), (0.006, 0.085, 0.012), "plastic_edge_wear", 0.002)
    cube_obj("Bucket_A_front_scuff_01", (-0.070, -0.159, 0.205), (0.090, 0.005, 0.028), "aged_plastic_stain", 0.001)
    cube_obj("Bucket_A_front_scuff_02", (0.070, -0.157, 0.125), (0.055, 0.005, 0.022), "plastic_edge_wear", 0.001)
    cube_obj("Bucket_A_side_vertical_stain", (0.158, -0.055, 0.180), (0.005, 0.050, 0.130), "aged_plastic_stain", 0.001)
    cube_obj("Bucket_A_bottom_dust", (0.0, -0.155, 0.045), (0.18, 0.006, 0.025), "dust_dark", 0.002)


def asset_mop() -> None:
    cylinder_between("Mop_A_old_wood_handle", (0.08, 0.0, 0.18), (0.24, 0.0, 1.42), 0.018, "old_wood", 12)
    cylinder_between("Mop_A_handle_dark_wear_low", (0.095, 0.0, 0.30), (0.112, 0.0, 0.43), 0.019, "dust_dark", 12)
    cylinder_between("Mop_A_handle_worn_tip", (0.228, 0.0, 1.32), (0.240, 0.0, 1.42), 0.019, "cardboard_edge_wear", 12)
    cylinder_between("Mop_A_metal_collar", (0.05, 0.0, 0.15), (0.10, 0.0, 0.24), 0.028, "dull_metal_gray", 12)
    cube_obj("Mop_A_head_bar", (0.0, 0.0, 0.12), (0.34, 0.06, 0.045), "old_dark_metal", 0.008)
    cube_obj("Mop_A_head_edge_wear", (-0.08, -0.032, 0.143), (0.13, 0.006, 0.012), "dull_metal_gray", 0.002)
    for index in range(13):
        angle = -0.85 + index * 0.14
        x0 = math.sin(angle) * 0.07
        y0 = math.cos(angle) * 0.03
        x1 = math.sin(angle) * (0.14 + 0.04 * (index % 3))
        y1 = -0.15 - 0.015 * (index % 4)
        strand_material = "old_gray_cloth" if index % 3 != 0 else "fabric_shadow"
        cylinder_between(f"Mop_A_cloth_strand_{index:02d}", (x0, y0, 0.08), (x1, y1, 0.025), 0.009, strand_material, 8)
    cube_obj("Mop_A_cloth_matted_shadow", (0.055, -0.148, 0.045), (0.16, 0.025, 0.025), "fabric_shadow", 0.006)


def asset_cloth_pile() -> None:
    cube_obj("CleaningClothPile_A_bottom_fold", (0.0, 0.0, 0.025), (0.44, 0.30, 0.05), "old_offwhite_fabric", 0.025)
    cube_obj("CleaningClothPile_A_mid_fold", (-0.04, 0.025, 0.075), (0.38, 0.27, 0.045), "old_gray_cloth", 0.023)
    cube_obj("CleaningClothPile_A_top_fold", (0.05, -0.025, 0.12), (0.31, 0.23, 0.04), "old_offwhite_fabric", 0.022)
    cube_obj("CleaningClothPile_A_shadow_fold", (0.11, -0.13, 0.087), (0.18, 0.035, 0.025), "dust_dark", 0.01)


def asset_chair() -> None:
    cube_obj("Chair_Old_A_seat_cushion", (0.0, 0.0, 0.46), (0.46, 0.42, 0.07), "old_tan_vinyl", 0.035)
    cube_obj("Chair_Old_A_front_seam_shadow", (0.0, -0.214, 0.470), (0.39, 0.006, 0.018), "fabric_shadow", 0.002)
    cube_obj("Chair_Old_A_left_edge_wear", (-0.225, -0.015, 0.483), (0.012, 0.34, 0.012), "vinyl_edge_wear", 0.002)
    cube_obj("Chair_Old_A_seat_scuff_01", (-0.075, -0.060, 0.499), (0.115, 0.050, 0.006), "fabric_shadow", 0.002)
    cube_obj("Chair_Old_A_seat_scuff_02", (0.100, 0.075, 0.501), (0.075, 0.040, 0.006), "vinyl_edge_wear", 0.002)
    back = cube_obj("Chair_Old_A_back_cushion", (0.0, 0.205, 0.72), (0.48, 0.055, 0.34), "old_tan_vinyl", 0.035)
    back.rotation_euler[0] = math.radians(-6)
    back_wear = cube_obj("Chair_Old_A_back_top_wear", (0.0, 0.178, 0.885), (0.34, 0.008, 0.022), "vinyl_edge_wear", 0.002)
    back_wear.rotation_euler[0] = math.radians(-6)
    back_stain = cube_obj("Chair_Old_A_back_low_shadow", (-0.09, 0.174, 0.640), (0.17, 0.008, 0.052), "fabric_shadow", 0.002)
    back_stain.rotation_euler[0] = math.radians(-6)
    cube_obj("Chair_Old_A_underseat_shadow", (0.0, 0.010, 0.415), (0.40, 0.36, 0.030), "fabric_shadow", 0.006)
    for x in (-0.18, 0.18):
        for y in (-0.15, 0.15):
            cylinder_between(f"Chair_Old_A_leg_{x}_{y}", (x, y, 0.04), (x * 0.86, y * 0.82, 0.43), 0.015, "dull_metal_gray", 10)
    for x in (-0.18, 0.18):
        cylinder_between(f"Chair_Old_A_back_tube_{x}", (x, 0.17, 0.47), (x, 0.225, 0.88), 0.014, "dull_metal_gray", 10)
    for x in (-0.18, 0.18):
        for y in (-0.15, 0.15):
            cylinder_between(f"Chair_Old_A_black_foot_{x}_{y}", (x, y, 0.0), (x, y, 0.035), 0.021, "old_dark_metal", 10)


def asset_cabinet() -> None:
    cube_obj("SmallCabinet_A_body", (0.0, 0.0, 0.375), (0.45, 0.40, 0.75), "old_beige_furniture", 0.018)
    cube_obj("SmallCabinet_A_top_lip", (0.0, -0.01, 0.775), (0.49, 0.43, 0.04), "old_beige_furniture", 0.012)
    cube_obj("SmallCabinet_A_drawer_front", (0.0, -0.205, 0.60), (0.38, 0.018, 0.16), "old_beige_furniture", 0.01)
    cube_obj("SmallCabinet_A_door_front", (0.0, -0.207, 0.31), (0.38, 0.018, 0.32), "old_beige_furniture", 0.01)
    cube_obj("SmallCabinet_A_panel_gap", (0.0, -0.218, 0.49), (0.40, 0.006, 0.014), "cabinet_panel_shadow", 0.002)
    cylinder_between("SmallCabinet_A_drawer_handle", (-0.08, -0.235, 0.62), (0.08, -0.235, 0.62), 0.01, "dull_metal_gray", 10)
    cylinder_between("SmallCabinet_A_door_handle", (-0.16, -0.235, 0.27), (-0.16, -0.235, 0.40), 0.01, "dull_metal_gray", 10)
    cube_obj("SmallCabinet_A_base_shadow", (0.0, -0.01, 0.045), (0.43, 0.38, 0.05), "cabinet_panel_shadow", 0.008)


def asset_shelf() -> None:
    for x in (-0.48, 0.48):
        for y in (-0.18, 0.18):
            cylinder_between(f"MetalShelf_A_upright_{x}_{y}", (x, y, 0.0), (x, y, 1.80), 0.018, "dull_metal_gray", 10)
    for idx, z in enumerate((0.12, 0.62, 1.12, 1.62)):
        cube_obj(f"MetalShelf_A_shelf_{idx}", (0.0, 0.0, z), (1.0, 0.40, 0.045), "dull_metal_gray", 0.008)
        cube_obj(f"MetalShelf_A_front_lip_{idx}", (0.0, -0.215, z + 0.035), (1.03, 0.035, 0.055), "old_dark_metal", 0.006)
        cube_obj(f"MetalShelf_A_back_lip_{idx}", (0.0, 0.215, z + 0.035), (1.03, 0.035, 0.055), "old_dark_metal", 0.006)
    for z in (0.55, 1.05, 1.55):
        cylinder_between(f"MetalShelf_A_side_cross_l_{z}", (-0.50, -0.20, z - 0.20), (-0.50, 0.20, z + 0.20), 0.009, "old_dark_metal", 8)
        cylinder_between(f"MetalShelf_A_side_cross_r_{z}", (0.50, 0.20, z - 0.20), (0.50, -0.20, z + 0.20), 0.009, "old_dark_metal", 8)


def asset_electric_box() -> None:
    cube_obj("ElectricBox_A_body", (0.0, 0.0, 0.25), (0.35, 0.12, 0.50), "dull_metal_gray", 0.012)
    cube_obj("ElectricBox_A_front_door", (0.0, -0.064, 0.25), (0.31, 0.012, 0.43), "old_beige_furniture", 0.008)
    cube_obj("ElectricBox_A_door_seam", (0.0, -0.072, 0.25), (0.285, 0.004, 0.395), "cabinet_panel_shadow", 0.002)
    cylinder_between("ElectricBox_A_round_knob", (0.095, -0.086, 0.26), (0.095, -0.108, 0.26), 0.018, "dull_metal_gray", 12)
    for z in (0.09, 0.41):
        cube_obj(f"ElectricBox_A_hinge_{z}", (-0.18, -0.075, z), (0.025, 0.025, 0.07), "old_dark_metal", 0.004)
    for x in (-0.125, 0.125):
        cube_obj(f"ElectricBox_A_mount_tab_top_{x}", (x, 0.04, 0.54), (0.055, 0.025, 0.055), "dull_metal_gray", 0.005)


def asset_vent() -> None:
    cube_obj("Vent_Wall_A_frame", (0.0, 0.0, 0.175), (0.60, 0.05, 0.35), "dull_metal_gray", 0.012)
    cube_obj("Vent_Wall_A_dark_recess", (0.0, -0.028, 0.175), (0.51, 0.012, 0.25), "pipe_inner_dark", 0.004)
    for idx in range(6):
        z = 0.08 + idx * 0.038
        slat = cube_obj(f"Vent_Wall_A_horizontal_slat_{idx}", (0.0, -0.048, z), (0.50, 0.022, 0.022), "old_dark_metal", 0.004)
        slat.rotation_euler[0] = math.radians(-7)


def asset_pipe_straight() -> None:
    cylinder_between("Pipe_Straight_A_tube", (-0.50, 0.0, 0.08), (0.50, 0.0, 0.08), 0.045, "dull_metal_gray", 18)
    for x in (-0.38, 0.38):
        cylinder_between(f"Pipe_Straight_A_ring_{x}", (x, 0.0, 0.08), (x + 0.04, 0.0, 0.08), 0.052, "old_dark_metal", 18)
        cube_obj(f"Pipe_Straight_A_wall_bracket_{x}", (x, 0.055, 0.08), (0.05, 0.025, 0.18), "dull_metal_gray", 0.005)
        cube_obj(f"Pipe_Straight_A_bracket_tab_{x}", (x, 0.075, 0.18), (0.06, 0.025, 0.035), "dull_metal_gray", 0.004)
    cube_obj("Pipe_Straight_A_rust_patch", (-0.12, -0.047, 0.115), (0.10, 0.006, 0.018), "subtle_rust", 0.003)


def make_elbow_mesh(name: str, bend_radius: float, tube_radius: float, material_name: str) -> bpy.types.Object:
    ring_steps = 14
    tube_steps = 10
    verts = []
    faces = []
    for i in range(ring_steps + 1):
        theta = (math.pi * 0.5) * i / ring_steps
        center = Vector((math.cos(theta) * bend_radius, math.sin(theta) * bend_radius, 0.08))
        radial = Vector((math.cos(theta), math.sin(theta), 0))
        vertical = Vector((0, 0, 1))
        for j in range(tube_steps):
            phi = math.tau * j / tube_steps
            pos = center + radial * (math.cos(phi) * tube_radius) + vertical * (math.sin(phi) * tube_radius)
            verts.append(tuple(pos))
    for i in range(ring_steps):
        for j in range(tube_steps):
            a = i * tube_steps + j
            b = i * tube_steps + ((j + 1) % tube_steps)
            c = (i + 1) * tube_steps + ((j + 1) % tube_steps)
            d = (i + 1) * tube_steps + j
            faces.append((a, b, c, d))
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(MATERIALS[material_name])
    obj.modifiers.new("weighted_normals", "WEIGHTED_NORMAL")
    return obj


def asset_pipe_corner() -> None:
    make_elbow_mesh("Pipe_Corner_A_elbow_tube", 0.23, 0.045, "dull_metal_gray")
    cylinder_between("Pipe_Corner_A_x_stub", (-0.22, 0.0, 0.08), (0.25, 0.0, 0.08), 0.045, "dull_metal_gray", 18)
    cylinder_between("Pipe_Corner_A_y_stub", (0.0, -0.22, 0.08), (0.0, 0.25, 0.08), 0.045, "dull_metal_gray", 18)
    cube_obj("Pipe_Corner_A_bracket_x", (-0.08, 0.055, 0.08), (0.06, 0.025, 0.18), "dull_metal_gray", 0.005)
    cube_obj("Pipe_Corner_A_bracket_y", (0.055, -0.08, 0.08), (0.025, 0.06, 0.18), "dull_metal_gray", 0.005)
    cube_obj("Pipe_Corner_A_rust_patch", (0.18, 0.10, 0.125), (0.08, 0.006, 0.018), "subtle_rust", 0.003)


BUILDERS = {
    "Box_Small_A": asset_box_small,
    "Box_Medium_A": asset_box_medium,
    "Box_Large_A": asset_box_large,
    "Box_Stack_2_A": asset_box_stack_2,
    "Box_Stack_3_A": asset_box_stack_3,
    "Bucket_A": asset_bucket,
    "Mop_A": asset_mop,
    "CleaningClothPile_A": asset_cloth_pile,
    "Chair_Old_A": asset_chair,
    "SmallCabinet_A": asset_cabinet,
    "MetalShelf_A": asset_shelf,
    "ElectricBox_A": asset_electric_box,
    "Vent_Wall_A": asset_vent,
    "Pipe_Straight_A": asset_pipe_straight,
    "Pipe_Corner_A": asset_pipe_corner,
}


def export_asset(asset_name: str) -> None:
    reset_scene()
    make_materials()
    BUILDERS[asset_name]()
    for obj in bpy.context.scene.objects:
        obj.select_set(False)
    glb_path = PROP_ROOT / ASSET_DIRS[asset_name] / f"{asset_name}.glb"
    blend_path = SOURCE_ROOT / f"{asset_name}.blend"
    bpy.ops.wm.save_as_mainfile(filepath=str(blend_path))
    bpy.ops.export_scene.gltf(
        filepath=str(glb_path),
        export_format="GLB",
        export_apply=True,
        export_lights=False,
        export_cameras=False,
    )
    print(f"NATURAL_PROP_EXPORT {asset_name} glb={glb_path.relative_to(PROJECT_ROOT)} blend={blend_path.relative_to(PROJECT_ROOT)}")


def main() -> int:
    ensure_dirs()
    for asset_name in ASSET_DIRS:
        export_asset(asset_name)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
