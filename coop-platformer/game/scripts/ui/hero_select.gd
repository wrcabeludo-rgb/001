class_name HeroSelect
extends Control
## Picking heroes before the game starts. Each player moves a marker between
## the Gunner and the Swordsman (left / right) and takes one (jump or attack);
## a hero someone has taken is closed to the other player. Skill undoes the
## choice, or goes back to the title when nothing is chosen. A second player
## joins right here (jump or Start). When every player has a hero, the game
## goes on to `next_scene`.

const BACKGROUND := preload("res://assets/art/ui/menu_bg_01.png")
const TITLE_FONT := preload("res://assets/fonts/RussoOne-Regular.ttf")
const AVATARS := {
	Heroes.Id.SHOOTER: preload("res://assets/art/ui/avatar_gunner.png"),
	Heroes.Id.SWORDSMAN: preload("res://assets/art/ui/avatar_swordsman.png"),
}
const ABOUT := {
	Heroes.Id.SHOOTER: "Винтовка с заряженным выстрелом, дробовик и пинок. Двойной прыжок. Бьёт издалека.",
	Heroes.Id.SWORDSMAN: "Серия из трёх ударов, блок и рывок. Больше здоровья. Лезет в самую гущу.",
}
const CARD_SIZE := Vector2(600, 760)
const CARD_X := {Heroes.Id.SHOOTER: 290.0, Heroes.Id.SWORDSMAN: 1030.0}
const CARD_Y := 215.0
## After the last player picks, the game waits this long before going on.
const START_DELAY := 0.8
const TITLE_SCENE := "res://scenes/title.tscn"

## Where the game goes once everyone has a hero ("" stays here: tests).
static var next_scene := "res://scenes/intro_comic.tscn"

## Every player has a hero (PlayerManager.heroes is set).
signal heroes_chosen

## For each slot: the hero under its marker, and whether it is taken.
var cursor := [Heroes.Id.SHOOTER, Heroes.Id.SWORDSMAN]
var chosen := [false, false]

var _frames := {}
var _markers: Array[Label] = []
var _status: Label
var _countdown := -1.0


func _ready() -> void:
	var background := TextureRect.new()
	background.texture = BACKGROUND
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.size = Vector2(1920, 1080)
	add_child(background)
	add_child(Harm.box(Vector2.ZERO, Vector2(1920, 1080), Color(0, 0, 0, 0.55)))

	var title := Label.new()
	title.text = "ВЫБОР ГЕРОЯ"
	title.position = Vector2(0, 28)
	title.size = Vector2(1920, 100)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", TITLE_FONT)
	title.add_theme_font_size_override("font_size", 72)
	add_child(title)

	for hero in [Heroes.Id.SHOOTER, Heroes.Id.SWORDSMAN]:
		_build_card(hero)
	for slot in PlayerManager.MAX_PLAYERS:
		var marker := Label.new()
		marker.add_theme_font_override("font", TITLE_FONT)
		marker.add_theme_font_size_override("font_size", 34)
		marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		marker.size = Vector2(220, 50)
		add_child(marker)
		_markers.append(marker)

	_status = Label.new()
	_status.position = Vector2(0, 985)
	_status.size = Vector2(1920, 80)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 26)
	_status.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	add_child(_status)

	# Each joined player starts on a different hero.
	for slot in PlayerManager.MAX_PLAYERS:
		if PlayerManager.players[slot] != null:
			cursor[slot] = PlayerManager.heroes[slot]
	PlayerManager.player_joined.connect(_on_joined)
	PlayerManager.player_left.connect(_on_left)
	_refresh()


func _build_card(hero: Heroes.Id) -> void:
	var color: Color = Heroes.COLORS[hero]
	var card := Control.new()
	card.position = Vector2(CARD_X[hero], CARD_Y)
	card.size = CARD_SIZE
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(card)
	var frame := Harm.box(Vector2(-6, -6), CARD_SIZE + Vector2(12, 12), color)
	card.add_child(frame)
	_frames[hero] = frame
	card.add_child(Harm.box(Vector2.ZERO, CARD_SIZE, Color(0.04, 0.04, 0.07, 0.9)))
	# A soft glow of the hero's colour behind the figure.
	var gradient := Gradient.new()
	gradient.set_color(0, Color(color, 0.32))
	gradient.set_color(1, Color(color, 0.0))
	var glow_texture := GradientTexture2D.new()
	glow_texture.gradient = gradient
	glow_texture.fill = GradientTexture2D.FILL_RADIAL
	glow_texture.fill_from = Vector2(0.5, 0.5)
	glow_texture.fill_to = Vector2(0.5, 0.0)
	var glow := TextureRect.new()
	glow.texture = glow_texture
	glow.position = Vector2(20, 60)
	glow.size = Vector2(CARD_SIZE.x - 40, 520)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(glow)
	var avatar := TextureRect.new()
	avatar.texture = AVATARS[hero]
	avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	avatar.position = Vector2(20, 20)
	avatar.size = Vector2(CARD_SIZE.x - 40, 560)
	card.add_child(avatar)
	var name_label := Label.new()
	name_label.text = Heroes.NAMES[hero].to_upper()
	name_label.position = Vector2(0, 590)
	name_label.size = Vector2(CARD_SIZE.x, 70)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_override("font", TITLE_FONT)
	name_label.add_theme_font_size_override("font_size", 52)
	name_label.add_theme_color_override("font_color", color)
	card.add_child(name_label)
	var about := Label.new()
	about.text = ABOUT[hero]
	about.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	about.position = Vector2(30, 664)
	about.size = Vector2(CARD_SIZE.x - 60, 90)
	about.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	about.add_theme_font_size_override("font_size", 22)
	about.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	card.add_child(about)


