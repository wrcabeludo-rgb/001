class_name LevelExit
extends Area2D
## The end of a level: a glowing doorway. The first hero to step in finishes
## the level for the whole team.

signal reached

const SIZE := Vector2(90, 180)
const COLOR := Color(0.55, 1.0, 0.75)

var _glow: ColorRect
var _done := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = Layers.PLAYER_BODIES
	monitorable = false
	var shape := RectangleShape2D.new()
	shape.size = SIZE
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.position = Vector2(0, -SIZE.y / 2.0)
	add_child(collision)
	add_child(Harm.box(Vector2(-SIZE.x / 2.0 - 10, -SIZE.y - 10), SIZE + Vector2(20, 10), Color(0.25, 0.28, 0.32)))
	_glow = Harm.box(Vector2(-SIZE.x / 2.0, -SIZE.y), SIZE, COLOR)
	add_child(_glow)
	var label := Label.new()
	label.text = "ВЫХОД"
	label.position = Vector2(-60, -SIZE.y - 50)
	label.size = Vector2(120, 36)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", COLOR)
	add_child(label)
	body_entered.connect(_on_body_entered)


func _process(_delta: float) -> void:
	_glow.color.a = 0.55 + 0.25 * sin(Time.get_ticks_msec() * 0.004)


func _on_body_entered(body: Node2D) -> void:
	var hero := body as Player
	if hero != null and hero.is_alive() and not _done:
		_done = true
		reached.emit()
