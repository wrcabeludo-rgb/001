class_name MovingPlatform
extends AnimatableBody2D
## A platform that carries heroes and enemies. It can be jumped onto from
## below and dropped through (down + jump), like any one-way platform.
## SHUTTLE goes back and forth between two points with a short pause at each.
## LIFT waits at the bottom; it rises while a hero stands on it, waits at the
## top while anyone is on board and goes back down a moment after it is empty.

enum Mode { SHUTTLE, LIFT }

const THICKNESS := 20.0
const COLOR := Color(0.55, 0.62, 0.72)
const LIFT_COLOR := Color(0.9, 0.75, 0.3)

@export var speed := 160.0
@export var pause_time := 0.6
@export var lift_speed := 230.0
## A lift goes back down this long after the last hero stepped off.
@export var lift_return_delay := 1.0

var mode: Mode = Mode.SHUTTLE
var width := 180.0
## The two end points (the platform's top centre), in parent coordinates.
var point_a := Vector2.ZERO
var point_b := Vector2.ZERO

var _target := 1
var _pause := 0.0
var _empty_timer := 0.0


func setup(p_mode: Mode, from: Vector2, to: Vector2, p_width: float) -> void:
	mode = p_mode
	point_a = from
	point_b = to
	width = p_width
	position = from


func _ready() -> void:
	sync_to_physics = true
	collision_layer = Layers.ONE_WAY
	collision_mask = 0
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width, THICKNESS)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.position = Vector2(0, THICKNESS / 2.0)
	collision.one_way_collision = true
	add_child(collision)
	var lift_art := Harm.prop_sprite("lift", Vector2.ZERO) if mode == Mode.LIFT else null
	if lift_art != null:
		# Stretched to the lift's width; its deck is a little below the picture's top.
		var drawn := lift_art.texture.get_size()
		var factor := width / drawn.x
		lift_art.scale = Vector2(factor, factor)
		lift_art.position = Vector2(0, drawn.y * factor / 2.0 - drawn.y * factor * 0.3)
		add_child(lift_art)
		return
	add_child(Harm.plank(Vector2(-width / 2.0, 0), width, COLOR))
	if mode == Mode.LIFT:
		# A lift has a yellow warning edge.
		add_child(Harm.box(Vector2(-width / 2.0, 0), Vector2(width, 5), LIFT_COLOR))
	if mode == Mode.LIFT:
		add_child(Harm.box(Vector2(-6, THICKNESS), Vector2(12, 14), Color(0.3, 0.3, 0.35)))


## True while at least one living hero stands on the platform.
func has_rider() -> bool:
	for node in get_tree().get_nodes_in_group("players"):
		var hero := node as Player
		if hero == null or not hero.is_alive() or not hero.is_on_floor():
			continue
		var feet := hero.global_position + Vector2(0, Player.SIZE.y / 2.0)
		if absf(feet.x - global_position.x) < width / 2.0 + Player.SIZE.x / 2.0 - 4.0 \
				and absf(feet.y - global_position.y) < 6.0:
			return true
	return false


func _physics_process(delta: float) -> void:
	if mode == Mode.SHUTTLE:
		_shuttle(delta)
	else:
		_lift(delta)


func _shuttle(delta: float) -> void:
	if _pause > 0.0:
		_pause -= delta
		return
	var goal := point_b if _target == 1 else point_a
	position = position.move_toward(goal, speed * delta)
	if position == goal:
		_target = 1 - _target
		_pause = pause_time


func _lift(delta: float) -> void:
	if has_rider():
		_empty_timer = lift_return_delay
		position = position.move_toward(point_b, lift_speed * delta)
		return
	_empty_timer -= delta
	if _empty_timer <= 0.0:
		position = position.move_toward(point_a, lift_speed * delta)
