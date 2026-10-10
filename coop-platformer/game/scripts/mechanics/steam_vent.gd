class_name SteamVent
extends Node2D
## A steam pipe in the floor. On a timer it puffs (warning) and then blows a
## column of steam that throws heroes high up — a lift to ledges that cannot be
## reached by jumping. It does not hurt.

enum State { IDLE, WARNING, BLAST }

const COLUMN_WIDTH := 70.0
const PIPE_COLOR := Color(0.32, 0.34, 0.4)
const WHEEL_COLOR := Color(0.75, 0.15, 0.12)

@export var idle_time := 2.0
@export var warning_time := 0.6
@export var blast_time := 1.2
## How high the column reaches above the floor.
@export var height := 330.0
## Upward speed given to a hero inside the column.
@export var push_speed := 950.0

var state := State.IDLE

var _timer := 0.0
var _steam: CPUParticles2D
var _puffs: CPUParticles2D


## `floor_point` is the floor under the pipe.
func setup(floor_point: Vector2, phase := 0.0) -> void:
	position = floor_point
	_timer = idle_time - phase


func _ready() -> void:
	var art := Harm.prop_sprite("steam_vent", Vector2(60, 60))
	var nozzle := Vector2(0, -34)
	if art != null:
		# The pipe is left of the drawing's middle (the valve wheel is on its right).
		var factor := 92.0 / art.texture.get_width()
		art.scale = Vector2(factor, factor)
		var drawn := art.texture.get_size() * factor
		art.position = Vector2(drawn.x * 0.146, -drawn.y / 2.0)
		add_child(art)
		nozzle = Vector2(0, -drawn.y + 6.0)
	_steam = _make_steam(40, 0.75, 700.0, 18.0, 46.0)
	_puffs = _make_steam(6, 0.5, 160.0, 8.0, 18.0)
	_steam.position = nozzle
	_puffs.position = nozzle


func _make_steam(amount: int, lifetime: float, speed: float, size_min: float, size_max: float) -> CPUParticles2D:
	var steam := CPUParticles2D.new()
	steam.position = Vector2(0, -34)
	steam.emitting = false
	steam.amount = amount
	steam.lifetime = lifetime
	steam.direction = Vector2.UP
	steam.spread = 9.0
	steam.initial_velocity_min = speed * 0.7
	steam.initial_velocity_max = speed
	steam.damping_min = speed * 0.4
	steam.damping_max = speed * 0.7
	steam.gravity = Vector2.ZERO
	steam.scale_amount_min = size_min
	steam.scale_amount_max = size_max
	steam.scale_amount_curve = Curve.new()
	steam.scale_amount_curve.add_point(Vector2(0, 0.4))
	steam.scale_amount_curve.add_point(Vector2(1, 1.0))
	steam.color_ramp = Fx.ramp([Color(1, 1, 1, 0.75), Color(0.85, 0.88, 0.92, 0.45), Color(0.8, 0.82, 0.86, 0.0)])
	add_child(Fx.soften(steam))
	return steam


func column_rect() -> Rect2:
	return Rect2(global_position + Vector2(-COLUMN_WIDTH / 2.0, -height), Vector2(COLUMN_WIDTH, height))


func _physics_process(delta: float) -> void:
	_timer -= delta
	match state:
		State.IDLE:
			if _timer <= 0.0:
				state = State.WARNING
				_timer += warning_time
		State.WARNING:
			if _timer <= 0.0:
				state = State.BLAST
				_timer += blast_time
				Sound.play("flame", 0.1, -4.0, 1.7)
		State.BLAST:
			_blow()
			if _timer <= 0.0:
				state = State.IDLE
				_timer += idle_time
	_steam.emitting = state == State.BLAST
	_puffs.emitting = state == State.WARNING
	queue_redraw()


func _blow() -> void:
	var rect := column_rect()
	for node in get_tree().get_nodes_in_group("players"):
		var hero := node as Player
		if hero == null or not hero.is_alive():
			continue
		var feet := hero.global_position + Vector2(0, Player.SIZE.y / 2.0)
		if feet.x > rect.position.x - Player.SIZE.x / 2.0 and feet.x < rect.end.x + Player.SIZE.x / 2.0 \
				and feet.y > rect.position.y and feet.y <= rect.end.y + 4.0:
			hero.launch(-push_speed)


func _draw() -> void:
	if get_child_count() > 2:
		return
	# The pipe stub with a red valve wheel.
	draw_rect(Rect2(-22, -34, 44, 34), PIPE_COLOR)
	draw_rect(Rect2(-28, -40, 56, 10), PIPE_COLOR.lightened(0.15))
	draw_rect(Rect2(-22, -34, 6, 34), PIPE_COLOR.lightened(0.25))
	draw_arc(Vector2(30, -16), 10.0, 0.0, TAU, 16, WHEEL_COLOR, 4.0)
	draw_line(Vector2(20, -16), Vector2(40, -16), WHEEL_COLOR, 3.0)
	var lamp := Color(1.0, 0.75, 0.2) if state != State.IDLE else Color(0.4, 0.3, 0.1)
	draw_circle(Vector2(-30, -26), 5.0, lamp)
