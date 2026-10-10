class_name Hazard
extends Node2D
## Spikes, acid or molten metal along a row of tiles. Touching it hurts a hero
## and throws them up and towards the nearer edge, so they can always climb out.
## Molten metal burns harder and throws higher.

enum Kind { SPIKES, ACID, MOLTEN }

const SPIKE_COLOR := Color(0.78, 0.8, 0.86)
const SPIKE_HEIGHT := 26.0
const ACID_DEPTH := 40.0

var kind: Kind = Kind.SPIKES
var damage := 2
var throw_up := 900.0
var throw_side := 380.0
## The dangerous area in world coordinates.
var rect := Rect2()



## `cells` is the row of tiles; the danger fills its bottom part.
func setup(p_kind: Kind, cells: Rect2) -> void:
	kind = p_kind
	var height := SPIKE_HEIGHT if kind == Kind.SPIKES else ACID_DEPTH
	rect = Rect2(cells.position.x, cells.end.y - height, cells.size.x, height)
	if kind == Kind.ACID:
		throw_up = 1000.0
	elif kind == Kind.MOLTEN:
		damage = 3
		throw_up = 1150.0


func _ready() -> void:
	if kind == Kind.SPIKES:
		var picture := Harm.tiled_prop("spikes", Vector2(rect.position.x, rect.end.y - 40.0), Vector2(rect.size.x, 40.0))
		if picture != null:
			add_child(picture)
			return
		var x := rect.position.x
		while x < rect.end.x - 1.0:
			add_child(Harm.spike(Vector2(x, rect.end.y), 20.0, SPIKE_HEIGHT, SPIKE_COLOR))
			x += 20.0
	elif kind == Kind.ACID:
		var pool := SlimeLook.Pool.new()
		pool.position = rect.position
		pool.size = rect.size
		add_child(pool)
	else:
		# The cast-iron vat holding the metal, its rim just under the surface.
		var vat := Harm.tiled_prop("molten_vat", Vector2(rect.position.x, rect.end.y - 10.0), Vector2(rect.size.x, 60.0))
		if vat != null:
			add_child(vat)
		var molten := MoltenLook.new()
		molten.position = rect.position
		molten.size = rect.size
		add_child(molten)


func _physics_process(_delta: float) -> void:
	for hurtbox in Harm.hurtboxes_in_rect(get_world_2d(), rect, Harm.HEROES):
		var x := hurtbox.global_position.x
		var side := -1.0 if x - rect.position.x < rect.end.x - x else 1.0
		hurtbox.take_hit(Hit.make(damage, Vector2(side * throw_side, -throw_up), hurtbox.global_position))


## Molten metal: a white-hot rippling surface over orange and red depths, a
## glow above it, sparks and heat shimmer rising.
class MoltenLook:
	extends Node2D

	const HOT := Color(1.0, 0.92, 0.6)
	const ORANGE := Color(1.0, 0.5, 0.1)
	const DEEP := Color(0.6, 0.1, 0.03)

	var size := Vector2(120, 40)
	var _time := 0.0

	func _ready() -> void:
		var sparks := CPUParticles2D.new()
		sparks.position = Vector2(size.x / 2.0, 6.0)
		sparks.amount = maxi(4, int(size.x / 30.0))
		sparks.lifetime = 1.0
		sparks.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		sparks.emission_rect_extents = Vector2(size.x / 2.0 - 6.0, 2.0)
		sparks.direction = Vector2.UP
		sparks.spread = 25.0
		sparks.initial_velocity_min = 40.0
		sparks.initial_velocity_max = 120.0
		sparks.gravity = Vector2(0, -20)
		sparks.scale_amount_min = 2.0
		sparks.scale_amount_max = 4.0
		sparks.color_ramp = Fx.ramp([Color(1, 0.9, 0.5), Color(1.0, 0.4, 0.1), Color(0.6, 0.1, 0.05, 0.0)])
		sparks.material = Fx.additive()
		add_child(Fx.soften(sparks))
		var glow := Fx.dot()
		var light := Sprite2D.new()
		light.texture = glow
		light.material = Fx.additive()
		light.modulate = Color(1.0, 0.45, 0.1, 0.35)
		light.position = Vector2(size.x / 2.0, 0)
		light.scale = Vector2(size.x / Fx.DOT_SIZE * 1.3, 6.0)
		add_child(light)

	func _process(delta: float) -> void:
		_time += delta
		queue_redraw()

	func _draw() -> void:
		var surface := PackedVector2Array()
		var steps := maxi(8, int(size.x / 12.0))
		for i in steps + 1:
			var x := size.x * float(i) / steps
			surface.append(Vector2(x, 5.0 + 2.5 * sin(_time * 2.5 + x * 0.06) + 1.5 * sin(_time * 4.1 - x * 0.13)))
		var body := surface.duplicate()
		body.append(Vector2(size.x, size.y))
		body.append(Vector2(0, size.y))
		draw_colored_polygon(body, ORANGE)
		draw_rect(Rect2(0, size.y * 0.45, size.x, size.y * 0.55), Color(DEEP, 0.7))
		draw_polyline(surface, HOT, 4.0)
		# Dark crusts of cooling slag drifting on the surface.
		for i in int(size.x / 70.0):
			var x := fposmod(i * 70.0 + _time * 14.0, size.x - 24.0)
			draw_rect(Rect2(x, 9.0, 22.0, 4.0), Color(0.25, 0.08, 0.04, 0.8))
