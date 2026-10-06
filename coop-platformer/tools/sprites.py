"""Turns ChatGPT pictures (white background) into game sprites.

    python3 tools/sprites.py            # rebuild every sprite listed below

Characters: the white background is removed by a flood fill from the picture's
border (so light colours inside the character stay solid), edges are softened,
the picture is cropped and scaled. Heroes are also cut into a cutout rig:
body, back leg and front leg (polygons below, in the original's pixels).
"""
import json
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "..", "art_source")
OUT = os.path.join(HERE, "..", "game", "assets", "art")


def remove_background(img, threshold=232):
    """RGBA picture with the near-white background (connected to the border) made transparent."""
    rgb = np.asarray(img.convert("RGB")).astype(np.int16)
    near_white = rgb.min(axis=2) >= threshold
    pure_white = rgb.min(axis=2) >= 250
    background = np.zeros_like(near_white)
    background[0, :] = near_white[0, :]
    background[-1, :] = near_white[-1, :]
    background[:, 0] = near_white[:, 0]
    background[:, -1] = near_white[:, -1]
    # Grow the background through near-white pixels until it stops changing.
    while True:
        grown = background.copy()
        grown[1:, :] |= background[:-1, :]
        grown[:-1, :] |= background[1:, :]
        grown[:, 1:] |= background[:, :-1]
        grown[:, :-1] |= background[:, 1:]
        grown &= near_white
        if (grown == background).all():
            break
        background = grown
    background |= pure_white
    alpha = np.where(background, 0, 255).astype(np.uint8)
    # Soft edge: a slight blur of the mask, then pull the light fringe toward the inside colour.
    soft = np.asarray(Image.fromarray(alpha).filter(ImageFilter.GaussianBlur(0.8))).astype(np.float32)
    alpha = np.minimum(alpha, soft.astype(np.uint8))
    rgba = np.dstack([rgb.astype(np.uint8), alpha])
    return Image.fromarray(rgba, "RGBA")


def crop(img, pad=4):
    box = img.getchannel("A").point(lambda a: 255 if a > 8 else 0).getbbox()
    box = (max(box[0] - pad, 0), max(box[1] - pad, 0), min(box[2] + pad, img.width), min(box[3] + pad, img.height))
    return img.crop(box), box


def scaled(img, height):
    factor = height / img.height
    return img.resize((max(1, round(img.width * factor)), height), Image.LANCZOS), factor


def save(img, name):
    path = os.path.join(OUT, name)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path)
    print("wrote", os.path.relpath(path, os.path.join(HERE, "..")), img.size)


# ---------------------------------------------------------------- enemies

ENEMIES = {
    # file: (source, height in game pixels x2 for sharpness)
    "enemies/walker.png": ("enemies/enemy_walker_original.png", 220),
    "enemies/charger.png": ("enemies/enemy_charger_original.png", 200),
    "enemies/ambusher.png": ("enemies/enemy_ambusher_original.png", 180),
}


def build_enemies():
    for name, (source, height) in ENEMIES.items():
        path = os.path.join(SRC, source)
        if not os.path.exists(path):
            continue
        img, _ = crop(remove_background(Image.open(path)))
        img, _ = scaled(img, height)
        save(img, name)


# ---------------------------------------------------------------- heroes

