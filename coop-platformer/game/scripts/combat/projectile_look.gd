class_name ProjectileLook
extends Node2D
## How a bullet looks, drawn along +x (the projectile turns to its flight):
## BOLT — the Gunner's cyan energy bolt with a fading tail; PLASMA — the
## charged shot, a big pulsing ball of light; PELLET — a hot shotgun spark;
## SLIME — a wobbling glob of mutant spit that drips as it flies.

enum Style { BOLT, PLASMA, PELLET, SLIME }

var style: Style = Style.BOLT
var color := Color(0.3, 0.95, 1.0)
var size := Vector2(18, 8)

var _time := 0.0


func _ready() -> void:
	if style != Style.SLIME:
		material = Fx.additive()
	else:
		var drips := CPUParticles2D.new()
		drips.amount = 8
		drips.lifetime = 0.45
		drips.local_coords = false
		drips.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		drips.emission_sphere_radius = size.x * 0.3
		drips.gravity = Vector2(0, 700)
		drips.initial_velocity_max = 30.0
		drips.scale_amount_min = 2.0
		drips.scale_amount_max = 4.0
		drips.color_ramp = Fx.ramp([color, Color(color.darkened(0.4), 0.0)])
		add_child(Fx.soften(drips))


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	match style:
		Style.BOLT:
			_streak(46.0, 7.0, Color(color, 0.0), Color(color, 0.55))
			_capsule(26.0, 14.0, Color(color, 0.35))
			_capsule(18.0, 5.0, Color(0.9, 1.0, 1.0, 0.95))
		Style.PELLET:
			var hot := Color(1.0, 0.75, 0.3)
			_streak(26.0, 4.0, Color(hot, 0.0), Color(hot, 0.7))
			_capsule(10.0, 8.0, Color(hot, 0.4))
			_capsule(6.0, 3.0, Color(1, 1, 0.85))
		Style.PLASMA:
			var pulse := 1.0 + 0.12 * sin(_time * 30.0)
			_streak(80.0, size.y * 0.9, Color(color, 0.0), Color(color, 0.45))
			for i in 4:
				draw_circle(Vector2.ZERO, size.y * (1.4 - i * 0.28) * pulse, Color(color, 0.22))
			draw_circle(Vector2.ZERO, size.y * 0.42, Color(1, 1, 1, 0.95))
			# Small sparks circling the ball.
			for i in 3:
				var angle := _time * 14.0 + i * TAU / 3.0
				draw_circle(Vector2(cos(angle), sin(angle)) * size.y * 0.75, 2.5, Color(0.9, 1, 1, 0.9))
		Style.SLIME:
			var r := size.x * 0.5
			var wobble := Vector2(1.0 + 0.12 * sin(_time * 18.0), 1.0 - 0.12 * sin(_time * 18.0))
			draw_set_transform(Vector2.ZERO, 0.0, wobble)
			draw_circle(Vector2(-r * 0.6, 0), r * 0.55, color.darkened(0.25))
			draw_circle(Vector2.ZERO, r, color.darkened(0.45))
			draw_circle(Vector2.ZERO, r * 0.82, color)
			draw_circle(Vector2(r * 0.25, -r * 0.3), r * 0.28, Color(1, 1, 0.8, 0.8))
			draw_set_transform(Vector2.ZERO)


## A shape rounded at both ends, centred, `length` long along x.
func _capsule(length: float, width: float, fill: Color) -> void:
	var half := maxf(length - width, 0.0) / 2.0
	draw_rect(Rect2(-half, -width / 2.0, half * 2.0, width), fill)
	draw_circle(Vector2(-half, 0), width / 2.0, fill)
	draw_circle(Vector2(half, 0), width / 2.0, fill)


## The tail behind the head: thin and clear at the end, `head` colour at the front.
func _streak(length: float, width: float, tail: Color, head: Color) -> void:
	var points := PackedVector2Array([Vector2(-length, 0), Vector2(0, -width / 2.0), Vector2(0, width / 2.0)])
	draw_polygon(points, PackedColorArray([tail, head, head]))
