"""Zone 3-1 "Подножие Башни". Run: python3 tools/levels/tower_base.py [--png preview.png]"""
from grid import Grid, finish

g = Grid(470)
put, fill, ground = g.put, g.fill, g.ground

# A. The street at the foot of the tower
ground(1, 46, 26)
put(25, 3, "1"); put(25, 5, "2")
put(25, 24, "N"); put(25, 38, "N"); put(16, 32, "R")
# B. The checkpoint yard: searchlights over the yard, cover, an alarm hatch at the far side
fill(0, 8, 47, 120)
ground(47, 120, 26)
put(9, 60, "S"); put(9, 84, "S"); put(9, 104, "S")
put(25, 56, "k"); put(25, 72, "k"); put(25, 90, "k"); put(25, 108, "k")
put(25, 116, "A")
put(25, 66, "N"); put(25, 98, "y")
# C. A barrier with its lever on a ledge; snipers on the ledges above
ground(121, 200, 26)
put(25, 123, "C"); put(25, 124, "p")
fill(0, 8, 121, 200)
fill(20, 20, 128, 140)
fill(21, 25, 127, 127, "H")
put(19, 138, "/")
put(19, 132, "J")
fill(9, 21, 146, 146); put(22, 146, "I")
fill(26, 27, 150, 155, "s"); put(27, 152, "$"); put(27, 154, "U")
fill(19, 19, 160, 166); put(18, 164, "J")
put(25, 172, "y"); put(25, 182, "N"); put(25, 192, "j")
# D. The lobby: the first arena
ground(201, 250, 26)
put(25, 202, "C"); put(25, 203, "+"); put(25, 204, "p")
fill(0, 21, 208, 208); put(22, 208, "[")
fill(0, 21, 244, 244); put(22, 244, "]")
fill(22, 22, 213, 216, "="); fill(22, 22, 236, 239, "="); fill(19, 19, 223, 229, "=")
# E. The garage: flickering barriers, lasers, grenadiers behind cover
fill(0, 8, 251, 340)
ground(251, 340, 26)
put(22, 262, "i"); fill(0, 21, 262, 262)
put(9, 275, "z"); put(9, 279, "z")
put(22, 290, "i"); fill(0, 21, 290, 290)
put(25, 300, "k"); put(25, 306, "j"); put(25, 320, "k"); put(25, 326, "j")
put(9, 312, "S"); put(25, 336, "A")
put(25, 296, "y")
# F. A glass bridge over the pit, an exo-trooper, a second secret, the exit lift
put(25, 338, "C")
ground(341, 345, 26)
fill(26, 26, 346, 366, "o")
ground(367, 469, 26)
put(25, 380, "l"); put(25, 395, "N"); put(15, 400, "R")
fill(19, 19, 404, 418); fill(20, 25, 403, 403, "H")
fill(15, 15, 411, 418); fill(16, 18, 418, 418)
fill(16, 18, 412, 417, "s"); put(18, 414, "$"); put(18, 416, "+")
fill(0, 8, 420, 469)
put(25, 430, "l"); put(25, 445, "y"); put(25, 450, "y")
put(25, 462, "E")

finish(g, "scripts/level/tower_base_level.gd", (25, 3), [
    ("yard", (25, 118)), ("lever", (19, 138)), ("secret 1", (27, 152)), ("after barrier", (25, 199)),
    ("arena", (25, 226)), ("garage", (25, 337)), ("bridge end", (25, 368)), ("secret 2", (18, 414)),
    ("exit", (25, 462)),
])
