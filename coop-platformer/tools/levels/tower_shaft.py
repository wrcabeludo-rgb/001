"""Zone 3-2 "Шахта лифта": a climb up a lift shaft while the Heart's plasma rises
from below. Run: python3 tools/levels/tower_shaft.py [--png preview.png]"""
from grid import Grid, finish

W, H = 44, 140
g = Grid(W, H)
put, fill = g.put, g.fill
fill(0, 0, 0, W - 1)
fill(138, 138, 1, W - 2)
fill(139, 139, 1, W - 2, "m")
put(137, 4, "1"); put(137, 6, "2")


def zigzag(top, bottom, items=None, kind="=", start=0):
    """One-way platforms every 2 rows from `bottom` up to `top`, zigzagging
    across the shaft; `items` puts things on given steps: {step: [(dx, letter)]}."""
    items = items or {}
    xs = list(range(3, 34, 5)) + list(range(33, 3, -5))
    length = 7
    step = start
    for r in range(bottom, top - 1, -2):
        x = xs[step % len(xs)]
        fill(r, r, x, x + length - 1, kind)
        for dx, letter in items.get(step - start, []):
            put(r - 1, x + dx, letter)
        step += 1


def landing(r, extra=()):
    """A full-width one-way floor (jump up through it) with a checkpoint."""
    fill(r, r, 1, W - 2, "=")
    for c, letter in extra:
        put(r - 1, c, letter)


# A. The bottom of the shaft: zigzag up, troopers waiting on the platforms
zigzag(112, 136, {3: [(3, "y")], 7: [(3, "N")], 10: [(2, "y")]})
landing(110, [(20, "C"), (22, "p"), (8, "N"), (36, "N")])
# B. Glass ledges that crack under the feet; drones in the shaft
# Solid glass must not hang over the step below, so the steps climb one way, rest on
# a catwalk, then climb back.
for r, x in ((108, 3), (106, 10), (104, 17), (102, 24), (100, 31), (98, 38)):
    fill(r, r, x, min(x + 4, W - 2), "o")
fill(96, 96, 24, 37, "=")
for r, x in ((94, 17), (92, 10), (90, 3)):
    fill(r, r, x, x + 4, "o")
fill(88, 88, 1, 9, "=")
fill(86, 86, 12, 16, "o")
put(103, 19, "j"); put(95, 30, "y"); put(89, 5, "N")
put(98, 6, "R"); put(92, 36, "R")
landing(84, [(30, "C"), (32, "+")])
# C. A gravity lift up the middle; snipers on side ledges, turrets under them
fill(62, 83, 21, 21, "u")
fill(61, 61, 17, 25, "=")
for r, side in ((78, 1), (72, 0), (66, 1)):
    if side:
        fill(r, r, W - 7, W - 2); put(r - 1, W - 4, "J"); put(r + 1, W - 5, "t")
    else:
        fill(r, r, 1, 6); put(r - 1, 3, "J"); put(r + 1, 4, "t")
# D. Ladders and platforms, a hidden office behind the wall, an exo-trooper landing
zigzag(41, 59, {4: [(3, "y")], 8: [(3, "N")]}, start=3)
fill(46, 50, W - 9, W - 2, "s"); put(50, W - 6, "$"); put(50, W - 4, "U")
fill(45, 45, W - 10, W - 2); fill(51, 51, W - 10, W - 2); fill(46, 50, W - 10, W - 10)
fill(46, 50, W - 10, W - 10, "s")
landing(39, [(12, "C"), (14, "+"), (30, "l")])
# E. The last climb with grenadiers and troopers, the exit at the top
zigzag(11, 37, {3: [(3, "j")], 7: [(3, "y")], 9: [(2, "N")]})
landing(9)
put(8, 40, "E"); put(8, 20, "N"); put(8, 26, "y")

finish(g, "scripts/level/tower_shaft_level.gd", (137, 4), [
    ("first landing", (109, 20)), ("glass top", (83, 30)), ("lift top", (60, 20)), ("secret", (50, W - 6)),
    ("third landing", (38, 12)), ("exit", (8, 40)),
])
