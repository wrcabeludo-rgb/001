class_name GamepadCheck
extends Control
## Shows every gamepad the game sees, live: its number, name and id, which
## player it belongs to, the buttons held right now and the stick positions.
## For sorting out controllers that do not respond. Esc, or holding the skill
## button (Circle / B) on any device for a second, goes back to the title.

const TITLE_FONT := preload("res://assets/fonts/RussoOne-Regular.ttf")
const TITLE_SCENE := "res://scenes/title.tscn"
const BUTTON_NAMES := {
	JOY_BUTTON_A: "Крест/A", JOY_BUTTON_B: "Круг/B", JOY_BUTTON_X: "Квадрат/X", JOY_BUTTON_Y: "Треугольник/Y",
	JOY_BUTTON_BACK: "Share", JOY_BUTTON_GUIDE: "PS", JOY_BUTTON_START: "Options",
	JOY_BUTTON_LEFT_STICK: "L3", JOY_BUTTON_RIGHT_STICK: "R3", JOY_BUTTON_LEFT_SHOULDER: "L1",
	JOY_BUTTON_RIGHT_SHOULDER: "R1", JOY_BUTTON_DPAD_UP: "↑", JOY_BUTTON_DPAD_DOWN: "↓",
	JOY_BUTTON_DPAD_LEFT: "←", JOY_BUTTON_DPAD_RIGHT: "→", JOY_BUTTON_TOUCHPAD: "Тачпад",
}
const BACK_HOLD := 1.0

var _text: Label
var _back_timer := 0.0


func _ready() -> void:
	add_child(Harm.box(Vector2.ZERO, Vector2(1920, 1080), Color(0.05, 0.05, 0.08)))
	var title := Label.new()
	title.text = "ПРОВЕРКА ГЕЙМПАДОВ"
	title.position = Vector2(0, 40)
	title.size = Vector2(1920, 90)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", TITLE_FONT)
	title.add_theme_font_size_override("font_size", 64)
	add_child(title)
	_text = Label.new()
	_text.position = Vector2(120, 160)
	_text.size = Vector2(1680, 820)
	_text.add_theme_font_size_override("font_size", 28)
	add_child(_text)
	var help := Label.new()
	help.text = "Нажимайте кнопки на каждом геймпаде. Назад — Esc или держать Круг/B секунду"
	help.position = Vector2(0, 1000)
	help.size = Vector2(1920, 40)
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help.add_theme_font_size_override("font_size", 24)
	help.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	add_child(help)


func _process(delta: float) -> void:
	var lines := PackedStringArray()
	var pads := Input.get_connected_joypads()
	lines.append("Windows сообщает о геймпадах: %d" % pads.size())
	lines.append("")
	var holding_back := false
	for device_id in pads:
		var owner := "не в игре (нажмите Крест/A или Options, чтобы присоединиться)"
		for slot in PlayerManager.MAX_PLAYERS:
			var device: PlayerInput = PlayerManager.players[slot]
			if device != null and device.kind == PlayerInput.Kind.GAMEPAD and device.device_id == device_id:
				owner = "Игрок %d (%s)" % [slot + 1, Heroes.NAMES[PlayerManager.heroes[slot]]]
		var held := PackedStringArray()
		for button in range(0, 21):
			if Input.is_joy_button_pressed(device_id, button):
				held.append(BUTTON_NAMES.get(button, "кнопка %d" % button))
		if Input.is_joy_button_pressed(device_id, JOY_BUTTON_B):
			holding_back = true
		lines.append("Геймпад №%d — %s" % [device_id + 1, Input.get_joy_name(device_id)])
		lines.append("    id: %s" % Input.get_joy_guid(device_id))
		lines.append("    кто играет: %s" % owner)
		lines.append("    нажато: %s" % (", ".join(held) if not held.is_empty() else "—"))
		lines.append("    левый стик: %+.2f %+.2f   правый: %+.2f %+.2f" % [
			Input.get_joy_axis(device_id, JOY_AXIS_LEFT_X), Input.get_joy_axis(device_id, JOY_AXIS_LEFT_Y),
			Input.get_joy_axis(device_id, JOY_AXIS_RIGHT_X), Input.get_joy_axis(device_id, JOY_AXIS_RIGHT_Y)])
		lines.append("")
	if pads.is_empty():
		lines.append("Ни одного геймпада не видно.")
	_text.text = "\n".join(lines)
	_back_timer = _back_timer + delta if holding_back else 0.0
	if Input.is_physical_key_pressed(KEY_ESCAPE) or _back_timer >= BACK_HOLD:
		get_tree().change_scene_to_file(TITLE_SCENE)
