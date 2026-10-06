class_name GunTurret
extends Enemy
## Robot turret: stays put; when a hero is in range it charges up (warning)
## and fires a slow bullet at them.

const BULLET_COLOR := Color(0.55, 1.0, 0.25)

@export var fire_range := 900.0
@export var windup_time := 0.6
@export var fire_cooldown := 1.6
@export var bullet_damage := 2
@export var bullet_speed := 560.0
@export var bullet_knockback := 450.0

var _timer := 0.8
var _charging := false


func _init() -> void:
	max_health = 8
	body_size = Vector2(60, 50)
	color = ROBOT_COLOR
	contact_damage = 0
	knockback_resistance = 1.0
	# In world 1 the turret is a mutant spitter rooted in the ground.
	art = "spitter"
	art_height = 120.0


func _think(delta: float) -> void:
	velocity.x = 0.0
	_timer -= delta
	var hero := nearest_hero(fire_range)
	if hero != null:
		facing = 1 if hero.global_position.x >= global_position.x else -1
	if not _charging:
		if hero != null and _timer <= 0.0:
			_charging = true
			_timer = windup_time
			telegraph(windup_time)
		return
	if _timer > 0.0:
		return
	_charging = false
	_timer = fire_cooldown
	if hero == null:
		return
	var bullet := Projectile.new()
	var mouth := global_position + (Vector2(facing * 42.0, -50.0) if _sprite != null else Vector2(0, -10))
	bullet.setup(Layers.Team.ENEMIES, mouth, hero.global_position - mouth,
		bullet_speed, bullet_damage, bullet_knockback, Vector2(20, 20), BULLET_COLOR, 0, 3.0)
	get_parent().add_child(bullet)
