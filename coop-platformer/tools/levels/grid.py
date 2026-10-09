"""Helpers for building level maps in Python (the legend is in game/scripts/level/level.gd).

Each level script builds a Grid, then calls `finish()`, which
  - checks that every important spot can be reached by a hero without a double jump,
  - writes the rows into the level's .gd file between the MAP markers,
  - optionally renders a preview PNG (pass --png path).
"""
import os
import re
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "game")
SOLID = set("#x<>e")
STANDABLE_TOP = set("#x=<>e")
# Molten metal, acid and spikes: never stood on.
DEADLY = set("^~%")
ENEMIES = set("wfghcaBWGRtKnO")


class Grid:
    def __init__(self, width, height=30):
        self.w = width
        self.h = height
        self.g = [["."] * width for _ in range(height)]
        self.fill(0, height - 1, 0, 0)
        self.fill(0, height - 1, width - 1, width - 1)

    def put(self, r, c, ch):
        self.g[r][c] = ch

    def fill(self, r0, r1, c0, c1, ch="#"):
        for r in range(r0, r1 + 1):
            for c in range(c0, c1 + 1):
                self.g[r][c] = ch

    def ground(self, c0, c1, surface):
        """Solid ground from row `surface` down to the bottom."""
        self.fill(surface, self.h - 1, c0, c1)

    def at(self, r, c):
        if 0 <= r < self.h and 0 <= c < self.w:
            return self.g[r][c]
        return "#"

    def rows(self):
        return ["".join(row) for row in self.g]

    # ------------------------------------------------------------ reachability

    def _free(self, r, c):
        ch = self.at(r, c)
        return ch not in SOLID

    def _stand_cells(self):
        """Cells where a hero (2 cells tall) can stand."""
        spots = set()
        for r in range(1, self.h - 1):
            for c in range(1, self.w - 1):
                below = self.at(r + 1, c)
                if not (self._free(r, c) and self._free(r - 1, c)):
                    continue
                if self.at(r, c) in DEADLY or below in DEADLY:
                    continue
                if below in STANDABLE_TOP or self.at(r, c) in "HrMLY*":
                    spots.add((r, c))
        # Moving platforms and lifts: every cell along their path can be stood on.
        for r in range(self.h):
            for c in range(self.w):
                ch = self.at(r, c)
                if ch in "MY":
                    for cc in range(self.w):
                        if self.at(r, cc) == "*":
                            for x in range(min(c, cc), max(c, cc) + 1):
                                spots.add((r, x))
                if ch == "L":
                    for rr in range(r, -1, -1):
                        spots.add((rr, c))
                        if self.at(rr, c) == "*":
                            break
        return spots

    def _clear_column(self, r_from, r_to, c):
        lo, hi = sorted((r_from, r_to))
        for r in range(lo - 1, hi + 1):
            if not self._free(r, c):
                return False
        return True

    def reachable(self, start):
        spots = self._stand_cells()
        seen = {start}
        todo = [start]
        while todo:
            r, c = todo.pop()
            for nr, nc in self._moves(r, c, spots):
                if (nr, nc) not in seen:
                    seen.add((nr, nc))
                    todo.append((nr, nc))
        return seen

    def _moves(self, r, c, spots):
        # Climbing ladders and ropes.
        if self.at(r, c) in "Hr" or self.at(r + 1, c) in "Hr":
            for dr in (-1, 1):
                if (r + dr, c) in spots or self.at(r + dr, c) in "Hr":
                    yield (r + dr, c)
        if self.at(r, c) == "H" and self.at(r - 1, c) not in "H":
            yield (r - 1, c)
        # A steam vent throws a hero about five cells up.
        if self.at(r, c) == "V":
            for dr in range(-6, 0):
                for dc in range(-3, 4):
                    if (r + dr, c + dc) in spots and self._clear_column(r, r + dr, c):
                        yield (r + dr, c + dc)
        for dr in range(-2, self.h):
            for dc in range(-7, 8):
                nr, nc = r + dr, c + dc
                if (nr, nc) not in spots or (dr == 0 and dc == 0):
                    continue
                reach = {-2: 3, -1: 4}.get(dr, min(4 + max(dr, 0) // 2, 7))
                if abs(dc) > reach:
                    continue
                if self._path_clear(r, c, nr, nc):
                    yield (nr, nc)

    def _path_clear(self, r, c, nr, nc):
        """Rough check of a jump: room above the start, no wall between."""
        top = min(r, nr)
        if nr < r and not (self._free(top - 2, c) and self._free(top - 2, nc)):
            return False
        step = 1 if nc >= c else -1
        for x in range(c, nc + step, step):
            if not (self._free(top, x) and self._free(top - 1, x)):
                return False
        return True

    def check(self, start, must_reach):
        seen = self.reachable(start)
        missing = []
        for name, (r, c) in must_reach:
            # Accept standing on the spot or right next to it.
            if not any((r + dr, c + dc) in seen for dr in (-1, 0, 1) for dc in (-1, 0, 1)):
                missing.append(f"{name} (row {r}, col {c})")
        return missing

    # ------------------------------------------------------------ output

    def png(self, path, scale=6):
        from PIL import Image
        colors = {"#": (90, 95, 105), ".": (20, 20, 28), "=": (150, 160, 175), "x": (150, 110, 90),
                  "~": (110, 255, 60), "^": (230, 230, 240), "H": (170, 130, 70), "r": (200, 180, 120),
                  "C": (120, 255, 190), "E": (120, 255, 190), "[": (255, 80, 80), "]": (255, 80, 80),
                  "d": (140, 90, 200), "/": (255, 220, 80), "+": (255, 70, 90), "p": (80, 220, 255),
                  "b": (230, 60, 30), "k": (100, 140, 110), "F": (255, 140, 30), "v": (180, 160, 140),
                  "M": (130, 160, 220), "*": (130, 160, 220), "L": (230, 200, 60), "z": (255, 50, 120),
                  ">": (60, 60, 70), "<": (60, 60, 70), "e": (90, 160, 255), "%": (255, 120, 20),
                  "P": (200, 200, 210), "Q": (170, 110, 60), "V": (230, 230, 230), "Y": (230, 180, 40),
                  "1": (80, 230, 255), "2": (255, 160, 60), "s": (60, 60, 120), "$": (255, 215, 0), "U": (255, 255, 255)}
        img = Image.new("RGB", (self.w * scale, self.h * scale))
        px = img.load()
        for r in range(self.h):
            for c in range(self.w):
                ch = self.g[r][c]
                col = colors.get(ch, (255, 0, 255) if ch in ENEMIES else (255, 255, 0))
                for y in range(scale):
                    for x in range(scale):
                        px[c * scale + x, r * scale + y] = col
        img.save(path)

    def write_into(self, gd_path):
        path = os.path.join(ROOT, gd_path)
        text = open(path, encoding="utf-8").read()
        body = "\n".join('\t"%s",' % row for row in self.rows())
        # The block runs from "const MAP := [" to the first line that is just "]".
        new, count = re.subn(r"(const MAP := \[\n).*?(^\]\n)", lambda m: m.group(1) + body + "\n" + m.group(2),
                             text, count=1, flags=re.S | re.M)
        assert count == 1, "MAP block not found in " + gd_path
        open(path, "w", encoding="utf-8").write(new)


def finish(grid, gd_path, start, must_reach):
    missing = grid.check(start, must_reach)
    if "--png" in sys.argv:
        grid.png(sys.argv[sys.argv.index("--png") + 1])
    if missing:
        print("UNREACHABLE:\n  " + "\n  ".join(missing))
        sys.exit(1)
    grid.write_into(gd_path)
    print(f"{gd_path}: {grid.w}x{grid.h}, all {len(must_reach)} key spots reachable")
