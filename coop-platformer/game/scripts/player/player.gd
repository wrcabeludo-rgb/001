class_name Player
extends CharacterBody2D
## Placeholder hero (a coloured box) with the full platforming movement:
## acceleration, coyote time, jump buffering, variable jump height,
## wall slide and wall jump, double jump (shooter) and dash (swordsman),
## climbing ladders and ropes, dropping through one-way platforms (down + jump),
## crouching (down on the ground: stops, ducks under shots, attacks low).
## Attacks live in a HeroCombat child (ShooterCombat / SwordsmanCombat).
## Movement numbers live in MovementStats, combat numbers in CombatStats.

signal died(player: Player)

const SIZE := Vector2(48, 96)
## How far to probe sideways when looking for a wall to slide on.
const WALL_PROBE := 2.0
const HITSTOP_TIME := 0.05
const HITSTOP_SCALE := 0.05
## After jumping off a ladder or rope, it cannot be grabbed again for this long.
const REGRAB_TIME := 0.3
## How long one-way platforms are ignored after dropping through one.
const DROP_TIME := 0.22
## A crouching hero can be hit only this high above the floor.
const CROUCH_HEIGHT := 56.0

var slot := 0
var input: PlayerInput
var hero: Heroes.Id = Heroes.Id.SHOOTER
var stats: MovementStats
var combat_stats: CombatStats
var facing := 1
var health: Health
var combat: HeroCombat
## Where the hero last stood safely on the ground (partners respawn here).
var last_safe_position := Vector2.ZERO
## Scrap (money) collected in this zone; it joins the hero's saved wallet
## when the zone is finished.
var scrap := 0
## Temporary power-ups: name -> seconds left ("rage", "shield", "haste").
var powers := {}
## Down held on the ground: the hero stays put, lower, and attacks low.
var crouching := false

## How long each power-up lasts and how it shows on the hero.
const POWER_TIME := {"rage": 12.0, "shield": 10.0, "haste": 12.0}
const POWER_NAMES := {"rage": "Ярость ×2", "shield": "Щит", "haste": "Скорость"}
const POWER_COLORS := {"rage": Color(1.0, 0.3, 0.3), "shield": Color(0.5, 0.8, 1.0), "haste": Color(1.0, 0.95, 0.4)}

var _coyote_timer := 0.0
var _jump_buffer_timer := 0.0
var _wall_coyote_timer := 0.0
var _last_wall_dir := 0
var _wall_jump_lock_timer := 0.0
var _air_jumps_left := 0
var _air_dashes_left := 0
var _dash_timer := 0.0
var _dash_cooldown_timer := 0.0
## True while rising from a jump the player can still cut short.
var _jump_rising := false
var _stun_timer := 0.0
var _invulnerable_timer := 0.0
var _hurtbox: Hurtbox
var _collision: CollisionShape2D
## The ladder or rope the hero is holding, or null.
var _climb: Climbable
var _regrab_timer := 0.0
var _drop_timer := 0.0
var _wall_sliding := false
var _wall_dust: CPUParticles2D

var _body: ColorRect
var _aura: ColorRect
var _eye: ColorRect
## The drawn puppet (null until the hero has art; then the box is hidden).
var _rig: HeroRig


func setup(p_slot: int, p_input: PlayerInput, p_hero: Heroes.Id) -> void:
	slot = p_slot
	input = p_input
	set_hero(p_hero)


func set_hero(p_hero: Heroes.Id) -> void:
	hero = p_hero
	stats = Heroes.MOVEMENT[hero]
	combat_stats = Heroes.COMBAT[hero]
	if is_inside_tree():
		_build_combat()
		_apply_look()


func is_dashing() -> bool:
	return _dash_timer > 0.0


func is_stunned() -> bool:
	return _stun_timer > 0.0


func is_invulnerable() -> bool:
	return _invulnerable_timer > 0.0


## Health with the armour bought in the shop.
func max_health() -> int:
	return combat_stats.max_health + 2 * SaveGame.count_items(hero, ["armor1", "armor2"])


func has_power(power: String) -> bool:
	return powers.get(power, 0.0) > 0.0


func give_power(power: String) -> void:
	powers[power] = POWER_TIME.get(power, 10.0)


