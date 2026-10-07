class_name SlimeLook
## The look of the green sludge: the boss's wave running along the floor, the
## geysers bursting from the floor and their warning stains, and acid puddles. All are
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


## Where a geyser will come up: the floor tiles darken in a spreading stain
## lying on the surface, sludge bubbles through, and a ring blinks as a warning.
class Mark:
	extends Node2D

	var width := 90.0
	var delay := 0.9
	var _time := 0.0

	func _ready() -> void:
		var bubbles := SlimeLook.drips(10, Vector2(width * 0.8, 2), 500.0)
		bubbles.initial_velocity_min = 40.0
		bubbles.initial_velocity_max = 120.0
		add_child(bubbles)

	func _process(delta: float) -> void:
		_time += delta
		queue_redraw()

	func _draw() -> void:
		var grow := clampf(_time / delay, 0.0, 1.0)
		# Flat on the top of the tiles (y = 0 is the floor surface).
		draw_set_transform(Vector2(0, 3), 0.0, Vector2(1.0, 0.18))
		draw_circle(Vector2.ZERO, width * 0.75 * grow, Color(SlimeLook.DARK, 0.85))
		draw_circle(Vector2.ZERO, width * 0.5 * grow, Color(SlimeLook.BODY, 0.6 * grow))
		if int(_time * 10.0) % 2 == 0:
			draw_arc(Vector2.ZERO, width * 0.8, 0.0, TAU, 40, Color(1.0, 0.9, 0.3, 0.9), 10.0)
		draw_set_transform(Vector2.ZERO)


## A fountain of sludge shooting up out of the floor (y = 0) to `height`:
## a wobbling jet, a frothy crown spraying drops, a splash ring on the floor.
class Geyser:
	extends Node2D

	var width := 90.0
	var height := 0.0
	var _time := 0.0
	var _spray: CPUParticles2D

	func _ready() -> void:
		var splash := SlimeLook.drips(24, Vector2(width * 1.2, 4), 1300.0)
		splash.initial_velocity_max = 320.0
		splash.spread = 60.0
		add_child(splash)
		_spray = SlimeLook.drips(30, Vector2(width * 0.8, 10), 1300.0)
		_spray.initial_velocity_min = 120.0
		_spray.initial_velocity_max = 380.0
		_spray.spread = 75.0
		add_child(_spray)

	func _process(delta: float) -> void:
		_time += delta
		_spray.position = Vector2(0, -height)
		_spray.emitting = height > 40.0
		queue_redraw()

	func _draw() -> void:
		var half := width / 2.0
		# The splash ring lying on the floor tiles.
		draw_set_transform(Vector2(0, 2), 0.0, Vector2(1.0, 0.22))
		draw_circle(Vector2.ZERO, half * 1.5, Color(SlimeLook.DARK, 0.8))
		draw_circle(Vector2.ZERO, half * 1.15, SlimeLook.BODY)
		draw_set_transform(Vector2.ZERO)
		if height < 4.0:
			return
		# The jet: wider at the bottom, edges wobbling as it gushes.
		var left := PackedVector2Array()
		var right := PackedVector2Array()
		var steps := 14
		for i in steps + 1:
			var k := float(i) / steps
			var w := half * (1.0 - 0.35 * k) + 5.0 * sin(_time * 30.0 + k * 8.0)
			left.append(Vector2(-w, -height * k))
			right.append(Vector2(w, -height * k))
		right.reverse()
		draw_colored_polygon(left + right, SlimeLook.BODY)
		# Light streaks rushing upwards.
		for i in 4:
			var x := lerpf(-half * 0.45, half * 0.45, float(i) / 3.0)
			var bottom := minf(-fmod(_time * 1800.0 + i * 140.0, height + 120.0) + 60.0, 0.0)
			var top := maxf(bottom - 90.0, -height)
			if bottom > top:
				draw_rect(Rect2(x - 3, top, 6, bottom - top), Color(SlimeLook.LIGHT, 0.65))
		draw_polyline(left, Color(SlimeLook.DARK, 0.7), 4.0)
		# The fountain spilling over: blobs arcing out and down to both sides.
		for side in [-1.0, 1.0]:
			for i in 9:
				var k := fmod(float(i) / 9.0 + _time * 1.6, 1.0)
				var spill := Vector2(side * half * (0.3 + 1.6 * k), -height + height * 0.4 * k * k - 30.0 * sin(k * PI))
				draw_circle(spill, half * (0.32 - 0.18 * k), Color(SlimeLook.BODY, 1.0 - k * 0.6))
		# The frothy crown.
		for i in 5:
			var angle := TAU * i / 5.0 + _time * 6.0
			draw_circle(Vector2(cos(angle) * half * 0.45, -height + sin(angle) * 10.0), half * 0.42, SlimeLook.BODY)
		draw_circle(Vector2(0, -height - 6.0), half * 0.4, SlimeLook.LIGHT)


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
