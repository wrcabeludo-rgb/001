class_name EnergyBarrier
extends Door
## A wall of magenta energy between two emitters (world 3). It stops heroes
## like a door; a lever switches it off for good. A timed barrier (`cycle` > 0)
## flickers off and on by itself: on for `on_time`, off for the rest.

const FIELD := Color(1.0, 0.18, 0.53)
const CORE := Color(1.0, 0.75, 0.9)

## Seconds of a full on/off cycle for a timed barrier; 0 = only a lever opens it.
var cycle := 0.0
var on_time := 2.0

var _time := 0.0
var _field: Node2D


func _build_look() -> void:
	_look = Harm.box(-size / 2.0, size, Color.TRANSPARENT)
	add_child(_look)
	_frame = Harm.box(Vector2.ZERO, Vector2.ZERO, Color.TRANSPARENT)
	add_child(_frame)
	# The emitters at the top and the bottom stay when the field is off: the
	# drawn lens heads (the base on the floor, the head under the ceiling), or bars.
	var bottom_art := Harm.prop_sprite("barrier_bottom", size)
	var top_art := Harm.prop_sprite("barrier_top", size)
	if bottom_art != null and top_art != null:
		top_art.position = Vector2(0, -size.y / 2.0 + top_art.texture.get_height() * 0.25)
		add_child(bottom_art)
		add_child(top_art)
	else:
		for end in [-1.0, 1.0]:
			var emitter := Harm.box(Vector2(-size.x / 2.0 - 4.0, end * size.y / 2.0 - (14.0 if end > 0 else 0.0)),
				Vector2(size.x + 8.0, 14.0), Color(0.15, 0.15, 0.2))
			add_child(emitter)
			emitter.add_child(Harm.box(Vector2(6, 5), Vector2(size.x - 4.0, 4), FIELD))
	_field = Field.new()
	_field.size = size
	add_child(_field)
	_field.visible = not is_open


func _physics_process(delta: float) -> void:
	_time += delta
	if cycle > 0.0:
		var on := fmod(_time, cycle) < on_time
		if on == is_open:
			_set_open(not on)


func _set_open(value: bool) -> void:
	if is_open == value:
		return
	is_open = value
	_collision.set_deferred("disabled", value)
	_field.visible = not value
	if is_inside_tree() and cycle <= 0.0:
		Sound.play("shock", 0.0, -6.0, 0.7)


## The crackling field: bright vertical strands that flicker.
class Field:
	extends Node2D

	var size := Vector2(44, 180)
	var _bolts: Array[PackedVector2Array] = []
	var _timer := 0.0

	func _ready() -> void:
		material = Fx.additive()

	func _process(delta: float) -> void:
		_timer -= delta
		if _timer <= 0.0:
			_timer = 0.06
			_bolts.clear()
			for i in 3:
				var x := randf_range(-0.35, 0.35) * size.x
				_bolts.append(Electric.bolt(Vector2(x, -size.y / 2.0 + 14.0), Vector2(x, size.y / 2.0 - 14.0), 8, 6.0))
		queue_redraw()

	func _draw() -> void:
		var flicker := 0.75 + 0.25 * sin(Time.get_ticks_msec() * 0.03)
		draw_rect(Rect2(-size / 2.0 + Vector2(0, 14), size - Vector2(0, 28)), Color(EnergyBarrier.FIELD, 0.22 * flicker))
		draw_rect(Rect2(Vector2(-3, -size.y / 2.0 + 14), Vector2(6, size.y - 28)), Color(EnergyBarrier.CORE, 0.5 * flicker))
		for points in _bolts:
			draw_polyline(points, Color(EnergyBarrier.FIELD, 0.8 * flicker), 3.0)
			draw_polyline(points, Color(EnergyBarrier.CORE, flicker), 1.2)
