class_name Electric
## Electricity: jagged lightning bolts, crackling sparks around a stunned
## enemy and the arc of the shock baton jumping from one enemy to another.

const COLOR := Color(0.45, 0.8, 1.0)
const CORE := Color(0.9, 0.97, 1.0)


## Points of a zigzag from `from` to `to`, each bend pushed sideways at random.
static func bolt(from: Vector2, to: Vector2, bends := 6, jitter := 14.0) -> PackedVector2Array:
	var points := PackedVector2Array([from])
	var side := (to - from).orthogonal().normalized()
	for i in range(1, bends):
		var t := float(i) / bends
		points.append(from.lerp(to, t) + side * randf_range(-jitter, jitter))
	points.append(to)
	return points


## A bolt with a glow around a white-hot core.
static func draw_bolt(canvas: CanvasItem, points: PackedVector2Array, width: float, alpha := 1.0) -> void:
	canvas.draw_polyline(points, Color(COLOR, 0.35 * alpha), width * 3.0)
	canvas.draw_polyline(points, Color(COLOR, 0.8 * alpha), width * 1.5)
	canvas.draw_polyline(points, Color(CORE, alpha), width * 0.6)


## Little bolts crackling over a rectangle (an enemy's body). `strength` 1 is
## a full stun; lower values fade the sparks out.
class Sparks:
	extends Node2D

	var size := Vector2(60, 80)
	var strength := 0.0
	var _bolts: Array[PackedVector2Array] = []
	var _timer := 0.0

	func _ready() -> void:
		material = Fx.additive()
		z_index = 2

	func _process(delta: float) -> void:
		_timer -= delta
		if _timer <= 0.0:
			_timer = 0.05
			_bolts.clear()
			if randf() < strength:
				for i in 1 + int(strength * 2.5):
					var start := Vector2(randf_range(-0.5, 0.5) * size.x, randf_range(-0.5, 0.5) * size.y)
					var end := start + Vector2.from_angle(randf() * TAU) * randf_range(20.0, 46.0)
					_bolts.append(Electric.bolt(start, end, 4, 8.0))
		queue_redraw()

	func _draw() -> void:
		for points in _bolts:
			Electric.draw_bolt(self, points, 2.2, clampf(strength, 0.3, 1.0))


## A bolt between two points that flickers and fades in `life` seconds.
class Arc:
	extends Node2D

	var from := Vector2.ZERO
	var to := Vector2.ZERO
	var life := 0.3
	var _age := 0.0
	var _points := PackedVector2Array()

	func _ready() -> void:
		material = Fx.additive()
		z_index = 3

	func _process(delta: float) -> void:
		_age += delta
		if _age >= life:
			queue_free()
			return
		_points = Electric.bolt(from, to, 9, 22.0)
		queue_redraw()

	func _draw() -> void:
		if _points.size() >= 2:
			Electric.draw_bolt(self, _points, 4.0, 1.0 - _age / life)
