class_name SwordsmanCombat
extends HeroCombat
## The Swordsman. Attack: a combo of three slashes (the third is stronger and
## knocks back hard); up + attack: a slash above. Extra (hold): block, which
## cuts damage and knockback from the front but slows the hero down.

const SLASH_COLOR := Color(1.0, 0.55, 0.2)
const SHIELD_COLOR := Color(1.0, 0.65, 0.3, 0.85)

var blocking := false

var _step := 0
var _swing_timer := 0.0
var _combo_timer := 0.0
var _queued := false
var _slash: Hitbox
var _up_slash: Hitbox
var _shield: ColorRect


func setup(p_player: Player) -> void:
	super.setup(p_player)
	_slash = Hitbox.new()
	add_child(_slash)
	_slash.setup(Layers.Team.PLAYERS, Vector2(96, 76), Vector2(62, -6), SLASH_COLOR)
	_up_slash = Hitbox.new()
	add_child(_up_slash)
	_up_slash.setup(Layers.Team.PLAYERS, Vector2(84, 80), Vector2(0, -88), SLASH_COLOR)
	for hitbox in [_slash, _up_slash]:
		hitbox.landed.connect(func(_target: Hurtbox) -> void: player.hitstop())

	_shield = ColorRect.new()
	_shield.size = Vector2(10, Player.SIZE.y + 10)
	_shield.color = SHIELD_COLOR
	_shield.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
		hit.damage = roundi(hit.damage * stats.block_damage_multiplier)
		hit.knockback *= stats.block_knockback_multiplier
		hit.blocked = true
	return hit


func _swing() -> void:
	_swing_timer = stats.swing_time
	if player.input.is_held("up"):
		_up_slash.activate(stats.swing_time, stats.up_slash_damage, Vector2(0, -stats.slash_knockback), 1)
		Sound.play("slash")
		return
	if _combo_timer <= 0.0:
		_step = 0
	var damages := [stats.slash1_damage, stats.slash2_damage, stats.slash3_damage]
	var finisher := _step == 2
	var push := Vector2(stats.finisher_knockback, -320) if finisher else Vector2(stats.slash_knockback, -150)
	_slash.activate(stats.swing_time, damages[_step], push, player.facing)
	Sound.play("slash_heavy" if finisher else "slash")
	_step = (_step + 1) % 3
	_combo_timer = stats.swing_time + stats.combo_window


func _update_shield() -> void:
	_shield.visible = blocking
	_shield.position = Vector2(player.facing * (Player.SIZE.x / 2 + 8) - _shield.size.x / 2, -_shield.size.y / 2)
