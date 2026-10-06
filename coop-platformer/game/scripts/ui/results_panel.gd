class_name ResultsPanel
extends Control
## "Level complete": time, difficulty and what each hero achieved. After a
## short pause, jump / attack / Start on any device (or Enter) continues.

signal closed

const WAIT_BEFORE_INPUT := 1.0

var _time := 0.0


## `lines` are shown under the title, one per line.
func setup(title: String, lines: PackedStringArray) -> void:
	size = Vector2(1920, 1080)
	add_child(Harm.box(Vector2.ZERO, Vector2(1920, 1080), Color(0, 0, 0, 0.75)))
	var heading := Label.new()
	heading.text = title
	heading.position = Vector2(0, 260)
	heading.size = Vector2(1920, 100)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_override("font", preload("res://assets/fonts/RussoOne-Regular.ttf"))
	heading.add_theme_font_size_override("font_size", 84)
	heading.add_theme_color_override("font_color", Color(0.55, 1.0, 0.75))
	add_child(heading)
	var body := Label.new()
	body.text = "\n".join(lines)
	body.position = Vector2(0, 420)
	body.size = Vector2(1920, 400)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_theme_font_size_override("font_size", 36)
	add_child(body)
	var hint := Label.new()
	hint.name = "Hint"
	hint.text = "Прыжок или Start — продолжить"
	hint.position = Vector2(0, 880)
	hint.size = Vector2(1920, 50)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 26)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	add_child(hint)


func _physics_process(delta: float) -> void:
	_time += delta
	get_node("Hint").visible = _time >= WAIT_BEFORE_INPUT
	if _time < WAIT_BEFORE_INPUT:
		return
	var pressed := Input.is_action_just_pressed("ui_accept")
	for device in PlayerManager.all_devices():
		for action in ["jump", "attack", "start"]:
			pressed = pressed or device.just_pressed(action)
	if pressed:
		set_process(false)
		closed.emit()
