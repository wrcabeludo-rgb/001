class_name Kamikaze
extends Enemy
## A small rolling bomb: it rolls at the nearest hero, and close up it starts
## blinking and explodes a moment later, hurting heroes and robots alike.
## A strong blow (a kick, the sword's finisher) knocks it back like a ball —
## it then blows up on the first wall or robot it hits.

const BLAST_RADIUS := 120.0
const HERO_DAMAGE := 3
const ROBOT_DAMAGE := 8
## A hit pushing at least this hard bats the bomb away instead of hurting it.
const BAT_KNOCKBACK := 600.0

@export var roll_speed := 250.0
@export var sight := 700.0
@export var fuse_time := 0.8

var armed := false

var _fuse := 0.0
var _batted := 0.0
var _exploded := false


func _init() -> void:
	max_health = 3
	body_size = Vector2(44, 44)
	color = ROBOT_COLOR.lerp(Color(0.8, 0.3, 0.2), 0.4)
	contact_damage = 0
	art = "kamikaze"
	art_height = 64.0
	health_drop_chance = 0.0
	ammo_drop_chance = 0.15
	scrap_min = 0
	scrap_max = 1


func receive_hit(hit: Hit) -> bool:
	if not is_alive():
		return false
	if hit.knockback.length() >= BAT_KNOCKBACK:
		# Batted away: it flies off and goes off on impact.
		_batted = 1.5
		velocity = hit.knockback * 1.1
		velocity.y = minf(velocity.y, -350.0)
		_arm(1.5)
		_flash_timer = 0.1
		Sound.play("kick", 0.05, 0.0, 1.4)
		return true
	return super.receive_hit(hit)


func _arm(fuse: float) -> void:
	if not armed:
		armed = true
		_fuse = fuse
		telegraph(fuse)
		Sound.play("charge_ready", 0.0, -2.0, 1.6)


func _physics_process(delta: float) -> void:
	if not is_alive():
		return
	if _batted > 0.0:
		_batted -= delta
		_fuse -= delta
		velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)
		move_and_slide()
		_update_look()
		if _fuse <= 0.0 or is_on_wall() or _robot_close():
			explode()
		return
	super._physics_process(delta)


func _think(delta: float) -> void:
	if armed:
		_fuse -= delta
		velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
		if _fuse <= 0.0:
			explode()
		return
	var hero := nearest_hero(sight)
	if hero == null:
		velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
		return
	facing = 1 if hero.global_position.x >= global_position.x else -1
	velocity.x = move_toward(velocity.x, facing * roll_speed, 900.0 * delta)
	if global_position.distance_to(hero.global_position) < 90.0:
		_arm(fuse_time)


func _robot_close() -> bool:
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy != null and enemy != self and enemy.is_alive() \
				and enemy.global_position.distance_to(global_position) < 70.0:
			return true
	return false


## The blast hurts everyone close: heroes a little, robots a lot.
func explode() -> void:
	if _exploded:
		return
	_exploded = true
	Fx.explosion(get_parent(), global_position, BLAST_RADIUS * 0.6)
	Sound.play("explosion", 0.1, -2.0)
	get_tree().call_group("cameras", "shake", 6.0)
	for hurtbox in Harm.hurtboxes_in_circle(get_world_2d(), global_position, BLAST_RADIUS, Harm.EVERYONE):
		if hurtbox.receiver == self:
			continue
		var push := (hurtbox.global_position - global_position).normalized() * 600.0 + Vector2(0, -300)
		var damage := HERO_DAMAGE if hurtbox.receiver is Player else ROBOT_DAMAGE
		hurtbox.take_hit(Hit.make(damage, push, global_position))
	if is_alive():
		health.damage(health.current)


func _on_died() -> void:
	if not _exploded:
		explode()
	super._on_died()


## No corpse: it is blown to bits.
func _leave_corpse() -> void:
	pass


