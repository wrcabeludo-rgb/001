extends Level
## Single-screen test room for tuning movement and combat: help overlay,
## practice targets, input status and the F1 tuning panel. F2 opens the Polygon.
## Left: a shaft for wall jumps. Middle: stairs, each step 2 tiles higher and never
## overhanging another. Right: a gap for double jump / dash, dummies and a turret.

const TUNING_PANEL := preload("res://scripts/debug/tuning_panel.gd")

## 32 x 18 tiles = exactly one screen (legend in Level).
const MAP := [
	"################################",
	"#..............................#",
	"#..............................#",
	"#..............................#",
	"#..............................#",
	"#..............................#",
	"#...#######....................#",
	"#...#..........................#",
	"#...#.........................T#",
	"#...#...............####.....###",
	"#...#..........................#",
	"#...#...........###............#",
	"#...#..........................#",
	"#...#.......###................#",
	"#..............................#",
	"#.......###....................#",
	"#.......###....1.2....D.wD..D..#",
	"################################",
]

const HELP_TEXT := """Тестовая комната.  F1 — настройка движения.  F2 — «Полигон» (враги), ещё раз F2 — «Мастерская» (механики)
Присоединиться: прыжок или Start. Выйти: удерживать Start 1.5 с. Сменить героя: вниз + доп.
Левая клавиатура: A/D/W/S — бег и прицел, K/Пробел — прыжок, J — атака, L — навык, I — доп.
Правая клавиатура: стрелки, Num2 — прыжок, Num1 — атака, Num3 — навык, Num5 — доп.
Геймпад: стик/крестовина, A — прыжок, X — атака, B — навык, Y — доп.
Стрелок: атака — выстрел (с направлением — в 8 сторон); держать и отпустить — заряженный выстрел; навык — пинок
Мечник: атака — серия из 3 ударов; вверх + атака — удар вверх; навык — рывок; держать доп. — блок"""

var _status: Label


func _init() -> void:
	use_coop_camera = false
	other_scene = "res://scenes/coop_level.tscn"


func get_map() -> Array:
	return MAP


func _ready() -> void:
	super._ready()
	add_child(TUNING_PANEL.new())

	var help := Label.new()
	help.text = HELP_TEXT
	help.position = Vector2(700, 160)
	help.add_theme_font_size_override("font_size", 18)
	hud.add_child(help)

	_status = Label.new()
	_status.position = Vector2(700, 345)
	_status.add_theme_font_size_override("font_size", 22)
	_status.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
	hud.add_child(_status)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	for slot in PlayerManager.MAX_PLAYERS:
		var device: PlayerInput = PlayerManager.players[slot]
		if device != null and device.is_held("down") and device.just_pressed("extra"):
			PlayerManager.swap_hero(slot)


func _process(delta: float) -> void:
	super._process(delta)
	var lines := PackedStringArray()
	for slot in PlayerManager.MAX_PLAYERS:
		var device: PlayerInput = PlayerManager.players[slot]
		if device == null:
			lines.append("Игрок %d: свободно" % (slot + 1))
		else:
			var hero_name: String = Heroes.NAMES[PlayerManager.heroes[slot]]
			lines.append("Игрок %d: %s — %s  [%s]" % [slot + 1, hero_name, device.label, " ".join(device.held_actions())])
	lines.append("Геймпадов подключено: %d    FPS: %d" % [PlayerManager.gamepad_count(), Engine.get_frames_per_second()])
	_status.text = "\n".join(lines)
