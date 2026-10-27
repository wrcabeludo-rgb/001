class_name ExoHeavy
extends Enemy
## Lumen exo-trooper in powered armour: slow and tough, barely moved by hits.
## When a hero is in range it spins up its arm gun (long warning) and sweeps a
## fan of bullets from low to high across the hero.

const BULLET_COLOR := Color(1.0, 0.55, 0.2)

@export var walk_speed := 50.0
@export var fire_range := 760.0
@export var windup_time := 0.9
@export var sweep_shots := 9
@export var sweep_gap := 0.09
@export var cooldown := 2.2

var _timer := 1.2
var _winding := false
var _shots := 0
var _base_angle := 0.0


func _init() -> void:
	max_health = 30
	body_size = Vector2(96, 120)
	color = Color(0.2, 0.2, 0.26)
	contact_damage = 2
	knockback_resistance = 0.9
	art = "exo_heavy"
	art_height = 180.0
	scrap_min = 4
	scrap_max = 6
	health_drop_chance = 0.6


func _think(delta: float) -> void:
	_timer -= delta
	var hero := hero_in_line(fire_range, 260.0)
	if _shots > 0:
		velocity.x = 0.0
		if _timer <= 0.0:
			var t := 1.0 - float(_shots - 1) / maxf(sweep_shots - 1, 1)
			# From below the target to above it, whichever way it faces.
			_fire(_base_angle + lerpf(0.35, -0.35, t) * facing)
			_shots -= 1
			_timer = sweep_gap if _shots > 0 else cooldown
		return
	if _winding:
		velocity.x = 0.0
		if _timer <= 0.0:
			_winding = false
			_shots = sweep_shots
		return
	if hero == null:
		patrol(walk_speed)
		return
	facing = 1 if hero.global_position.x >= global_position.x else -1
	velocity.x = facing * walk_speed if absf(hero.global_position.x - global_position.x) > 340.0 else 0.0
	if _timer <= 0.0:
		_winding = true
		_timer = windup_time
		_base_angle = (hero.global_position - _muzzle()).angle()
		telegraph(windup_time)
		Sound.play("charge_ready", 0.0, -4.0, 0.6)


func _muzzle() -> Vector2:
	return global_position + Vector2(facing * 56.0, -20.0)


func _fire(angle: float) -> void:
	var direction := Vector2.from_angle(angle)
	var bullet := Projectile.new()
	bullet.setup(Layers.Team.ENEMIES, _muzzle(), direction, 760.0, 1, 260.0, Vector2(16, 7), BULLET_COLOR, 0, 1.6)
	get_parent().add_child(bullet)
	Sound.play("shoot", 0.1, -12.0, 0.9)
	punch(Vector2(-0.03, 0.02))


func _on_interrupted() -> void:
	pass
