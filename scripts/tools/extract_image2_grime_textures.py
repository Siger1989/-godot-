from __future__ import annotations

import argparse
import shutil
from datetime import datetime
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageFilter


ROOT = Path(__file__).resolve().parents[2]
OUT_DIR = ROOT / "materials" / "textures" / "grime"
SOURCE_DIR = OUT_DIR / "source"
ARCHIVE_DIR = OUT_DIR / "archive"
SCREENSHOT_DIR = ROOT / "artifacts" / "screenshots"

OUTPUTS = [
    ("ceiling_edge_grime_01.png", (1024, 160), 128, (110, 102, 76), 0),
    ("ceiling_edge_grime_02.png", (1024, 160), 128, (119, 108, 78), 1),
    ("ceiling_edge_grime_03.png", (1024, 160), 128, (100, 99, 78), 2),
    ("baseboard_dirt_01.png", (1024, 192), 128, (110, 103, 80), 3),
    ("baseboard_dirt_02.png", (1024, 192), 128, (125, 109, 78), 4),
    ("baseboard_dirt_03.png", (1024, 192), 128, (104, 101, 82), 5),
    ("corner_grime_01.png", (320, 768), 128, (108, 102, 82), 6),
    ("corner_grime_02.png", (320, 768), 128, (120, 106, 80), 7),
    ("corner_grime_03.png", (320, 768), 128, (103, 101, 84), 8),
]


def _near_white(pixel: tuple[int, int, int]) -> bool:
    r, g, b = pixel
    return r > 238 and g > 238 and b > 238


def _find_separator_spans(image: Image.Image, axis: str) -> list[tuple[int, int]]:
    width, height = image.size
    limit = width if axis == "x" else height
    other_limit = height if axis == "x" else width
    separator = []
    pixels = image.load()
    for index in range(limit):
        white_count = 0
        for other in range(other_limit):
            pixel = pixels[index, other] if axis == "x" else pixels[other, index]
            if _near_white(pixel):
                white_count += 1
        separator.append(white_count / float(other_limit) > 0.88)

    spans: list[tuple[int, int]] = []
    start = None
    for index, is_sep in enumerate(separator):
        if is_sep and start is None:
            start = index
        elif not is_sep and start is not None:
            if index - start >= 4:
                spans.append((start, index))
            start = None
    if start is not None and limit - start >= 4:
        spans.append((start, limit))
    return spans


def _cell_bounds(image: Image.Image) -> list[tuple[int, int, int, int]]:
    width, height = image.size
    x_spans = _find_separator_spans(image, "x")
    y_spans = _find_separator_spans(image, "y")
    if len(x_spans) < 2 or len(y_spans) < 2:
        # Fallback for a regular 3x3 atlas with gutters.
        cell_w = width // 3
        cell_h = height // 3
        return [
            (col * cell_w, row * cell_h, (col + 1) * cell_w, (row + 1) * cell_h)
            for row in range(3)
            for col in range(3)
        ]

    xs = [(0, x_spans[0][0]), (x_spans[0][1], x_spans[1][0]), (x_spans[1][1], width)]
    ys = [(0, y_spans[0][0]), (y_spans[0][1], y_spans[1][0]), (y_spans[1][1], height)]
    return [(x0, y0, x1, y1) for y0, y1 in ys for x0, x1 in xs]


def _smoothstep(edge0: float, edge1: float, value: float) -> float:
    if edge0 == edge1:
        return 1.0 if value >= edge1 else 0.0
    t = max(0.0, min(1.0, (value - edge0) / (edge1 - edge0)))
    return t * t * (3.0 - 2.0 * t)


