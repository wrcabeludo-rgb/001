"""Cuts sheets of several drawings (art_source/sheets) into separate originals.

A sheet is drawn on white with items in rows. The rows are found as bands of
non-white rows, the items in a row as runs of non-white columns (small gaps,
like sparks around a baton, are bridged). Items go into art_source under the
names listed for the sheet, left to right, top to bottom; None skips an item.
The usual tools/sprites.py tables then treat them like single drawings.
"""
import os

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "..", "art_source")

SHEETS = {
    "sheet_enemies_3": [
        "enemies/enemy_rifleman_original.png", "enemies/enemy_sniper_original.png",
        "enemies/enemy_grenadier_original.png",
        "enemies/enemy_trooper_original.png", "enemies/enemy_exo_heavy_original.png",
    ],
    "sheet_props_3a": [
        "props/prop_searchlight_original.png", "props/prop_alarm_hatch_original.png",
        "props/prop_choice_lever_original.png",
        "props/prop_checkpoint_tower_original.png", "props/prop_exit_tower_original.png",
    ],
    # The two barrier emitters are the same drawing: one is enough.
    "sheet_props_3b": [
        "tiles/tile_3_platform_source.png",
        "props/prop_glass_floor_original.png",
        "props/prop_barrier_emitter_original.png", None, "props/pickup_life_original.png",
        "props/prop_grenade_original.png",
    ],
    "sheet_tiles_3": [
        "tiles/tile_3-1_ground_original.png", "tiles/tile_3-2_ground_original.png",
        "tiles/tile_3-3_ground_original.png",
        "tiles/tile_3-1_wall_original.png", "tiles/tile_3-2_wall_original.png",
        "tiles/tile_3-3_wall_original.png",
    ],
}

# Texture swatches are cut a little inside their edges (the drawn border goes).
INSET = {"sheet_tiles_3": 10}


def _components(mask):
    """Boxes (left, top, right, bottom) of the 8-connected groups of True cells,
    and the cells labelled by group (1, 2...)."""
    h, w = mask.shape
    seen = np.zeros_like(mask)
    labels = np.zeros(mask.shape, np.int32)
    boxes = []
    for y0, x0 in zip(*np.nonzero(mask)):
        if seen[y0, x0]:
            continue
        seen[y0, x0] = True
        stack = [(y0, x0)]
        box = [x0, y0, x0, y0]
        while stack:
            y, x = stack.pop()
            labels[y, x] = len(boxes) + 1
            box = [min(box[0], x), min(box[1], y), max(box[2], x), max(box[3], y)]
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    ny, nx = y + dy, x + dx
                    if 0 <= ny < h and 0 <= nx < w and mask[ny, nx] and not seen[ny, nx]:
                        seen[ny, nx] = True
                        stack.append((ny, nx))
        boxes.append(box)
    return boxes, labels


def items(img, white=236, cell=4, reach=1, min_size=12):
    """Boxes of the drawings on a sheet, in reading order (rows top to bottom,
    left to right in a row), each with a pixel mask of its own drawing (so a
    neighbour reaching into its box is left out). Found on a coarse grid of
    `cell` pixels; ink closer than `reach` cells counts as one drawing."""
    ink = np.asarray(img.convert("RGB")).min(axis=2) < white
    h, w = ink.shape[0] // cell, ink.shape[1] // cell
    coarse = ink[:h * cell, :w * cell].reshape(h, cell, w, cell).sum(axis=(1, 3)) > 1
    padded = np.pad(coarse, reach)
    grown = np.zeros_like(coarse)
    for dy in range(2 * reach + 1):
        for dx in range(2 * reach + 1):
            grown |= padded[dy:dy + h, dx:dx + w]
    boxes = []
    groups, labels = _components(grown)
    for label, (left, top, right, bottom) in enumerate(groups, 1):
        if right - left < min_size and bottom - top < min_size:
            continue
        own = np.kron(labels == label, np.ones((cell, cell), bool))
        own = np.pad(own, ((0, ink.shape[0] - own.shape[0]), (0, ink.shape[1] - own.shape[1])))
        # Back to pixels, tight around the real ink.
        x0, y0 = max((left - reach) * cell, 0), max((top - reach) * cell, 0)
        x1, y1 = min((right + reach + 1) * cell, ink.shape[1]), min((bottom + reach + 1) * cell, ink.shape[0])
        part = ink[y0:y1, x0:x1] & own[y0:y1, x0:x1]
        ys, xs = np.nonzero(part)
        boxes.append((x0 + xs.min(), y0 + ys.min(), x0 + xs.max() + 1, y0 + ys.max() + 1, own))
    # Rows: a drawing whose middle is inside the current row's height joins it.
    boxes.sort(key=lambda b: b[1])
    rows = []
    for box in boxes:
        middle = (box[1] + box[3]) / 2
        if rows and rows[-1][0] <= middle <= rows[-1][1]:
            rows[-1][2].append(box)
            rows[-1][1] = max(rows[-1][1], box[3])
        else:
            rows.append([box[1], box[3], [box]])
    return [box for row in rows for box in sorted(row[2], key=lambda b: b[0])]


def cut_sheets(pad=12):
    for sheet, names in SHEETS.items():
        path = os.path.join(SRC, "sheets", sheet + ".png")
        if not os.path.exists(path):
            continue
        img = Image.open(path).convert("RGB")
        boxes = items(img)
        if len(boxes) != len(names):
            raise SystemExit(f"{sheet}: found {len(boxes)} drawings, expected {len(names)}: {boxes}")
        inset = INSET.get(sheet)
        pixels = np.asarray(img)
        for name, (left, top, right, bottom, own) in zip(names, boxes):
            if name is None:
                continue
            if inset:
                piece = img.crop((left + inset, top + inset, right - inset, bottom - inset))
            else:
                alone = np.where(own[..., None], pixels, 255).astype(np.uint8)
                piece = Image.new("RGB", (right - left + 2 * pad, bottom - top + 2 * pad), "white")
                piece.paste(Image.fromarray(alone).crop((left, top, right, bottom)), (pad, pad))
            out = os.path.join(SRC, name)
            os.makedirs(os.path.dirname(out), exist_ok=True)
            piece.save(out)
            print("cut", sheet, "->", name, piece.size)


if __name__ == "__main__":
    cut_sheets()
