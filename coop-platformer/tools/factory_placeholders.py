"""Stand-in parallax backgrounds for world 2 until the painted ones arrive.

Run: python3 tools/factory_placeholders.py
Writes game/assets/art/placeholders/factory_{far,mid}_{1,2,3}.png (dark, foggy
silhouettes of a factory hall (girders, robot arms, pipes, chimneys) tinted per
zone — 2-1 cold steel and magenta, 2-2 orange heat, 2-3 toxic green.
seamless horizontally) and placeholders/tiles/2-*_{wall,ground}.png (steel plates)."""
import os
import random

from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "game", "assets", "art", "placeholders")
W, H = 1536, 1024

ZONES = {
    1: {"sky": (18, 20, 30), "haze": (60, 40, 80), "glow": (255, 46, 136), "dark": (24, 27, 36)},
    2: {"sky": (26, 16, 14), "haze": (120, 50, 20), "glow": (255, 120, 30), "dark": (30, 22, 20)},
    3: {"sky": (14, 22, 20), "haze": (30, 70, 40), "glow": (140, 255, 80), "dark": (20, 28, 26)},
}


def wrap_rect(draw, x0, y0, x1, y1, fill):
    for shift in (-W, 0, W):
        draw.rectangle([x0 + shift, y0, x1 + shift, y1], fill=fill)


def wrap_ellipse(draw, box, fill):
    x0, y0, x1, y1 = box
    for shift in (-W, 0, W):
        draw.ellipse([x0 + shift, y0, x1 + shift, y1], fill=fill)


def wrap_line(draw, points, fill, width):
    for shift in (-W, 0, W):
        draw.line([(x + shift, y) for x, y in points], fill=fill, width=width)


