class_name Door
extends StaticBody2D
## A heavy door from a tile down to the floor. Closed it works as a wall;
## open it slides up out of the way. Used behind levers and as arena gates.

const COLOR := Color(0.38, 0.3, 0.5)
const GATE_COLOR := Color(1.0, 0.35, 0.35)
const SLIDE_TIME := 0.35

var size := Vector2(60, 180)
var is_open := false
## Arena gates are red and start open.
var gate := false

var _collision: CollisionShape2D
var _look: ColorRect
var _frame: ColorRect


func setup(rect: Rect2, p_gate := false, start_open := false) -> void:
	position = rect.get_center()
	size = Vector2(rect.size.x - 16.0, rect.size.y)
	gate = p_gate
	is_open = start_open


func _ready() -> void:
	collision_layer = Layers.WORLD
	var shape := RectangleShape2D.new()
	shape.size = size
	_collision = CollisionShape2D.new()
	_collision.shape = shape
	_collision.disabled = is_open
	add_child(_collision)
	var color := GATE_COLOR if gate else COLOR
	# A faint frame stays visible while the door is open.
	_frame = Harm.box(-size / 2.0 - Vector2(6, 0), Vector2(size.x + 12, 6), color.darkened(0.3))
	add_child(_frame)
	_look = Harm.box(-size / 2.0, size, color)
	_look.clip_contents = true
	add_child(_look)
	var art_path := Harm.prop_path("gate" if gate else "door")
	if ResourceLoader.exists(art_path):
		# The picture is stretched over the door; it slides up with it.
		_look.color = Color.TRANSPARENT
		var picture := TextureRect.new()
		picture.texture = load(art_path)
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_SCALE
		picture.size = Vector2(size.x + 16, size.y)
		picture.position = Vector2(-8, 0)
		picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_look.clip_contents = false
		_look.add_child(picture)
		_frame.visible = false
	else:
		for i in int(size.y / 30.0):
			_look.add_child(Harm.box(Vector2(6, i * 30 + 12), Vector2(size.x - 12, 4), color.darkened(0.25)))
	_look.scale.y = 0.0 if is_open else 1.0


func open() -> void:
	_set_open(true)


func close() -> void:
	_set_open(false)


func _set_open(value: bool) -> void:
	if is_open == value:
		return
	is_open = value
	_collision.set_deferred("disabled", value)
	if is_inside_tree():
		Sound.play("door")
	var tween := create_tween()
	tween.tween_property(_look, "scale:y", 0.0 if value else 1.0, SLIDE_TIME)
