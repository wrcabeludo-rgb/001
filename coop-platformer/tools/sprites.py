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

from bgtools import make_seamless, white_to_alpha

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "..", "art_source")
OUT = os.path.join(HERE, "..", "game", "assets", "art")


def remove_background(img, threshold=232, holes=False):
    """RGBA picture with the near-white background (connected to the border) made transparent.
    With `holes`, near-white areas enclosed by the object (between ladder rungs) go too;
    a number instead of True clears only enclosed areas of at least that many pixels,
    so small bright spots (lamp glare) stay."""
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
    if holes is True:
        background |= pure_white | near_white
    elif holes:
        background |= _big_regions(near_white & ~background, holes)
    else:
        background |= pure_white
    if holes:
        # Eat the light fringe around the holes as well.
        grown = background.copy()
        grown[1:, :] |= background[:-1, :]
        grown[:-1, :] |= background[1:, :]
        grown[:, 1:] |= background[:, :-1]
        grown[:, :-1] |= background[:, 1:]
        background = grown & (rgb.min(axis=2) >= 190) | background
    alpha = np.where(background, 0, 255).astype(np.uint8)
    # Soft edge: a slight blur of the mask, then pull the light fringe toward the inside colour.
    soft = np.asarray(Image.fromarray(alpha).filter(ImageFilter.GaussianBlur(0.8))).astype(np.float32)
    alpha = np.minimum(alpha, soft.astype(np.uint8))
    rgba = np.dstack([rgb.astype(np.uint8), alpha])
    return Image.fromarray(rgba, "RGBA")


def _big_regions(mask, min_area):
    """The parts of `mask` made of connected areas of at least `min_area` pixels."""
    marks = Image.fromarray(np.where(mask, 255, 0).astype(np.uint8)).copy()
    result = np.zeros_like(mask)
    ys, xs = np.nonzero(mask[::4, ::4])
    for y, x in zip(ys * 4, xs * 4):
        if marks.getpixel((int(x), int(y))) != 255:
            continue
        ImageDraw.floodfill(marks, (int(x), int(y)), 128)
        area = np.asarray(marks) == 128
        if area.sum() >= min_area:
            result |= area
        ImageDraw.floodfill(marks, (int(x), int(y)), 0)
    return result


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
    "enemies/brute.png": ("enemies/enemy_brute_original.png", 300),
    "enemies/flyer.png": ("enemies/enemy_flyer_original.png", 200),
    # The spit stream of the original picture is cut off: in the game it is a projectile.
    "enemies/spitter.png": ("enemies/enemy_spitter_original.png", 200),
    "enemies/boss.png": ("enemies/boss_sludge_master_original.png", 600),
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


# ---------------------------------------------------------------- tiles

TILE_SIZE = 640


def build_tiles():
    """Seamless zone textures, scaled down (they tile in the game)."""
    folder = os.path.join(SRC, "tiles")
    if not os.path.isdir(folder):
        return
    for file in sorted(os.listdir(folder)):
        if not file.endswith("_original.png"):
            continue
        img = Image.open(os.path.join(folder, file)).convert("RGB").resize((TILE_SIZE, TILE_SIZE), Image.LANCZOS)
        save(img, "tiles/" + file.replace("_original", "").replace("tile_", ""))


# ---------------------------------------------------------------- hero poses

# The drawings come from ChatGPT at about the same scale, so each hero gets one
# scale for all poses, measured on one figure: (picture, box, its height compared
# with the standing hero).
POSE_REFERENCE = {
    "gunner": ("gunner_kick", None, 1.0),
    "swordsman": ("swordsman_block", None, 0.95),
}

