"""Рисует превью уровня без запуска Godot.

Читает карту прямо из scripts/level.gd (чтобы не было двух источников правды)
и собирает картинку теми же тайлами, что использует игра.

Зависимость: Pillow.
    pip install Pillow
Запуск из корня проекта:
    python tools/render_preview.py
Результат: preview/level.png (весь уровень) и preview/view_N.png
(кадры размером с игровое окно 360x180, увеличенные в 3 раза).
"""

from __future__ import annotations

import random
import re
import sys
from pathlib import Path

try:
    from PIL import Image, ImageDraw
except ImportError:  # pragma: no cover
    sys.exit("Нужен Pillow: pip install Pillow")

ROOT = Path(__file__).resolve().parent.parent
TILE = 18
CHAR_TILE = 24
VIEW_W, VIEW_H = 360, 180
SCALE = 3
SKY = (140, 199, 235, 255)

# Координаты тайлов должны совпадать с scripts/tiles.gd
GRASS, DIRT = (2, 0), (2, 6)
COIN, GEM, HEART = (11, 7), (7, 3), (4, 2)
CLOUD = (14, 7)
POLE, POLE_TOP = (9, 5), (9, 4)
DECOR = {
    "b": (4, 6), "m": (8, 6), "c": (7, 6), "t": (6, 6),
    "s": (4, 4), "n": (5, 5), "k": (11, 5), "r": (10, 6),
}
# Тайлы персонажей: (колонка, строка, сдвиг по X, сдвиг по Y)
WALKER = (2, 0, -3, -5)
FLYER = (7, 2, -3, -3)
PLAYER = (0, 0, -3, None)  # по Y считаем от низа клетки
FLAG_COLOR, FLAG_OUTLINE = (224, 72, 58, 255), (43, 43, 58, 255)
POLE_HEIGHT, FLAG_W, FLAG_H = 5, 15, 11


def read_map() -> list[str]:
    """Достаёт массив строк MAP из scripts/level.gd."""
    source = (ROOT / "scripts" / "level.gd").read_text(encoding="utf-8")
    block = re.search(r"const MAP := \[(.*?)\n\]", source, re.S)
    if not block:
        sys.exit("Не нашёл const MAP в scripts/level.gd")
    rows = re.findall(r'"([^"]*)"', block.group(1))
    width = max(len(r) for r in rows)
    return [r.ljust(width, ".") for r in rows]


def main() -> None:
    tiles = Image.open(ROOT / "assets" / "tiles.png").convert("RGBA")
    chars = Image.open(ROOT / "assets" / "characters.png").convert("RGBA")

    def tile(col: int, row: int) -> Image.Image:
        return tiles.crop((col * TILE, row * TILE, col * TILE + TILE, row * TILE + TILE))

    def char(col: int, row: int) -> Image.Image:
        return chars.crop((
            col * CHAR_TILE, row * CHAR_TILE,
            col * CHAR_TILE + CHAR_TILE, row * CHAR_TILE + CHAR_TILE,
        ))

    grid = read_map()
    height, width = len(grid), len(grid[0])
    canvas = Image.new("RGBA", (width * TILE, height * TILE), SKY)

    def solid(x: int, y: int) -> bool:
        return 0 <= x < width and 0 <= y < height and grid[y][x] == "#"

    # Небо: тот же принцип, что в level.gd — группы облаков по 2..4 тайла.
    rng = random.Random(20260916)
    sky = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    for _ in range(26):
        cx = rng.uniform(-80, width * TILE + 80)
        cy = rng.uniform(10, 78)
        for j in range(rng.randint(2, 4)):
            puff = tile(*CLOUD)
            puff.putalpha(puff.getchannel("A").point(lambda a: int(a * 0.75)))
            sky.alpha_composite(puff, (int(cx + j * TILE), int(cy)))
    canvas.alpha_composite(sky)

    for y in range(height):
        for x in range(width):
            if solid(x, y):
                canvas.alpha_composite(
                    tile(*(GRASS if not solid(x, y - 1) else DIRT)), (x * TILE, y * TILE)
                )

    draw = ImageDraw.Draw(canvas)
    for y in range(height):
        for x in range(width):
            c = grid[y][x]
            px, py = x * TILE, y * TILE
            if c in DECOR:
                canvas.alpha_composite(tile(*DECOR[c]), (px, py))
            elif c == "o":
                canvas.alpha_composite(tile(*COIN), (px, py))
            elif c == "*":
                canvas.alpha_composite(tile(*GEM), (px, py))
            elif c == "+":
                canvas.alpha_composite(tile(*HEART), (px, py))
            elif c == "e":
                canvas.alpha_composite(char(WALKER[0], WALKER[1]), (px + WALKER[2], py + WALKER[3]))
            elif c == "f":
                canvas.alpha_composite(char(FLYER[0], FLYER[1]), (px + FLYER[2], py + FLYER[3]))
            elif c == "P":
                canvas.alpha_composite(char(PLAYER[0], PLAYER[1]), (px + PLAYER[2], (y + 1) * TILE - CHAR_TILE))
            elif c == "G":
                for i in range(POLE_HEIGHT):
                    canvas.alpha_composite(
                        tile(*(POLE_TOP if i == POLE_HEIGHT - 1 else POLE)), (px, py - i * TILE)
                    )
                bx, by = px + TILE // 2, py - (POLE_HEIGHT - 1) * TILE - FLAG_H // 2
                draw.polygon([(bx - 1, by - 2), (bx + FLAG_W + 1, by + FLAG_H // 2), (bx - 1, by + FLAG_H + 2)],
                             fill=FLAG_OUTLINE)
                draw.polygon([(bx, by), (bx + FLAG_W, by + FLAG_H // 2), (bx, by + FLAG_H)], fill=FLAG_COLOR)

    out = ROOT / "preview"
    out.mkdir(exist_ok=True)
    canvas.convert("RGB").save(out / "level.png")
    print(f"preview/level.png  {canvas.size[0]}x{canvas.size[1]}")

    total_h = height * TILE
    for i, ox in enumerate(range(0, width * TILE - VIEW_W, max(1, (width * TILE - VIEW_W) // 3))):
        if i > 2:
            break
        crop = canvas.crop((ox, total_h - VIEW_H, ox + VIEW_W, total_h))
        crop.resize((VIEW_W * SCALE, VIEW_H * SCALE), Image.NEAREST).convert("RGB").save(out / f"view_{i}.png")
        print(f"preview/view_{i}.png  сдвиг по X = {ox}")


if __name__ == "__main__":
    main()
