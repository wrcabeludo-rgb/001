class_name Player
extends CharacterBody2D
## Placeholder hero (a coloured box) with the full platforming movement:
## acceleration, coyote time, jump buffering, variable jump height,
## wall slide and wall jump, double jump (shooter) and dash (swordsman).
## Attacks live in a HeroCombat child (ShooterCombat / SwordsmanCombat).
## Movement numbers live in MovementStats, combat numbers in CombatStats.

signal died(player: Player)

const SIZE := Vector2(48, 96)
## How far to probe sideways when looking for a wall to slide on.
const WALL_PROBE := 2.0
const HITSTOP_TIME := 0.05
const HITSTOP_SCALE := 0.05

var slot := 0
var input: PlayerInput
var hero: Heroes.Id = Heroes.Id.SHOOTER
var stats: MovementStats
var combat_stats: CombatStats
var facing := 1
var health: Health
var combat: HeroCombat

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

var _body: ColorRect
var _eye: ColorRect
var _tag: Label


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


## Called by a Hurtbox when an enemy attack lands. Returns true if it counted.
func receive_hit(hit: Hit) -> bool:
	if is_invulnerable() or health.is_dead():
		return false
	hit = combat.modify_hit(hit)
	health.damage(hit.damage)
	velocity = hit.knockback
	_dash_timer = 0.0
	_jump_rising = false
	_invulnerable_timer = combat_stats.hurt_invulnerability if not hit.blocked else 0.2
	if not hit.blocked:
		_stun_timer = combat_stats.hurt_stun
	return true


## Back to full health and control (respawn).
func revive(at: Vector2, invulnerable_time := 1.0) -> void:
	global_position = at
	velocity = Vector2.ZERO
	_stun_timer = 0.0
	_invulnerable_timer = invulnerable_time
	health.reset(combat_stats.max_health)


## A tiny freeze of the whole game when a melee hit lands, so it feels heavy.
func hitstop() -> void:
	PlayerManager.hitstop(HITSTOP_TIME, HITSTOP_SCALE)


func _ready() -> void:
	add_to_group("players")
	# Players stand on the world but pass through each other.
	collision_layer = Layers.PLAYER_BODIES
	collision_mask = Layers.WORLD

	var shape := RectangleShape2D.new()
	shape.size = SIZE
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)

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

	_tag = Label.new()
	_tag.add_theme_font_size_override("font_size", 20)
	_tag.position = Vector2(-50, -SIZE.y / 2 - 32)
	_tag.size = Vector2(100, 28)
	_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_tag)

	health = Health.new()
	add_child(health)
	health.died.connect(func() -> void: died.emit(self))
	_hurtbox = Hurtbox.new()
	add_child(_hurtbox)
	_hurtbox.setup(Layers.Team.PLAYERS, SIZE - Vector2(8, 8), self)

	_build_combat()
	_apply_look()


func _physics_process(delta: float) -> void:
	if input == null:
		return

	var move := input.get_move()
	var on_floor := is_on_floor()
	var wall_dir := _get_wall_dir()

	_tick_timers(delta)
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

	_apply_horizontal(move.x, on_floor, delta)
	var sliding := _apply_gravity(move.x, on_floor, wall_dir, delta)
	_try_jump(on_floor)

	# Variable jump height: letting go of jump while rising cuts the jump short.
	if _jump_rising and not input.is_held("jump") and velocity.y < 0.0:
		velocity.y *= stats.jump_cut
		_jump_rising = false
	if velocity.y >= 0.0:
		_jump_rising = false

	move_and_slide()
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
	health.reset(combat_stats.max_health)


func _tick_timers(delta: float) -> void:
	_stun_timer -= delta
	_invulnerable_timer -= delta
	_coyote_timer -= delta
	_jump_buffer_timer -= delta
	_wall_coyote_timer -= delta
	_wall_jump_lock_timer -= delta
	_dash_cooldown_timer -= delta


func _apply_horizontal(direction: float, on_floor: bool, delta: float) -> void:
	if _wall_jump_lock_timer > 0.0:
		return
	var accel: float
	if on_floor:
		accel = stats.ground_accel if direction != 0.0 else stats.ground_decel
	else:
		accel = stats.air_accel if direction != 0.0 else stats.air_decel
	var target := direction * stats.run_speed * combat.speed_multiplier()
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
	elif stats.wall_jump_enabled and _wall_coyote_timer > 0.0:
		_jump(stats.velocity_for_height(stats.wall_jump_height))
		velocity.x = -_last_wall_dir * stats.wall_jump_speed_x
		facing = -_last_wall_dir
		_wall_jump_lock_timer = stats.wall_jump_lock_time
	elif _air_jumps_left > 0:
		_air_jumps_left -= 1
		_jump(stats.velocity_for_height(stats.air_jump_height))


func _jump(vertical_velocity: float) -> void:
	velocity.y = vertical_velocity
	_jump_rising = true
	_jump_buffer_timer = 0.0
	_coyote_timer = 0.0
	_wall_coyote_timer = 0.0


func _can_dash(on_floor: bool) -> bool:
	return _dash_cooldown_timer <= 0.0 and (on_floor or _air_dashes_left > 0)


func _start_dash(move: Vector2, on_floor: bool) -> void:
	if move.x != 0.0:
		facing = int(signf(move.x))
	if not on_floor:
		_air_dashes_left -= 1
	_dash_timer = stats.dash_time
	_dash_cooldown_timer = stats.dash_cooldown
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
	_tag.text = "P%d %s" % [slot + 1, Heroes.NAMES[hero]]
	_update_look(false)


func _update_look(sliding: bool) -> void:
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
	# Blink while invulnerable after a hit.
	modulate.a = 0.35 if is_invulnerable() and (Time.get_ticks_msec() / 70) % 2 == 0 else 1.0
	_eye.position = Vector2(facing * (SIZE.x / 2 - 14) - 5, -SIZE.y / 2 + 14)
