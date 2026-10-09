class_name ShooterCombat
extends HeroCombat
## The Gunner. Attack: a shot in one of 8 directions (tap again to keep firing).
## Hold attack and release after charge_time: a piercing charged shot that costs ammo.
## Skill: a short kick that pushes enemies away.
## Extra: switch weapons (the shotgun is bought in the shop): five pellets in
## a fan, short range, one ammo per shot; without ammo it fires the rifle.
## The flamethrower (also from the shop): hold attack for a jet of fire that
## goes through enemies and sets them burning; it burns one ammo every quarter
## second.

const SHOT_COLOR := Color(0.3, 0.95, 1.0)
const CHARGED_COLOR := Color(0.7, 1.0, 1.0)
## Shots leave the gun this far from the hero's centre.
const MUZZLE_DISTANCE := 44.0
const MUZZLE_HEIGHT := -36.0
## Crouching, the gun is held at knee height: low enough for small enemies.
const CROUCH_MUZZLE_HEIGHT := 2.0

var ammo := 0
## "rifle", "shotgun" or "flamer".
var weapon := "rifle"

const SHOTGUN_PELLETS := 5
const SHOTGUN_SPREAD := 0.5
const SHOTGUN_COOLDOWN := 0.5
const SHOTGUN_LIFETIME := 0.22

## The flamethrower's jet: how far it reaches, how often it licks the enemies
## in it, how long they burn afterwards, how long one ammo lasts.
const FLAME_RANGE := 300.0
const FLAME_WIDTH := 70.0
const FLAME_TICK := 0.25
const FLAME_DAMAGE := 1
const FLAME_BURN := 3.0
const FLAME_FUEL_TIME := 0.25

var _fire_cooldown := 0.0
var _kick_cooldown := 0.0
var _charge := 0.0
var _kick: Hitbox
var _flame: Hitbox
var _jet: CPUParticles2D
var _flame_tick := 0.0
var _fuel_timer := 0.0


func setup(p_player: Player) -> void:
	super.setup(p_player)
	ammo = max_ammo() if SaveGame.has_item(player.hero, "pouch") else stats.start_ammo
	weapon = SaveGame.weapon(player.hero)
	if not weapon in ShopItems.owned_weapons(player.hero):
		weapon = "rifle"
	_kick = Hitbox.new()
	add_child(_kick)
	_kick.setup(Layers.Team.PLAYERS, Vector2(62, 48), Vector2(52, 12), SHOT_COLOR)
	_kick.show_flash = false
	_kick.landed.connect(func(_target: Hurtbox) -> void: player.hitstop())
	_flame = Hitbox.new()
	add_child(_flame)
	_flame.setup(Layers.Team.PLAYERS, Vector2(FLAME_RANGE, FLAME_WIDTH), Vector2(FLAME_RANGE / 2.0, 0), SHOT_COLOR)
	_flame.show_flash = false
	_flame.burn = FLAME_BURN


func update(delta: float) -> void:
	_fire_cooldown -= delta
	_kick_cooldown -= delta
	var input := player.input
	if player.is_stunned():
		_charge = 0.0
		_update_flamer(delta, false)
		return

	if input.just_pressed("extra") and not input.is_held("down"):
		_switch_weapon()
	var flamer := weapon == "flamer" and ammo > 0
	_update_flamer(delta, flamer and input.is_held("attack"))
	if input.just_pressed("attack") and _fire_cooldown <= 0.0 and not flamer:
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
				stats.charged_pierce, ProjectileLook.Style.PLASMA)
			Sound.play("shoot_charged")
		_charge = 0.0

	if input.just_pressed("skill") and _kick_cooldown <= 0.0:
		_kick_cooldown = stats.kick_cooldown
		_kick.activate(0.12, roundi(stats.kick_damage * player.damage_multiplier()),
			Vector2(stats.kick_knockback, -320), player.facing)
		player.animate_kick()
		var swoosh := SlashArc.make(42, 12, 1.4, -0.3, Color(0.75, 0.9, 1.0), player.facing, 0.2)
		swoosh.position = Vector2(player.facing * 22, -10)
		add_child(swoosh)
		Sound.play("kick")


func muzzle_height() -> float:
	return CROUCH_MUZZLE_HEIGHT if player.crouching else MUZZLE_HEIGHT


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


func _shoot(damage: int, knockback: float, size: Vector2, color: Color, pierce: int,
		style := ProjectileLook.Style.BOLT) -> void:
	var direction := aim_direction()
	var start := player.global_position + Vector2(0, muzzle_height()) + direction * MUZZLE_DISTANCE
	_fire(start, direction, damage, knockback, size, color, pierce, stats.shot_lifetime, style)