def _make_alpha_from_key(cell: Image.Image, max_alpha: int) -> Image.Image:
    cell = cell.convert("RGB")
    width, height = cell.size
    alpha = Image.new("L", (width, height), 0)
    source_pixels = cell.load()
    alpha_pixels = alpha.load()
    for y in range(height):
        for x in range(width):
            r, g, b = source_pixels[x, y]
            if _near_white((r, g, b)):
                continue
            # The generated source uses magenta key. Use distance from magenta
            # as a soft mask, then keep only the natural stain body.
            dr = abs(r - 255)
            dg = g
            db = abs(b - 255)
            distance = (dr * dr + dg * dg + db * db) ** 0.5
            mask = _smoothstep(42.0, 155.0, distance)
            alpha_pixels[x, y] = int(mask * max_alpha)
    alpha = alpha.filter(ImageFilter.GaussianBlur(1.1))
    return alpha.point(lambda value: 0 if value < 3 else value)


def _compose(alpha: Image.Image, color: tuple[int, int, int]) -> Image.Image:
    width, height = alpha.size
    image = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    alpha_pixels = alpha.load()
    out_pixels = image.load()
    noise = Image.effect_noise((width, height), 22).convert("L").filter(ImageFilter.GaussianBlur(3.0))
    noise_pixels = noise.load()
    for y in range(height):
        for x in range(width):
            a = alpha_pixels[x, y]
            if a <= 0:
                continue
            n = (noise_pixels[x, y] - 128) / 255.0
            r = max(72, min(150, int(color[0] + n * 10)))
            g = max(72, min(145, int(color[1] + n * 8)))
            b = max(58, min(125, int(color[2] + n * 6)))
            out_pixels[x, y] = (r, g, b, a)
    return image


def _clear_alpha_border(image: Image.Image, border: int = 3) -> Image.Image:
    image = image.copy()
    alpha = image.getchannel("A")
    draw = ImageDraw.Draw(alpha)
    width, height = alpha.size
    draw.rectangle((0, 0, width - 1, border - 1), fill=0)
    draw.rectangle((0, height - border, width - 1, height - 1), fill=0)
    draw.rectangle((0, 0, border - 1, height - 1), fill=0)
    draw.rectangle((width - border, 0, width - 1, height - 1), fill=0)
    image.putalpha(alpha)
    return image


def _archive_existing(timestamp: str) -> Path:
    archive = ARCHIVE_DIR / f"procedural_before_image2_{timestamp}"
    archive.mkdir(parents=True, exist_ok=True)
    for name, _, _, _, _ in OUTPUTS:
        src = OUT_DIR / name
        if src.exists():
            shutil.copy2(src, archive / name)
    return archive


