class_name SlimeLook
## The look of the green sludge: the boss's wave running along the floor, the
## column pouring from above and its warning mark, and acid puddles. All are
## drawn and animated in code (no pictures).

const DARK := Color(0.12, 0.35, 0.06)
const BODY := Color(0.38, 0.85, 0.18)
const LIGHT := Color(0.8, 1.0, 0.45)


## Drips of sludge falling off an effect, in world space.
static func drips(amount: int, area: Vector2, gravity := 900.0) -> CPUParticles2D:
	var particles := CPUParticles2D.new()
	particles.amount = amount
	particles.lifetime = 0.6
	particles.local_coords = false
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = area / 2.0
	particles.direction = Vector2.UP
	particles.spread = 50.0
	particles.initial_velocity_min = 60.0
	particles.initial_velocity_max = 180.0
	particles.gravity = Vector2(0, gravity)
	particles.scale_amount_min = 2.5
	particles.scale_amount_max = 5.0
	particles.color_ramp = Fx.ramp([LIGHT, BODY, Color(DARK, 0.0)])
	return Fx.soften(particles)


## A rolling crest of sludge, `size` wide and high, standing on y = 0, rolling
## towards +x (scale.x mirrors it).
class Wave:
	extends Node2D

	var size := Vector2(46, 56)
	var _time := 0.0

	func _ready() -> void:
		var spray := SlimeLook.drips(14, Vector2(size.x, 10))
		spray.position = Vector2(0, -size.y * 0.8)
		add_child(spray)

	func _process(delta: float) -> void:
		_time += delta
		queue_redraw()

	func _draw() -> void:
		var points := PackedVector2Array()
		var steps := 14
		for i in steps + 1:
			var k := float(i) / steps
			var x := lerpf(-size.x * 0.9, size.x * 0.5, k)
			# Low at the back, rising to a curling front.
			var height := size.y * (0.3 + 0.7 * pow(k, 1.6)) * (0.9 + 0.1 * sin(_time * 25.0 + k * 9.0))
			points.append(Vector2(x, -height))
		points.append(Vector2(size.x * 0.62, -size.y * 0.55))
		points.append(Vector2(size.x * 0.5, 0))
		points.append(Vector2(-size.x * 0.9, 0))
		draw_colored_polygon(points, SlimeLook.BODY)
		# A lighter rim along the top.
		var rim := PackedVector2Array()
		for i in steps + 1:
			rim.append(points[i] + Vector2(0, 3))
		draw_polyline(rim, SlimeLook.LIGHT, 4.0)
		draw_rect(Rect2(-size.x * 0.9, -4, size.x * 1.4, 4), SlimeLook.DARK)


## Sludge pouring down onto y = 0 in a column `size` wide and high.
class Column:
	extends Node2D

	var size := Vector2(90, 520)
	var _time := 0.0

	func _ready() -> void:
		var splash := SlimeLook.drips(30, Vector2(size.x, 6), 1400.0)
		splash.position = Vector2(0, -16)
		splash.lifetime = 0.4
		splash.initial_velocity_max = 380.0
		splash.spread = 70.0
		add_child(splash)

	func _process(delta: float) -> void:
		_time += delta
		queue_redraw()

	func _draw() -> void:
		var half := size.x / 2.0
		# The stream: edges wobbling as it pours, narrower at the top.
		var left := PackedVector2Array()
		var right := PackedVector2Array()
		var steps := 16
		for i in steps + 1:
			var y := -size.y + size.y * float(i) / steps
			var wobble := 6.0 * sin(_time * 22.0 + i * 1.3)
			var width := half * (0.7 + 0.3 * float(i) / steps)
			left.append(Vector2(-width + wobble, y))
			right.append(Vector2(width + wobble * 0.6, y))
		right.reverse()
		draw_colored_polygon(left + right, Color(SlimeLook.BODY, 0.92))
		# Streaks running down the stream.
		for i in 5:
			var x := lerpf(-half * 0.55, half * 0.55, float(i) / 4.0)
			var y := maxf(fmod(_time * 1400.0 + i * 170.0, size.y + 200.0) - size.y - 100.0, -size.y)
			var streak := minf(110.0, -y - 16.0)
			if streak > 0.0:
				draw_rect(Rect2(x - 3, y, 6, streak), Color(SlimeLook.LIGHT, 0.6))
		draw_polyline(left, Color(SlimeLook.DARK, 0.7), 4.0)
		# A heap spreading where it lands.
		draw_set_transform(Vector2(0, -12), 0.0, Vector2(1.0, 0.4))
		draw_circle(Vector2.ZERO, half * 1.3, SlimeLook.BODY)
		draw_circle(Vector2(0, -6), half * 0.9, SlimeLook.LIGHT.darkened(0.15))
		draw_set_transform(Vector2.ZERO)


## Where the column will land: a dark stain spreading on the floor and a
## blinking warning ring.
class Mark:
	extends Node2D

	var width := 90.0
	var delay := 0.9
	var _time := 0.0

	func _process(delta: float) -> void:
		_time += delta
		queue_redraw()

	func _draw() -> void:
		var grow := clampf(_time / delay, 0.0, 1.0)
		draw_set_transform(Vector2(0, -4), 0.0, Vector2(1.0, 0.25))
		draw_circle(Vector2.ZERO, width * 0.6 * grow, Color(SlimeLook.DARK, 0.7))
		if int(_time * 10.0) % 2 == 0:
			draw_arc(Vector2.ZERO, width * 0.62, 0.0, TAU, 32, Color(1.0, 0.9, 0.3, 0.9), 6.0)
		draw_set_transform(Vector2.ZERO)


## A pool of acid filling `size` (top-left at 0, 0): a rippling surface, a
## darker depth and bubbles popping.
class Pool:
	extends Node2D

	var size := Vector2(120, 40)
	var _time := 0.0

	func _ready() -> void:
		var bubbles := CPUParticles2D.new()
		bubbles.position = Vector2(size.x / 2.0, size.y * 0.5)
		bubbles.amount = maxi(3, int(size.x / 40.0))
		bubbles.lifetime = 0.9
		bubbles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		bubbles.emission_rect_extents = Vector2(size.x / 2.0 - 6.0, size.y * 0.3)
		bubbles.direction = Vector2.UP
		bubbles.spread = 10.0
		bubbles.initial_velocity_min = 20.0
		bubbles.initial_velocity_max = 40.0
		bubbles.gravity = Vector2.ZERO
		bubbles.scale_amount_min = 3.0
		bubbles.scale_amount_max = 6.0
		bubbles.color_ramp = Fx.ramp([Color(SlimeLook.LIGHT, 0.0), Color(SlimeLook.LIGHT, 0.8), Color(SlimeLook.LIGHT, 0.0)])
		add_child(Fx.soften(bubbles))

	func _process(delta: float) -> void:
		_time += delta
		queue_redraw()

	func _draw() -> void:
		var surface := PackedVector2Array()
		var steps := maxi(8, int(size.x / 12.0))
		for i in steps + 1:
			var x := size.x * float(i) / steps
			surface.append(Vector2(x, 6.0 + 3.0 * sin(_time * 4.0 + x * 0.08)))
		var body := surface.duplicate()
		body.append(Vector2(size.x, size.y))
		body.append(Vector2(0, size.y))
		draw_colored_polygon(body, Color(SlimeLook.BODY, 0.75))
		draw_rect(Rect2(0, size.y * 0.55, size.x, size.y * 0.45), Color(SlimeLook.DARK, 0.45))
		draw_polyline(surface, Color(SlimeLook.LIGHT, 0.9), 3.0)
