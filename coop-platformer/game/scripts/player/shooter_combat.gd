class_name ShooterCombat
extends HeroCombat
## The Gunner. Attack: a shot in one of 8 directions (tap again to keep firing).
## Hold attack and release after charge_time: a piercing charged shot that costs ammo.
## Skill: a short kick that pushes enemies away.

const SHOT_COLOR := Color(0.3, 0.95, 1.0)
const CHARGED_COLOR := Color(0.7, 1.0, 1.0)
## Shots leave the gun this far from the hero's centre.
const MUZZLE_DISTANCE := 34.0
const MUZZLE_HEIGHT := -12.0

var ammo := 0

var _fire_cooldown := 0.0
var _kick_cooldown := 0.0
var _charge := 0.0
var _kick: Hitbox


func setup(p_player: Player) -> void:
	super.setup(p_player)
	ammo = stats.start_ammo
	_kick = Hitbox.new()
	add_child(_kick)
	_kick.setup(Layers.Team.PLAYERS, Vector2(62, 48), Vector2(52, 12), SHOT_COLOR)
	_kick.landed.connect(func(_target: Hurtbox) -> void: player.hitstop())


func update(delta: float) -> void:
	_fire_cooldown -= delta
	_kick_cooldown -= delta
	var input := player.input
	if player.is_stunned():
		_charge = 0.0
		return

	if input.just_pressed("attack") and _fire_cooldown <= 0.0:
		_fire_cooldown = stats.fire_cooldown
		_shoot(stats.shot_damage, stats.shot_knockback, Vector2(18, 8), SHOT_COLOR, 0)
	if input.is_held("attack"):
		_charge += delta
	if input.just_released("attack"):
		if is_charged():
			ammo -= stats.charged_cost
			_shoot(stats.charged_damage, stats.charged_knockback, Vector2(46, 22), CHARGED_COLOR,
				stats.charged_pierce)
		_charge = 0.0

	if input.just_pressed("skill") and _kick_cooldown <= 0.0:
		_kick_cooldown = stats.kick_cooldown
		_kick.activate(0.12, stats.kick_damage, Vector2(stats.kick_knockback, -320), player.facing)


func is_charged() -> bool:
	return _charge >= stats.charge_time and ammo >= stats.charged_cost


func is_glowing() -> bool:
	return is_charged()


func add_ammo(amount: int) -> void:
	ammo = mini(stats.max_ammo, ammo + amount)


## Up/down and diagonals come from the direction held; nothing held = straight ahead.
## Standing on the ground, "down" is ignored so the hero never shoots the floor.
func aim_direction() -> Vector2:
	var aim := player.input.get_move()
	if player.is_on_floor() and aim.y > 0.0:
		aim.y = 0.0
	if aim == Vector2.ZERO:
		aim = Vector2(player.facing, 0)
	return aim.normalized()


func _shoot(damage: int, knockback: float, size: Vector2, color: Color, pierce: int) -> void:
	var direction := aim_direction()
	var start := player.global_position + Vector2(0, MUZZLE_HEIGHT) + direction * MUZZLE_DISTANCE
	var projectile := Projectile.new()
	projectile.setup(Layers.Team.PLAYERS, start, direction, stats.shot_speed, damage, knockback,
		size, color, pierce, stats.shot_lifetime)
	player.get_parent().add_child(projectile)
