class_name GameOver
extends CanvasLayer
## Every hero ran out of lives. With a continue left the world starts over
## from its first zone (lives full again); without one the whole game starts
## over. Leaving for the title spends the continue too, so it cannot be dodged.

var _level: Level
var _menu: MenuList
var _hint: Label


func setup(level: Level) -> void:
	_level = level


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 50
	get_tree().paused = true
	add_child(Harm.box(Vector2.ZERO, Vector2(1920, 1080), Color(0.05, 0, 0.02, 0.8)))
	var title := _label("ИГРА ОКОНЧЕНА", 200, 100, Color(1.0, 0.3, 0.4))
	title.add_theme_font_override("font", MenuList.FONT)
	var left := SaveGame.continues()
	var zone_id := _level.zone_id if _level != null else ""
	var world := zone_id.get_slice("-", 0)
	var entries: Array = []
	if left > 0:
		_label("Continue осталось: %d" % left, 330, 40, Color.WHITE)
		entries.append({"text": "Continue — мир %s заново" % world, "action": _continue,
			"hint": "Жизни снова 3 у каждого, мир начинается с первой зоны"})
		entries.append({"text": "Выйти в меню", "action": _continue_later,
			"hint": "Continue всё равно тратится: «Продолжить» начнёт мир %s заново" % world})
	else:
		_label("Continue кончились — игра начинается сначала", 330, 40, Color.WHITE)
		var difficulty := GameSettings.difficulty
		SaveGame.new_game(difficulty)
		entries.append({"text": "Новая игра", "action": func() -> void: _go(SaveGame.ZONES[0]["scene"])})
		entries.append({"text": "Выйти в меню", "action": func() -> void: _go("res://scenes/title.tscn")})
	_menu = MenuList.new()
	_menu.position = Vector2(460, 460)
	_menu.size = Vector2(1000, 300)
	_menu.font_size = 44
	add_child(_menu)
	_hint = _label("", 900, 26, Color(1, 1, 1, 0.7))
	_menu.selection_changed.connect(func(_index: int) -> void: _hint.text = _menu.hint())
	_menu.set_entries(entries)
	_hint.text = _menu.hint()


func _label(text: String, y: float, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = Vector2(0, y)
	label.size = Vector2(1920, font_size * 1.4)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	add_child(label)
	return label


func _continue() -> void:
	_go(SaveGame.use_continue(_level.zone_id))


func _continue_later() -> void:
	SaveGame.use_continue(_level.zone_id)
	_go("res://scenes/title.tscn")


func _go(scene: String) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(scene)
