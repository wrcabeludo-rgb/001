class_name TurretDummy
extends TrainingDummy
## A practice turret: every few seconds fires a slow bullet at the nearest hero,
## to test taking damage, knockback, invulnerability and the Swordsman's block.

const BULLET_COLOR := Color(1.0, 0.18, 0.53)

@export var fire_interval := 1.8
@export var fire_range := 1300.0
@export var bullet_damage := 2
@export var bullet_speed := 520.0
@export var bullet_knockback := 450.0

var _fire_timer := 1.0


func _ready() -> void:
	max_health = 15
	body_size = Vector2(60, 50)
	super._ready()


func _process(delta: float) -> void:
	super._process(delta)
	if health.is_dead():
		return
	_fire_timer -= delta
	if _fire_timer > 0.0:
		return
	var target := _nearest_hero()
	if target == null:
		return
	_fire_timer = fire_interval
	var bullet := Projectile.new()
	bullet.setup(Layers.Team.ENEMIES, global_position, target.global_position - global_position,
		bullet_speed, bullet_damage, bullet_knockback, Vector2(20, 20), BULLET_COLOR, 0, 4.0)
	get_parent().add_child(bullet)


func _nearest_hero() -> Player:
	var best: Player = null
	var best_distance := fire_range
	for node in get_tree().get_nodes_in_group("players"):
		var hero := node as Player
		if hero == null or hero.health == null or hero.health.is_dead():
			continue
		var distance := global_position.distance_to(hero.global_position)
		if distance < best_distance:
			best_distance = distance
			best = hero
	return best
