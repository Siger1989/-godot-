from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[2]
OUT_DIR = ROOT / "materials" / "textures" / "grime"


def smoothstep(edge0: float, edge1: float, value: float) -> float:
    if edge0 == edge1:
        return 1.0 if value >= edge1 else 0.0
    t = max(0.0, min(1.0, (value - edge0) / (edge1 - edge0)))
    return t * t * (3.0 - 2.0 * t)


def color_lerp(a: tuple[int, int, int], b: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return (
        int(a[0] + (b[0] - a[0]) * t),
        int(a[1] + (b[1] - a[1]) * t),
        int(a[2] + (b[2] - a[2]) * t),
    )


def apply_alpha_shape(
    alpha: Image.Image,
    kind: str,
    rng: random.Random,
    variant: int,
) -> Image.Image:
    w, h = alpha.size
    pixels = alpha.load()
    noise = Image.effect_noise((w, h), 58 + variant * 7).convert("L").filter(ImageFilter.GaussianBlur(2.8))
    noise_pixels = noise.load()

    for y in range(h):
        for x in range(w):
            value = pixels[x, y]
            if value <= 0:
                continue

            side_fade = smoothstep(0.0, w * 0.07, x) * (1.0 - smoothstep(w * 0.90, w, x))
            top_fade = smoothstep(0.0, h * 0.04, y) * (1.0 - smoothstep(h * 0.95, h, y))
            if kind == "baseboard":
                vertical = 1.0 - smoothstep(h * 0.10, h * 0.92, y)
            elif kind == "ceiling":
                vertical = smoothstep(h * 0.08, h * 0.94, y)
            else:
                center_distance = abs(x - w * 0.48) / (w * 0.5)
                vertical = (1.0 - smoothstep(0.22, 1.0, center_distance)) * top_fade

            grain = 0.82 + (noise_pixels[x, y] / 255.0) * 0.36
            shaped = int(value * side_fade * top_fade * vertical * grain)
            pixels[x, y] = max(0, min(180, shaped))
    alpha = alpha.filter(ImageFilter.GaussianBlur(1.4))
    return alpha.point(lambda value: max(0, min(168, int(value * 3.2))))


def make_horizontal(kind: str, seed: int, variant: int) -> Image.Image:
    rng = random.Random(seed)
    width = 1024
    height = 192 if kind == "baseboard" else 160
    alpha = Image.new("L", (width, height), 0)
    draw = ImageDraw.Draw(alpha, "L")

    edge_y = height - 14 if kind == "ceiling" else 14
    for _ in range(34 + variant * 5):
        cx = rng.randint(-120, width + 120)
        cy = int(rng.gauss(edge_y, height * 0.12))
        rx = rng.randint(42, 220)
        ry = rng.randint(5, 38)
        strength = rng.randint(10, 46)
        draw.ellipse((cx - rx, cy - ry, cx + rx, cy + ry), fill=strength)

    for _ in range(12 + variant * 2):
        y = int(rng.gauss(edge_y, height * 0.08))
        x0 = rng.randint(-60, width - 160)
        x1 = x0 + rng.randint(160, 520)
        width_px = rng.randint(3, 12)
        strength = rng.randint(8, 28)
        draw.line((x0, y, x1, y + rng.randint(-8, 8)), fill=strength, width=width_px)

    if kind == "baseboard":
        for _ in range(10):
            x = rng.randint(0, width)
            y0 = rng.randint(0, height // 3)
            y1 = rng.randint(height // 2, height - 6)
            draw.line((x, y0, x + rng.randint(-10, 10), y1), fill=rng.randint(5, 18), width=2)

    alpha = alpha.filter(ImageFilter.GaussianBlur(7.5 + variant * 1.2))
    alpha = apply_alpha_shape(alpha, kind, rng, variant)
    colors = [
        (128, 112, 73),
        (104, 105, 82),
        (150, 123, 75),
    ]
    alt_colors = [
        (96, 92, 72),
        (137, 118, 82),
        (118, 104, 76),
    ]
    return compose_rgba(alpha, colors[(variant - 1) % 3], alt_colors[(variant - 1) % 3], rng)


def make_corner(seed: int, variant: int) -> Image.Image:
    rng = random.Random(seed)
    width = 320
    height = 768
    alpha = Image.new("L", (width, height), 0)
    draw = ImageDraw.Draw(alpha, "L")

    for _ in range(42 + variant * 4):
        cx = int(rng.gauss(width * 0.48, width * 0.13))
        cy = rng.randint(-30, height + 30)
        rx = rng.randint(16, 92)
        ry = rng.randint(28, 145)
        strength = rng.randint(8, 38)
        draw.ellipse((cx - rx, cy - ry, cx + rx, cy + ry), fill=strength)

    for _ in range(11):
        x = int(rng.gauss(width * 0.48, width * 0.08))
        y0 = rng.randint(0, height // 4)
        y1 = y0 + rng.randint(140, 420)
        draw.line((x, y0, x + rng.randint(-18, 18), y1), fill=rng.randint(8, 22), width=rng.randint(2, 6))

    alpha = alpha.filter(ImageFilter.GaussianBlur(10.0))
    alpha = apply_alpha_shape(alpha, "corner", rng, variant)
    colors = [
        (111, 106, 82),
        (132, 111, 74),
        (94, 100, 82),
    ]
    alt_colors = [
        (145, 124, 81),
        (103, 97, 75),
        (126, 110, 82),
    ]
    return compose_rgba(alpha, colors[(variant - 1) % 3], alt_colors[(variant - 1) % 3], rng)


def compose_rgba(
    alpha: Image.Image,
    color_a: tuple[int, int, int],
    color_b: tuple[int, int, int],
    rng: random.Random,
) -> Image.Image:
    w, h = alpha.size
    rgba = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    alpha_pixels = alpha.load()
    rgba_pixels = rgba.load()
    color_noise = Image.effect_noise((w, h), 34).convert("L").filter(ImageFilter.GaussianBlur(5.0))
    noise_pixels = color_noise.load()

    for y in range(h):
        for x in range(w):
            a = alpha_pixels[x, y]
            if a <= 1:
                continue
            t = 0.5 + (noise_pixels[x, y] - 128) / 320.0 + math.sin((x + y * 0.37) * 0.009) * 0.10
            color = color_lerp(color_a, color_b, max(0.0, min(1.0, t)))
            rgba_pixels[x, y] = (color[0], color[1], color[2], a)

    # Guarantee true transparent edges and corners.
    edge_clear = Image.new("L", (w, h), 0)
    edge_draw = ImageDraw.Draw(edge_clear)
    edge_draw.rectangle((2, 2, w - 3, h - 3), fill=255)
    rgba.putalpha(ImageChops.multiply(rgba.getchannel("A"), edge_clear))
    return rgba


def save(path: Path, image: Image.Image) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path)


def main() -> None:
    for index in range(1, 4):
        save(
            OUT_DIR / f"ceiling_edge_grime_{index:02d}.png",
            make_horizontal("ceiling", 7100 + index * 97, index),
        )
        save(
            OUT_DIR / f"baseboard_dirt_{index:02d}.png",
            make_horizontal("baseboard", 9200 + index * 131, index),
        )
        save(
            OUT_DIR / f"corner_grime_{index:02d}.png",
            make_corner(11300 + index * 149, index),
        )
    print(f"GRIME_TEXTURE_GENERATION PASS dir={OUT_DIR}")


if __name__ == "__main__":
    main()
