class_name Rifleman
extends Walker
## Lumen security rifleman: patrols; when a hero is in sight it stops, aims
## (warning) and fires a burst of three; it backs off when a hero gets close.

const BULLET_COLOR := Color(1.0, 0.3, 0.55)

@export var fire_range := 720.0
@export var keep_away := 230.0
@export var aim_time := 0.4
@export var burst := 3
@export var burst_gap := 0.13
@export var cooldown := 1.4

var _timer := 0.6
var _shots := 0
var _aiming := false
var _target: Player


func _init() -> void:
	max_health = 7
	body_size = Vector2(52, 92)
	color = Color(0.25, 0.25, 0.32)
	contact_damage = 1
	art = "rifleman"
	art_height = 130.0
	walk_speed = 80.0
	chase_speed = 150.0
	sight = 720.0
	scrap_min = 1
	scrap_max = 3


func _think(delta: float) -> void:
	_timer -= delta
	var hero := hero_in_line(fire_range, 220.0)
	if _shots > 0:
		velocity.x = 0.0
		if _timer <= 0.0:
			_shots -= 1
			_timer = burst_gap if _shots > 0 else cooldown
			_shoot()
		return
	if _aiming:
		velocity.x = 0.0
		if _timer <= 0.0:
			_aiming = false
			_shots = burst
			_timer = 0.0
		return
	if hero == null:
		patrol(walk_speed)
		return
	_target = hero
	facing = 1 if hero.global_position.x >= global_position.x else -1
	var distance := absf(hero.global_position.x - global_position.x)
	if distance < keep_away and is_on_floor() and ground_ahead(-facing) and not wall_ahead(-facing):
		velocity.x = -facing * walk_speed * 1.3
	else:
		velocity.x = 0.0
	if _timer <= 0.0:
		_aiming = true
		_timer = aim_time
		telegraph(aim_time)


func _shoot() -> void:
	if _target == null or not is_instance_valid(_target):
		return
	var muzzle := global_position + Vector2(facing * 40.0, -18.0)
	var bullet := Projectile.new()
	bullet.setup(Layers.Team.ENEMIES, muzzle, (_target.global_position - muzzle).rotated(randf_range(-0.05, 0.05)),
		820.0, 1, 280.0, Vector2(18, 7), BULLET_COLOR, 0, 1.6)
	get_parent().add_child(bullet)
	Sound.play("shoot", 0.1, -10.0, 1.3)
	punch(Vector2(-0.05, 0.03))


func _on_interrupted() -> void:
	_aiming = false
	_shots = 0
	_timer = cooldown * 0.6
