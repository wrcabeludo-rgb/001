class_name ScoutDrone
extends Enemy
## Scout drone: hovers near its post under the ceiling. When it sees a hero it
## stops and aims — a thin red line shows exactly where it will shoot — then
## fires a fast laser bolt along that line.

enum State { HOVER, AIM, COOLDOWN }

const LASER_COLOR := Color(1.0, 0.2, 0.25)

@export var sight := 650.0
@export var aim_time := 0.7
@export var cooldown := 1.6
@export var bolt_damage := 2
@export var bolt_speed := 1100.0

var state := State.HOVER

var _home := Vector2.ZERO
var _time := 0.0
var _timer := 0.0
var _aim := Vector2.RIGHT
var _line: Line2D


func _init() -> void:
	max_health = 4
	body_size = Vector2(52, 36)
	color = ROBOT_COLOR
	contact_damage = 1
	uses_gravity = false
	art = "scout_drone"
	art_height = 80.0
	art_centered = true


func _ready() -> void:
	super._ready()
	_home = global_position
	_line = Line2D.new()
	_line.width = 2.0
	_line.default_color = Color(LASER_COLOR, 0.7)
	_line.visible = false
	add_child(_line)


func _think(delta: float) -> void:
	_time += delta
	_timer -= delta
	match state:
		State.HOVER:
			var bob := _home + Vector2(sin(_time * 1.1) * 90.0, sin(_time * 2.6) * 10.0)
			velocity = (bob - global_position) * 2.5
			var hero := nearest_hero(sight)
			if hero != null:
				state = State.AIM
				_timer = aim_time
				_aim = (hero.global_position - global_position).normalized()
				facing = 1 if _aim.x >= 0.0 else -1
				telegraph(aim_time)
		State.AIM:
			velocity = velocity.move_toward(Vector2.ZERO, 1000.0 * delta)
			# The aim slowly follows the hero, so standing still is a mistake.
			var hero := nearest_hero(sight * 1.3)
			if hero != null and _timer > aim_time * 0.35:
				var wanted := (hero.global_position - global_position).normalized()
				_aim = _aim.slerp(wanted, minf(1.0, 3.0 * delta)).normalized()
			if _timer <= 0.0:
				_fire()
				state = State.COOLDOWN
				_timer = cooldown
		State.COOLDOWN:
			velocity = velocity.move_toward(Vector2.ZERO, 600.0 * delta)
			if _timer <= 0.0:
				state = State.HOVER
	_line.visible = state == State.AIM
	if _line.visible:
		_line.points = PackedVector2Array([Vector2.ZERO, _aim * sight])
		_line.default_color = Color(LASER_COLOR, 0.35 + 0.4 * absf(sin(_time * 18.0)))


func _fire() -> void:
	var bolt := Projectile.new()
	var start := global_position + _aim * 34.0
	bolt.setup(Layers.Team.ENEMIES, start, _aim, bolt_speed, bolt_damage, 380.0, Vector2(34, 8), LASER_COLOR, 0, 1.2)
	get_parent().add_child(bolt)
	Sound.play("laser", 0.1, 0.0, 1.4)
	punch(Vector2(-0.1, 0.08))


func _on_interrupted() -> void:
	if state == State.AIM:
		state = State.COOLDOWN
		_timer = cooldown * 0.5
