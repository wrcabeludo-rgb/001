extends CanvasLayer
## F1 panel with sliders for both heroes' MovementStats.
## Changes apply live and last until the game is closed; "Скопировать"
## puts the current numbers on the clipboard so they can be sent back.

## [property, caption, min, max, step]
const PARAMS := [
	["run_speed", "Скорость бега", 100.0, 900.0, 10.0],
	["ground_accel", "Разгон на земле", 500.0, 12000.0, 100.0],
	["ground_decel", "Торможение на земле", 500.0, 12000.0, 100.0],
	["air_accel", "Разгон в воздухе", 200.0, 12000.0, 100.0],
	["air_decel", "Торможение в воздухе", 0.0, 12000.0, 100.0],
	["jump_height", "Высота прыжка", 40.0, 400.0, 5.0],
	["jump_time_to_apex", "Время до верхней точки", 0.15, 0.7, 0.01],
	["fall_gravity_multiplier", "Множитель гравитации при падении", 1.0, 3.0, 0.05],
	["max_fall_speed", "Макс. скорость падения", 300.0, 2500.0, 50.0],
	["jump_cut", "Обрезка прыжка при отпускании", 0.1, 1.0, 0.05],
	["coyote_time", "Прыжок после края (с)", 0.0, 0.3, 0.01],
	["jump_buffer", "Прыжок до приземления (с)", 0.0, 0.3, 0.01],
	["air_jumps", "Прыжков в воздухе", 0.0, 3.0, 1.0],
	["air_jump_height", "Высота прыжка в воздухе", 40.0, 400.0, 5.0],
	["wall_slide_speed", "Скорость скольжения по стене", 0.0, 800.0, 10.0],
	["wall_jump_height", "Высота прыжка от стены", 40.0, 400.0, 5.0],
	["wall_jump_speed_x", "Отталкивание от стены", 100.0, 1000.0, 10.0],
	["wall_jump_lock_time", "Блок управления после стены (с)", 0.0, 0.5, 0.01],
	["dash_speed", "Скорость рывка", 300.0, 2500.0, 25.0],
	["dash_time", "Длительность рывка (с)", 0.05, 0.5, 0.01],
	["dash_cooldown", "Перезарядка рывка (с)", 0.0, 1.5, 0.05],
]

var _defaults := {}
## Heroes.Id -> {property: [HSlider, value Label]}
var _controls := {}
var _note: Label


func _ready() -> void:
	layer = 10
	visible = false
	for hero in Heroes.MOVEMENT:
		_defaults[hero] = Heroes.MOVEMENT[hero].duplicate()
	_build()


func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.physical_keycode == KEY_F1:
		visible = not visible


func _build() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(820, 20)
	panel.size = Vector2(1080, 1040)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.08, 0.92)
	style.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var root := VBoxContainer.new()
	panel.add_child(root)

	var buttons := HBoxContainer.new()
	root.add_child(buttons)
	var title := Label.new()
	title.text = "Настройка движения (F1 — закрыть)"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(title)
	_add_button(buttons, "Скопировать значения", _copy_to_clipboard)
	_add_button(buttons, "Сбросить", _reset)

	_note = Label.new()
	_note.text = "Изменения действуют до закрытия игры. Скопируй значения и пришли их мне, чтобы сохранить."
	_note.add_theme_font_size_override("font_size", 14)
	root.add_child(_note)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 24)
	scroll.add_child(columns)

	for hero in Heroes.MOVEMENT:
		columns.add_child(_build_hero_column(hero))


func _build_hero_column(hero: Heroes.Id) -> Control:
	var stats: MovementStats = Heroes.MOVEMENT[hero]
	var column := VBoxContainer.new()
	var header := Label.new()
	header.text = Heroes.NAMES[hero]
	header.add_theme_color_override("font_color", Heroes.COLORS[hero])
	column.add_child(header)

	var grid := GridContainer.new()
	grid.columns = 3
	column.add_child(grid)
	_controls[hero] = {}

	for param in PARAMS:
		var property: String = param[0]
		var caption := Label.new()
		caption.text = param[1]
		caption.custom_minimum_size = Vector2(250, 0)
		caption.add_theme_font_size_override("font_size", 14)
		grid.add_child(caption)

		var slider := HSlider.new()
		slider.min_value = param[2]
		slider.max_value = param[3]
		slider.step = param[4]
		slider.custom_minimum_size = Vector2(180, 24)
		slider.value = stats.get(property)
		grid.add_child(slider)

		var value_label := Label.new()
		value_label.custom_minimum_size = Vector2(60, 0)
		value_label.add_theme_font_size_override("font_size", 14)
		value_label.text = _format(stats.get(property), param[4])
		grid.add_child(value_label)

		_controls[hero][property] = [slider, value_label]
		slider.value_changed.connect(_on_slider_changed.bind(hero, property, param[4]))
	return column


func _add_button(parent: Control, text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.pressed.connect(callback)
	parent.add_child(button)


func _on_slider_changed(value: float, hero: Heroes.Id, property: String, step: float) -> void:
	var stats: MovementStats = Heroes.MOVEMENT[hero]
	# Integer properties (air_jumps) must stay ints.
	stats.set(property, int(value) if typeof(stats.get(property)) == TYPE_INT else value)
	_controls[hero][property][1].text = _format(value, step)


func _reset() -> void:
	for hero in Heroes.MOVEMENT:
		var stats: MovementStats = Heroes.MOVEMENT[hero]
		for param in PARAMS:
			var property: String = param[0]
			stats.set(property, _defaults[hero].get(property))
			_controls[hero][property][0].set_value_no_signal(stats.get(property))
			_controls[hero][property][1].text = _format(stats.get(property), param[4])
	_note.text = "Значения сброшены."


func _copy_to_clipboard() -> void:
	var lines := PackedStringArray()
	for hero in Heroes.MOVEMENT:
		var stats: MovementStats = Heroes.MOVEMENT[hero]
		lines.append("[%s]" % Heroes.NAMES[hero])
		for param in PARAMS:
			lines.append("%s = %s" % [param[0], _format(stats.get(param[0]), param[4])])
	DisplayServer.clipboard_set("\n".join(lines))
	_note.text = "Значения скопированы в буфер обмена — вставь их в сообщение мне."


func _format(value: float, step: float) -> String:
	return str(int(round(value))) if step >= 1.0 else "%.2f" % value
