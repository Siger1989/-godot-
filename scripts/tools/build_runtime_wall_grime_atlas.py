from __future__ import annotations

import json
import math
import shutil
import time
from pathlib import Path

from PIL import Image, ImageChops, ImageFilter, ImageOps


PROJECT_ROOT = Path(__file__).resolve().parents[2]
LAYER_CONFIG = PROJECT_ROOT / "codex_tools" / "texture_tool" / "texture_layers.json"
WALL_ALBEDO = PROJECT_ROOT / "materials" / "textures" / "backrooms_wall_albedo.png"
ATLAS_PATH = PROJECT_ROOT / "materials" / "textures" / "backrooms_wall_runtime_grime_atlas.png"
CONFIG_PATH = PROJECT_ROOT / "materials" / "textures" / "backrooms_wall_runtime_grime_config.json"
BACKUP_DIR = PROJECT_ROOT / "materials" / "textures" / "_texture_tool_backups"
TILE_SIZE = 256
GRID_SIZE = 4


def _project_path(path: str) -> Path:
    return (PROJECT_ROOT / path).resolve()


def _load_wall_state() -> dict:
    if not LAYER_CONFIG.exists():
        return {}
    config = json.loads(LAYER_CONFIG.read_text(encoding="utf-8"))
    return config.get("wall", {}) if isinstance(config, dict) else {}


def _candidate_paths(wall_state: dict) -> list[Path]:
    seen: set[Path] = set()
    output: list[Path] = []
    for layer in wall_state.get("layers", []):
        if not bool(layer.get("enabled", True)):
            continue
        for raw_path in layer.get("pool", []):
            path = _project_path(str(raw_path))
            if path.exists() and path not in seen:
                seen.add(path)
                output.append(path)
    return output


def _make_alpha_from_luminance(image: Image.Image) -> Image.Image:
    gray = ImageOps.grayscale(image)
    histogram = gray.histogram()
    total = sum(histogram)
    cutoff = max(1, int(total * 0.82))
    running = 0
    background = 235
    for value, count in enumerate(histogram):
        running += count
        if running >= cutoff:
            background = value
            break

    alpha = gray.point(lambda value: max(0, min(255, int((background - value) * 2.8))))
    alpha = alpha.filter(ImageFilter.GaussianBlur(1.2))
    return alpha.point(lambda value: 0 if value < 10 else value)


def _horizontal_edge_mask(size: tuple[int, int]) -> Image.Image:
    width, height = size
    edge_width = max(1, int(width * 0.18))
    data = []
    for _y in range(height):
        for x in range(width):
            left = x / edge_width
            right = (width - 1 - x) / edge_width
            value = max(0.0, min(1.0, min(left, right)))
            value = value * value * (3.0 - 2.0 * value)
            data.append(int(255 * value))
    mask = Image.new("L", size)
    mask.putdata(data)
    return mask


def _tile_from_candidate(path: Path) -> Image.Image:
    source = Image.open(path).convert("RGBA")
    source.thumbnail((TILE_SIZE, TILE_SIZE), Image.Resampling.LANCZOS)
    tile = Image.new("RGBA", (TILE_SIZE, TILE_SIZE), (92, 78, 44, 0))
    x = (TILE_SIZE - source.width) // 2
    y = (TILE_SIZE - source.height) // 2
    source_rgb = source.convert("RGB")
    alpha = _make_alpha_from_luminance(source_rgb)
    alpha = ImageChops.multiply(alpha, _horizontal_edge_mask(alpha.size)).filter(ImageFilter.GaussianBlur(0.6))
    dark_rgb = ImageOps.grayscale(source_rgb).point(lambda value: max(32, min(150, int(value * 0.46)))).convert("RGB")
    stain = Image.merge("RGBA", (*dark_rgb.split(), alpha))
    tile.alpha_composite(stain, (x, y))
    return tile


