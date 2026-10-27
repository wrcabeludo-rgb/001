extends Control
## After the ending comic: the results of the run and the credits roll up the
## screen over the ending music, then a hint about the other choice at the
## Heart. Jump, attack or Start skips the roll; once it is over, the title.

const SCROLL_SPEED := 70.0
const ENDING_NAMES := {"off": "«Неон погас»", "keep": "«Город сияет»"}
const OTHER_ENDING := {
	"off": "А если бы «Сердце» осталось гореть?",
	"keep": "А если бы «Сердце» погасло?",
}

var _roll: Label
var _hint: Label
var _finished := false
var _opened_at := 0


func _ready() -> void:
	_opened_at = Time.get_ticks_msec()
	Sound.music("ending")
	add_child(Harm.box(Vector2.ZERO, Vector2(1920, 1080), Color(0.02, 0.02, 0.04)))
	_roll = Label.new()
	_roll.text = roll_text()
	_roll.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_roll.position = Vector2(160, 1080)
	_roll.size = Vector2(1600, 0)
	_roll.add_theme_font_size_override("font_size", 30)
	_roll.add_theme_constant_override("line_spacing", 6)
	add_child(_roll)
	_hint = Label.new()
	_hint.text = "%s\nВыбор зоны → 3-3: у «Сердца» можно решить иначе.\n\nПрыжок или атака — в главное меню" % \
		OTHER_ENDING.get(SaveGame.data.get("ending", "off"), OTHER_ENDING["off"])
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hint.size = Vector2(1920, 1080)
	_hint.add_theme_font_override("font", MenuList.FONT)
	_hint.add_theme_font_size_override("font_size", 40)
	_hint.add_theme_color_override("font_color", Color(1.0, 0.45, 0.75))
	_hint.modulate.a = 0.0
	add_child(_hint)


## The results of this run (also shown by tests).
static func results_lines() -> PackedStringArray:
	var data := SaveGame.data
	var seconds := int(float(data["stats"]["time"]))
	var lines := PackedStringArray()
	lines.append("Концовка: %s" % ENDING_NAMES.get(data.get("ending", "off"), ENDING_NAMES["off"]))
	lines.append("Сложность: %s" % GameSettings.NAMES[GameSettings.difficulty])
	lines.append("Время в пути: %d:%02d:%02d" % [seconds / 3600, seconds / 60 % 60, seconds % 60])
	lines.append("Падений героев: %d" % int(data["stats"]["deaths"]))
	var secrets_total := SaveGame.secrets_total()
	if secrets_total > 0:
		lines.append("Тайники: %d из %d" % [data["secrets"].size(), secrets_total])
	lines.append("Найдено жизней: %d из %d" % [data["lives_found"].size(), SaveGame.lives_total()])
	lines.append("Continue потрачено: %d из %d" % [SaveGame.START_CONTINUES - SaveGame.continues(),
		SaveGame.START_CONTINUES])
	return lines


static func roll_text() -> String:
	var lines := PackedStringArray(["НЕОН И ПЕПЕЛ", "", "", "ИТОГИ", ""])
	lines.append_array(results_lines())
	lines.append_array(["", "", "", Credits.text(), "", "", "", "Спасибо, что прошли «Неон и пепел»!"])
	return "\n".join(lines)


func _process(delta: float) -> void:
	if not _finished:
		_roll.position.y -= SCROLL_SPEED * delta
		if _roll.position.y + _roll.get_minimum_size().y < 0.0:
			_finish()
	elif _hint.modulate.a < 1.0:
		_hint.modulate.a = minf(1.0, _hint.modulate.a + delta)
	# The button that closed the comic must not skip the roll at once.
	if Time.get_ticks_msec() - _opened_at < 800:
		return
	for device in PlayerManager.all_devices():
		if device.just_pressed("jump") or device.just_pressed("attack") or device.just_pressed("start"):
			if _finished:
				get_tree().change_scene_to_file("res://scenes/title.tscn")
			else:
				_finish()
			return


func _finish() -> void:
	_finished = true
	_roll.visible = false
