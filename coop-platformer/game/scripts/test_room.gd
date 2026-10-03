extends Node2D
## Stage 0 test room: grey-box geometry built from an ASCII map,
## players spawned as they join, and a help overlay.

const TILE := 60
const COLOR_WALL := Color(0.35, 0.37, 0.42)
const PLAYER_COLORS := [Color(0.3, 0.8, 1.0), Color(1.0, 0.6, 0.25)]

## '#' = wall, '1' / '2' = spawn point of player 1 / 2. 32 x 18 tiles = 1920 x 1080.
const MAP := [
	"################################",
	"#..............................#",
	"#..............................#",
	"#..............................#",
	"#..............................#",
	"#..............................#",
	"#..............................#",
	"#..............................#",
	"#..............................#",
	"#.....................######...#",
	"#..............................#",
	"#..............######..........#",
	"#..............................#",
	"#.......######.................#",
	"#..............................#",
	"#..#####...........##..........#",
	"#.........1.2......##..........#",
	"################################",
]

const HELP_TEXT := """ЭТАП 0 — тестовая комната
Присоединиться: прыжок или Start на своём устройстве. Выйти: удерживать Start 1.5 с.
Клавиатура (левая): A/D — бег, W/S — вверх/вниз, K или Пробел — прыжок, J — атака, L — навык, I — доп., Esc — Start
Клавиатура (правая): стрелки — бег, Num2 — прыжок, Num1 — атака, Num3 — навык, Num5 — доп., Num Enter — Start
Геймпад: стик или крестовина — бег, A — прыжок, X — атака, B — навык, Y — доп., Start — Start"""

var _spawn_points := {}
var _players := {}
var _status: Label


func _ready() -> void:
	_build_level()
	_build_hud()
	PlayerManager.player_joined.connect(_spawn_player)
	PlayerManager.player_left.connect(_despawn_player)
	for slot in PlayerManager.MAX_PLAYERS:
		if PlayerManager.players[slot] != null:
			_spawn_player(slot)


func _process(_delta: float) -> void:
	var lines := PackedStringArray()
	for slot in PlayerManager.MAX_PLAYERS:
		var device: PlayerInput = PlayerManager.players[slot]
		if device == null:
			lines.append("Игрок %d: свободно" % (slot + 1))
		else:
			lines.append("Игрок %d: %s  [%s]" % [slot + 1, device.label, " ".join(device.held_actions())])
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
			if cell == "1" or cell == "2":
				# Spawn so the player's feet touch the bottom of this cell.
				_spawn_points[int(cell) - 1] = Vector2((col + 0.5) * TILE, (row + 1) * TILE - Player.SIZE.y / 2)
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


func _build_hud() -> void:
	var hud := CanvasLayer.new()
	add_child(hud)

	var help := Label.new()
	help.text = HELP_TEXT
	help.position = Vector2(80, 76)
	help.add_theme_font_size_override("font_size", 20)
	hud.add_child(help)

	_status = Label.new()
	_status.position = Vector2(80, 260)
	_status.add_theme_font_size_override("font_size", 22)
	_status.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
	hud.add_child(_status)


func _spawn_player(slot: int) -> void:
	var player := Player.new()
	player.name = "Player%d" % (slot + 1)
	player.setup(slot, PlayerManager.players[slot], PLAYER_COLORS[slot])
	player.position = _spawn_points[slot]
	add_child(player)
	_players[slot] = player


func _despawn_player(slot: int) -> void:
	if _players.has(slot):
		_players[slot].queue_free()
		_players.erase(slot)
