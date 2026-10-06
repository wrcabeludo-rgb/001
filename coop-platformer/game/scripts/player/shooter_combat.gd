class_name ShooterCombat
extends HeroCombat
## The Gunner. Attack: a shot in one of 8 directions (tap again to keep firing).
## Hold attack and release after charge_time: a piercing charged shot that costs ammo.
## Skill: a short kick that pushes enemies away.
## Extra: switch weapons (the shotgun is bought in the shop): five pellets in
## a fan, short range, one ammo per shot; without ammo it fires the rifle.

const SHOT_COLOR := Color(0.3, 0.95, 1.0)
const CHARGED_COLOR := Color(0.7, 1.0, 1.0)
## Shots leave the gun this far from the hero's centre.
const MUZZLE_DISTANCE := 44.0
const MUZZLE_HEIGHT := -36.0

var ammo := 0
## "rifle" or "shotgun".
var weapon := "rifle"

const SHOTGUN_PELLETS := 5
const SHOTGUN_SPREAD := 0.5
const SHOTGUN_COOLDOWN := 0.5
const SHOTGUN_LIFETIME := 0.22

var _fire_cooldown := 0.0
var _kick_cooldown := 0.0
var _charge := 0.0
var _kick: Hitbox


func setup(p_player: Player) -> void:
	super.setup(p_player)
	ammo = max_ammo() if SaveGame.has_item(player.hero, "pouch") else stats.start_ammo
	weapon = SaveGame.weapon(player.hero)
	if not weapon in ShopItems.owned_weapons(player.hero):
		weapon = "rifle"
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

	if input.just_pressed("extra") and not input.is_held("down"):
		_switch_weapon()
	if input.just_pressed("attack") and _fire_cooldown <= 0.0:
		if weapon == "shotgun" and ammo > 0:
			_fire_cooldown = SHOTGUN_COOLDOWN
			ammo -= 1
			_shotgun()
			if ammo == 0:
				_out_of_shells()
		else:
			_fire_cooldown = stats.fire_cooldown
			_shoot(stats.shot_damage, stats.shot_knockback, Vector2(18, 8), SHOT_COLOR, 0)
			Sound.play("shoot")
	# Only the rifle charges: with the shotgun every press is just a blast.
	if input.is_held("attack") and weapon == "rifle":
		var was_charged := is_charged()
		_charge += delta
		if is_charged() and not was_charged:
			Sound.play("charge_ready", 0.0)
	if input.just_released("attack"):
		if is_charged() and weapon == "rifle":
			ammo -= stats.charged_cost
			_shoot(stats.charged_damage, stats.charged_knockback, Vector2(46, 22), CHARGED_COLOR,
				stats.charged_pierce)
			Sound.play("shoot_charged")
		_charge = 0.0

	if input.just_pressed("skill") and _kick_cooldown <= 0.0:
		_kick_cooldown = stats.kick_cooldown
		_kick.activate(0.12, roundi(stats.kick_damage * player.damage_multiplier()),
			Vector2(stats.kick_knockback, -320), player.facing)
		Sound.play("kick")


func is_charged() -> bool:
	return _charge >= charge_time() and ammo >= stats.charged_cost


func charge_time() -> float:
	return stats.charge_time * (0.6 if SaveGame.has_item(player.hero, "quick_charge") else 1.0)


func max_ammo() -> int:
	return stats.max_ammo + (20 if SaveGame.has_item(player.hero, "pouch") else 0)


func is_glowing() -> bool:
	return is_charged()


func add_ammo(amount: int) -> void:
	ammo = mini(max_ammo(), ammo + amount)


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
	_fire(start, direction, damage, knockback, size, color, pierce, stats.shot_lifetime)


func _fire(start: Vector2, direction: Vector2, damage: int, knockback: float, size: Vector2, color: Color,
		pierce: int, lifetime: float) -> void:
	player.animate_attack()
	var projectile := Projectile.new()
	projectile.setup(Layers.Team.PLAYERS, start, direction, stats.shot_speed,
		roundi(damage * player.damage_multiplier()), knockback, size, color, pierce, lifetime)
	player.get_parent().add_child(projectile)


func _shotgun() -> void:
	var direction := aim_direction()
	var start := player.global_position + Vector2(0, MUZZLE_HEIGHT) + direction * MUZZLE_DISTANCE
	for i in SHOTGUN_PELLETS:
		var angle := (float(i) / (SHOTGUN_PELLETS - 1) - 0.5) * SHOTGUN_SPREAD
		_fire(start, direction.rotated(angle), stats.shot_damage, stats.shot_knockback * 2.0,
			Vector2(14, 8), SHOT_COLOR, 0, SHOTGUN_LIFETIME)
	Sound.play("shoot_charged", 0.08, -4.0)


## The shotgun ran dry: back to the rifle (which never runs out).
func _out_of_shells() -> void:
	weapon = "rifle"
	_charge = 0.0
	var level := player.get_parent() as Level
	if level != null:
		level.show_toast("P%d: патроны кончились — винтовка" % (player.slot + 1))


func _switch_weapon() -> void:
	var owned := ShopItems.owned_weapons(player.hero)
	if owned.size() < 2:
		return
	weapon = owned[(owned.find(weapon) + 1) % owned.size()]
	_charge = 0.0
	SaveGame.set_weapon(player.hero, weapon)
	Sound.play("menu_move", 0.0)