## Hero attacks deal this many times their damage ("rage" doubles it).
func damage_multiplier() -> float:
	return 2.0 if has_power("rage") else 1.0


## Scrap the hero has in total: saved plus collected in this zone.
func total_scrap() -> int:
	return SaveGame.scrap(hero) + scrap


func is_wall_sliding() -> bool:
	return _wall_sliding


func is_climbing() -> bool:
	return _climb != null


func is_alive() -> bool:
	return health != null and not health.is_dead()


## Instant death (falling out of the screen or into a pit).
func kill() -> void:
	if is_alive():
		health.damage(health.current)


## A dead hero is hidden and takes no part in the game until revived.
func set_active(active: bool) -> void:
	visible = active
	set_physics_process(active)
	_collision.set_deferred("disabled", not active)
	_hurtbox.set_deferred("monitorable", active)


## Called by a Hurtbox when an enemy attack lands. Returns true if it counted.
func receive_hit(hit: Hit) -> bool:
	# The Swordsman's dash passes through enemies and their attacks.
	if is_invulnerable() or is_dashing() or health.is_dead() or has_power("shield"):
		return false
	hit.damage = GameSettings.damage_to_heroes(hit.damage)
	hit = combat.modify_hit(hit)
	health.damage(hit.damage)
	Sound.play("block" if hit.blocked else ("death" if health.is_dead() else "hurt"))
	velocity = hit.knockback
	_dash_timer = 0.0
	_jump_rising = false
	_release_climb()
	_invulnerable_timer = combat_stats.hurt_invulnerability if not hit.blocked else 0.2
	if not hit.blocked:
		_stun_timer = combat_stats.hurt_stun
	return true


## Back to full health and control (respawn).
func revive(at: Vector2, invulnerable_time := 1.0) -> void:
	set_active(true)
	global_position = at
	last_safe_position = at
	velocity = Vector2.ZERO
	_stun_timer = 0.0
	_release_climb()
	_invulnerable_timer = invulnerable_time
	health.reset(max_health())


## A tiny freeze of the whole game when a melee hit lands, so it feels heavy.
func hitstop() -> void:
	PlayerManager.hitstop(HITSTOP_TIME, HITSTOP_SCALE)


func _ready() -> void:
	add_to_group("players")
	# Players stand on the world but pass through each other.
	collision_layer = Layers.PLAYER_BODIES
	collision_mask = Layers.GROUND

	var shape := RectangleShape2D.new()
	shape.size = SIZE
	_collision = CollisionShape2D.new()
	_collision.shape = shape
	add_child(_collision)
	last_safe_position = position

	# A glow around the hero while a power-up is active.
	_aura = Harm.box(-SIZE / 2 - Vector2(8, 8), SIZE + Vector2(16, 16), Color.TRANSPARENT)
	add_child(_aura)

	_body = ColorRect.new()
	_body.size = SIZE
	_body.position = -SIZE / 2
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_body)

	# A small dark square on the front side shows where the hero is facing.
	_eye = ColorRect.new()
	_eye.size = Vector2(10, 10)
	_eye.color = Color(0.1, 0.1, 0.15)
	_eye.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_eye)


	health = Health.new()
	add_child(health)
	health.died.connect(func() -> void: died.emit(self))
	_hurtbox = Hurtbox.new()
	add_child(_hurtbox)
	_hurtbox.setup(Layers.Team.PLAYERS, SIZE - Vector2(8, 8), self)

	_wall_dust = CPUParticles2D.new()
	_wall_dust.emitting = false
	_wall_dust.amount = 14
	_wall_dust.lifetime = 0.45
	_wall_dust.direction = Vector2(0, -1)
	_wall_dust.spread = 25.0
	_wall_dust.initial_velocity_min = 40.0
	_wall_dust.initial_velocity_max = 90.0
	_wall_dust.gravity = Vector2(0, 120)
	_wall_dust.scale_amount_min = 2.0
	_wall_dust.scale_amount_max = 4.0
	_wall_dust.color = Color(0.75, 0.7, 0.65, 0.6)
	add_child(_wall_dust)

	_build_combat()
	_apply_look()


