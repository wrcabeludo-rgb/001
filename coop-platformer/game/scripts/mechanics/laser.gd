class_name Laser
extends Node2D
## A laser beam from a ceiling emitter down to the floor, on a timer:
## off, then a thin blinking line (warning), then the deadly beam: a white-hot
## core in a flickering glow, with sparks where it burns the floor.

enum State { OFF, WARNING, ON }

const BEAM_COLOR := Color(1.0, 0.2, 0.45)
const BEAM_WIDTH := 16.0

@export var off_time := 1.6
@export var warning_time := 0.7
@export var on_time := 1.2
@export var damage := 3
@export var knockback := Vector2(520, -420)

var state := State.OFF
## The beam area in world coordinates.
var rect := Rect2()

var _timer := 0.0
var _look: Look
var _sparks: CPUParticles2D


## `top` is the emitter, `length` how far down the beam reaches; `phase` shifts
## the cycle so neighbouring lasers take turns.
func setup(top: Vector2, length: float, phase := 0.0) -> void:
	rect = Rect2(top.x - BEAM_WIDTH / 2.0, top.y, BEAM_WIDTH, length)
	_timer = off_time - phase


func _ready() -> void:
	_look = Look.new()
	_look.position = Vector2(rect.get_center().x, rect.position.y)
	_look.length = rect.size.y
	add_child(_look)
	_sparks = CPUParticles2D.new()
	_sparks.position = Vector2(rect.get_center().x, rect.end.y - 4.0)
	_sparks.emitting = false
	_sparks.amount = 16
	_sparks.lifetime = 0.35
	_sparks.direction = Vector2.UP
	_sparks.spread = 70.0
	_sparks.initial_velocity_min = 120.0
	_sparks.initial_velocity_max = 320.0
	_sparks.gravity = Vector2(0, 900)
	_sparks.scale_amount_min = 2.0
	_sparks.scale_amount_max = 3.5
	_sparks.color_ramp = Fx.ramp([Color(1, 1, 1), BEAM_COLOR, Color(BEAM_COLOR, 0.0)])
	_sparks.material = Fx.additive()
	add_child(Fx.soften(_sparks))


func cycle_time() -> float:
	return off_time + warning_time + on_time


func _physics_process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		match state:
			State.OFF:
				state = State.WARNING
				_timer += warning_time
			State.WARNING:
				state = State.ON
				if _hero_near():
					Sound.play("laser")
				_timer += on_time
			State.ON:
				state = State.OFF
				_timer += off_time
	_update_look()
	if state != State.ON:
		return
	for hurtbox in Harm.hurtboxes_in_rect(get_world_2d(), rect, Harm.HEROES):
		var side := 1.0 if hurtbox.global_position.x >= rect.get_center().x else -1.0
		hurtbox.take_hit(Hit.make(damage, Vector2(side * knockback.x, knockback.y), hurtbox.global_position))


## Only lasers on screen make noise (roughly: a hero within a screen's width).
func _hero_near() -> bool:
	for node in get_tree().get_nodes_in_group("players"):
		if node is Player and node.is_alive() and absf(node.global_position.x - rect.get_center().x) < 1100.0:
			return true
	return false


func _update_look() -> void:
	_look.state = state
	_look.blink = int(_timer * 12.0) % 2 == 0
	_sparks.emitting = state == State.ON


## The emitter under the ceiling and its beam, drawn from the emitter (0, 0) down.
class Look:
	extends Node2D

	const HOUSING := Color(0.22, 0.23, 0.28)

	var length := 300.0
	var state := State.OFF
	var blink := false
	var _time := 0.0

	func _process(delta: float) -> void:
		_time += delta
		queue_redraw()

	func _draw() -> void:
		var beam_top := 22.0
		if state == State.ON:
			var flicker := 1.0 + 0.15 * sin(_time * 60.0) + 0.1 * sin(_time * 23.0)
			for layer in [[BEAM_WIDTH * 2.6, 0.18], [BEAM_WIDTH * 1.4, 0.35], [BEAM_WIDTH * 0.8, 0.7]]:
				var w: float = layer[0] * flicker
				draw_rect(Rect2(-w / 2.0, beam_top, w, length - beam_top), Color(BEAM_COLOR, layer[1]))
			draw_rect(Rect2(-2.5, beam_top, 5.0, length - beam_top), Color(1, 0.95, 0.97))
			# A hot spot where the beam meets the floor.
			draw_circle(Vector2(0, length), BEAM_WIDTH * 1.6 * flicker, Color(BEAM_COLOR, 0.35))
		elif state == State.WARNING and blink:
			draw_rect(Rect2(-1.5, beam_top, 3.0, length - beam_top), Color(BEAM_COLOR, 0.6))
		# The emitter: a metal box with a lens that glows while the beam is live.
		draw_rect(Rect2(-24, 0, 48, 14), HOUSING)
		draw_rect(Rect2(-24, 0, 48, 4), HOUSING.lightened(0.2))
		draw_colored_polygon(PackedVector2Array([Vector2(-14, 14), Vector2(14, 14), Vector2(8, 22), Vector2(-8, 22)]),
			HOUSING.darkened(0.3))
		var lens := 0.25 if state == State.OFF else (1.0 if state == State.ON or blink else 0.5)
		draw_circle(Vector2(0, 18), 6.0, Color(BEAM_COLOR, lens))
		draw_circle(Vector2(0, 18), 12.0, Color(BEAM_COLOR, lens * 0.3))