# Where each pose's frames come from: (picture in art_source/heroes/poses/originals
# without "_original.png", box or None for the whole picture). The wall poses have
# the wall drawn on the right: the box stops just before it. A picture with two
# figures is drawn smaller: a third item gives that picture its own scale, either
# the box of an upright figure in it, or the frame's height compared with the
# standing hero.
POSE_SOURCES = {
    "gunner_crouch": [("gunner_crouch", None)],
    "gunner_kick": [("gunner_kick", None)],
    "gunner_wall": [("gunner_wall", (0, 0, 926, 1536))],
    "gunner_climb": [("gunner_climb", (0, 0, 724, 1086), 1.12), ("gunner_climb", (724, 0, 1448, 1086), 1.12)],
    "swordsman_crouch": [("swordsman_crouch", (0, 880, 1024, 1536), (0, 0, 1024, 875))],
    "swordsman_block": [("swordsman_block", None)],
    "swordsman_slash_down": [("swordsman_slash_down", None)],
    "swordsman_slash_rising": [("swordsman_slash_rising", None)],
    "swordsman_slash_finisher": [("swordsman_finisher_a", None), ("swordsman_finisher_b", None)],
    "swordsman_slash_overhead": [("swordsman_slash_overhead", None)],
    "swordsman_wall": [("swordsman_wall", (0, 0, 874, 1536))],
    # Back view with a hand raised above the head.
    "swordsman_climb": [("swordsman_climb", (0, 0, 724, 1086), 1.12), ("swordsman_climb", (724, 0, 1448, 1086), 1.12)],
}
# Run cycles: a sheet of RUN_FRAMES figures in a row (art_source/heroes/poses/originals/<hero>_run_original.png),
# each figure as tall as RUN_HEIGHT of the standing hero.
RUN_FRAMES = 4
RUN_HEIGHT = 0.97
# How far the wall is from the hero's middle in the wall pose (art pixels).
WALL_GAP = 48


def _green_to_white(img):
    """A prop drawn in flat bright green (a ladder in a climbing pose) becomes background."""
    rgb = np.asarray(img.convert("RGB")).copy()
    r, g, b = (rgb[:, :, i].astype(np.int16) for i in range(3))
    green = (g > 170) & (r < 130) & (b < 130) & (g - np.maximum(r, b) > 80)
    rgb[green] = 255
    return Image.fromarray(rgb)


def _pose_cutout(name, box):
    """One figure from an original: background, a drawn green prop and stray specks removed, cropped."""
    if box and box[0] == "sheet":
        return _sheet_frames(name)[box[1]]
    path = os.path.join(SRC, "heroes/poses/originals", name + "_original.png")
    if not os.path.exists(path):
        return None
    img = Image.open(path)
    if box:
        img = img.crop(box)
    img = remove_background(_green_to_white(img), holes=400)
    alpha = np.asarray(img)[:, :, 3]
    keep = _big_regions(alpha > 0, 3000)
    img.putalpha(Image.fromarray(np.where(keep, alpha, 0).astype(np.uint8)))
    img, _ = crop(img)
    return img


def _add_run_cycles():
    """Each run sheet becomes RUN_FRAMES frames (see _sheet_frames)."""
    for hero in HEROES:
        key = hero + "_run"
        if os.path.exists(os.path.join(SRC, "heroes/poses/originals", key + "_original.png")):
            POSE_SOURCES.setdefault(key, [(key, ("sheet", i), RUN_HEIGHT) for i in range(RUN_FRAMES)])