HEROES = {
    "gunner": {
        "source": "heroes/gunner_side_original.png",
        "height": 220,
        # Legs, as polygons in the original picture (x, y).
        "back_leg": [(300, 930), (420, 930), (430, 1060), (380, 1200), (380, 1330), (470, 1420), (480, 1490),
                     (210, 1490), (220, 1420), (240, 1300), (240, 1150), (270, 1060)],
        "front_leg": [(420, 930), (520, 930), (545, 1060), (520, 1180), (520, 1310), (600, 1360), (665, 1400),
                      (665, 1440), (440, 1440), (430, 1330), (420, 1200), (400, 1080)],
        "back_hip": (360, 950),
        "front_hip": (465, 950),
        # Where shots leave the rifle.
        "muzzle": (1000, 268),
    },
    "swordsman": {
        "source": "heroes/swordsman_side_original.png",
        "height": 230,
        "back_leg": [(260, 900), (400, 900), (395, 1010), (330, 1080), (270, 1130), (260, 1300), (330, 1360),
                     (345, 1475), (75, 1475), (90, 1380), (120, 1300), (125, 1150), (160, 1030)],
        "front_leg": [(420, 890), (565, 890), (560, 1000), (530, 1120), (520, 1250), (540, 1340), (600, 1360),
                      (680, 1390), (680, 1435), (398, 1435), (400, 1330), (410, 1200), (378, 1110), (400, 1000)],
        "back_hip": (330, 915),
        "front_hip": (490, 905),
        # Keep the glowing blade in the body even where it crosses a leg.
        "keep_in_body": "blade",
    },
}


def _blade_mask(rgb):
    r, g, b = rgb[..., 0].astype(int), rgb[..., 1].astype(int), rgb[..., 2].astype(int)
    return (r > 200) & (g > 70) & (b < 120) & (r - b > 120)


def build_heroes():
    rig = {}
    for name, spec in HEROES.items():
        path = os.path.join(SRC, spec["source"])
        if not os.path.exists(path):
            continue
        full = remove_background(Image.open(path))
        rgb = np.asarray(full)[..., :3]
        keep = _blade_mask(rgb) if spec.get("keep_in_body") == "blade" else np.zeros(rgb.shape[:2], bool)
        parts = {}
        masks = {}
        for leg in ("back_leg", "front_leg"):
            mask = Image.new("L", full.size, 0)
            ImageDraw.Draw(mask).polygon(spec[leg], fill=255)
            m = np.asarray(mask) > 0
            if leg == "back_leg":
                # Where both legs overlap, the front leg owns the pixels.
                front = Image.new("L", full.size, 0)
                ImageDraw.Draw(front).polygon(spec["front_leg"], fill=255)
                m &= ~(np.asarray(front) > 0)
            masks[leg] = m & ~keep
        arr = np.asarray(full).copy()
        body = arr.copy()
        for leg, m in masks.items():
            part = np.zeros_like(arr)
            part[m] = arr[m]
            parts[leg] = part
            body[m, 3] = 0
        parts["body"] = body
        # Crop all parts with one box so they stay aligned, then scale.
        _, box = crop(full)
        height = spec["height"]
        factor = height / (box[3] - box[1])
        info = {"scale": factor, "size": None}
        for part_name, part in parts.items():
            img = Image.fromarray(part, "RGBA").crop(box)
            img = img.resize((round(img.width * factor), height), Image.LANCZOS)
            save(img, f"heroes/{name}_{part_name}.png")
            info["size"] = img.size
        to_local = lambda p: [round((p[0] - box[0]) * factor, 1), round((p[1] - box[1]) * factor, 1)]
        info["back_hip"] = to_local(spec["back_hip"])
        info["front_hip"] = to_local(spec["front_hip"])
        if "muzzle" in spec:
            info["muzzle"] = to_local(spec["muzzle"])
        rig[name] = info
        # A preview of the cut, for checking by eye.
        preview = Image.new("RGBA", full.size, (30, 30, 40, 255))
        tint = {"back_leg": (80, 160, 255), "front_leg": (255, 120, 80)}
        preview.alpha_composite(Image.fromarray(body, "RGBA"))
        for leg, m in masks.items():
            layer = np.zeros_like(arr)
            layer[m] = arr[m]
            layer[m, :3] = (layer[m, :3] * 0.5 + np.array(tint[leg]) * 0.5).astype(np.uint8)
            preview.alpha_composite(Image.fromarray(layer, "RGBA"))
        preview.crop(box).save(os.path.join(SRC, "heroes", f"{name}_rig_preview.png"))
    if rig:
        path = os.path.join(OUT, "heroes", "rig.json")
        with open(path, "w") as f:
            json.dump(rig, f, indent=1)
        print("wrote", path)


if __name__ == "__main__":
    build_enemies()
    build_heroes()