func _physics_process(delta: float) -> void:
	for slot in PlayerManager.MAX_PLAYERS:
		if PlayerManager.players[slot] != null:
			_control(slot, PlayerManager.players[slot])
	for device in PlayerManager.all_devices():
		if PlayerManager.players.has(device):
			continue
		# Attack joins too (jump and Start are handled by PlayerManager);
		# with nobody in the game yet, skill goes back to the title.
		if device.just_pressed("attack"):
			PlayerManager.join(device)
		elif device.just_pressed("skill") and not PlayerManager.players.any(func(p: Variant) -> bool: return p != null):
			get_tree().change_scene_to_file(TITLE_SCENE)
			return
	if _countdown >= 0.0:
		_countdown -= delta
		if _countdown < 0.0:
			_start()


func _control(slot: int, device: PlayerInput) -> void:
	if device.just_pressed("skill"):
		if chosen[slot]:
			chosen[slot] = false
			Sound.play("menu_move")
		elif slot == 0:
			Sound.play("menu_select")
			get_tree().change_scene_to_file(TITLE_SCENE)
			return
		_refresh()
		return
	if chosen[slot]:
		return
	if device.just_pressed("left") or device.just_pressed("right"):
		cursor[slot] = Heroes.other(cursor[slot])
		Sound.play("menu_move")
		_refresh()
	elif device.just_pressed("jump") or device.just_pressed("attack"):
		if _taken_by_other(slot, cursor[slot]):
			Sound.play("telegraph")
			return
		chosen[slot] = true
		Sound.play("menu_select")
		_refresh()


func _taken_by_other(slot: int, hero: Heroes.Id) -> bool:
	for other in PlayerManager.MAX_PLAYERS:
		if other != slot and PlayerManager.players[other] != null and chosen[other] and cursor[other] == hero:
			return true
	return false


func _on_joined(slot: int) -> void:
	chosen[slot] = false
	# A newcomer starts on the hero that is still free.
	cursor[slot] = Heroes.other(cursor[1 - slot]) if PlayerManager.players[1 - slot] != null else Heroes.Id.SHOOTER
	_refresh()


func _on_left(slot: int) -> void:
	chosen[slot] = false
	_refresh()


func _refresh() -> void:
	var joined := 0
	var picked := 0
	var lines := PackedStringArray()
	for slot in PlayerManager.MAX_PLAYERS:
		var marker := _markers[slot]
		var playing := PlayerManager.players[slot] != null
		marker.visible = playing
		if not playing:
			lines.append("Игрок %d: нажмите прыжок или Start, чтобы присоединиться" % (slot + 1))
			continue
		joined += 1
		var hero: Heroes.Id = cursor[slot]
		var both_here: bool = PlayerManager.players[1 - slot] != null and cursor[1 - slot] == hero
		marker.text = ("ИГРОК %d ✓" if chosen[slot] else "▼ ИГРОК %d ▼") % (slot + 1)
		marker.add_theme_color_override("font_color", Heroes.COLORS[hero] if chosen[slot] else Color.WHITE)
		marker.position = Vector2(CARD_X[hero] + CARD_SIZE.x / 2.0 - 110.0 + (slot * 2 - 1) * (130.0 if both_here else 0.0),
			CARD_Y - 58.0)
		if chosen[slot]:
			picked += 1
			lines.append("Игрок %d: %s — готов (навык — передумать)" % [slot + 1, Heroes.NAMES[hero]])
		elif _taken_by_other(slot, hero):
			lines.append("Игрок %d: %s уже занят — выберите другого героя" % [slot + 1, Heroes.NAMES[hero]])
		else:
			lines.append("Игрок %d: влево / вправо — выбор, прыжок — взять" % (slot + 1))
	for hero in _frames:
		var taken := false
		for slot in PlayerManager.MAX_PLAYERS:
			taken = taken or (PlayerManager.players[slot] != null and chosen[slot] and cursor[slot] == hero)
		_frames[hero].visible = taken or _hovered(hero)
		_frames[hero].modulate.a = 1.0 if taken else 0.35
	_status.text = "\n".join(lines)
	_countdown = START_DELAY if joined > 0 and picked == joined else -1.0


func _hovered(hero: Heroes.Id) -> bool:
	for slot in PlayerManager.MAX_PLAYERS:
		if PlayerManager.players[slot] != null and cursor[slot] == hero:
			return true
	return false


func _start() -> void:
	for slot in PlayerManager.MAX_PLAYERS:
		if PlayerManager.players[slot] != null:
			PlayerManager.heroes[slot] = cursor[slot]
	heroes_chosen.emit()
	if next_scene != "":
		get_tree().change_scene_to_file(next_scene)
