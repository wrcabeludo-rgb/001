"""Zone 3-3 "Ядро «Сердца»" (the world 3 boss and the finale).
Run: python3 tools/levels/tower_core.py [--png preview.png]"""
from grid import Grid, finish

g = Grid(430)
put, fill, ground = g.put, g.fill, g.ground

# A. The reactor gallery: Heart vents send waves along the floor
fill(0, 8, 1, 90)
ground(1, 90, 26)
put(25, 3, "1"); put(25, 5, "2")
put(25, 26, "q"); put(25, 52, "q"); put(25, 74, "q")
put(25, 36, "N"); put(25, 62, "y"); put(25, 84, "N")
# B. Gravity lifts to the upper ring, flickering barriers, snipers, a hidden capacitor room
ground(91, 160, 26)
put(25, 93, "C"); put(25, 94, "p")
fill(0, 4, 91, 160)
fill(10, 25, 100, 100, "u")
fill(9, 9, 97, 140)
put(8, 112, "J"); put(8, 128, "y")
fill(5, 8, 118, 118); put(8, 118, "i")
fill(10, 25, 141, 141, "u")
fill(9, 9, 141, 145)
fill(26, 27, 120, 125, "s"); put(27, 122, "$"); put(27, 124, "U")
put(25, 112, "l"); put(25, 150, "j")
fill(0, 21, 155, 155); put(22, 155, "i")
# C. The capacitor hall arena
ground(161, 210, 26)
fill(0, 4, 161, 210)
put(25, 162, "C"); put(25, 163, "+"); put(25, 164, "p")
fill(0, 21, 168, 168); put(22, 168, "[")
fill(0, 21, 204, 204); put(22, 204, "]")
fill(22, 22, 173, 176, "="); fill(22, 22, 196, 199, "="); fill(19, 19, 183, 189, "=")
# D. A glass bridge over the reactor pit, Heart vents, exo-troopers
ground(211, 222, 26)
fill(26, 26, 223, 240, "o")
ground(241, 320, 26)
fill(0, 8, 211, 320)
put(25, 252, "q"); put(25, 280, "q"); put(25, 306, "q")
put(25, 266, "l"); put(25, 294, "N"); put(25, 300, "N"); put(15, 270, "R")
# E. Before the commander: supplies, the boss hall
put(25, 316, "C"); put(25, 317, "+"); put(25, 318, "+"); put(25, 319, "p")
ground(321, 429, 26)
fill(0, 21, 324, 324); put(22, 324, "[")
fill(0, 21, 378, 378); put(22, 378, "]")
fill(22, 22, 331, 335, "="); fill(22, 22, 367, 371, "="); fill(18, 18, 347, 355, "=")
# F. The Heart: two switches
fill(0, 4, 379, 429)
put(25, 395, "{"); put(25, 412, "}")

finish(g, "scripts/level/tower_core_level.gd", (25, 3), [
    ("lifts", (25, 99)), ("upper ring", (8, 130)), ("secret", (27, 122)), ("arena", (25, 186)),
    ("bridge end", (25, 242)), ("boss", (25, 350)), ("switch off", (25, 395)), ("switch keep", (25, 412)),
])
