from __future__ import annotations

import math
import os
import random
from pathlib import Path

import bpy
from mathutils import Vector


PROJECT_ROOT = Path(os.environ.get("BACKROOMS_PROJECT_ROOT", Path.cwd())).resolve()
SOURCE_ROOT = PROJECT_ROOT / "artifacts" / "blender_sources" / "doors"
PROP_ROOT = PROJECT_ROOT / "assets" / "backrooms" / "props" / "doors"

ASSET_NAME = "OldOfficeDoor_A"
DOOR_WIDTH = 0.98
DOOR_HEIGHT = 2.09
DOOR_THICKNESS = 0.048

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


def mat(
    name: str,
    color: tuple[float, float, float, float],
    roughness: float = 0.82,
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
    roughness: float,
    variation: float,
    vertical_streak: float,
    seed: int,
) -> bpy.types.Material:
    material = mat(name, color, roughness)
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
    size: int = 96,
) -> bpy.types.Image:
    rng = random.Random(seed)
    image = bpy.data.images.new(f"{name}_procedural_albedo", size, size, alpha=True)
    image.colorspace_settings.name = "sRGB"
    column_streaks = [rng.uniform(-variation, variation) for _x in range(size)]
    pixels: list[float] = []
    for y in range(size):
        lower_dirt = max(0.0, 1.0 - y / float(size - 1)) ** 5.0
        for x in range(size):
            grain = rng.uniform(-variation, variation)
            streak = column_streaks[x] * vertical_streak
            broad = math.sin((x + seed) * 0.11) * math.sin((y + seed) * 0.07) * variation * 0.35
            dirt = lower_dirt * 0.10
            pixels.extend([
                _clamp(color[0] + grain + streak + broad - dirt),
                _clamp(color[1] + grain + streak + broad - dirt),
                _clamp(color[2] + grain + streak + broad - dirt),
                color[3],
            ])
    image.pixels.foreach_set(pixels)
    image.pack()
    return image


def _set_input_if_present(node: bpy.types.Node, input_name: str, value: object) -> None:
    if input_name in node.inputs:
        node.inputs[input_name].default_value = value


def _clamp(value: float) -> float:
    return max(0.0, min(1.0, value))


def make_materials() -> None:
    textured_mat("old_yellowed_door_panel", (0.55, 0.50, 0.39, 1.0), 0.92, 0.025, 0.42, 601)
    mat("door_edge_wear", (0.68, 0.62, 0.48, 1.0), 0.93)
    mat("door_bottom_grime", (0.18, 0.15, 0.10, 1.0), 0.97)
    mat("door_seam_shadow", (0.12, 0.11, 0.09, 1.0), 0.97)
    mat("dull_old_metal", (0.34, 0.33, 0.30, 1.0), 0.78, 0.45)
    mat("dark_handle_gap", (0.06, 0.055, 0.05, 1.0), 0.96)


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
    bevel_width: float = 0.01,
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


def add_round_plate(name: str, loc: tuple[float, float, float], radius: float, depth: float, material_name: str) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cylinder_add(vertices=20, radius=radius, depth=depth, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.rotation_euler[0] = math.radians(90.0)
    assign(obj, material_name)
    bevel(obj, 0.002)
    return obj


def create_old_office_door() -> None:
    front_y = -DOOR_THICKNESS * 0.5 - 0.003
    back_y = DOOR_THICKNESS * 0.5 + 0.003
    right_x = DOOR_WIDTH * 0.5
    left_x = -DOOR_WIDTH * 0.5

    cube_obj(
        "OldOfficeDoor_A_panel",
        (0.0, 0.0, DOOR_HEIGHT * 0.5),
        (DOOR_WIDTH, DOOR_THICKNESS, DOOR_HEIGHT),
        "old_yellowed_door_panel",
        0.012,
    )
    cube_obj("OldOfficeDoor_A_front_left_edge_wear", (left_x + 0.012, front_y, 1.10), (0.010, 0.006, 1.52), "door_edge_wear", 0.001)
    cube_obj("OldOfficeDoor_A_front_top_edge_wear", (-0.02, front_y, DOOR_HEIGHT - 0.020), (0.72, 0.006, 0.010), "door_edge_wear", 0.001)
    cube_obj("OldOfficeDoor_A_bottom_grime", (0.0, front_y, 0.105), (0.84, 0.006, 0.115), "door_bottom_grime", 0.002)
    cube_obj("OldOfficeDoor_A_bottom_edge_shadow", (0.0, front_y, 0.018), (0.94, 0.007, 0.016), "door_seam_shadow", 0.001)

    for z in (0.72, 1.36):
        cube_obj(f"OldOfficeDoor_A_faint_horizontal_seam_{z:.2f}", (0.0, front_y, z), (0.64, 0.004, 0.006), "door_seam_shadow", 0.001)
    cube_obj("OldOfficeDoor_A_small_scuff_a", (-0.15, front_y, 1.54), (0.13, 0.005, 0.014), "door_seam_shadow", 0.001)
    cube_obj("OldOfficeDoor_A_small_scuff_b", (0.18, front_y, 0.50), (0.17, 0.005, 0.016), "door_edge_wear", 0.001)

    handle_z = 1.02
    handle_x = -0.36
    add_round_plate("OldOfficeDoor_A_front_handle_plate", (handle_x, front_y - 0.008, handle_z), 0.058, 0.014, "dull_old_metal")
    cylinder_between("OldOfficeDoor_A_front_handle_lever", (handle_x, front_y - 0.020, handle_z), (handle_x + 0.16, front_y - 0.020, handle_z), 0.014, "dull_old_metal", 14)
    cube_obj("OldOfficeDoor_A_front_handle_gap", (handle_x, front_y - 0.029, handle_z), (0.035, 0.006, 0.035), "dark_handle_gap", 0.001)
    add_round_plate("OldOfficeDoor_A_back_handle_plate", (handle_x, back_y + 0.008, handle_z), 0.052, 0.014, "dull_old_metal")
    cylinder_between("OldOfficeDoor_A_back_handle_lever", (handle_x, back_y + 0.020, handle_z), (handle_x - 0.13, back_y + 0.020, handle_z), 0.012, "dull_old_metal", 12)

    for index, z in enumerate((0.37, 1.04, 1.72)):
        cube_obj(f"OldOfficeDoor_A_hinge_leaf_front_{index}", (right_x + 0.008, front_y, z), (0.030, 0.016, 0.155), "dull_old_metal", 0.003)
        cube_obj(f"OldOfficeDoor_A_hinge_leaf_back_{index}", (right_x + 0.008, back_y, z), (0.030, 0.016, 0.155), "dull_old_metal", 0.003)
        cylinder_between(
            f"OldOfficeDoor_A_hinge_pin_{index}",
            (right_x + 0.027, 0.0, z - 0.080),
            (right_x + 0.027, 0.0, z + 0.080),
            0.010,
            "dull_old_metal",
            10,
        )


def export_asset() -> None:
    reset_scene()
    make_materials()
    create_old_office_door()
    for obj in bpy.context.scene.objects:
        obj.select_set(False)
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
    print(f"BACKROOMS_DOOR_EXPORT {ASSET_NAME} glb={glb_path.relative_to(PROJECT_ROOT)} blend={blend_path.relative_to(PROJECT_ROOT)}")


def main() -> int:
    ensure_dirs()
    export_asset()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
