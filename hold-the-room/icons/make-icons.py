# Генерирует icon-192.png и icon-512.png (нужен Pillow): python3 make-icons.py
import math
from pathlib import Path
from PIL import Image, ImageDraw

BG, PINK, AMBER, CYAN, WOOD = '#1a0f09', '#ff3d8b', '#ffb03a', '#3de0ff', '#5a2c10'


def draw(size):
    s = size * 4  # рисуем крупно и уменьшаем для сглаживания
    im = Image.new('RGB', (s, s), BG)
    d = ImageDraw.Draw(im)
    u = s / 100
    # доски сцены внизу
    for i, y in enumerate(range(int(70 * u), s, int(8 * u))):
        d.rectangle([0, y, s, y + 7 * u], fill='#3b2213' if i % 2 else '#4a2c18')
    # неоновое кольцо (внутри безопасной зоны maskable)
    d.ellipse([18 * u, 14 * u, 82 * u, 78 * u], outline=PINK, width=int(4.5 * u))
    # гитара по диагонали
    cx, cy, a = 46 * u, 52 * u, math.radians(-40)

    def rot(x, y):
        return (cx + x * math.cos(a) - y * math.sin(a), cy + x * math.sin(a) + y * math.cos(a))
    d.polygon([rot(6 * u, -2.2 * u), rot(36 * u, -2.2 * u), rot(36 * u, 2.2 * u), rot(6 * u, 2.2 * u)], fill=WOOD)
    d.polygon([rot(34 * u, -3.5 * u), rot(41 * u, -3.5 * u), rot(41 * u, 3.5 * u), rot(34 * u, 3.5 * u)], fill=AMBER)
    for ox, r in ((0, 11), (-9, 9)):
        x, y = rot(ox * u, 0)
        d.ellipse([x - r * u, y - r * 0.85 * u, x + r * u, y + r * 0.85 * u], fill=AMBER)
    x, y = rot(-1 * u, 0)
    d.ellipse([x - 3.2 * u, y - 3.2 * u, x + 3.2 * u, y + 3.2 * u], fill='#2a160c')
    # нота
    d.ellipse([28 * u, 38 * u, 37 * u, 45 * u], fill=CYAN)
    d.rectangle([34.5 * u, 22 * u, 37 * u, 42 * u], fill=CYAN)
    d.polygon([(37 * u, 22 * u), (43 * u, 27 * u), (42 * u, 32 * u), (37 * u, 28 * u)], fill=CYAN)
    return im.resize((size, size), Image.LANCZOS)


here = Path(__file__).parent
for n in (192, 512):
    draw(n).save(here / f'icon-{n}.png', optimize=True)