func _fire(start: Vector2, direction: Vector2, damage: int, knockback: float, size: Vector2, color: Color,
		pierce: int, lifetime: float, style := ProjectileLook.Style.BOLT) -> void:
	player.animate_attack(2.2 if style == ProjectileLook.Style.PELLET else 1.0)
	var projectile := Projectile.new()
	projectile.setup(Layers.Team.PLAYERS, start, direction, stats.shot_speed,
		roundi(damage * player.damage_multiplier()), knockback, size, color, pierce, lifetime)
	projectile.style = style
	player.get_parent().add_child(projectile)
	if style != ProjectileLook.Style.PELLET:
		_muzzle_flash(start, color)


## A short flash of light at the end of the barrel.
func _muzzle_flash(at: Vector2, color: Color) -> void:
	var flash := Fx.Flare.new()
	flash.position = at
	flash.radius = 26.0
	flash.life = 0.08
	flash.color = color.lightened(0.3)
	player.get_parent().add_child(flash)


func _shotgun() -> void:
	var direction := aim_direction()
	var start := player.global_position + Vector2(0, muzzle_height()) + direction * MUZZLE_DISTANCE
	for i in SHOTGUN_PELLETS:
		var angle := (float(i) / (SHOTGUN_PELLETS - 1) - 0.5) * SHOTGUN_SPREAD
		_fire(start, direction.rotated(angle), stats.shot_damage, stats.shot_knockback * 2.0,
			Vector2(14, 8), SHOT_COLOR, 0, SHOTGUN_LIFETIME, ProjectileLook.Style.PELLET)
	Sound.play("shotgun", 0.08)
	# A big orange flash, a puff of smoke and a spent shell flying out.
	var flash := Fx.Flare.new()
	flash.position = start
	flash.radius = 60.0
	flash.life = 0.1
	flash.color = Color(1.0, 0.7, 0.3)
	player.get_parent().add_child(flash)
	Fx.burst(player.get_parent(), start, [Color(0.6, 0.58, 0.55, 0.5), Color(0.4, 0.4, 0.4, 0.0)], 8, 120.0, 12.0,
		0.6, -80.0, false, direction, 30.0)
	Fx.burst(player.get_parent(), start - direction * 30.0, [Color(0.9, 0.3, 0.15), Color(0.6, 0.2, 0.1, 0.0)], 1,
		260.0, 5.0, 0.6, 1400.0, false, Vector2(-direction.x * 0.5, -1.0), 15.0)


## The jet of fire while attack is held: it follows the aim, licks everything
## in front of the barrel and burns ammo.
func _update_flamer(delta: float, on: bool) -> void:
	if not on:
		if _jet != null:
			_jet.emitting = false
		_flame_tick = 0.0
		_fuel_timer = 0.0
		return
	if _jet == null:
		_jet = _make_jet()
	var direction := aim_direction()
	var start := player.global_position + Vector2(0, muzzle_height()) + direction * MUZZLE_DISTANCE
	_jet.global_position = start
	_jet.direction = direction
	_jet.emitting = true
	_flame.global_position = start
	_flame.rotation = direction.angle()
	_fuel_timer -= delta
	if _fuel_timer <= 0.0:
		_fuel_timer += FLAME_FUEL_TIME
		ammo -= 1
		player.animate_attack(0.5)
		Sound.play("flamer", 0.06)
		if ammo <= 0:
			ammo = 0
			_jet.emitting = false
			_out_of_shells()
			return
	_flame_tick -= delta
	if _flame_tick <= 0.0:
		_flame_tick = FLAME_TICK
		_flame.activate(0.06, roundi(FLAME_DAMAGE * player.damage_multiplier()), Vector2.ZERO, 1)


## Tongues of fire: white-hot at the nozzle, swelling into orange and red,
## then a little smoke. They stay in the world, so the jet bends as the hero moves.
func _make_jet() -> CPUParticles2D:
	var jet := CPUParticles2D.new()
	jet.amount = 48
	jet.lifetime = 0.36
	jet.local_coords = false
	jet.spread = 7.0
	jet.initial_velocity_min = 560.0
	jet.initial_velocity_max = 640.0
	jet.damping_min = 700.0
	jet.damping_max = 850.0
	jet.gravity = Vector2(0, -320)
	jet.scale_amount_min = 20.0
	jet.scale_amount_max = 28.0
	jet.scale_amount_curve = Curve.new()
	jet.scale_amount_curve.add_point(Vector2(0, 0.25))
	jet.scale_amount_curve.add_point(Vector2(0.5, 0.85))
	jet.scale_amount_curve.add_point(Vector2(1, 1.0))
	jet.color_ramp = Fx.ramp([Color(1, 1, 0.85), Color(1.0, 0.75, 0.25), Color(1.0, 0.4, 0.08),
		Color(0.75, 0.12, 0.04, 0.6), Color(0.15, 0.12, 0.12, 0.0)])
	jet.material = Fx.additive()
	jet.z_index = 3
	jet.emitting = false
	add_child(Fx.soften(jet))
	return jet


## The shotgun or the flamethrower ran dry: back to the rifle (which never runs out).
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
