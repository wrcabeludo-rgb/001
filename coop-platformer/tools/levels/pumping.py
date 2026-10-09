"""Zone 2-3 "Насосная станция" (with the world 2 boss). Run: python3 tools/levels/pumping.py [--png preview.png]"""
from grid import Grid, finish

g = Grid(580)
put, fill, ground = g.put, g.fill, g.ground

# A. The pump room entrance
fill(0, 9, 1, 40)
ground(1, 43, 26)
put(25, 3, "1"); put(25, 5, "2")
put(25, 22, "W"); put(10, 30, "t"); put(25, 36, "W")
# B. Electrified floors (taking turns) with catwalks above as the safe way
fill(0, 9, 41, 100)
ground(44, 100, 26)
for c in (46, 62, 78):
    fill(26, 26, c, c + 9, "e")
fill(22, 22, 48, 53, "="); fill(22, 22, 64, 69, "="); fill(22, 22, 80, 85, "=")
put(25, 58, "K"); put(16, 74, "R"); put(25, 94, "W")
# C. A sludge canal crossed on belts (one runs against you)
fill(0, 9, 101, 160)
ground(101, 156, 27); ground(101, 102, 26); fill(26, 26, 103, 156, "~")
fill(24, 24, 104, 115, ">")
fill(23, 23, 119, 127, "<")
fill(24, 24, 131, 141, ">")
fill(24, 24, 145, 152, ">")
put(15, 122, "R"); put(14, 140, "R")
# D. A checkpoint, then a belt against you under four presses
ground(157, 212, 26)
put(25, 159, "C"); put(25, 160, "p")
fill(0, 9, 157, 164)
fill(0, 19, 165, 207)
fill(26, 26, 165, 207, "<")
for c in (170, 180, 190, 200):
    fill(20, 20, c, c + 1, "P")
put(25, 185, "W"); put(25, 204, "W")
# E. A steam vent up to the pump control ledge (a hidden room inside it)
fill(0, 9, 208, 262)
ground(213, 262, 26)
put(25, 215, "V")
fill(19, 25, 218, 234)
fill(19, 20, 228, 232, "s"); put(20, 229, "$"); put(20, 231, "U")
put(18, 222, "G"); put(10, 226, "t")
# F. The pump hall arena
put(25, 238, "C"); put(25, 239, "+"); put(25, 240, "p")
fill(0, 21, 244, 244); put(22, 244, "[")
fill(0, 21, 280, 280); put(22, 280, "]")
ground(244, 380, 26)
fill(22, 22, 249, 252, "="); fill(22, 22, 272, 275, "="); fill(19, 19, 259, 265, "=")
# G. Electro floor, a vent up to a belt on a ledge, a hidden cellar, a loader
fill(0, 9, 281, 380)
fill(26, 26, 286, 295, "e")
put(25, 300, "V")
fill(19, 25, 303, 316)
fill(19, 19, 303, 316, ">")
put(18, 308, "G")
fill(26, 27, 324, 329, "s"); put(27, 326, "$"); put(27, 328, "+")
put(25, 340, "O"); put(25, 350, "W"); put(16, 356, "n")
# H. Last checkpoint before the chase
put(25, 366, "C"); put(25, 367, "+"); put(25, 368, "+"); put(25, 369, "p")
# I. The chase: the loader breaks in behind; belts help, presses and pits and
#    debris slow you down
put(25, 382, "X")
fill(0, 9, 381, 412)
ground(381, 499, 26)
fill(26, 26, 392, 410, ">")
fill(26, 29, 414, 416, ".")
fill(0, 19, 420, 446)
fill(20, 20, 424, 425, "P"); fill(20, 20, 438, 439, "P")
fill(0, 9, 447, 499)
put(10, 455, "v"); put(10, 466, "v")
fill(26, 29, 470, 472, ".")
fill(26, 26, 476, 484, "e")
put(25, 432, "K"); put(25, 460, "K")
# J. The loader's last stand: the boss hall
fill(0, 21, 503, 503); put(22, 503, "[")
fill(0, 21, 557, 557); put(22, 557, "]")
ground(500, 579, 26)
fill(22, 22, 510, 514, "="); fill(22, 22, 546, 550, "="); fill(18, 18, 526, 534, "=")
# K. The way out
put(25, 572, "E")

finish(g, "scripts/level/pumping_level.gd", (25, 3), [
    ("electro", (25, 100)), ("canal", (25, 157)), ("presses", (25, 210)), ("ledge", (18, 225)),
    ("secret 1", (20, 229)), ("arena", (25, 262)), ("belt ledge", (18, 310)), ("secret 2", (27, 326)),
    ("chase", (25, 382)), ("chase end", (25, 498)), ("boss", (25, 530)), ("exit", (25, 572)),
])
