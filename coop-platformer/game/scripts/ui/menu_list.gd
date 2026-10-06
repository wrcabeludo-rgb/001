class_name MenuList
extends VBoxContainer
## A vertical menu driven by any keyboard half, any gamepad or the mouse:
## up / down choose, jump or attack confirm, left / right change a value,
## skill (or Esc on the mouse side) goes back. Works while the game is paused.
## Each entry: {"text": String or Callable returning String,
##   "action": Callable (optional), "adjust": Callable(direction: int) (optional),
##   "enabled": bool (optional, default true), "hint": String (optional)}

signal back
signal selection_changed(index: int)

const SELECTED_COLOR := Color(0.35, 0.95, 1.0)
const NORMAL_COLOR := Color(0.85, 0.85, 0.9)
const DISABLED_COLOR := Color(0.45, 0.45, 0.5)
const FONT := preload("res://assets/fonts/RussoOne-Regular.ttf")

var font_size := 48
var selected := 0
## Devices that may use this menu; empty means every device.
var devices: Array = []

var _entries: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	alignment = BoxContainer.ALIGNMENT_BEGIN
	add_theme_constant_override("separation", 10)


func set_entries(entries: Array, select := 0) -> void:
	_entries = entries
	for child in get_children():
		remove_child(child)
		child.queue_free()
	for i in _entries.size():
		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_override("font", FONT)
		label.add_theme_font_size_override("font_size", font_size)
		label.mouse_filter = Control.MOUSE_FILTER_STOP
		label.mouse_entered.connect(_on_hover.bind(i))
		label.gui_input.connect(_on_item_input.bind(i))
		add_child(label)
	selected = -1
	_select(select, false)


func entry(index: int) -> Dictionary:
	return _entries[index]


## Redraws texts (after a value changed).
func refresh() -> void:
	for i in get_child_count():
		var label := get_child(i) as Label
		var text := _text(i)
		var enabled := _enabled(i)
		label.text = ("▶  %s  ◀" if i == selected else "%s") % text
		var color := SELECTED_COLOR if i == selected else NORMAL_COLOR
		label.add_theme_color_override("font_color", color if enabled else DISABLED_COLOR)


func hint() -> String:
	if selected < 0 or selected >= _entries.size():
		return ""
	return _entries[selected].get("hint", "")


func _text(i: int) -> String:
	var text: Variant = _entries[i]["text"]
	return text.call() if text is Callable else str(text)


func _enabled(i: int) -> bool:
	return _entries[i].get("enabled", true)


func _select(index: int, play_sound := true) -> void:
	if _entries.is_empty():
		return
	var new_index := wrapi(index, 0, _entries.size())
	if new_index != selected and play_sound:
		Sound.play("menu_move", 0.0)
	selected = new_index
	refresh()
	selection_changed.emit(selected)


func _activate() -> void:
	if not _enabled(selected) or not _entries[selected].has("action"):
		return
	Sound.play("menu_select", 0.0)
	var entries := _entries
	entries[selected]["action"].call()
	# The action may have replaced the page; only redraw if it did not.
	if entries == _entries and is_inside_tree():
		refresh()


func _adjust(direction: int) -> void:
	if not _enabled(selected) or not _entries[selected].has("adjust"):
		return
	Sound.play("menu_move", 0.0)
	_entries[selected]["adjust"].call(direction)
	refresh()


func _physics_process(_delta: float) -> void:
	if not is_visible_in_tree() or _entries.is_empty():
		return
	var move := 0
	var side := 0
	var confirm := false
	var cancel := false
	var sources: Array = devices if not devices.is_empty() else PlayerManager.all_devices()
	for device in sources:
		if device == null:
			continue
		if device.just_pressed("up"):
			move = -1
		elif device.just_pressed("down"):
			move = 1
		if device.just_pressed("left"):
			side = -1
		elif device.just_pressed("right"):
			side = 1
		confirm = confirm or device.just_pressed("jump") or device.just_pressed("attack")
		cancel = cancel or device.just_pressed("skill")
	if devices.is_empty():
		confirm = confirm or Input.is_action_just_pressed("ui_accept")
	if move != 0:
		_select(selected + move)
	elif side != 0:
		_adjust(side)
	elif confirm:
		_activate()
	elif cancel:
		back.emit()


func _on_hover(index: int) -> void:
	if index != selected:
		_select(index)


func _on_item_input(event: InputEvent, index: int) -> void:
	var click := event as InputEventMouseButton
	if click == null or not click.pressed:
		return
	if click.button_index == MOUSE_BUTTON_LEFT:
		_select(index, false)
		if _entries[index].has("adjust") and not _entries[index].has("action"):
			_adjust(1)
		else:
			_activate()
	elif click.button_index == MOUSE_BUTTON_RIGHT and _entries[index].has("adjust"):
		_select(index, false)
		_adjust(-1)
