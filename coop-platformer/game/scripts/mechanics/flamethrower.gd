class_name Flamethrower
extends Node2D
## A flamethrower turret on a wall. On a timer it sputters sparks (warning),
## then shoots a jet of fire sideways that burns heroes and throws them back.
## The fire and sparks are particles: white-hot at the nozzle, orange, then smoke.

enum State { IDLE, WARNING, FIRE }

const FLAME_HEIGHT := 44.0

@export var idle_time := 2.0
@export var warning_time := 0.7
@export var fire_time := 1.3
@export var damage := 2
@export var knockback := Vector2(600, -380)

var state := State.IDLE
## +1 shoots right, -1 left.
var direction := 1
## The fire area in world coordinates.
var rect := Rect2()

var _timer := 0.0
var _fire: CPUParticles2D
var _smoke: CPUParticles2D
var _sparks: CPUParticles2D


func setup(nozzle: Vector2, p_direction: int, reach: float, phase := 0.0) -> void:
	direction = p_direction
	var start_x := nozzle.x if direction > 0 else nozzle.x - reach
	rect = Rect2(start_x, nozzle.y - FLAME_HEIGHT / 2.0, reach, FLAME_HEIGHT)
	_timer = idle_time - phase
	position = nozzle


func _ready() -> void:
	var art := Harm.prop_sprite("flamethrower", Vector2.ZERO)
	if art != null:
		# Mounted on the wall, nozzle where the flame starts; drawn behind the walls.
		art.flip_h = direction < 0
		art.position = Vector2(direction * -16.0, 26.0)
		art.z_index = -1
		add_child(art)
	else:
		add_child(Harm.box(Vector2(-30 if direction > 0 else -10, -24), Vector2(40, 48), Color(0.36, 0.3, 0.3)))
	var reach := rect.size.x
	_fire = _jet(90, 0.42, reach, 10.0, 34.0,
		[Color(1, 1, 0.85), Color(1.0, 0.75, 0.25), Color(1.0, 0.35, 0.08, 0.8), Color(0.5, 0.1, 0.05, 0.0)], true)
	_smoke = _jet(24, 0.8, reach * 0.9, 16.0, 44.0,
		[Color(0.2, 0.18, 0.18, 0.0), Color(0.18, 0.16, 0.16, 0.45), Color(0.1, 0.1, 0.1, 0.0)], false)
	_smoke.gravity = Vector2(0, -160)
	_sparks = _jet(10, 0.3, 90.0, 4.0, 4.0, [Color(1, 1, 0.7), Color(1.0, 0.6, 0.2, 0.0)], true)
	_sparks.spread = 40.0
	_sparks.gravity = Vector2(0, 500)


## A stream of particles out of the nozzle, reaching about `reach` pixels,
## each growing from `from_size` to `to_size`.
func _jet(amount: int, lifetime: float, reach: float, from_size: float, to_size: float, colors: Array,
		glow: bool) -> CPUParticles2D:
	var jet := CPUParticles2D.new()
	jet.emitting = false
	jet.amount = amount
	jet.lifetime = lifetime
	jet.direction = Vector2(direction, 0)
	jet.spread = 9.0
	jet.initial_velocity_min = reach / lifetime * 0.9
	jet.initial_velocity_max = reach / lifetime * 1.15
	jet.gravity = Vector2(0, -120)
	jet.scale_amount_min = from_size
	jet.scale_amount_max = from_size * 1.3
	var grow := Curve.new()
	grow.add_point(Vector2(0, 1.0))
	grow.add_point(Vector2(1, to_size / from_size))
	jet.scale_amount_curve = grow
	jet.color_ramp = Fx.ramp(colors)
	if glow:
		jet.material = Fx.additive()
	jet.position = Vector2(direction * 6.0, 0)
	add_child(Fx.soften(jet))
	return jet


func _physics_process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		match state:
			State.IDLE:
				state = State.WARNING
				_timer += warning_time
			State.WARNING:
				state = State.FIRE
				if _hero_near():
					Sound.play("flame")
				_timer += fire_time
			State.FIRE:
				state = State.IDLE
				_timer += idle_time
	_fire.emitting = state == State.FIRE
	_smoke.emitting = state == State.FIRE
	_sparks.emitting = state == State.WARNING
	if state != State.FIRE:
		return
	for hurtbox in Harm.hurtboxes_in_rect(get_world_2d(), rect, Harm.HEROES):
		hurtbox.take_hit(Hit.make(damage, Vector2(direction * knockback.x, knockback.y), hurtbox.global_position))


func _hero_near() -> bool:
	for node in get_tree().get_nodes_in_group("players"):
		if node is Player and node.is_alive() and absf(node.global_position.x - global_position.x) < 1100.0:
			return true
	return false