func _physics_process(delta: float) -> void:
	if input == null:
		return

	var move := input.get_move()
	var on_floor := is_on_floor()
	var wall_dir := _get_wall_dir()

	_tick_timers(delta)
	crouching = false
	if is_stunned():
		_process_stun(on_floor, delta)
		return
	if on_floor:
		_coyote_timer = stats.coyote_time
		_air_jumps_left = stats.air_jumps
		_air_dashes_left = stats.air_dashes
	elif wall_dir != 0:
		_wall_coyote_timer = stats.wall_coyote_time
		_last_wall_dir = wall_dir
		_air_dashes_left = stats.air_dashes
	if input.just_pressed("jump"):
		_jump_buffer_timer = stats.jump_buffer

	if _climb == null and not is_dashing():
		_try_grab(move, on_floor)
	if _climb != null:
		_process_climb(move, delta)
		combat.update(delta)
		return

	if is_dashing():
		_process_dash(delta)
		combat.update(delta)
		return
	if stats.dash_enabled and input.just_pressed("skill") and _can_dash(on_floor):
		_start_dash(move, on_floor)
		_process_dash(delta)
		combat.update(delta)
		return

	if move.x != 0.0 and _wall_jump_lock_timer <= 0.0:
		facing = int(signf(move.x))

	crouching = on_floor and move.y > 0.5
	_apply_horizontal(0.0 if crouching else move.x, on_floor, delta)
	var sliding := _apply_gravity(move.x, on_floor, wall_dir, delta)
	if on_floor and move.y > 0.5 and _jump_buffer_timer > 0.0 and _on_one_way():
		_drop_through()
	_try_jump(on_floor)

	# Variable jump height: letting go of jump while rising cuts the jump short.
	if _jump_rising and not input.is_held("jump") and velocity.y < 0.0:
		velocity.y *= stats.jump_cut
		_jump_rising = false
	if velocity.y >= 0.0:
		_jump_rising = false

	var falling_speed := velocity.y
	move_and_slide()
	if is_on_floor():
		last_safe_position = global_position
		if not on_floor and falling_speed > 500.0:
			Sound.play("land")
	combat.update(delta)
	_update_look(sliding)


## Knocked back after a hit: no control, the push slowly fades.
func _process_stun(on_floor: bool, delta: float) -> void:
	_apply_gravity(0.0, on_floor, 0, delta)
	velocity.x = move_toward(velocity.x, 0.0, stats.ground_decel * 0.4 * delta)
	move_and_slide()
	combat.update(delta)
	_update_look(false)


func _build_combat() -> void:
	if combat != null:
		combat.queue_free()
	match hero:
		Heroes.Id.SHOOTER:
			combat = ShooterCombat.new()
		Heroes.Id.SWORDSMAN:
			combat = SwordsmanCombat.new()
	add_child(combat)
	combat.setup(self)
	health.reset(max_health())


func _tick_timers(delta: float) -> void:
	_stun_timer -= delta
	_invulnerable_timer -= delta
	_coyote_timer -= delta
	_jump_buffer_timer -= delta
	_wall_coyote_timer -= delta
	_wall_jump_lock_timer -= delta
	_dash_cooldown_timer -= delta
	_regrab_timer -= delta
	for power in powers.keys():
		powers[power] -= delta
		if powers[power] <= 0.0:
			powers.erase(power)
	if _drop_timer > 0.0:
		_drop_timer -= delta
		if _drop_timer <= 0.0 and _climb == null:
			collision_mask = Layers.GROUND


func _apply_horizontal(direction: float, on_floor: bool, delta: float) -> void:
	if _wall_jump_lock_timer > 0.0:
		return
	var accel: float
	if on_floor:
		accel = stats.ground_accel if direction != 0.0 else stats.ground_decel
	else:
		accel = stats.air_accel if direction != 0.0 else stats.air_decel
	var haste := 1.3 if has_power("haste") else 1.0
	var target := direction * stats.run_speed * combat.speed_multiplier() * haste
	velocity.x = move_toward(velocity.x, target, accel * delta)


## Applies gravity and wall sliding. Returns true while sliding down a wall.
func _apply_gravity(direction: float, on_floor: bool, wall_dir: int, delta: float) -> bool:
	if on_floor:
		return false
	var gravity := stats.rise_gravity()
	if velocity.y > 0.0:
		gravity *= stats.fall_gravity_multiplier
	velocity.y = minf(velocity.y + gravity * delta, stats.max_fall_speed)

	var pushing_into_wall := wall_dir != 0 and int(signf(direction)) == wall_dir
	if stats.wall_jump_enabled and pushing_into_wall and velocity.y > 0.0:
		velocity.y = minf(velocity.y, stats.wall_slide_speed)
		return true
	return false


