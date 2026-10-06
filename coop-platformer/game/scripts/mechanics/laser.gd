class_name Laser
extends Node2D
## A laser beam from a ceiling emitter down to the floor, on a timer:
## off, then a thin blinking line (warning), then the deadly beam.

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
var _beam: ColorRect


## `top` is the emitter, `length` how far down the beam reaches; `phase` shifts
## the cycle so neighbouring lasers take turns.
func setup(top: Vector2, length: float, phase := 0.0) -> void:
	rect = Rect2(top.x - BEAM_WIDTH / 2.0, top.y, BEAM_WIDTH, length)
	_timer = off_time - phase


func _ready() -> void:
	add_child(Harm.box(Vector2(rect.get_center().x - 22, rect.position.y), Vector2(44, 20), Color(0.3, 0.32, 0.4)))
	_beam = Harm.box(rect.position + Vector2(0, 20), rect.size - Vector2(0, 20), BEAM_COLOR)
	add_child(_beam)
	_beam.visible = false


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
	_beam.visible = state == State.ON or (state == State.WARNING and int(_timer * 12.0) % 2 == 0)
	var width := BEAM_WIDTH if state == State.ON else 3.0
	_beam.size.x = width
	_beam.position.x = rect.get_center().x - width / 2.0
	_beam.color = BEAM_COLOR if state == State.ON else Color(BEAM_COLOR, 0.6)
