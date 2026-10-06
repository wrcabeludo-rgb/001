extends Control
## Title screen: play (difficulty choice → intro comic → level 1), the test
## levels, or quit. Works with any keyboard half, any gamepad and the mouse:
## up / down to choose, jump or attack to confirm, skill to go back.
## Pressing a button on a device also joins it as a player (PlayerManager).

const BACKGROUND := preload("res://assets/art/ui/menu_bg_01.png")
const TITLE_FONT := preload("res://assets/fonts/RussoOne-Regular.ttf")
const SELECTED_COLOR := Color(0.35, 0.95, 1.0)
const NORMAL_COLOR := Color(0.85, 0.85, 0.9)

const COMIC_SCENE := "res://scenes/intro_comic.tscn"
const TEST_SCENE := "res://scenes/test_room.tscn"

enum Page { MAIN, DIFFICULTY }

var page := Page.MAIN
var selected := 0

var _items: VBoxContainer
var _hint: Label
var _entries: Array = []


func _ready() -> void:
	var background := TextureRect.new()
	background.texture = BACKGROUND
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.size = Vector2(1920, 1080)
	add_child(background)
	add_child(Harm.box(Vector2.ZERO, Vector2(1920, 1080), Color(0, 0, 0, 0.35)))

	var title := Label.new()
	title.text = "НЕОН И ПЕПЕЛ"
	title.position = Vector2(0, 150)
	title.size = Vector2(1920, 180)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", TITLE_FONT)
	title.add_theme_font_size_override("font_size", 140)
	title.add_theme_color_override("font_color", Color(1.0, 0.95, 0.9))
	title.add_theme_color_override("font_outline_color", Color(1.0, 0.35, 0.55))
	title.add_theme_constant_override("outline_size", 10)
	add_child(title)

	_items = VBoxContainer.new()
	_items.position = Vector2(660, 480)
	_items.size = Vector2(600, 400)
	_items.add_theme_constant_override("separation", 14)
	add_child(_items)

	_hint = Label.new()
	_hint.position = Vector2(0, 900)
	_hint.size = Vector2(1920, 40)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", 26)
	_hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	add_child(_hint)

	var help := Label.new()
	help.text = "Вверх / вниз — выбор, прыжок или атака — подтвердить, навык — назад. Второй игрок подключается кнопкой Start прямо в игре"
	help.position = Vector2(0, 1010)
	help.size = Vector2(1920, 30)
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help.add_theme_font_size_override("font_size", 20)
	help.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	add_child(help)

	_show_page(Page.MAIN)
	Sound.music("menu")


## Menu entries of the current page: [text, Callable].
func _page_entries(which: Page) -> Array:
	if which == Page.MAIN:
		return [
			["Играть", func() -> void: _show_page(Page.DIFFICULTY)],
			["Тестовые уровни", func() -> void: get_tree().change_scene_to_file(TEST_SCENE)],
			["Выход", func() -> void: get_tree().quit()],
		]
	var entries: Array = []
	for difficulty in [GameSettings.Difficulty.EASY, GameSettings.Difficulty.NORMAL, GameSettings.Difficulty.HARD]:
		entries.append([GameSettings.NAMES[difficulty], _start_game.bind(difficulty)])
	entries.append(["Назад", func() -> void: _show_page(Page.MAIN)])
	return entries


func _show_page(which: Page) -> void:
	page = which
	for child in _items.get_children():
		_items.remove_child(child)
		child.queue_free()
	_entries = _page_entries(which)
	for i in _entries.size():
		var label := Label.new()
		label.text = _entries[i][0]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_override("font", TITLE_FONT)
		label.add_theme_font_size_override("font_size", 52)
		label.mouse_filter = Control.MOUSE_FILTER_STOP
		label.mouse_entered.connect(_select.bind(i))
		label.gui_input.connect(_on_item_input.bind(i))
		_items.add_child(label)
	_select(1 if which == Page.DIFFICULTY else 0)


func _select(index: int) -> void:
	selected = wrapi(index, 0, _entries.size())
	for i in _items.get_child_count():
		var label := _items.get_child(i) as Label
		var is_selected := i == selected
		label.text = ("▶  %s  ◀" if is_selected else "%s") % _entries[i][0]
		label.add_theme_color_override("font_color", SELECTED_COLOR if is_selected else NORMAL_COLOR)
	_hint.text = ""
	if page == Page.DIFFICULTY and selected < 3:
		_hint.text = GameSettings.HINTS[selected]


func _activate() -> void:
	_entries[selected][1].call()


func _start_game(difficulty: GameSettings.Difficulty) -> void:
	GameSettings.difficulty = difficulty
	get_tree().change_scene_to_file(COMIC_SCENE)


func _on_item_input(event: InputEvent, index: int) -> void:
	var click := event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		_select(index)
		Sound.play("menu_select", 0.0)
		_activate()


func _physics_process(_delta: float) -> void:
	var move := 0
	var confirm := Input.is_action_just_pressed("ui_accept")
	var back := false
	for device in PlayerManager.all_devices():
		if device.just_pressed("up"):
			move = -1
		elif device.just_pressed("down"):
			move = 1
		confirm = confirm or device.just_pressed("jump") or device.just_pressed("attack")
		back = back or device.just_pressed("skill")
	if move != 0:
		_select(selected + move)
		Sound.play("menu_move", 0.0)
	elif confirm:
		Sound.play("menu_select", 0.0)
		_activate()
	elif back and page == Page.DIFFICULTY:
		_show_page(Page.MAIN)
