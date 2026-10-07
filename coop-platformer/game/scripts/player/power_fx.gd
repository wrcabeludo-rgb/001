class_name PowerFx
extends Node2D
## How a hero's power-ups show: rage — red flames licking up around the hero;
## shield — a shimmering bubble that ripples when it stops a hit; haste —
## golden sparks kicked up at the feet (the afterimages come from HeroRig).
## Picking one up flashes a ring; the last seconds blink as a warning.
## Placed at the hero's centre.

const RAGE := Color(1.0, 0.25, 0.15)
const SHIELD := Color(0.45, 0.8, 1.0)
const HASTE := Color(1.0, 0.9, 0.35)
## The effect blinks during this many last seconds.
const WARN_TIME := 2.0
const BUBBLE := Vector2(62, 92)

var _player: Player
var _flames: CPUParticles2D
var _sparks: CPUParticles2D
var _time := 0.0
var _ripple := 0.0
var _seen := {}


func setup(player: Player) -> void:
	_player = player


func _ready() -> void:
	z_index = 1
	_flames = CPUParticles2D.new()
	_flames.amount = 36
	_flames.lifetime = 0.55
	_flames.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_flames.emission_rect_extents = Vector2(26, 44)
	_flames.direction = Vector2.UP
	_flames.spread = 12.0
	_flames.initial_velocity_min = 60.0
	_flames.initial_velocity_max = 140.0
	_flames.gravity = Vector2(0, -120)
	_flames.scale_amount_min = 8.0
	_flames.scale_amount_max = 16.0
	var shrink := Curve.new()
	shrink.add_point(Vector2(0, 1))
	shrink.add_point(Vector2(1, 0.2))
	_flames.scale_amount_curve = shrink
	_flames.color_ramp = Fx.ramp([Color(1, 0.85, 0.4, 0.0), Color(1, 0.45, 0.15, 0.8), Color(0.8, 0.1, 0.05, 0.0)])
	_flames.material = Fx.additive()
	_flames.local_coords = false
	add_child(Fx.soften(_flames))
	_sparks = CPUParticles2D.new()
	_sparks.amount = 14
	_sparks.lifetime = 0.35
	_sparks.position = Vector2(0, Player.SIZE.y / 2.0 - 4.0)
	_sparks.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_sparks.emission_rect_extents = Vector2(14, 2)
	_sparks.direction = Vector2.UP
	_sparks.spread = 60.0
	_sparks.initial_velocity_min = 60.0
	_sparks.initial_velocity_max = 160.0
	_sparks.gravity = Vector2(0, 500)
	_sparks.scale_amount_min = 2.0
	_sparks.scale_amount_max = 4.0
	_sparks.color_ramp = Fx.ramp([Color(1, 1, 0.8), HASTE, Color(1.0, 0.6, 0.1, 0.0)])
	_sparks.material = Fx.additive()
	_sparks.local_coords = false
	add_child(Fx.soften(_sparks))


## The shield stopped a hit: the bubble ripples.
func shield_ping() -> void:
	_ripple = 1.0


func _process(delta: float) -> void:
	if _player == null:
		return
	_time += delta
	_ripple = move_toward(_ripple, 0.0, delta * 3.0)
	for power in _player.powers.keys():
		if not _seen.has(power):
			_pickup_flash(Player.POWER_COLORS[power])
	_seen = _player.powers.duplicate()
	_flames.emitting = _shown("rage")
	_sparks.emitting = _shown("haste") and absf(_player.velocity.x) > 50.0 and _player.is_on_floor()
	queue_redraw()


## Shown now: active, and not in the "off" half of the warning blink.
func _shown(power: String) -> bool:
	var left: float = _player.powers.get(power, 0.0)
	return left > 0.0 and (left > WARN_TIME or int(left * 8.0) % 2 == 0)


func _pickup_flash(color: Color) -> void:
	var ring := Fx.Flare.new()
	ring.color = color
	ring.radius = 120.0
	ring.life = 0.35
	add_child(ring)
	Fx.burst(self, Vector2.ZERO, [Color(1, 1, 1), color, Color(color, 0.0)], 24, 380.0, 4.0, 0.5, 0.0)


func _draw() -> void:
	if _shown("shield"):
		var pulse := 1.0 + 0.03 * sin(_time * 5.0) + 0.15 * _ripple
		var r := BUBBLE * pulse
		draw_set_transform(Vector2(0, -6), 0.0, Vector2(r.x / r.y, 1.0))
		draw_circle(Vector2.ZERO, r.y, Color(SHIELD, 0.12 + 0.25 * _ripple))
		draw_arc(Vector2.ZERO, r.y, 0.0, TAU, 48, Color(SHIELD, 0.7), 3.0 + 4.0 * _ripple)
		# A shimmer running around the bubble and a highlight on top.
		var at := _time * 2.2
		draw_arc(Vector2.ZERO, r.y - 4.0, at, at + 0.9, 16, Color(1, 1, 1, 0.75), 4.0)
		draw_arc(Vector2.ZERO, r.y * 0.78, -2.4, -1.6, 12, Color(1, 1, 1, 0.35), 5.0)
		draw_set_transform(Vector2.ZERO)
	if _shown("rage"):
		# A red heat glow around the body.
		for i in 3:
			draw_circle(Vector2(0, -8), 52.0 - i * 12.0, Color(RAGE, 0.07 + 0.03 * sin(_time * 9.0)))
