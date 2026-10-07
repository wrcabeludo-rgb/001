class_name SwordsmanCombat
extends HeroCombat
## The Swordsman. Attack: a combo of three slashes (the third is stronger and
## knocks back hard); up + attack: a slash above. Extra (hold): block, which
## cuts damage and knockback from the front but slows the hero down.
## The heavy blade (bought in the shop, chosen there) hits harder and further
## but swings slower. Crouching, the slashes go low.
## Each swing looks different: a downward cut, a rising cut, then a big
## sweeping finisher; up + attack sweeps over the head.

const SLASH_COLOR := Color(1.0, 0.55, 0.2)
const HEAVY_SLASH_COLOR := Color(1.0, 0.38, 0.12)
## How much lower the slashes go while crouching.
const CROUCH_DROP := 26.0

var blocking := false
var heavy := false

const HEAVY_DAMAGE := 1.6
const HEAVY_SWING := 1.35

var _step := 0
var _swing_timer := 0.0
var _combo_timer := 0.0
var _queued := false
var _slash: Hitbox
var _up_slash: Hitbox
var _shield: GuardShield
var _slash_height := 0.0
var _embers: CPUParticles2D


func setup(p_player: Player) -> void:
	super.setup(p_player)
	heavy = SaveGame.weapon(player.hero) == "heavy" and SaveGame.has_item(player.hero, "heavy_blade")
	_slash = Hitbox.new()
	add_child(_slash)
	if heavy:
		_slash.setup(Layers.Team.PLAYERS, Vector2(124, 86), Vector2(76, -6), SLASH_COLOR)
	else:
		_slash.setup(Layers.Team.PLAYERS, Vector2(96, 76), Vector2(62, -6), SLASH_COLOR)
	_slash_height = _slash.offset.y
	_up_slash = Hitbox.new()
	add_child(_up_slash)
	_up_slash.setup(Layers.Team.PLAYERS, Vector2(84, 80), Vector2(0, -88), SLASH_COLOR)
	for hitbox in [_slash, _up_slash]:
		hitbox.show_flash = false
		hitbox.landed.connect(func(_target: Hurtbox) -> void: player.hitstop())

	if heavy:
		_add_embers()
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
	return roundi(base * (HEAVY_DAMAGE if heavy else 1.0) * player.damage_multiplier())


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
	var size := 1.15 if heavy else 1.0
	var color := HEAVY_SLASH_COLOR if heavy else SLASH_COLOR
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
	return 0.78 if heavy else 1.0


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
