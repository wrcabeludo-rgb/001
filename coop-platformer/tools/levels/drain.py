"""Zone 1-3 "Главный сток" (with the world 1 boss). Run: python3 tools/levels/drain.py [--png preview.png]"""
from grid import Grid, finish

g = Grid(442)
put, fill, ground = g.put, g.fill, g.ground

# A. A sewer junction (start)
fill(0, 12, 1, 45)
ground(1, 45, 26)
put(25, 3, "1"); put(25, 5, "2")
put(25, 22, "w"); put(13, 30, "a"); put(25, 36, "w")
# B. The sludge river: two rafts one after the other, a rope as a short cut
fill(0, 10, 46, 100)
ground(46, 95, 27); fill(26, 26, 46, 95, "~")
put(25, 47, "M"); put(25, 70, "*")
put(24, 72, "M"); put(24, 94, "*")
fill(11, 19, 85, 85, "r")
put(18, 60, "f"); put(18, 80, "f")
ground(96, 120, 26)
put(25, 99, "g")
# C. A climb up the pipes: ladders, ledges, flyers
fill(0, 5, 101, 200)
put(25, 103, "C"); put(25, 104, "p")
fill(19, 25, 105, 105, "H"); fill(18, 18, 106, 111)
fill(13, 17, 111, 111, "H"); fill(12, 12, 112, 120, "=")
put(15, 116, "f")
# D. The upper gallery: debris, gas flamethrowers, a brute
ground(121, 200, 12)
for c in (140, 150, 160):
    put(6, c, "v")
put(11, 170, "#"); put(11, 171, "F"); put(11, 184, "F")
put(11, 130, "w"); put(11, 192, "w"); put(11, 197, "h")
# E. Down into the cistern: checkpoint, supplies, an arena
ground(201, 246, 26)
put(25, 204, "C"); put(25, 206, "+"); put(25, 207, "p")
fill(0, 21, 210, 210); put(22, 210, "[")
fill(0, 21, 236, 236); put(22, 236, "]")
fill(22, 22, 215, 218, "="); fill(22, 22, 228, 231, "="); fill(19, 19, 221, 225, "=")
# F. A crumbling walkway over a sludge pool, ambushers in a low tunnel, secret cellar
ground(247, 262, 27); fill(26, 26, 247, 262, "~")
for c0 in (248, 253, 258):
    fill(24, 24, c0, c0 + 3, "x")
ground(263, 342, 26)
fill(0, 18, 263, 292)
put(19, 275, "a"); put(19, 288, "a"); put(25, 280, "w"); put(25, 294, "c")
fill(26, 27, 268, 273, "s")
put(27, 270, "$"); put(27, 272, "U")
# G. A lever on a ledge (and a hidden room behind it) opens the door; a gauntlet
fill(20, 20, 296, 307); fill(17, 17, 295, 302); fill(17, 20, 295, 295)
fill(18, 19, 296, 302, "s")
put(19, 298, "$"); put(19, 300, "+")
fill(21, 25, 308, 308, "H"); put(19, 304, "/")
fill(0, 21, 315, 315); put(22, 315, "d")
put(25, 320, "k"); put(25, 326, "b"); put(25, 327, "b"); put(25, 334, "h")
fill(24, 25, 330, 330); put(23, 330, "g")
put(25, 338, "C")
# H. Before the boss: supplies
ground(343, 441, 26)
put(25, 345, "+"); put(25, 346, "+"); put(25, 348, "p")
put(25, 360, "w"); put(25, 372, "w")
# I. The Sludge Master's den
fill(0, 21, 386, 386); put(22, 386, "[")
fill(0, 21, 416, 416); put(22, 416, "]")
fill(22, 22, 391, 394, "="); fill(22, 22, 408, 411, "=")
# J. The way out
put(25, 432, "E")

finish(g, "scripts/level/drain_level.gd", (25, 3), [
    ("river end", (25, 98)), ("pipes top", (11, 122)), ("gallery end", (11, 199)), ("arena", (25, 223)),
    ("walkway end", (25, 264)), ("secret 1", (27, 270)), ("lever", (19, 304)), ("secret 2", (19, 298)),
    ("gauntlet", (25, 336)), ("boss", (25, 401)), ("exit", (25, 432)),
])
