class_name Credits
## Who made what in the game, for the credits screen (title menu, "Авторы").
## The same list is in CREDITS.md; keep both in step.

const MUSIC := [
	["Меню", "Gearhead"],
	["1-1 Трущобы", "Neolith"],
	["1-2 Затопленное метро", "Zap Beat"],
	["1-3 Главный сток", "Noise Attack"],
	["Босс", "Summon the Rawk"],
	["Лавка", "RetroFuture Dirty"],
]


static func text() -> String:
	var lines := PackedStringArray(["МУЗЫКА", ""])
	for track in MUSIC:
		lines.append("%s — «%s»" % [track[0], track[1]])
	lines.append("")
	lines.append("Kevin MacLeod (incompetech.com)")
	lines.append("Licensed under Creative Commons: By Attribution 4.0")
	lines.append("creativecommons.org/licenses/by/4.0/")
	lines.append("")
	lines.append("Звуки — синтезированы для игры. Шрифты Russo One и Exo 2 — SIL Open Font License.")
	return "\n".join(lines)
