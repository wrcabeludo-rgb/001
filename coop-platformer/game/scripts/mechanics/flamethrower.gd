class_name Flamethrower
extends Node2D
## A flamethrower turret on a wall. On a timer it sputters sparks (warning),
## then shoots a jet of fire sideways that burns heroes and throws them back.

enum State { IDLE, WARNING, FIRE }

const FLAME_COLOR := Color(1.0, 0.55, 0.15, 0.85)
const SPARK_COLOR := Color(1.0, 0.9, 0.4)
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
var _flame: ColorRect
var _sparks: ColorRect


func setup(nozzle: Vector2, p_direction: int, reach: float, phase := 0.0) -> void:
	direction = p_direction
	var start_x := nozzle.x if direction > 0 else nozzle.x - reach
	rect = Rect2(start_x, nozzle.y - FLAME_HEIGHT / 2.0, reach, FLAME_HEIGHT)
	_timer = idle_time - phase
	position = nozzle


func _ready() -> void:
	add_child(Harm.box(Vector2(-30 if direction > 0 else -10, -24), Vector2(40, 48), Color(0.36, 0.3, 0.3)))
	_flame = Harm.box(rect.position - position, rect.size, FLAME_COLOR)
	_flame.visible = false
	add_child(_flame)
	_sparks = Harm.box(Vector2(direction * 14 - 8, -8), Vector2(16, 16), SPARK_COLOR)
	_sparks.visible = false
	add_child(_sparks)


func _physics_process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		match state:
			State.IDLE:
				state = State.WARNING
				_timer += warning_time
			State.WARNING:
				state = State.FIRE
				_timer += fire_time
			State.FIRE:
				state = State.IDLE
				_timer += idle_time
	_flame.visible = state == State.FIRE
	_flame.color.a = 0.75 + 0.2 * sin(Time.get_ticks_msec() * 0.05)
	_sparks.visible = state == State.WARNING and int(_timer * 14.0) % 2 == 0
	if state != State.FIRE:
		return
	for hurtbox in Harm.hurtboxes_in_rect(get_world_2d(), rect, Harm.HEROES):
		hurtbox.take_hit(Hit.make(damage, Vector2(direction * knockback.x, knockback.y), hurtbox.global_position))
