extends Control
## Title screen. Main page: continue, new game, zone select, shop, settings,
## test levels, credits, quit. New game asks for the difficulty. Every way into
## the game passes the hero select screen (then the intro comic for a new game).
## Pressing a button on a device also joins it as a player (PlayerManager).

const BACKGROUND := preload("res://assets/art/ui/menu_bg_01.png")
const TITLE_FONT := preload("res://assets/fonts/RussoOne-Regular.ttf")

const COMIC_SCENE := "res://scenes/intro_comic.tscn"
const SHOP_SCENE := "res://scenes/shop.tscn"
const TEST_SCENE := "res://scenes/test_room.tscn"
const HERO_SELECT_SCENE := "res://scenes/hero_select.tscn"

var _menu: MenuList
var _hint: Label
var _credits: Label
var _on_back := Callable()


func _ready() -> void:
	var background := TextureRect.new()
	background.texture = BACKGROUND
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.size = Vector2(1920, 1080)
	add_child(background)
	add_child(Harm.box(Vector2.ZERO, Vector2(1920, 1080), Color(0, 0, 0, 0.35)))

	var title := TitleLogo.new()
	title.position = Vector2(0, 110)
	add_child(title)

	_credits = Label.new()
	_credits.text = Credits.text()
	_credits.position = Vector2(260, 290)
	_credits.size = Vector2(1400, 560)
	_credits.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_credits.add_theme_font_size_override("font_size", 26)
	_credits.visible = false
	add_child(_credits)

	_menu = MenuList.new()
	_menu.position = Vector2(560, 380)
	_menu.size = Vector2(800, 500)
	_menu.font_size = 46
	add_child(_menu)
	_menu.back.connect(func() -> void:
		if _on_back.is_valid():
			_on_back.call())

	_hint = Label.new()
	_hint.position = Vector2(0, 930)
	_hint.size = Vector2(1920, 40)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", 26)
	_hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	add_child(_hint)
	_menu.selection_changed.connect(func(_index: int) -> void: _hint.text = _menu.hint())

	var help := Label.new()
	help.text = "Вверх / вниз — выбор, прыжок или атака — подтвердить, навык — назад. Второй игрок подключается кнопкой Start прямо в игре"
	help.position = Vector2(0, 1010)
	help.size = Vector2(1920, 30)
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help.add_theme_font_size_override("font_size", 20)
	help.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	add_child(help)

	show_main()
	Sound.music("menu")


func show_main() -> void:
	var progress := SaveGame.has_progress()
	var entries: Array = []
	if progress:
		var next: Dictionary = SaveGame.ZONES[int(SaveGame.data["next_zone"])]
		entries.append({"text": "Продолжить", "action": func() -> void: _choose_heroes(next["scene"]),
			"hint": "%s · сложность: %s" % [next["title"], GameSettings.NAMES[GameSettings.difficulty]]})
	entries.append({"text": "Новая игра", "action": show_difficulty,
		"hint": "Прогресс и покупки будут сброшены" if progress else ""})
	if progress:
		entries.append({"text": "Выбор зоны", "action": show_zones})
		entries.append({"text": "Магазин", "action": func() -> void: _open(SHOP_SCENE),
			"hint": "Потратить лом на оружие и улучшения"})
	entries.append({"text": "Настройки", "action": show_settings})
	entries.append({"text": "Тестовые уровни", "action": func() -> void: _open(TEST_SCENE),
		"hint": "Тестовая комната, «Полигон» и «Мастерская» (F2 — следующая)"})
	entries.append({"text": "Авторы", "action": show_credits, "hint": "Музыка, звуки, шрифты"})
	entries.append({"text": "Выход", "action": func() -> void: get_tree().quit()})
	_on_back = Callable()
	_show_page(entries)


## The credits text with one "Назад" under it.
func show_credits() -> void:
	_on_back = show_main
	_credits.visible = true
	_menu.position.y = 830
	_menu.size.y = 120
	_menu.set_entries([{"text": "Назад", "action": show_main}])


## Any page but the credits: the menu back in its place.
func _show_page(entries: Array, select := 0) -> void:
	_credits.visible = false
	_menu.position.y = 380
	_menu.size.y = 500
	_menu.set_entries(entries, select)


func show_difficulty() -> void:
	var entries: Array = []
	for difficulty in [GameSettings.Difficulty.EASY, GameSettings.Difficulty.NORMAL, GameSettings.Difficulty.HARD]:
		entries.append({"text": GameSettings.NAMES[difficulty], "hint": GameSettings.HINTS[difficulty],
			"action": func() -> void:
				SaveGame.new_game(difficulty)
				_choose_heroes(COMIC_SCENE)})
	entries.append({"text": "Назад", "action": show_main})
	_on_back = show_main
	_show_page(entries, 1)


func show_zones() -> void:
	var entries: Array = []
	var unlocked := int(SaveGame.data["unlocked"])
	for i in SaveGame.ZONES.size():
		var zone: Dictionary = SaveGame.ZONES[i]
		var open := i < unlocked
		var best: float = SaveGame.data["best_times"].get(zone["id"], -1.0)
		entries.append({
			"text": zone["title"] if open else "%s — закрыто" % zone["id"],
			"enabled": open,
			"hint": ("Лучшее время: %d:%02d" % [int(best) / 60, int(best) % 60]) if best >= 0.0 else "",
			"action": func() -> void: _choose_heroes(zone["scene"]),
		})
	entries.append({"text": "Назад", "action": show_main})
	_on_back = show_main
	_show_page(entries)


func show_settings() -> void:
	_on_back = show_main
	_show_page(SettingsEntries.build(show_main))


## The hero select screen first, then `scene`.
func _choose_heroes(scene: String) -> void:
	HeroSelect.next_scene = scene
	_open(HERO_SELECT_SCENE)


func _open(scene: String) -> void:
	get_tree().change_scene_to_file(scene)
