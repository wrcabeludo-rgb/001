class_name PauseMenu
extends CanvasLayer
## Start during a level: the game stops and this menu opens — continue,
## settings, let the player who paused leave, or return to the title screen.

signal closed

var slot := 0

var _menu: MenuList
var _hint: Label
var _level: Level
var _opened_frame := 0
var _back_action := Callable()


func setup(level: Level, p_slot: int) -> void:
	_level = level
	slot = p_slot


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 50
	add_child(Harm.box(Vector2.ZERO, Vector2(1920, 1080), Color(0, 0, 0, 0.65)))
	var title := Label.new()
	title.text = "ПАУЗА"
	title.position = Vector2(0, 200)
	title.size = Vector2(1920, 100)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", MenuList.FONT)
	title.add_theme_font_size_override("font_size", 90)
	add_child(title)
	_menu = MenuList.new()
	_menu.position = Vector2(560, 360)
	_menu.size = Vector2(800, 500)
	_menu.font_size = 44
	add_child(_menu)
	_hint = Label.new()
	_hint.position = Vector2(0, 900)
	_hint.size = Vector2(1920, 40)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", 26)
	_hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	add_child(_hint)
	_menu.selection_changed.connect(func(_index: int) -> void: _hint.text = _menu.hint())
	_menu.back.connect(func() -> void: _back_action.call())
	_show_main()
	_opened_frame = Engine.get_physics_frames()


func _show_main() -> void:
	_back_action = close
	_menu.set_entries([
		{"text": "Продолжить", "action": close},
		{"text": "Настройки", "action": _show_settings},
		{"text": "Отключить игрока %d" % (slot + 1), "action": _leave,
			"hint": "Игрок %d выходит; подключиться снова — прыжок или Start" % (slot + 1)},
		{"text": "Выйти в меню", "action": _quit_to_title,
			"hint": "Лом, собранный в этой зоне, не сохранится"},
	])


func _show_settings() -> void:
	_back_action = _show_main
	_menu.set_entries(SettingsEntries.build(_show_main))


func _physics_process(_delta: float) -> void:
	# Start again closes the menu (not in the frame that opened it).
	if Engine.get_physics_frames() == _opened_frame:
		return
	for device in PlayerManager.all_devices():
		if device.just_pressed("start"):
			close()
			return


func close() -> void:
	get_tree().paused = false
	closed.emit()
	queue_free()


func _leave() -> void:
	close()
	PlayerManager.remove_player(slot)


func _quit_to_title() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/title.tscn")
