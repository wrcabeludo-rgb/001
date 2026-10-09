class_name SwordsmanCombat
extends HeroCombat
## The Swordsman. Attack: a combo of three slashes (the third is stronger and
## knocks back hard); up + attack: a slash above. Extra (hold): block, which
## cuts damage and knockback from the front but slows the hero down.
## The heavy blade (bought in the shop, chosen there) hits harder and further
## but swings slower. The shock baton (also from the shop) hits a little
## weaker and shorter, but every hit stuns with electricity, and the third
## blow of the combo jumps to the nearest other enemy. Crouching, the slashes go low.
## Each swing looks different: a downward cut, a rising cut, then a big
## sweeping finisher; up + attack sweeps over the head.

const SLASH_COLOR := Color(1.0, 0.55, 0.2)
const HEAVY_SLASH_COLOR := Color(1.0, 0.38, 0.12)
## How much lower the slashes go while crouching.
const CROUCH_DROP := 26.0

var blocking := false
## "blade", "heavy" or "shock".
var weapon := "blade"
var heavy := false
var shocking := false

const HEAVY_DAMAGE := 1.6
const HEAVY_SWING := 1.35
const SHOCK_DAMAGE := 0.8
## Seconds an enemy stays stunned after a hit of the shock baton.
const SHOCK_STUN := 2.0
## How far the finisher's discharge jumps to the next enemy.
const CHAIN_RANGE := 200.0

var _step := 0
var _swing_timer := 0.0
var _combo_timer := 0.0
var _queued := false
var _slash: Hitbox
var _up_slash: Hitbox
var _shield: GuardShield
var _slash_height := 0.0
var _embers: CPUParticles2D
var _crackle: Electric.Sparks
## The finisher of the shock baton is swinging: its first hit jumps on.
var _chain_ready := false


func setup(p_player: Player) -> void:
	super.setup(p_player)
	weapon = SaveGame.weapon(player.hero)
	if not weapon in ShopItems.owned_weapons(player.hero):
		weapon = "blade"
	heavy = weapon == "heavy"
	shocking = weapon == "shock"
	_slash = Hitbox.new()
	add_child(_slash)
	if heavy:
		_slash.setup(Layers.Team.PLAYERS, Vector2(124, 86), Vector2(76, -6), SLASH_COLOR)
	elif shocking:
		_slash.setup(Layers.Team.PLAYERS, Vector2(88, 72), Vector2(56, -6), SLASH_COLOR)
	else:
		_slash.setup(Layers.Team.PLAYERS, Vector2(96, 76), Vector2(62, -6), SLASH_COLOR)
	_slash_height = _slash.offset.y
	_up_slash = Hitbox.new()
	add_child(_up_slash)
	_up_slash.setup(Layers.Team.PLAYERS, Vector2(84, 80), Vector2(0, -88), SLASH_COLOR)
	for hitbox in [_slash, _up_slash]:
		hitbox.show_flash = false
		hitbox.shock = SHOCK_STUN if shocking else 0.0
		hitbox.landed.connect(_on_landed)

	if heavy:
		_add_embers()
	if shocking:
		_crackle = Electric.Sparks.new()
		_crackle.size = Vector2(40, 30)
		_crackle.strength = 0.3
		add_child(_crackle)
	_shield = GuardShield.new()
	_shield.visible = false
	add_child(_shield)


func update(delta: float) -> void:
	_swing_timer -= delta
	_combo_timer -= delta
	var input := player.input
	if player.is_stunned():
		blocking = false
		_queued = false
		_update_shield()
		return

	var swinging := _swing_timer > 0.0
	blocking = input.is_held("extra") and not swinging
	if not blocking:
		if input.just_pressed("attack"):
			if swinging:
				_queued = true
			else:
				_swing()
		elif _queued and not swinging:
			_queued = false
			_swing()
	_update_shield()


func speed_multiplier() -> float:
	return stats.block_speed_multiplier if blocking else 1.0


func modify_hit(hit: Hit) -> Hit:
	var from_front := signf(hit.source_position.x - player.global_position.x) == float(player.facing)
	if blocking and from_front:
		var guard := 0.1 if SaveGame.has_item(player.hero, "iron_block") else stats.block_damage_multiplier
		hit.damage = roundi(hit.damage * guard)
		hit.knockback *= stats.block_knockback_multiplier
		hit.blocked = true
		_shield.flare()
	return hit


func is_blocking() -> bool:
	return blocking


func _damage(base: int) -> int:
	var multiplier := HEAVY_DAMAGE if heavy else (SHOCK_DAMAGE if shocking else 1.0)
	return roundi(base * multiplier * player.damage_multiplier())


## A blow landed: a short freeze; the shock baton also crackles and, on the
## finisher, the discharge jumps to the nearest other enemy.
func _on_landed(target: Hurtbox) -> void:
	player.hitstop()
	if not shocking:
		return
	var at := target.global_position
	Fx.burst(player.get_parent(), at, [Electric.CORE, Electric.COLOR, Color(Electric.COLOR, 0.0)], 14, 420.0, 3.0,
		0.25, 0.0)
	Sound.play("shock", 0.05)
	if _chain_ready:
		_chain_ready = false
		_chain(target.receiver as Enemy, at)


