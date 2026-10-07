class_name Fx
## One-shot visual effects: bursts of sparks, drops or dust, and explosions.
## Each removes itself when done.


## Particles flying out of `at` (world position) in all directions, or within
## `spread` degrees around `direction`. `glow` adds light instead of covering.
static func burst(parent: Node, at: Vector2, colors: Array, amount := 10, speed := 260.0, size := 3.0,
		lifetime := 0.35, gravity := 600.0, glow := true, direction := Vector2.UP, spread := 180.0) -> CPUParticles2D:
	var particles := CPUParticles2D.new()
	particles.position = at
	particles.one_shot = true
	particles.explosiveness = 0.95
	particles.amount = amount
	particles.lifetime = lifetime
	particles.direction = direction
	particles.spread = spread
	particles.initial_velocity_min = speed * 0.4
	particles.initial_velocity_max = speed
	particles.gravity = Vector2(0, gravity)
	particles.damping_min = speed * 0.5
	particles.damping_max = speed * 1.5
	particles.scale_amount_min = size * 0.6
	particles.scale_amount_max = size * 1.4
	particles.color_ramp = ramp(colors)
	if glow:
		particles.material = additive()
	particles.finished.connect(particles.queue_free)
	soften(particles)
	parent.add_child(particles)
	particles.emitting = true
	return particles


## Gives particles a soft round look instead of square pixels; their sizes
## stay in pixels (the dot is DOT_SIZE pixels across at scale 1).
static func soften(particles: CPUParticles2D) -> CPUParticles2D:
	particles.texture = dot()
	particles.scale_amount_min /= DOT_SIZE * 0.5
	particles.scale_amount_max /= DOT_SIZE * 0.5
	return particles


const DOT_SIZE := 32.0
static var _dot: GradientTexture2D


## A round dot, bright in the middle and fading to the edge.
static func dot() -> GradientTexture2D:
	if _dot == null:
		var gradient := Gradient.new()
		gradient.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
		gradient.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0.85), Color(1, 1, 1, 0.0)])
		_dot = GradientTexture2D.new()
		_dot.gradient = gradient
		_dot.fill = GradientTexture2D.FILL_RADIAL
		_dot.fill_from = Vector2(0.5, 0.5)
		_dot.fill_to = Vector2(0.5, 0.0)
		_dot.width = int(DOT_SIZE)
		_dot.height = int(DOT_SIZE)
	return _dot


## A blast: a flash of light, fire, smoke and flying bits.
static func explosion(parent: Node, at: Vector2, radius: float) -> void:
	var flash := Flare.new()
	flash.position = at
	flash.radius = radius * 1.3
	parent.add_child(flash)
	burst(parent, at, [Color(1, 1, 0.8), Color(1.0, 0.6, 0.15), Color(0.8, 0.15, 0.05, 0.0)], 40,
		radius * 4.0, 7.0, 0.5, 120.0)
	burst(parent, at, [Color(0.25, 0.22, 0.22, 0.8), Color(0.12, 0.11, 0.12, 0.0)], 24, radius * 2.0, 12.0,
		1.2, -60.0, false)
	burst(parent, at, [Color(0.35, 0.3, 0.28), Color(0.2, 0.18, 0.18, 0.0)], 16, radius * 5.0, 3.0, 0.9,
		1200.0, false)


## Colours over a particle's life, evenly spaced.
static func ramp(colors: Array) -> Gradient:
	var offsets := PackedFloat32Array()
	for i in colors.size():
		offsets.append(float(i) / maxf(colors.size() - 1, 1))
	var gradient := Gradient.new()
	gradient.offsets = offsets
	gradient.colors = PackedColorArray(colors)
	return gradient


static func additive() -> CanvasItemMaterial:
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return mat


## A round flash of light that swells and fades.
class Flare:
	extends Node2D

	var radius := 80.0
	var life := 0.3
	var color := Color(1.0, 0.75, 0.35)
	var _age := 0.0

	func _ready() -> void:
		material = Fx.additive()
		z_index = 3

	func _process(delta: float) -> void:
		_age += delta
		if _age >= life:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var t := _age / life
		var r := radius * (0.5 + 0.5 * t)
		for i in 4:
			draw_circle(Vector2.ZERO, r * (1.0 - i * 0.22), Color(color, (1.0 - t) * 0.25))
