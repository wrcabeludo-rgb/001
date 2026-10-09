class_name CeilingTurret
extends Enemy
## Security turret hanging from the ceiling: when a hero is in range it
## charges up (warning) and fires a burst of three bullets at them.

const BULLET_COLOR := Color(1.0, 0.45, 0.25)

@export var fire_range := 820.0
@export var windup_time := 0.6
@export var fire_cooldown := 2.0
@export var burst := 3
@export var burst_gap := 0.14
@export var bullet_damage := 1
@export var bullet_speed := 720.0

var _timer := 1.0
var _charging := false
var _shots_left := 0


func _init() -> void:
	max_health = 7
	body_size = Vector2(60, 46)
	color = ROBOT_COLOR
	contact_damage = 0
	knockback_resistance = 1.0
	uses_gravity = false
	art = "ceiling_turret"
	art_height = 100.0
	art_centered = true


func _think(delta: float) -> void:
	velocity = Vector2.ZERO
	_timer -= delta
	var hero := nearest_hero(fire_range)
	if hero != null:
		facing = 1 if hero.global_position.x >= global_position.x else -1
	if _shots_left > 0:
		if _timer <= 0.0:
			_shots_left -= 1
			_timer = burst_gap if _shots_left > 0 else fire_cooldown
			if hero != null:
				_shoot(hero)
		return
	if not _charging:
		if hero != null and _timer <= 0.0:
			_charging = true
			_timer = windup_time
			telegraph(windup_time)
		return
	if _timer <= 0.0:
		_charging = false
		_shots_left = burst
		_timer = 0.0


func _shoot(hero: Player) -> void:
	var muzzle := global_position + Vector2(facing * 26.0, 24.0)
	var bullet := Projectile.new()
	bullet.setup(Layers.Team.ENEMIES, muzzle, hero.global_position - muzzle, bullet_speed, bullet_damage, 300.0,
		Vector2(16, 10), BULLET_COLOR, 0, 2.0)
	get_parent().add_child(bullet)
	Sound.play("shoot", 0.1, -10.0, 1.5)
	punch(Vector2(0.06, -0.08))


func _on_interrupted() -> void:
	_charging = false
	_shots_left = 0
	_timer = fire_cooldown * 0.5