def _fallback_tile(index: int) -> Image.Image:
    tile = Image.new("RGBA", (TILE_SIZE, TILE_SIZE), (96, 78, 42, 0))
    center_x = TILE_SIZE * (0.35 + 0.08 * (index % 4))
    center_y = TILE_SIZE * (0.35 + 0.06 * ((index // 4) % 4))
    for y in range(TILE_SIZE):
        for x in range(TILE_SIZE):
            dx = (x - center_x) / (TILE_SIZE * (0.22 + 0.02 * (index % 3)))
            dy = (y - center_y) / (TILE_SIZE * (0.13 + 0.02 * (index % 2)))
            value = max(0.0, 1.0 - math.sqrt(dx * dx + dy * dy))
            if value <= 0.0:
                continue
            alpha = int(140 * value * value)
            tile.putpixel((x, y), (68, 58, 34, alpha))
    return tile.filter(ImageFilter.GaussianBlur(1.0))


def build_atlas(candidates: list[Path]) -> None:
    atlas = Image.new("RGBA", (TILE_SIZE * GRID_SIZE, TILE_SIZE * GRID_SIZE), (0, 0, 0, 0))
    for index in range(GRID_SIZE * GRID_SIZE):
        tile = _tile_from_candidate(candidates[index % len(candidates)]) if candidates else _fallback_tile(index)
        atlas.alpha_composite(tile, ((index % GRID_SIZE) * TILE_SIZE, (index // GRID_SIZE) * TILE_SIZE))
    ATLAS_PATH.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(ATLAS_PATH)


def _clamp(value: float, low: float, high: float) -> float:
    return max(low, min(high, value))


def _safe_float(value, default: float) -> float:
    try:
        return float(value)
    except (TypeError, ValueError):
        return default


def _layer_axis_scale_range(layer: dict, axis: str, default_min: float = 0.45, default_max: float = 1.05) -> tuple[float, float]:
    legacy_min = _clamp(_safe_float(layer.get("scale_min", default_min), default_min), 0.05, 4.0)
    legacy_max = _clamp(_safe_float(layer.get("scale_max", default_max), default_max), 0.05, 4.0)
    if legacy_max < legacy_min:
        legacy_min, legacy_max = legacy_max, legacy_min
    scale_min = _clamp(_safe_float(layer.get(f"scale_{axis}_min", legacy_min), legacy_min), 0.05, 4.0)
    scale_max = _clamp(_safe_float(layer.get(f"scale_{axis}_max", legacy_max), legacy_max), 0.05, 4.0)
    if scale_max < scale_min:
        scale_min, scale_max = scale_max, scale_min
    return scale_min, scale_max


def _wall_runtime_config(wall_state: dict) -> dict:
    top_weight = 0.0
    bottom_weight = 0.0
    top_band = 0.28
    bottom_band = 0.28
    max_count = 0.0
    max_opacity = 0.0
    effective_count = 0.0
    random_rotation_enabled = False
    rotation_degrees = 0.0
    scale_weight = 0.0
    scale_x_total = 0.0
    scale_y_total = 0.0
    top_offset_weight = 0.0
    bottom_offset_weight = 0.0
    top_offset_total = 0.0
    bottom_offset_total = 0.0

    for layer in wall_state.get("layers", []):
        if not bool(layer.get("enabled", True)):
            continue
        count = max(1.0, _safe_float(layer.get("count", 1), 1.0))
        opacity = _clamp(_safe_float(layer.get("opacity", 0.5), 0.5), 0.0, 1.0)
        probability = _clamp(_safe_float(layer.get("probability", 1.0), 1.0), 0.0, 1.0)
        band = _clamp(_safe_float(layer.get("band", 0.28), 0.28), 0.05, 1.0)
        weight = count * probability * max(opacity, 0.05)
        placement = str(layer.get("placement", "bottom"))
        scale_x_min, scale_x_max = _layer_axis_scale_range(layer, "x")
        scale_y_min, scale_y_max = _layer_axis_scale_range(layer, "y")
        position_y_offset = _clamp(_safe_float(layer.get("position_y_offset", 0.0), 0.0), -1.0, 1.0)
        if bool(layer.get("random_rotation", False)):
            random_rotation_enabled = True
            rotation_degrees = max(rotation_degrees, _clamp(_safe_float(layer.get("rotation_degrees", 0.0), 0.0), 0.0, 180.0))

        if placement == "top":
            top_weight += weight
            top_band = max(top_band, band)
            top_offset_total += position_y_offset * weight
            top_offset_weight += weight
        elif placement == "bottom":
            bottom_weight += weight
            bottom_band = max(bottom_band, band)
            bottom_offset_total += position_y_offset * weight
            bottom_offset_weight += weight
        elif placement == "full":
            top_weight += weight * 0.5
            bottom_weight += weight * 0.5
            top_band = max(top_band, band)
            bottom_band = max(bottom_band, band)
            top_offset_total += position_y_offset * weight * 0.5
            bottom_offset_total += position_y_offset * weight * 0.5
            top_offset_weight += weight * 0.5
            bottom_offset_weight += weight * 0.5
        elif placement == "center":
            top_weight += weight * 0.35
            bottom_weight += weight * 0.35
            top_offset_total += position_y_offset * weight * 0.35
            bottom_offset_total += position_y_offset * weight * 0.35
            top_offset_weight += weight * 0.35
            bottom_offset_weight += weight * 0.35

        scale_x_total += ((scale_x_min + scale_x_max) * 0.5) * weight
        scale_y_total += ((scale_y_min + scale_y_max) * 0.5) * weight
        scale_weight += weight

        max_count = max(max_count, count)
        max_opacity = max(max_opacity, opacity)
        effective_count = max(effective_count, count * probability)

    if top_weight <= 0.0 and bottom_weight <= 0.0:
        top_weight = 1.0
        bottom_weight = 1.0
        max_count = 4.0
        effective_count = 4.0
        max_opacity = 0.5

    size_x_scale = scale_x_total / scale_weight if scale_weight > 0.0 else 1.0
    size_y_scale = scale_y_total / scale_weight if scale_weight > 0.0 else 1.0
    top_offset = top_offset_total / top_offset_weight if top_offset_weight > 0.0 else 0.0
    bottom_offset = bottom_offset_total / bottom_offset_weight if bottom_offset_weight > 0.0 else 0.0

    return {
        "top_weight": round(top_weight, 4),
        "bottom_weight": round(bottom_weight, 4),
        "top_band": round(_clamp(top_band, 0.06, 0.48), 4),
        "bottom_band": round(_clamp(bottom_band, 0.06, 0.48), 4),
        "density": round(_clamp(0.08 + effective_count / 8.0, 0.0, 0.92), 4),
        "strength": round(_clamp(max_opacity, 0.2, 0.85), 4),
        "random_rotation": random_rotation_enabled,
        "rotation_degrees": round(rotation_degrees, 4),
        "size_x_scale": round(_clamp(size_x_scale, 0.05, 4.0), 4),
        "size_y_scale": round(_clamp(size_y_scale, 0.05, 4.0), 4),
        "top_offset": round(_clamp(top_offset, -1.0, 1.0), 4),
        "bottom_offset": round(_clamp(bottom_offset, -1.0, 1.0), 4),
    }


def write_runtime_config(wall_state: dict) -> None:
    CONFIG_PATH.write_text(
        json.dumps(_wall_runtime_config(wall_state), ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def restore_wall_base(wall_state: dict) -> None:
    base_path = _project_path(str(wall_state.get("base_path", ""))) if wall_state.get("base_path") else None
    if base_path is None or not base_path.exists():
        return
    if WALL_ALBEDO.exists():
        BACKUP_DIR.mkdir(parents=True, exist_ok=True)
        backup = BACKUP_DIR / f"backrooms_wall_albedo_before_runtime_grime_{time.strftime('%Y%m%d_%H%M%S')}.png"
        shutil.copy2(WALL_ALBEDO, backup)
    shutil.copy2(base_path, WALL_ALBEDO)


def main() -> None:
    wall_state = _load_wall_state()
    candidates = _candidate_paths(wall_state)
    build_atlas(candidates)
    write_runtime_config(wall_state)
    restore_wall_base(wall_state)
    print(
        "RUNTIME_WALL_GRIME_ATLAS PASS "
        f"candidates={len(candidates)} "
        f"atlas={ATLAS_PATH.relative_to(PROJECT_ROOT)} "
        f"config={CONFIG_PATH.relative_to(PROJECT_ROOT)}"
    )


if __name__ == "__main__":
    main()
