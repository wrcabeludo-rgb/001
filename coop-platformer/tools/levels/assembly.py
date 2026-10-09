"""Zone 2-1 "Сборочный цех". Run: python3 tools/levels/assembly.py [--png preview.png]"""
from grid import Grid, finish

g = Grid(472)
put, fill, ground = g.put, g.fill, g.ground

# A. The hall entrance: welders at work
fill(0, 9, 1, 40)
ground(1, 43, 26)
put(25, 3, "1"); put(25, 5, "2")
put(25, 22, "W"); put(25, 32, "W"); put(25, 38, "W")
# B. The first belts: one helps, one works against you
fill(0, 9, 41, 95)
fill(26, 26, 44, 70, ">")
ground(71, 73, 26)
fill(26, 26, 74, 95, "<")
fill(27, 29, 44, 95)
put(25, 60, "W"); put(25, 90, "W"); put(16, 84, "R")
# C. Belts over the abyss, running back towards the pit
fill(0, 9, 96, 150)
fill(24, 24, 98, 106, "<")
fill(23, 23, 110, 118, "<")
fill(22, 22, 122, 128, ">")
fill(23, 23, 132, 140, "<")
fill(24, 24, 144, 148, "<")
put(15, 116, "R"); put(14, 136, "R")
# D. A checkpoint, a hidden cellar, then a belt under three presses
ground(149, 200, 26)
put(25, 152, "C"); put(25, 154, "p")
fill(26, 27, 156, 161, "s"); put(27, 158, "$"); put(27, 160, "U")
fill(0, 9, 151, 164)
fill(0, 19, 165, 197)
fill(26, 26, 165, 197, ">")
for c in (170, 178, 186):
    fill(20, 20, c, c + 1, "P")
put(25, 175, "W"); put(25, 192, "W")
# E. Crate hatches over a belt that piles crates against a high ledge
fill(0, 5, 198, 252)
ground(201, 229, 27)
fill(26, 26, 203, 229, ">")
for c in (208, 216, 224):
    put(6, c, "Q")
fill(22, 29, 230, 252)
fill(24, 24, 224, 227, "=")
fill(21, 21, 216, 219, "=")
put(21, 236, "K"); put(21, 246, "W")
# F. Down into the first arena
ground(253, 300, 26)
put(25, 254, "C"); put(25, 255, "+"); put(25, 256, "p")
fill(0, 21, 258, 258); put(22, 258, "[")
fill(0, 21, 294, 294); put(22, 294, "]")
fill(22, 22, 264, 267, "="); fill(22, 22, 285, 288, "="); fill(19, 19, 274, 278, "=")
# G. Two levels of the line: a belt below, a catwalk above, turrets on the ceiling,
#    a lever up top opens the door ahead; a second hidden cellar
fill(0, 9, 295, 372)
ground(301, 372, 26)
fill(26, 26, 305, 340, "<")
fill(20, 20, 312, 362, "=")
put(10, 322, "t"); put(10, 352, "t")
put(19, 318, "W"); put(19, 340, "W"); put(19, 358, "/")
fill(21, 25, 364, 364, "H")
put(25, 344, "G"); put(25, 330, "W")
fill(26, 27, 346, 351, "s"); put(27, 348, "$"); put(27, 350, "+")
fill(10, 21, 368, 368); put(22, 368, "d")
# H. A crane over the pit
fill(0, 9, 373, 410)
ground(373, 376, 26)
put(24, 377, "Y"); put(24, 402, "*")
ground(406, 471, 26)
put(16, 386, "R"); put(16, 396, "R")
# I. The last stretch: a loader, kamikazes, a press at the door, the exit
fill(0, 9, 411, 445)
put(25, 410, "C"); put(25, 412, "+")
put(25, 422, "W"); put(25, 430, "O"); put(25, 438, "K"); put(25, 441, "K")
fill(0, 19, 446, 456)
fill(20, 20, 450, 451, "P")
fill(0, 9, 457, 470)
put(25, 466, "E")

finish(g, "scripts/level/assembly_level.gd", (25, 3), [
    ("belts", (25, 95)), ("abyss belts", (23, 146)), ("presses", (25, 199)), ("ledge", (21, 240)),
    ("arena", (25, 276)), ("secret 1", (27, 158)), ("catwalk", (19, 340)), ("lever", (19, 358)),
    ("secret 2", (27, 348)), ("crane", (24, 380)), ("after crane", (25, 408)), ("exit", (25, 466)),
])
