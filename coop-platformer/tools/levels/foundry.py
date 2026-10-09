"""Zone 2-2 "Литейная". Run: python3 tools/levels/foundry.py [--png preview.png]"""
from grid import Grid, finish

g = Grid(452)
put, fill, ground = g.put, g.fill, g.ground

# A. The foundry gate
fill(0, 9, 1, 43)
ground(1, 43, 26)
put(25, 3, "1"); put(25, 5, "2")
put(25, 20, "W"); put(25, 30, "W"); put(16, 36, "R")
# B. A pool of molten metal crossed on two cranes
fill(0, 9, 44, 100)
ground(44, 96, 27); fill(26, 26, 44, 96, "%")
put(23, 46, "Y"); put(23, 70, "*")
put(22, 74, "Y"); put(22, 93, "*")
put(15, 60, "R"); put(14, 86, "R")
# C. Steam vents up two ledges
ground(97, 140, 26)
fill(0, 5, 101, 200)
put(25, 99, "W")
put(25, 104, "V")
fill(19, 25, 107, 125)
put(18, 116, "W")
put(18, 124, "V")
fill(13, 25, 127, 140)
# D. The upper gallery: gas jets in the walls, a shield guard, a repair drone,
#    a hidden cellar under the floor
ground(141, 200, 13)
put(12, 142, "C"); put(12, 143, "p")
put(12, 152, "#"); put(12, 153, "F")
put(12, 168, "#"); put(12, 167, "F")
put(12, 160, "W"); put(12, 176, "G"); put(8, 178, "n"); put(12, 192, "W")
fill(13, 14, 182, 187, "s"); put(14, 184, "$"); put(14, 186, "U")
# E. Down into the casting hall: the arena
ground(201, 252, 26)
fill(0, 5, 201, 252)
put(25, 204, "C"); put(25, 205, "+"); put(25, 206, "p")
fill(0, 21, 212, 212); put(22, 212, "[")
fill(0, 21, 246, 246); put(22, 246, "]")
fill(22, 22, 217, 220, "="); fill(22, 22, 238, 241, "="); fill(19, 19, 227, 231, "=")
# F. A long trench of molten metal: crane, an island, another crane
fill(0, 9, 253, 330)
ground(253, 326, 27); fill(26, 26, 253, 326, "%")
put(23, 256, "Y"); put(23, 279, "*")
fill(22, 29, 283, 288)
put(22, 291, "Y"); put(22, 322, "*")
put(14, 268, "R"); put(13, 300, "R"); put(14, 316, "R")
# G. Presses over the casting floor; a steam vent up to a lever that opens the door
ground(327, 451, 26)
fill(0, 9, 327, 339)
fill(0, 19, 340, 368)
for c in (344, 352, 360):
    fill(20, 20, c, c + 1, "P")
fill(0, 9, 369, 451)
put(25, 335, "O"); put(25, 349, "W"); put(25, 357, "W")
put(25, 371, "V")
fill(20, 20, 373, 378)
put(19, 377, "/")
fill(10, 21, 381, 381); put(22, 381, "d")
fill(26, 27, 384, 389, "s"); put(27, 386, "$"); put(27, 388, "+")
# H. The last hall: a narrow pit of metal, a loader and a guard, the exit
put(25, 393, "C"); put(25, 394, "+")
ground(405, 407, 27); fill(26, 26, 405, 407, "%")
put(25, 420, "O"); put(25, 430, "G"); put(25, 436, "K"); put(16, 440, "R")
put(25, 446, "E")

finish(g, "scripts/level/foundry_level.gd", (25, 3), [
    ("cranes", (25, 98)), ("first ledge", (18, 112)), ("gallery", (12, 145)), ("secret 1", (14, 184)),
    ("arena", (25, 229)), ("island", (21, 285)), ("after trench", (25, 330)), ("lever", (19, 377)),
    ("secret 2", (27, 386)), ("exit", (25, 446)),
])
