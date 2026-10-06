"""Zone 1-1 "Трущобы". Run: python3 tools/levels/slums.py [--png preview.png]"""
from grid import Grid, finish

g = Grid(540)
put, fill, ground = g.put, g.fill, g.ground

# A. Start street
ground(1, 19, 26); ground(20, 28, 25)
put(25, 3, "1"); put(25, 5, "2")
fill(23, 23, 10, 12, "="); put(22, 11, "p")
put(25, 16, "w")
# B. Pits, a flyer, an ambusher under an overhang
ground(32, 36, 24); ground(40, 57, 25)
put(17, 38, "f")
fill(19, 20, 44, 48); put(21, 46, "a")
# C. Ladder up a building, cover against a spitter on the roof
fill(15, 24, 57, 57, "H")
ground(58, 80, 14)
put(13, 60, "C"); put(13, 66, "k"); put(13, 76, "g")
# D. Rooftops: rope over a gap, crumbling bridge, flyer
ground(84, 96, 14); put(13, 92, "c")
fill(5, 5, 98, 100); fill(6, 12, 99, 99, "r")
ground(102, 112, 15)
fill(15, 15, 113, 118, "x")
ground(119, 130, 15); put(14, 124, "w"); put(10, 127, "f")
# E. Street, sludge canal with a moving platform, barrels by a brute
ground(131, 139, 26); ground(140, 155, 27); fill(26, 26, 140, 155, "~")
put(25, 141, "M"); put(25, 154, "*")
ground(156, 205, 26)
put(25, 160, "b"); put(25, 161, "b"); put(25, 164, "h"); put(25, 168, "w")
# F. Checkpoint, supplies, arena
put(25, 172, "C"); put(25, 174, "+"); put(25, 175, "p")
fill(0, 21, 178, 178); put(22, 178, "[")
fill(0, 21, 200, 200); put(22, 200, "]")
fill(22, 22, 183, 186, "="); fill(22, 22, 192, 195, "="); fill(19, 19, 188, 190, "=")
# G. Collapsing tunnel: debris, spikes, flamethrowers
ground(206, 255, 26); fill(0, 21, 206, 255)
for c in (212, 217, 223):
    put(22, c, "v")
ground(228, 230, 27); fill(26, 26, 228, 230, "^")
put(25, 238, "#"); put(25, 239, "F"); put(25, 252, "F")
put(25, 244, "+")
# H. Lever on a ledge opens the door; gauntlet with cover, spitter, barrel
ground(256, 302, 26)
fill(20, 20, 258, 262); fill(21, 25, 263, 263, "H"); put(19, 259, "/"); put(19, 261, "p")
put(25, 265, "w"); put(16, 266, "f")
fill(0, 21, 270, 270); put(22, 270, "d")
put(25, 276, "k"); put(25, 282, "w"); put(25, 284, "b"); put(25, 286, "w")
fill(24, 25, 290, 290); put(23, 290, "g")
put(25, 297, "c")
# I. Market: shanty tiers of one-way platforms up to a high walkway
ground(303, 362, 26)
put(25, 305, "C"); put(25, 307, "+")
for i, row in enumerate([24, 22, 20, 18, 16, 14]):
    c0 = 312 if i % 2 == 0 else 316
    fill(row, row, c0, c0 + 5, "=")
put(23, 314, "w"); put(15, 314, "w"); put(9, 320, "f")
fill(12, 12, 323, 361)  # high walkway (one tile thick, solid)
put(11, 330, "g"); put(11, 336, "k")
put(25, 340, "h"); put(25, 350, "w"); put(25, 356, "w")
# Secret 1: a patch of false ground under the walkway drops into a cellar
fill(26, 26, 344, 349, "s"); fill(27, 27, 344, 349, ".")
put(27, 346, "$"); put(27, 348, "U")
fill(13, 25, 362, 362, "H")
# J. Bridge over the abyss along the walkway: gaps, crumbling planks, a rope, a charger
fill(12, 12, 363, 372); put(11, 368, "c")
fill(12, 12, 376, 381, "x")
fill(12, 12, 385, 392)
fill(3, 3, 395, 397); fill(4, 10, 396, 396, "r")
fill(12, 12, 400, 418); put(11, 404, "C"); put(11, 410, "w"); put(6, 414, "f")
fill(13, 25, 419, 419, "H")
ground(363, 419, 29)  # deep pit bottom far below: falling there kills (below the screen)
fill(29, 29, 363, 419, ".")
# K. Junkyard by the drain: brutes, spitters, barrels, cover, a checkpoint
ground(419, 480, 26)
put(25, 423, "C"); put(25, 425, "p")
put(25, 430, "k"); put(25, 434, "b"); put(25, 435, "b"); put(25, 437, "h")
fill(24, 25, 442, 444); put(23, 443, "g")
put(25, 448, "w"); put(25, 452, "c")
# Secret 2: a false patch of ground drops into a small cellar
fill(26, 26, 456, 464, "s"); fill(27, 27, 456, 464, ".")
put(27, 460, "$"); put(27, 462, "+")
put(25, 468, "w"); put(17, 470, "f"); put(25, 474, "h")
# L. Final climb: a lift up to the rooftops and the exit
ground(481, 539, 26)
put(25, 484, "L"); put(12, 484, "*")
ground(486, 539, 13)
put(12, 490, "w"); put(12, 500, "c"); put(12, 506, "+")
fill(11, 11, 512, 513); put(10, 513, "g")
put(12, 520, "w"); put(12, 530, "E")

finish(g, "scripts/level/slums_level.gd", (25, 3), [
    ("roof", (13, 62)), ("rooftop 3", (14, 105)), ("arena", (25, 189)), ("lever", (19, 259)),
    ("market top", (13, 318)), ("walkway", (11, 340)), ("secret 1", (27, 346)), ("bridge end", (11, 405)),
    ("junkyard", (25, 425)), ("secret 2", (27, 460)), ("exit", (12, 530)),
])