func _chain(from: Enemy, at: Vector2) -> void:
	var best: Enemy = null
	var best_distance := CHAIN_RANGE
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy == null or enemy == from or not enemy.is_alive():
			continue
		var distance := at.distance_to(enemy.global_position)
		if distance < best_distance:
			best_distance = distance
			best = enemy
	if best == null:
		return
	var arc := Electric.Arc.new()
	arc.to = best.global_position - at
	arc.position = at
	arc.life = 0.3
	player.get_parent().add_child(arc)
	var side := signf(best.global_position.x - at.x)
	var hit := Hit.make(_damage(stats.slash1_damage), Vector2(side * stats.slash_knockback, -150), at)
	hit.shock = SHOCK_STUN
	best.receive_hit(hit)


func _swing() -> void:
	var swing_time := stats.swing_time * (HEAVY_SWING if heavy else 1.0)
	_swing_timer = swing_time
	if player.input.is_held("up") and not player.crouching:
		_up_slash.activate(swing_time, _damage(stats.up_slash_damage), Vector2(0, -stats.slash_knockback), 1)
		player.animate_slash(HeroRig.Slash.OVERHEAD, swing_time)
		_trail(HeroRig.Slash.OVERHEAD, swing_time)
		Sound.play("slash", 0.06, 0.0, _sound_pitch())
		return
	if _combo_timer <= 0.0:
		_step = 0
	var damages := [stats.slash1_damage, stats.slash2_damage, stats.slash3_damage]
	var finisher := _step == 2
	_chain_ready = finisher and shocking
	var push := Vector2(stats.finisher_knockback, -320) if finisher else Vector2(stats.slash_knockback, -150)
	_slash.offset.y = _slash_height + (CROUCH_DROP if player.crouching else 0.0)
	_slash.activate(swing_time, _damage(damages[_step]), push, player.facing)
	var kind: int = [HeroRig.Slash.DOWN, HeroRig.Slash.RISING, HeroRig.Slash.FINISHER][_step]
	player.animate_slash(kind, swing_time)
	_trail(kind, swing_time)
	if finisher:
		get_tree().call_group("cameras", "shake", 5.0 if heavy else 3.0)
	Sound.play("slash_heavy" if finisher else "slash", 0.06, 0.0, _sound_pitch())
	_step = (_step + 1) % 3
	_combo_timer = swing_time + stats.combo_window


## The blade's trail for a swing; the heavy blade leaves a wider, redder one.
func _trail(kind: int, swing_time: float) -> void:
	var size := 1.15 if heavy else (0.92 if shocking else 1.0)
	var color := HEAVY_SLASH_COLOR if heavy else (Electric.COLOR if shocking else SLASH_COLOR)
	var low := CROUCH_DROP if player.crouching else 0.0
	var life := maxf(0.2, swing_time * 1.1)
	var arc: SlashArc
	match kind:
		HeroRig.Slash.DOWN:
			arc = SlashArc.make(54 * size, 12 * size, -1.4, 0.85, color, player.facing, life)
			arc.position = Vector2(player.facing * 6, -26 + low)
		HeroRig.Slash.RISING:
			arc = SlashArc.make(52 * size, 11 * size, 0.85, -1.35, color, player.facing, life)
			arc.position = Vector2(player.facing * 8, -22 + low)
		HeroRig.Slash.FINISHER:
			arc = SlashArc.make(64 * size, 20 * size, -2.3, 1.1, color.lightened(0.15), player.facing, life * 1.3)
			arc.position = Vector2(player.facing * 8, -26 + low)
		_:
			arc = SlashArc.make(48 * size, 13 * size, 0.3, -3.4, color, player.facing, life)
			arc.position = Vector2(0, -44)
	add_child(arc)


## The heavy blade sounds lower and heavier.
func _sound_pitch() -> float:
	return 0.78 if heavy else (1.12 if shocking else 1.0)


func _update_shield() -> void:
	_shield.visible = blocking
	_shield.scale.x = player.facing
	_shield.position = Vector2(player.facing * 4.0, -14.0 + (CROUCH_DROP * 0.6 if player.crouching else 0.0))


## The heavy blade is so hot it drips embers (low in front of the hero, where the blade hangs).
func _add_embers() -> void:
	var embers := CPUParticles2D.new()
	embers.amount = 10
	embers.lifetime = 0.8
	embers.local_coords = false
	embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	embers.emission_rect_extents = Vector2(18, 10)
	embers.direction = Vector2.DOWN
	embers.spread = 30.0
	embers.initial_velocity_min = 10.0
	embers.initial_velocity_max = 50.0
	embers.gravity = Vector2(0, 240)
	embers.scale_amount_min = 2.0
	embers.scale_amount_max = 4.0
	embers.color_ramp = Fx.ramp([Color(1, 0.9, 0.5), Color(1.0, 0.35, 0.08), Color(0.6, 0.1, 0.05, 0.0)])
	embers.material = Fx.additive()
	add_child(Fx.soften(embers))
	_embers = embers


func _process(_delta: float) -> void:
	if _embers != null:
		_embers.position = Vector2(player.facing * 34.0, 28.0)
	if _crackle != null:
		_crackle.position = Vector2(player.facing * 34.0, 18.0)
		# Brighter for a moment after each swing.
		_crackle.strength = 0.9 if _swing_timer > 0.0 else 0.3