def _make_contact_sheet(timestamp: str, outputs: list[Path]) -> Path:
    tile_w = 360
    tile_h = 250
    sheet = Image.new("RGB", (tile_w * 3, tile_h * 3), (31, 31, 31))
    draw = ImageDraw.Draw(sheet)
    try:
        font = ImageFont.truetype("arial.ttf", 16)
    except OSError:
        font = ImageFont.load_default()

    checker_a = (176, 176, 176)
    checker_b = (116, 116, 116)
    wall = (177, 153, 83)
    for index, path in enumerate(outputs):
        col = index % 3
        row = index // 3
        x0 = col * tile_w
        y0 = row * tile_h
        draw.rectangle((x0, y0, x0 + tile_w - 1, y0 + tile_h - 1), outline=(76, 76, 76))
        draw.text((x0 + 10, y0 + 8), path.name, fill=(238, 238, 238), font=font)
        img = Image.open(path).convert("RGBA")
        max_alpha = img.getchannel("A").getextrema()[1]

        preview_h = 172
        left_bg = Image.new("RGB", (tile_w // 2, preview_h), checker_a)
        checker = ImageDraw.Draw(left_bg)
        step = 18
        for yy in range(0, preview_h, step):
            for xx in range(0, tile_w // 2, step):
                if (xx // step + yy // step) % 2:
                    checker.rectangle((xx, yy, xx + step - 1, yy + step - 1), fill=checker_b)
        right_bg = Image.new("RGB", (tile_w // 2, preview_h), wall)
        left = _fit_rgba(img, left_bg.size)
        right = _fit_rgba(_boost_alpha(img, 3.0), right_bg.size)
        left_bg.paste(left, ((left_bg.width - left.width) // 2, (left_bg.height - left.height) // 2), left)
        right_bg.paste(right, ((right_bg.width - right.width) // 2, (right_bg.height - right.height) // 2), right)
        sheet.paste(left_bg, (x0, y0 + 38))
        sheet.paste(right_bg, (x0 + tile_w // 2, y0 + 38))
        draw.text((x0 + 10, y0 + tile_h - 28), f"maxA={max_alpha} | right alpha x3", fill=(238, 238, 238), font=font)

    SCREENSHOT_DIR.mkdir(parents=True, exist_ok=True)
    out = SCREENSHOT_DIR / f"grime_texture_image2_contact_sheet_{timestamp}.png"
    sheet.save(out)
    return out


def _fit_rgba(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    image = image.copy()
    image.thumbnail((size[0] - 12, size[1] - 12), Image.Resampling.LANCZOS)
    return image


def _boost_alpha(image: Image.Image, factor: float) -> Image.Image:
    image = image.copy()
    alpha = image.getchannel("A").point(lambda value: min(255, int(value * factor)))
    image.putalpha(alpha)
    return image


def _write_html(timestamp: str, preview: Path) -> Path:
    import base64

    data = base64.b64encode(preview.read_bytes()).decode("ascii")
    html = SCREENSHOT_DIR / f"grime_texture_image2_contact_sheet_{timestamp}.html"
    html.write_text(
        f"""<!doctype html>
<meta charset="utf-8">
<title>Image2 Grime Texture Preview</title>
<style>
body {{ margin: 0; background: #202020; color: #ddd; font-family: Arial, sans-serif; }}
main {{ padding: 16px; }}
img {{ max-width: 100%; height: auto; border: 1px solid #555; background: #111; }}
code {{ color: #eee; }}
</style>
<main>
<h1>Image2 Grime Texture Preview</h1>
<p>Left: original alpha on checkerboard. Right: alpha x3 on Backrooms wall color.</p>
<p><code>{preview.relative_to(ROOT).as_posix()}</code></p>
<img alt="image2 grime texture contact sheet" src="data:image/png;base64,{data}">
</main>
""",
        encoding="utf-8",
    )
    return html


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--atlas", required=True, type=Path)
    parser.add_argument("--timestamp", default=datetime.now().strftime("%Y%m%d_%H%M%S"))
    args = parser.parse_args()

    atlas = Image.open(args.atlas).convert("RGB")
    timestamp = args.timestamp
    SOURCE_DIR.mkdir(parents=True, exist_ok=True)
    source_copy = SOURCE_DIR / f"image2_grime_atlas_{timestamp}.png"
    shutil.copy2(args.atlas, source_copy)

    archive = _archive_existing(timestamp)
    bounds = _cell_bounds(atlas)
    if len(bounds) != 9:
        raise RuntimeError(f"Expected 9 cells, found {len(bounds)}")

    outputs: list[Path] = []
    for (name, size, max_alpha, color, index), box in zip(OUTPUTS, bounds):
        cell = atlas.crop(box)
        alpha = _make_alpha_from_key(cell, max_alpha)
        alpha = alpha.resize(size, Image.Resampling.LANCZOS)
        image = _compose(alpha, color)
        image = _clear_alpha_border(image)
        out = OUT_DIR / name
        image.save(out)
        outputs.append(out)

    preview = _make_contact_sheet(timestamp, outputs)
    html = _write_html(timestamp, preview)
    print(f"IMAGE2_GRIME_EXTRACT PASS source={source_copy}")
    print(f"archive={archive}")
    print(f"preview={preview}")
    print(f"html={html}")


if __name__ == "__main__":
    main()
