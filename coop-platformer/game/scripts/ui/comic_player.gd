extends Control
## Plays a comic: full-screen panels with fades and a caption at the bottom.
## A panel can ask for a screen shake ("shake": true) — used for the explosion.
## Jump / attack on any device shows the next panel, Start skips the whole comic.

signal finished

const FADE_TIME := 0.6
const HOLD_TIME := 5.0
const SHAKE_STRENGTH := 18.0
const SHAKE_TIME := 1.6
## Shaking panels are drawn slightly larger so the edges never show.
const SHAKE_OVERSCAN := 1.04

## Each entry: {"image": Texture2D, "caption": String, "shake": bool (optional)}
var panels: Array = []
## Scene to open when the comic ends; empty means only emit `finished`.
var next_scene := ""

var _index := -1
var _time := 0.0
var _image: TextureRect
var _caption: Label
var _fade: ColorRect


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var backdrop := ColorRect.new()
	backdrop.color = Color.BLACK
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	_image = TextureRect.new()
	_image.set_anchors_preset(Control.PRESET_FULL_RECT)
	_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(_image)

	var band := ColorRect.new()
	band.color = Color(0, 0, 0, 0.6)
	band.position = Vector2(0, 900)
	band.size = Vector2(1920, 180)
	add_child(band)

	_caption = Label.new()
	_caption.position = Vector2(160, 915)
	_caption.size = Vector2(1600, 150)
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.add_theme_font_size_override("font_size", 42)
	add_child(_caption)

	var hint := Label.new()
	hint.text = "Прыжок — дальше   ·   Start — пропустить"
	hint.position = Vector2(1400, 30)
	hint.size = Vector2(480, 30)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.add_theme_font_size_override("font_size", 20)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	add_child(hint)

	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)

	_show_next()


func _physics_process(_delta: float) -> void:
	for device in PlayerManager.all_devices():
		if device.just_pressed("start"):
			_finish()
			return
		if device.just_pressed("jump") or device.just_pressed("attack"):
			# Skip straight to the fade-out of the current panel.
			_time = maxf(_time, FADE_TIME + HOLD_TIME)


func _process(delta: float) -> void:
	if _index >= panels.size():
		return
	_time += delta
	var total := FADE_TIME * 2.0 + HOLD_TIME
	if _time >= total:
		_show_next()
		return

	var alpha := 0.0
	if _time < FADE_TIME:
		alpha = 1.0 - _time / FADE_TIME
	elif _time > FADE_TIME + HOLD_TIME:
		alpha = (_time - FADE_TIME - HOLD_TIME) / FADE_TIME
	_fade.color.a = alpha

	_image.position = Vector2.ZERO
	if panels[_index].get("shake", false) and _time < SHAKE_TIME:
		var strength := SHAKE_STRENGTH * pow(1.0 - _time / SHAKE_TIME, 2.0)
		_image.position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * strength


func _show_next() -> void:
	_index += 1
	_time = 0.0
	if _index >= panels.size():
		_finish()
		return
	_image.texture = panels[_index]["image"]
	_image.pivot_offset = _image.size / 2.0
	_image.scale = Vector2.ONE * (SHAKE_OVERSCAN if panels[_index].get("shake", false) else 1.0)
	_caption.text = panels[_index]["caption"]
	_fade.color.a = 1.0


func _finish() -> void:
	_index = panels.size()
	set_physics_process(false)
	finished.emit()
	if next_scene != "":
		get_tree().change_scene_to_file(next_scene)