def mix(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def far(zone, rng):
    z = ZONES[zone]
    img = Image.new("RGB", (W, H), z["sky"])
    draw = ImageDraw.Draw(img)
    # Haze glowing from below.
    for y in range(H):
        t = max(0.0, (y - H * 0.35) / (H * 0.65))
        draw.line([(0, y), (W, y)], fill=mix(z["sky"], z["haze"], t * 0.55))
    # Distant tall windows with the zone's glow.
    for x in range(40, W, 192):
        wrap_rect(draw, x, 120, x + 70, 520, mix(z["sky"], z["glow"], 0.12))
        for y in range(140, 500, 60):
            wrap_rect(draw, x + 6, y, x + 64, y + 4, z["sky"])
    # Roof trusses.
    beam = mix(z["dark"], (0, 0, 0), 0.2)
    wrap_rect(draw, 0, 60, W, 90, beam)
    for x in range(0, W, 96):
        wrap_line(draw, [(x, 90), (x + 48, 200), (x + 96, 90)], beam, 10)
    wrap_rect(draw, 0, 195, W, 210, beam)
    # Columns and hanging robot arms or ladles.
    for x in range(0, W, 384):
        wrap_rect(draw, x + 10, 200, x + 50, H, mix(z["dark"], z["sky"], 0.3))
    for i in range(7):
        x = rng.randrange(0, W)
        length = rng.randrange(200, 420)
        wrap_rect(draw, x, 210, x + 8, 210 + length, beam)
        if zone == 2:
            wrap_ellipse(draw, (x - 50, 190 + length, x + 58, 280 + length), beam)
            wrap_rect(draw, x - 40, 230 + length, x + 48, 250 + length, mix(beam, z["glow"], 0.5))
        else:
            wrap_line(draw, [(x + 4, 210 + length), (x + 60, 260 + length), (x + 40, 320 + length)], beam, 14)
    # Huge pipes along the bottom for the pumping station, machinery blocks elsewhere.
    for i in range(5):
        x = rng.randrange(0, W)
        w = rng.randrange(160, 340)
        h = rng.randrange(180, 380)
        wrap_rect(draw, x, H - h, x + w, H, mix(z["dark"], z["haze"], 0.15))
    if zone == 3:
        for y in (620, 760):
            wrap_rect(draw, 0, y, W, y + 70, mix(z["dark"], (0, 0, 0), 0.1))
            for x in range(60, W, 240):
                wrap_rect(draw, x, y + 26, x + 40, y + 44, mix(z["dark"], z["glow"], 0.5))
    img = img.filter(ImageFilter.GaussianBlur(3))
    return img


def mid(zone, rng):
    z = ZONES[zone]
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    body = mix(z["dark"], (0, 0, 0), 0.05) + (255,)
    edge = mix(z["dark"], z["glow"], 0.12) + (255,)
    # A catwalk with railings at the top of the filled half.
    wrap_rect(draw, 0, 560, W, 576, body)
    for x in range(0, W, 48):
        wrap_rect(draw, x, 520, x + 5, 560, body)
    wrap_rect(draw, 0, 518, W, 524, body)
    # Machines, crates, tanks below it.
    x = 0
    while x < W:
        w = rng.randrange(90, 220)
        h = rng.randrange(160, 440)
        kind = rng.random()
        if kind < 0.4:
            wrap_rect(draw, x, H - h, x + w, H, body)
            wrap_rect(draw, x, H - h, x + w, H - h + 6, edge)
            for ly in range(H - h + 30, H - 20, 70):
                wrap_rect(draw, x + 14, ly, x + 22, ly + 8, mix(z["dark"], z["glow"], 0.7) + (255,))
        elif kind < 0.7:
            wrap_ellipse(draw, (x, H - h, x + w, H - h + 60), body)
            wrap_rect(draw, x, H - h + 30, x + w, H, body)
        else:
            for cx in range(x, x + w, 64):
                wrap_rect(draw, cx, H - 64, cx + 58, H, body)
                wrap_rect(draw, cx + 4, H - 60, cx + 54, H - 56, edge)
        x += w + rng.randrange(20, 90)
    # Pipes running across.
    for y in (640, 700):
        wrap_rect(draw, 0, y, W, y + 22, body)
    img = img.filter(ImageFilter.GaussianBlur(1.5))
    return img


def main():
    os.makedirs(OUT, exist_ok=True)
    for zone in ZONES:
        rng = random.Random(zone * 17)
        far(zone, rng).save(os.path.join(OUT, "factory_far_%d.png" % zone))
        mid(zone, rng).save(os.path.join(OUT, "factory_mid_%d.png" % zone))
        print("placeholder backgrounds for zone 2-%d" % zone)



# ---------------------------------------------------------------- tiles

TILE = 256


def plates(base, seam, rivet, glow=None, cracks=False, grate=False, seed=0):
    """Seamless steel plates: panels with seams and rivets (or a grate)."""
    rng = random.Random(seed)
    img = Image.new("RGB", (TILE, TILE), base)
    draw = ImageDraw.Draw(img)
    # Subtle noise so flat colour does not look like a placeholder box.
    px = img.load()
    for y in range(TILE):
        for x in range(TILE):
            n = rng.randint(-6, 6)
            px[x, y] = tuple(max(0, min(255, c + n)) for c in base)
    if grate:
        for x in range(0, TILE, 32):
            draw.rectangle([x, 0, x + 6, TILE], fill=seam)
        for y in range(0, TILE, 32):
            draw.rectangle([0, y, TILE, y + 6], fill=seam)
        if glow:
            for x in range(8, TILE, 32):
                for y in range(8, TILE, 32):
                    if rng.random() < 0.35:
                        draw.rectangle([x + 4, y + 4, x + 20, y + 20], fill=glow)
        return img
    for x in (0, 128):
        draw.rectangle([x, 0, x + 3, TILE], fill=seam)
    for y in (0, 128):
        draw.rectangle([0, y, TILE, y + 3], fill=seam)
    for x in (12, 116, 140, 244):
        for y in (12, 116, 140, 244):
            draw.ellipse([x - 4, y - 4, x + 4, y + 4], fill=rivet)
    if cracks:
        for i in range(5):
            x, y = rng.randrange(TILE), rng.randrange(TILE)
            pts = [(x, y)]
            for j in range(4):
                x += rng.randint(-20, 20)
                y += rng.randint(5, 25)
                pts.append((x % TILE, y % TILE))
            draw.line(pts, fill=glow or seam, width=2)
    return img


def tread(base, ridge, seed=0):
    """Diamond tread plate for floors."""
    img = plates(base, tuple(int(c * 0.6) for c in base), ridge, seed=seed)
    draw = ImageDraw.Draw(img)
    for y in range(8, TILE, 24):
        for x in range(8 + (y // 24 % 2) * 12, TILE, 24):
            draw.line([(x, y + 4), (x + 8, y - 2)], fill=ridge, width=3)
    return img


def tiles():
    out = os.path.join(OUT, "tiles")
    os.makedirs(out, exist_ok=True)
    tread((58, 62, 72), (88, 94, 108), 1).save(os.path.join(out, "2-1_ground.png"))
    plates((38, 42, 52), (24, 26, 33), (70, 76, 90), seed=2).save(os.path.join(out, "2-1_wall.png"))
    plates((52, 40, 36), (30, 22, 20), (90, 70, 60), glow=(150, 70, 30), cracks=True, seed=3).save(
        os.path.join(out, "2-2_ground.png"))
    plates((40, 30, 28), (24, 18, 16), (70, 55, 48), seed=4).save(os.path.join(out, "2-2_wall.png"))
    plates((40, 50, 48), (22, 28, 27), (70, 80, 76), glow=(60, 110, 40), grate=True, seed=5).save(
        os.path.join(out, "2-3_ground.png"))
    plates((34, 42, 40), (20, 26, 25), (60, 72, 68), seed=6).save(os.path.join(out, "2-3_wall.png"))
    print("placeholder tiles for world 2")


if __name__ == "__main__":
    main()
    tiles()
