class_name HeartPulse
extends Node2D
## A vent of the Heart's energy in the floor (world 3): every few seconds it
## glows (warning) and sends a wave of energy along the floor both ways —
## jump over it.

const COLOR := Color(1.0, 0.25, 0.6)

@export var interval := 3.4
@export var warning_time := 0.7
@export var wave_speed := 480.0
@export var damage := 2

var _timer := 0.0


func setup(floor_point: Vector2, phase := 0.0) -> void:
	position = floor_point
	_timer = interval - phase


func _physics_process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_timer += interval
		for direction in [-1, 1]:
			var wave := Wave.new()
			wave.setup(position, direction, wave_speed, damage)
			get_parent().add_child(wave)
		Sound.play("shock", 0.05, -4.0, 0.6)
	queue_redraw()


func _draw() -> void:
	var warn := _timer < warning_time and int(_timer * 10.0) % 2 == 0
	draw_rect(Rect2(-34, -10, 68, 10), Color(0.2, 0.2, 0.26))
	draw_rect(Rect2(-26, -8, 52, 5), COLOR if warn else COLOR.darkened(0.6))
	if warn:
		draw_circle(Vector2(0, -6), 40.0, Color(COLOR, 0.2))


## The wave: the same as the boss's shockwave, but drawn as crackling energy.
class Wave:
	extends BossAttacks.Shockwave

	var _bolts: Array[PackedVector2Array] = []

	func _ready() -> void:
		material = Fx.additive()

	func _process(_delta: float) -> void:
		_bolts.clear()
		for i in 3:
			var x := randf_range(-SIZE.x / 2.0, SIZE.x / 2.0)
			_bolts.append(Electric.bolt(Vector2(x, 0), Vector2(x + randf_range(-20, 20), -randf_range(20, SIZE.y)), 4, 8.0))
		queue_redraw()

	func _draw() -> void:
		var shape := PackedVector2Array([Vector2(-SIZE.x / 2.0, 0), Vector2(-SIZE.x * 0.15, -SIZE.y * 0.8),
			Vector2(direction * SIZE.x * 0.2, -SIZE.y), Vector2(SIZE.x / 2.0, 0)])
		draw_colored_polygon(shape, Color(HeartPulse.COLOR, 0.35))
		for points in _bolts:
			draw_polyline(points, Color(1, 0.85, 0.95), 2.0)