## Ground jump has priority, then wall jump, then an air jump.
func _try_jump(on_floor: bool) -> void:
	if _jump_buffer_timer <= 0.0:
		return
	if on_floor or _coyote_timer > 0.0:
		_jump(stats.velocity_for_height(stats.jump_height))
		Sound.play("jump")
	elif stats.wall_jump_enabled and _wall_coyote_timer > 0.0:
		_jump(stats.velocity_for_height(stats.wall_jump_height))
		Sound.play("jump")
		velocity.x = -_last_wall_dir * stats.wall_jump_speed_x
		facing = -_last_wall_dir
		_wall_jump_lock_timer = stats.wall_jump_lock_time
	elif _air_jumps_left > 0:
		_air_jumps_left -= 1
		_jump(stats.velocity_for_height(stats.air_jump_height))
		Sound.play("double_jump")


func _jump(vertical_velocity: float) -> void:
	velocity.y = vertical_velocity
	_jump_rising = true
	_jump_buffer_timer = 0.0
	_coyote_timer = 0.0
	_wall_coyote_timer = 0.0


## Grabs a ladder with up (or down from its top), or a rope by jumping into it.
func _try_grab(move: Vector2, on_floor: bool) -> void:
	if _regrab_timer > 0.0 or is_stunned():
		return
	var feet := global_position + Vector2(0, SIZE.y / 2.0)
	for node in get_tree().get_nodes_in_group("climbables"):
		var climbable := node as Climbable
		if not climbable.reaches(feet):
			continue
		var wants := false
		if move.y < -0.5:
			wants = climbable.reaches(feet + Vector2(0, -8))
		elif move.y > 0.5:
			wants = climbable.reaches(feet + Vector2(0, 8))
		if climbable.kind == Climbable.Kind.ROPE and not on_floor:
			wants = true
		if wants:
			_climb = climbable
			collision_mask = Layers.WORLD
			velocity = Vector2.ZERO
			_jump_rising = false
			_air_jumps_left = stats.air_jumps
			_air_dashes_left = stats.air_dashes
			return


## On a ladder or rope: up/down to climb, jump to let go with a jump.
func _process_climb(move: Vector2, delta: float) -> void:
	if move.x != 0.0:
		facing = int(signf(move.x))
	if _jump_buffer_timer > 0.0:
		_release_climb()
		_jump(stats.velocity_for_height(stats.jump_height * stats.climb_jump_factor))
		velocity.x = move.x * stats.run_speed
		_regrab_timer = REGRAB_TIME
		return
	velocity.x = (_climb.center_x() - global_position.x) / maxf(delta, 0.001) * 0.3
	velocity.y = move.y * stats.climb_speed if absf(move.y) > 0.3 else 0.0
	move_and_slide()
	var feet := global_position.y + SIZE.y / 2.0
	var top := _climb.feet_area.position.y
	if feet <= top:
		# Reached the top: a ladder puts the hero on the ledge, a rope just holds.
		global_position.y = top - SIZE.y / 2.0
		velocity.y = 0.0
		if _climb.kind == Climbable.Kind.LADDER:
			_release_climb()
			last_safe_position = global_position
	elif feet > _climb.feet_area.end.y or (is_on_floor() and move.y > 0.3):
		_release_climb()
	_update_look(false)


func _release_climb() -> void:
	if _climb == null:
		return
	_climb = null
	if _drop_timer <= 0.0:
		collision_mask = Layers.GROUND


## True if the hero stands on a one-way platform (and not on solid ground).
func _on_one_way() -> bool:
	var saved := collision_mask
	collision_mask = Layers.WORLD
	var solid := test_move(global_transform, Vector2(0, 4))
	collision_mask = saved
	return not solid


func _drop_through() -> void:
	_drop_timer = DROP_TIME
	_jump_buffer_timer = 0.0
	collision_mask = Layers.WORLD
	global_position.y += 2.0


func _can_dash(on_floor: bool) -> bool:
	return _dash_cooldown_timer <= 0.0 and (on_floor or _air_dashes_left > 0)


