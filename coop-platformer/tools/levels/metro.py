"""Zone 1-2 "Затопленное метро". Run: python3 tools/levels/metro.py [--png preview.png]"""
from grid import Grid, finish

g = Grid(520)
put, fill, ground = g.put, g.fill, g.ground

# A. Station platform (start), stairs down to the tracks
fill(0, 14, 1, 36)
ground(1, 30, 23)
put(22, 3, "1"); put(22, 5, "2")
put(22, 20, "w"); put(15, 26, "a")
ground(31, 33, 24); ground(34, 36, 25)
# B. Flooded tunnel: sludge between the tracks, half-sunk train cars to jump along
fill(0, 17, 37, 100)
ground(37, 40, 26)
ground(41, 98, 27); fill(26, 26, 41, 98, "~")
for c in range(41, 98, 10):
    fill(24, 25, c, c + 6)
put(23, 44, "w"); put(23, 64, "w"); put(23, 84, "c")
put(18, 59, "a"); put(18, 79, "a")
# C. Station 2: checkpoint, a service lift up to the mezzanine
fill(0, 8, 99, 175)
ground(99, 119, 26)
put(25, 102, "C"); put(25, 105, "p")
put(25, 112, "L"); put(15, 112, "*")
fill(17, 25, 120, 120)
# Mezzanine: cover against a spitter, signal lasers, a crumbling stretch over a shaft
fill(16, 29, 114, 175)
fill(16, 29, 146, 151, "."); fill(16, 16, 146, 151, "x")
put(15, 124, "k"); put(15, 132, "g"); put(15, 140, "w")
for c in (156, 160, 164):
    put(9, c, "z")
put(15, 170, "w")
# D. Down a ladder to the tracks; a maintenance cart over a long sludge canal
fill(0, 12, 176, 215)
fill(17, 25, 176, 176, "H")
ground(176, 181, 26); ground(182, 205, 27); fill(26, 26, 182, 205, "~")
put(25, 181, "M"); put(25, 206, "*")
ground(206, 223, 26)
put(19, 190, "f"); put(19, 200, "f")
# E. Checkpoint, supplies and the station hall arena
put(25, 218, "C"); put(25, 220, "+"); put(25, 221, "p")
fill(0, 21, 224, 224); put(22, 224, "[")
fill(0, 21, 250, 250); put(22, 250, "]")
ground(224, 270, 26)
fill(22, 22, 229, 232, "="); fill(22, 22, 242, 245, "="); fill(19, 19, 235, 239, "=")
# F. A ventilation shaft up: one-way ledges, a flyer, a hidden room on the left
fill(0, 3, 251, 300)
for i, row in enumerate(range(24, 9, -2)):
    c0 = 262 if i % 2 == 0 else 266
    fill(row, row, c0, c0 + 4, "=")
put(12, 264, "f"); put(16, 263, "w")
fill(14, 14, 252, 261); fill(14, 17, 252, 252); fill(17, 17, 252, 261)
fill(15, 16, 253, 261, "s")
put(16, 254, "$"); put(16, 256, "U")
# G. Upper service tunnel: falling debris, a spike pit, gas flamethrowers, the last checkpoint
fill(8, 29, 271, 380)
fill(0, 3, 301, 380)
put(7, 303, "C"); put(7, 305, "+")
for c in (312, 318, 324):
    put(4, c, "v")
fill(8, 8, 330, 332, "^")
put(7, 340, "#"); put(7, 341, "F"); put(7, 352, "F")
put(7, 360, "w"); put(7, 368, "h"); put(7, 375, "w")
# H. A flooded hall far below: islands in the sludge, flyers, a spitter
fill(0, 2, 381, 470)
ground(381, 385, 26); ground(386, 425, 27); fill(26, 26, 386, 425, "~")
for c in range(388, 424, 5):
    fill(24, 25, c, c + 1)
put(23, 403, "g"); put(16, 395, "f"); put(16, 412, "f")
ground(426, 430, 26)
# I. A collapsing train bridge over the abyss, then a secret cellar
for c0 in (431, 438, 445):
    fill(24, 24, c0, c0 + 4, "x")
ground(451, 519, 26)
fill(26, 27, 458, 463, "s")
put(27, 460, "$"); put(27, 462, "+")
# J. The far station and the way out
fill(0, 10, 471, 519)
put(25, 476, "w"); put(25, 484, "c"); put(25, 492, "w"); put(25, 498, "h")
put(25, 512, "E")

finish(g, "scripts/level/metro_level.gd", (22, 3), [
    ("tunnel end", (25, 100)), ("mezzanine", (15, 125)), ("lasers", (15, 166)), ("cart", (25, 207)),
    ("arena", (25, 237)), ("shaft top", (7, 280)), ("secret 1", (16, 254)), ("tunnel", (7, 362)),
    ("hall", (25, 427)), ("bridge end", (25, 452)), ("secret 2", (27, 460)), ("exit", (25, 512)),
])