def _sheet_frames(name):
    """The figures of a sheet drawn in a row. Overlapping figures (a cape over
    the next one's boots) are told apart by connected pieces of drawing: each
    piece goes to the figure whose slot holds its middle."""
    img = remove_background(Image.open(os.path.join(SRC, "heroes/poses/originals", name + "_original.png")),
                            holes=400)
    alpha = np.asarray(img)[:, :, 3]
    marks = Image.fromarray(np.where(alpha > 0, 255, 0).astype(np.uint8)).copy()
    owner = np.full(alpha.shape, -1, np.int8)
    step = img.width / RUN_FRAMES
    ys, xs = np.nonzero(alpha[::3, ::3] > 0)
    for y, x in zip(ys * 3, xs * 3):
        if marks.getpixel((int(x), int(y))) != 255:
            continue
        ImageDraw.floodfill(marks, (int(x), int(y)), 128)
        piece = np.asarray(marks) == 128
        if piece.sum() > 200:
            owner[piece] = min(int(np.nonzero(piece)[1].mean() // step), RUN_FRAMES - 1)
        ImageDraw.floodfill(marks, (int(x), int(y)), 0)
    frames = []
    for i in range(RUN_FRAMES):
        frame = np.asarray(img).copy()
        frame[:, :, 3] = np.where(owner == i, frame[:, :, 3], 0)
        frames.append(crop(Image.fromarray(frame))[0])
    return frames


def build_poses():
    """Action poses -> <hero>_pose_<pose>_<n>.png and poses.json: for each frame,
    where the feet are across the picture (0..1), so the game stands the drawing
    on the hero's spot (the wall pose: against the wall)."""
    anchors = {}
    _add_run_cycles()
    for hero, (name, box, share) in POSE_REFERENCE.items():
        reference = _pose_cutout(name, box)
        if reference is None:
            continue
        hero_factor = HEROES[hero]["height"] * share / reference.size[1]
        for key, frames in POSE_SOURCES.items():
            if not key.startswith(hero + "_"):
                continue
            pose = key[len(hero) + 1:]
            for n, (source, frame_box, *upright) in enumerate(frames, 1):
                img = _pose_cutout(source, frame_box)
                if img is None:
                    continue
                factor = hero_factor
                if upright and isinstance(upright[0], (int, float)):
                    factor = HEROES[hero]["height"] * upright[0] / img.size[1]
                elif upright:
                    factor = HEROES[hero]["height"] / _pose_cutout(source, upright[0]).size[1]
                img = img.resize((max(1, round(img.size[0] * factor)), max(1, round(img.size[1] * factor))),
                                 Image.LANCZOS)
                alpha = np.asarray(img)[:, :, 3]
                width = alpha.shape[1]
                if pose == "wall":
                    anchor = (width - WALL_GAP) / width
                elif pose == "run":
                    # Steady between frames: the middle of the body, not a foot.
                    torso = alpha[int(alpha.shape[0] * 0.35):int(alpha.shape[0] * 0.6)]
                    anchor = np.nonzero(torso > 128)[1].mean() / width
                elif pose == "climb":
                    # Centred on the ladder: the middle of the figure's mass.
                    anchor = np.nonzero(alpha > 128)[1].mean() / width
                else:
                    soles = np.nonzero(alpha[int(alpha.shape[0] * 0.86):].max(axis=0) > 128)[0]
                    anchor = (soles.min() + soles.max()) / 2.0 / width if len(soles) else 0.5
                anchors["%s_%d" % (key, n)] = round(float(anchor), 3)
                save(img, "heroes/%s_pose_%s_%d.png" % (hero, pose, n))
    with open(os.path.join(OUT, "heroes/poses.json"), "w") as f:
        json.dump(anchors, f, indent=1)


# ---------------------------------------------------------------- shop backdrop

def _cover(img, size):
    """Scaled to cover `size` (cropping the overflow evenly)."""
    factor = max(size[0] / img.width, size[1] / img.height)
    img = img.resize((round(img.width * factor), round(img.height * factor)), Image.LANCZOS)
    left, top = (img.width - size[0]) // 2, (img.height - size[1]) // 2
    return img.crop((left, top, left + size[0], top + size[1]))


def build_shop_backdrop():
    """The slums behind the trader's stall: night sky and houses, a little blurred
    and darkened so the stall in front stands out, like a distant street."""
    size = (1920, 1080)
    art = os.path.join(OUT, "backgrounds")
    sky = _cover(Image.open(os.path.join(art, "sky_world1_1.png")).convert("RGBA"), size)
    houses = _cover(Image.open(os.path.join(art, "bg_mid_world1_01.png")).convert("RGBA"), size)
    picture = Image.alpha_composite(sky, houses).convert("RGB").filter(ImageFilter.GaussianBlur(3))
    rgb = np.asarray(picture).astype(np.float32) * np.array([0.62, 0.58, 0.7])
    # Darker towards the top and the edges.
    y, x = np.mgrid[0:size[1], 0:size[0]]
    shade = 1.0 - 0.35 * (1.0 - y / size[1]) ** 2 - 0.25 * (np.abs(x / size[0] - 0.5) * 2) ** 3
    rgb *= shade[:, :, None]
    save(Image.fromarray(np.clip(rgb, 0, 255).astype(np.uint8)), "ui/shop_bg.png")


# ---------------------------------------------------------------- hero select avatars

# The front view from each approved concept sheet (the leftmost figure).
AVATARS = {
    "ui/avatar_gunner.png": ("concepts/gunner_concept_approved.png", (0, 0, 560, 1024)),
    "ui/avatar_swordsman.png": ("concepts/swordsman_concept_approved.png", (0, 0, 560, 1024)),
}
AVATAR_HEIGHT = 700


def build_avatars():
    for name, (source, box) in AVATARS.items():
        img = Image.open(os.path.join(SRC, source)).crop(box)
        # A sheet that is already cut out keeps its own transparency.
        if img.mode != "RGBA" or img.getextrema()[3][0] == 255:
            img = remove_background(img, holes=400)
        img, _ = crop(img)
        img, _ = scaled(img, AVATAR_HEIGHT)
        save(img, name)


# ---------------------------------------------------------------- props

PROPS = {
    # output: (source, box around the wanted object in the original, height x2)
    "props/barrel.png": ("props/prop_barrel_original.png", (20, 90, 630, 1120), 170),
    "props/cover.png": ("props/prop_cover_original.png", (380, 650, 960, 1120), 170),
    "props/crate.png": ("props/prop_crate_original.png", (10, 290, 650, 920), 130),
    "props/checkpoint.png": ("props/prop_checkpoint_lever_original.png", (50, 10, 650, 1200), 340),
    "props/lever.png": ("props/prop_lever_original.png", (770, 0, 1190, 1200), 200),
    # Doors and gates are narrow in the game: their side views fit.
    "props/gate.png": ("props/prop_gate_original.png", (940, 0, 1160, 1230), 600),
    "props/door.png": ("props/prop_door_original.png", (1010, 110, 1180, 1230), 600),
    "props/exit.png": ("props/prop_exit_original.png", (0, 0, 1254, 1254), 420),
    "props/spikes.png": ("props/prop_spikes_original.png", (0, 300, 1254, 940), 80, True),
    # Only whole rung periods, so the ladder tiles upward without seams.
    "props/ladder.png": ("props/prop_ladder_original.png", (440, 355, 800, 1093), 240, True),
    "props/lift.png": ("props/prop_lift_original.png", (150, 510, 1390, 880), 104, True),
    "props/flamethrower.png": ("props/prop_flamethrower_original.png", (40, 140, 990, 930), 140),
    "props/pickup_health.png": ("props/pickup_health_original.png", (0, 100, 1254, 1100), 80),
    "props/pickup_ammo.png": ("props/pickup_ammo_original.png", (60, 120, 1200, 1060), 80),
    "props/pickup_scrap.png": ("props/pickup_scrap_original.png", (40, 180, 1220, 1060), 80),
    # The white gap between the awning and the counter has to go too.
    "props/trader.png": ("props/npc_trader_original.png", (0, 0, 1536, 1024), 620, 120),
}


def build_props():
    """Props: the picture often shows several variants; one is picked by its box."""
    for name, spec in PROPS.items():
        source, box, height = spec[:3]
        holes = len(spec) > 3 and spec[3]
        path = os.path.join(SRC, source)
        if not os.path.exists(path):
            continue
        img, _ = crop(remove_background(Image.open(path).crop(box), holes=holes))
        img, _ = scaled(img, height)
        save(img, name)


PLATFORM_HEIGHT = 30


def build_platform():
    """A strip of the catwalk texture: one walkway band, tiled sideways under one-way platforms."""
    path = os.path.join(SRC, "tiles", "tile_platform_source.png")
    if not os.path.exists(path):
        return
    band = Image.open(path).convert("RGB").crop((0, 100, 1254, 335))
    factor = PLATFORM_HEIGHT / band.height
    save(band.resize((round(band.width * factor), PLATFORM_HEIGHT), Image.LANCZOS), "tiles/platform.png")


# ---------------------------------------------------------------- backgrounds

BACKGROUNDS = {
    # output: (source, has a white sky to remove, seam overlap)
    "backgrounds/bg_far_world1_2.png": ("backgrounds/bg_far_world1_2_original.png", False, 400),
    "backgrounds/bg_mid_world1_2.png": ("backgrounds/bg_mid_world1_2_original.png", True, 360),
    "backgrounds/bg_far_world1_3.png": ("backgrounds/bg_far_world1_3_original.png", True, 400),
    "backgrounds/bg_mid_world1_3.png": ("backgrounds/bg_mid_world1_3_original.png", True, 360),
}


def build_backgrounds():
    """Parallax layers: white sky made transparent (mid layers), then seamless sideways."""
    for name, (source, white_sky, overlap) in BACKGROUNDS.items():
        path = os.path.join(SRC, source)
        if not os.path.exists(path):
            continue
        img = Image.open(path)
        img = white_to_alpha(img) if white_sky else img.convert("RGBA")
        img, _ = make_seamless(img, overlap)
        save(img, name)


# ---------------------------------------------------------------- moving sky of zone 1-1

def _periodic_noise(width, height, smooth, seed):
    """Soft noise that repeats seamlessly in both directions (white noise blurred in the FFT)."""
    rng = np.random.default_rng(seed)
    spec = np.fft.rfft2(rng.standard_normal((height, width)))
    fy = np.fft.fftfreq(height)[:, None]
    fx = np.fft.rfftfreq(width)[None, :]
    spec *= np.exp(-((fx * width / smooth) ** 2 + (fy * height / smooth * 2.5) ** 2))
    noise = np.fft.irfft2(spec, (height, width))
    return (noise - noise.min()) / (noise.max() - noise.min())


def _cloud_layer(width, height, seeds, band, color, strength):
    """Clouds: a few octaves of noise, kept inside a vertical band (fractions of the height)."""
    noise = sum(_periodic_noise(width, height, s, seed) * w for s, seed, w in seeds)
    noise /= sum(w for _, _, w in seeds)
    y = np.linspace(0, 1, height)[:, None]
    lo, hi = band
    profile = np.clip((y - lo) / 0.12, 0, 1) * np.clip((hi - y) / 0.12, 0, 1)
    alpha = np.clip((noise - 0.45) * 3.2, 0, 1) * profile * strength
    shade = 0.6 + 0.4 * noise
    rgb = np.stack([np.full_like(noise, c) * shade for c in color], axis=2)
    return Image.fromarray((np.dstack([np.clip(rgb, 0, 1), alpha]) * 255).astype(np.uint8), "RGBA")


def build_sky_1_1():
    sky = os.path.join(SRC, "backgrounds", "bg_sky_only_seamless.png")
    far = os.path.join(OUT, "backgrounds", "bg_far_world1_01.png")
    if os.path.exists(sky):
        save(Image.open(sky).convert("RGB"), "backgrounds/sky_world1_1.png")
    if os.path.exists(far):
        # The far layer keeps only its skyline; the moving sky shows above it.
        img = Image.open(far).convert("RGBA")
        a = np.asarray(img).astype(np.float32)
        y = np.linspace(0, 1, img.height)[:, None]
        a[..., 3] *= np.clip((y - 0.42) / 0.16, 0, 1)
        save(Image.fromarray(a.astype(np.uint8), "RGBA"), "backgrounds/skyline_world1_1.png")
    save(_cloud_layer(2048, 1024, [(14, 1, 0.6), (40, 2, 0.4)], (-0.2, 0.5), (0.16, 0.12, 0.22), 0.85),
         "backgrounds/clouds_world1_1.png")
    save(_cloud_layer(2048, 1024, [(10, 3, 0.5), (30, 4, 0.5)], (0.6, 1.1), (0.22, 0.18, 0.26), 0.7),
         "backgrounds/fog_world1_1.png")


if __name__ == "__main__":
    build_sky_1_1()
    build_platform()
    build_backgrounds()
    build_props()
    build_enemies()
    build_heroes()
    build_poses()
    build_avatars()
    build_shop_backdrop()
    build_tiles()