func _start_dash(move: Vector2, on_floor: bool) -> void:
	if move.x != 0.0:
		facing = int(signf(move.x))
	if not on_floor:
		_air_dashes_left -= 1
	_dash_timer = stats.dash_time
	_dash_cooldown_timer = stats.dash_cooldown * (0.5 if SaveGame.has_item(hero, "quick_dash") else 1.0)
	Sound.play("dash")
	_jump_rising = false


## A dash is a fixed-speed horizontal burst that ignores gravity.
## In stage 4 it will also pass through enemies.
func _process_dash(delta: float) -> void:
	_dash_timer -= delta
	velocity = Vector2(facing * stats.dash_speed, 0.0)
	if _dash_timer <= 0.0:
		velocity.x = facing * stats.run_speed
	move_and_slide()
	_update_look(false)


func _get_wall_dir() -> int:
	if test_move(global_transform, Vector2(WALL_PROBE, 0.0)):
		return 1
	if test_move(global_transform, Vector2(-WALL_PROBE, 0.0)):
		return -1
	return 0


func _apply_look() -> void:
	if _rig != null:
		_rig.queue_free()
	_rig = HeroRig.create("gunner" if hero == Heroes.Id.SHOOTER else "swordsman")
	if _rig != null:
		_rig.position = Vector2(0, SIZE.y / 2.0)
		add_child(_rig)
		move_child(_rig, _aura.get_index() + 1)
		_aura.position = Vector2(-40, SIZE.y / 2.0 - 156)
		_aura.size = Vector2(80, 160)
	_body.visible = _rig == null
	_eye.visible = _rig == null
	_update_look(false)


## The puppet's motion for a shot: the Gunner recoils.
func animate_attack() -> void:
	if _rig != null:
		_rig.recoil()


## The Gunner's kick.
func animate_kick() -> void:
	if _rig != null:
		_rig.kick()


## A sword swing (HeroRig.Slash): each one moves the body differently.
func animate_slash(kind: int, duration: float) -> void:
	if _rig != null:
		_rig.slash(kind, duration)


func _update_look(sliding: bool) -> void:
	_wall_sliding = sliding
	_wall_dust.emitting = sliding
	_wall_dust.position = Vector2(facing * SIZE.x / 2.0, -SIZE.y / 4.0)
	# A crouching hero is a smaller target: only the lower part can be hit.
	if crouching:
		_hurtbox.resize(Vector2(SIZE.x - 8, CROUCH_HEIGHT), Vector2(0, SIZE.y / 2.0 - CROUCH_HEIGHT / 2.0))
	else:
		_hurtbox.resize(SIZE - Vector2(8, 8), Vector2.ZERO)
	var color: Color = Heroes.COLORS[hero]
	if is_dashing():
		color = color.lightened(0.6)
	elif is_stunned():
		color = Color.WHITE
	elif combat.is_glowing():
		color = color.lightened(0.35 + 0.25 * sin(Time.get_ticks_msec() * 0.02))
	elif sliding:
		color = color.darkened(0.3)
	_body.color = color
	_body.size.y = CROUCH_HEIGHT + 8.0 if crouching else SIZE.y
	_body.position.y = SIZE.y / 2.0 - _body.size.y
	if _rig != null:
		_rig.pose(self, get_physics_process_delta_time())
		if is_stunned():
			_rig.tint(Color.WHITE, 0.7)
		elif combat.is_glowing():
			_rig.tint(Heroes.COLORS[hero], 0.25 + 0.2 * sin(Time.get_ticks_msec() * 0.02))
		elif is_dashing():
			_rig.tint(Color.WHITE, 0.3)
		else:
			_rig.tint(Color.WHITE, 0.0)
	_aura.visible = not powers.is_empty()
	if _aura.visible:
		var power: String = powers.keys()[0]
		_aura.color = Color(POWER_COLORS[power], 0.35 + 0.2 * sin(Time.get_ticks_msec() * 0.012))
	# Blink while invulnerable after a hit.
	modulate.a = 0.35 if is_invulnerable() and (Time.get_ticks_msec() / 70) % 2 == 0 else 1.0
	_eye.position = Vector2(facing * (SIZE.x / 2 - 14) - 5, -SIZE.y / 2 + 14)
