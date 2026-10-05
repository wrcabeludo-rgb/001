extends Node2D
## Test room: grey-box geometry built from an ASCII map, players spawned
## as they join, practice targets, corner HUD, a help overlay and the F1 tuning panel.
## Left: a shaft for wall jumps. Middle: stairs, each step 2 tiles higher and never
## overhanging another. Right: a gap for double jump / dash.

const TILE := 60
const COLOR_WALL := Color(0.35, 0.37, 0.42)
const TUNING_PANEL := preload("res://scripts/debug/tuning_panel.gd")

## '#' = wall, '1' / '2' = spawn point of player 1 / 2, 'D' = training dummy,
## 'T' = turret that shoots at heroes. 32 x 18 tiles = 1920 x 1080.
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
	"#.......###....1.2....D..D..D..#",
	"################################",
]

const HELP_TEXT := """ЭТАП 2 — бой.  F1 — настройка движения
Присоединиться: прыжок или Start. Выйти: удерживать Start 1.5 с. Сменить героя: вниз + доп.
Левая клавиатура: A/D/W/S — бег и прицел, K/Пробел — прыжок, J — атака, L — навык, I — доп.
Правая клавиатура: стрелки, Num2 — прыжок, Num1 — атака, Num3 — навык, Num5 — доп.
Геймпад: стик/крестовина, A — прыжок, X — атака, B — навык, Y — доп.
Стрелок: атака — выстрел (с направлением — в 8 сторон); держать и отпустить — заряженный выстрел; навык — пинок
Мечник: атака — серия из 3 ударов; вверх + атака — удар вверх; навык — рывок; держать доп. — блок"""

## Off in automated tests that need a quiet room.
var spawn_targets := true

var _spawn_points := {}
var _players := {}
var _status: Label
var _huds: Array[HeroHud] = []


func _ready() -> void:
	_build_level()
	_build_hud()
	PlayerManager.player_joined.connect(_spawn_player)
	PlayerManager.player_left.connect(_despawn_player)
	PlayerManager.hero_changed.connect(_on_hero_changed)
	add_child(TUNING_PANEL.new())
	for slot in PlayerManager.MAX_PLAYERS:
		if PlayerManager.players[slot] != null:
			_spawn_player(slot)


func _physics_process(_delta: float) -> void:
	for slot in PlayerManager.MAX_PLAYERS:
		var device: PlayerInput = PlayerManager.players[slot]
		if device != null and device.is_held("down") and device.just_pressed("extra"):
			PlayerManager.swap_hero(slot)


func _process(_delta: float) -> void:
	for slot in PlayerManager.MAX_PLAYERS:
		_huds[slot].show_player(_players.get(slot))
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


func _build_level() -> void:
	var walls := StaticBody2D.new()
	walls.name = "Walls"
	add_child(walls)

	for row in MAP.size():
		var line: String = MAP[row]
		var col := 0
		while col < line.length():
			var cell := line[col]
			var floor_point := Vector2((col + 0.5) * TILE, (row + 1) * TILE)
			if cell == "1" or cell == "2":
				# Spawn so the player's feet touch the bottom of this cell.
				_spawn_points[int(cell) - 1] = floor_point - Vector2(0, Player.SIZE.y / 2)
			elif cell == "D" and spawn_targets:
				_add_target(TrainingDummy.new(), floor_point - Vector2(0, TrainingDummy.SIZE.y / 2))
			elif cell == "T" and spawn_targets:
				_add_target(TurretDummy.new(), floor_point - Vector2(0, 25))
			if cell != "#":
				col += 1
				continue
			# Merge a horizontal run of walls into one rectangle.
			var start := col
			while col < line.length() and line[col] == "#":
				col += 1
			_add_wall(walls, Rect2(start * TILE, row * TILE, (col - start) * TILE, TILE))


func _add_wall(walls: StaticBody2D, rect: Rect2) -> void:
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.position = rect.get_center()
	walls.add_child(collision)

	var visual := ColorRect.new()
	visual.position = rect.position
	visual.size = rect.size
	visual.color = COLOR_WALL
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	walls.add_child(visual)


func _add_target(target: Node2D, at: Vector2) -> void:
	target.position = at
	add_child(target)


func _build_hud() -> void:
	var hud := CanvasLayer.new()
	add_child(hud)

	for slot in PlayerManager.MAX_PLAYERS:
		var panel := HeroHud.new()
		panel.position = Vector2(80, 70) if slot == 0 else Vector2(1440, 70)
		hud.add_child(panel)
		_huds.append(panel)

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


func _spawn_player(slot: int) -> void:
	var player := Player.new()
	player.name = "Player%d" % (slot + 1)
	player.setup(slot, PlayerManager.players[slot], PlayerManager.heroes[slot])
	player.position = _spawn_points[slot]
	add_child(player)
	player.died.connect(_on_player_died)
	_players[slot] = player


func _on_player_died(player: Player) -> void:
	# Stage 2: just come back at the spawn point. Real death rules arrive in stage 3.
	player.revive.call_deferred(_spawn_points[player.slot])


func _on_hero_changed(slot: int) -> void:
	if _players.has(slot):
		_players[slot].set_hero(PlayerManager.heroes[slot])


func _despawn_player(slot: int) -> void:
	if _players.has(slot):
		_players[slot].queue_free()
		_players.erase(slot)
