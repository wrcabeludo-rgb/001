class_name Sniper
extends Enemy
## Lumen security sniper: stays on its ledge. When it sees a hero it aims for
## a long time — a red line shows where — and fires one hard, fast shot.

const LASER := Color(1.0, 0.15, 0.2)

@export var sight := 1100.0
@export var aim_time := 1.3
@export var cooldown := 2.0
@export var shot_damage := 3

var _timer := 1.0
var _aiming := false
var _aim := Vector2.LEFT
var _line: Line2D


func _init() -> void:
	max_health = 6
	body_size = Vector2(52, 70)
	color = Color(0.22, 0.22, 0.3)
	contact_damage = 1
	knockback_resistance = 0.6
	art = "sniper"
	art_height = 110.0
	scrap_min = 2
	scrap_max = 3


func _ready() -> void:
	super._ready()
	_line = Line2D.new()
	_line.width = 2.0
	_line.visible = false
	add_child(_line)


func _think(delta: float) -> void:
	velocity.x = 0.0
	_timer -= delta
	var hero := nearest_hero(sight)
	if not _aiming:
		if hero != null and _timer <= 0.0:
			_aiming = true
			_timer = aim_time
			_aim = (hero.global_position - _eye_point()).normalized()
			facing = 1 if _aim.x >= 0.0 else -1
			telegraph(aim_time)
	else:
		# Follows the hero until the last moment, then holds still.
		if hero != null and _timer > 0.3:
			_aim = _aim.slerp((hero.global_position - _eye_point()).normalized(), minf(1.0, 4.0 * delta)).normalized()
			facing = 1 if _aim.x >= 0.0 else -1
		if _timer <= 0.0:
			_aiming = false
			_timer = cooldown
			_fire()
	_line.visible = _aiming
	if _aiming:
		_line.points = PackedVector2Array([_eye_point() - global_position, _eye_point() - global_position + _aim * sight])
		_line.default_color = Color(LASER, 0.3 + 0.5 * absf(sin(Time.get_ticks_msec() * 0.02)) if _timer < 0.3 else 0.35)


func _eye_point() -> Vector2:
	return global_position + Vector2(facing * 30.0, -14.0)


func _fire() -> void:
	var bullet := Projectile.new()
	bullet.setup(Layers.Team.ENEMIES, _eye_point() + _aim * 20.0, _aim, 1700.0, shot_damage, 520.0, Vector2(40, 6),
		LASER, 0, 1.2)
	get_parent().add_child(bullet)
	Sound.play("shoot_charged", 0.05, -6.0, 1.4)
	punch(Vector2(-0.1, 0.06))


func _on_interrupted() -> void:
	_aiming = false
	_timer = cooldown * 0.5
