class_name SludgeBoss
extends Enemy
## World 1 boss, "Хозяин стока": a huge mutant from the main sludge drain.
## It cannot be pushed or stunned. Every attack is announced by blinking and "!".
## Phase 1: ground slam (shockwaves along the floor — jump over them) and
##          sludge spit (globs that leave acid puddles).
## Phase 2 (below 2/3 health): roars and calls two walkers; adds a charge
##          across the arena — after hitting the wall it is dazed for a while.
## Phase 3 (below 1/3 health): faster, spits more, and makes sludge pour from
##          above onto blinking marks on the floor.
## Right after a new phase begins, the boss shows its new attack first.
## Its health grows with the number of heroes.

enum State { IDLE, ROAR, SLAM_WINDUP, SPIT_WINDUP, CHARGE_WINDUP, CHARGE, DAZED, RAIN_WINDUP, RECOVER }
enum Attack { SLAM, SPIT, CHARGE, RAIN }

const DISPLAY_NAME := "Хозяин стока"
const BOSS_COLOR := Color(0.3, 0.55, 0.22)
const DAZED_COLOR := Color(0.55, 0.6, 0.5)

@export var walk_speed := 80.0
@export var charge_speed := 650.0
@export var slam_damage := 4
@export var wave_damage := 3
@export var glob_damage := 2
@export var rain_damage := 3
## Extra health for each hero beyond the first, as a share of the base.
@export var health_per_extra_hero := 0.5

var state := State.IDLE
var _windup_length := 1.0
var _art_scale := Vector2.ONE
var _ooze: CPUParticles2D
var phase := 1

var _timer := 1.5
var _last_attack := -1
## The attack to use next regardless of chance (-1 = pick at random).
var _forced_attack := -1
var _bounds := Vector2.ZERO
var _minions: Array = []


func _init() -> void:
	max_health = 140
	body_size = Vector2(200, 230)
	color = BOSS_COLOR
	contact_damage = 3
	contact_knockback = 600.0
	knockback_resistance = 1.0
	health_drop_chance = 1.0
	ammo_drop_chance = 1.0
	scrap_min = 12
	scrap_max = 16
	art = "boss"
	art_height = 300.0


func _ready() -> void:
	super._ready()
	add_to_group("bosses")
	super_armor = true
	Sound.music("boss")
	if _sprite != null:
		_art_scale = _sprite.scale
	# Sludge dripping off the body all the time, more while it moves.
	_ooze = SlimeLook.drips(14, Vector2(body_size.x * 0.7, 30), 900.0)
	_ooze.position = Vector2(0, body_size.y * 0.1)
	_ooze.initial_velocity_max = 90.0
	add_child(_ooze)
	var heroes := 0
	for node in get_tree().get_nodes_in_group("players"):
		if node is Player and node.is_alive():
			heroes += 1
	var extra := health_per_extra_hero * maxi(heroes - 1, 0)
	health.reset(roundi(health.maximum * (1.0 + extra)))


func display_name() -> String:
	return DISPLAY_NAME


func cooldown() -> float:
	return [1.5, 1.15, 0.85][phase - 1]


func _think(delta: float) -> void:
	_find_bounds()
	_timer -= delta
	var wanted_phase := 1 if health.ratio() > 2.0 / 3.0 else (2 if health.ratio() > 1.0 / 3.0 else 3)
	if wanted_phase > phase and state == State.IDLE:
		_enter_phase(wanted_phase)
		return
	match state:
		State.IDLE:
			var hero := nearest_hero(4000.0)
			velocity.x = 0.0
			if hero == null:
				return
			var dx := hero.global_position.x - global_position.x
			facing = 1 if dx >= 0.0 else -1
			if absf(dx) > 280.0:
				velocity.x = facing * walk_speed
			if _timer <= 0.0:
				_start_attack(_pick_attack())
		State.ROAR:
			velocity.x = 0.0
			if _timer <= 0.0:
				_to_idle(0.6)
		State.SLAM_WINDUP:
			velocity.x = 0.0
			if _timer <= 0.0:
				_slam()
				_recover(0.8)
		State.SPIT_WINDUP:
			velocity.x = 0.0
			if _timer <= 0.0:
				_spit()
				_recover(0.5)
		State.CHARGE_WINDUP:
			velocity.x = -facing * 60.0
			if _timer <= 0.0:
				state = State.CHARGE
				_timer = 2.5
				contact_damage = 4
		State.CHARGE:
			velocity.x = facing * charge_speed
			if wall_ahead(facing) or _timer <= 0.0:
				state = State.DAZED
				_timer = 1.6
				velocity.x = 0.0
				contact_damage = 3
				get_tree().call_group("cameras", "shake", 14.0)
		State.DAZED:
			velocity.x = 0.0
			if _timer <= 0.0:
				_to_idle(cooldown())
		State.RAIN_WINDUP:
			velocity.x = 0.0
			if _timer <= 0.0:
				_rain()
				_recover(0.6)
		State.RECOVER:
			velocity.x = 0.0
			if _timer <= 0.0:
				_to_idle(cooldown())


func is_dazed() -> bool:
	return state == State.DAZED


func _to_idle(wait: float) -> void:
	state = State.IDLE
	_timer = wait


func _recover(time: float) -> void:
	state = State.RECOVER
	_timer = time


func _enter_phase(new_phase: int) -> void:
	phase = new_phase
	state = State.ROAR
	_timer = 1.2
	telegraph(1.2)
	Sound.play("boss_roar", 0.0)
	get_tree().call_group("cameras", "shake", 10.0)
	if phase == 2:
		_summon_walkers()
	_forced_attack = Attack.CHARGE if phase == 2 else Attack.RAIN


func _pick_attack() -> Attack:
	if _forced_attack >= 0:
		var forced: Attack = _forced_attack
		_forced_attack = -1
		return forced
	var options: Array = [Attack.SLAM, Attack.SPIT]
	if phase >= 2:
		options.append(Attack.CHARGE)
	if phase >= 3:
		options.append(Attack.RAIN)
	options.erase(_last_attack)
	return options.pick_random()


func _start_attack(attack: Attack) -> void:
	_last_attack = attack
	var windup := 0.9 if phase < 3 else 0.7
	match attack:
		Attack.SLAM:
			state = State.SLAM_WINDUP
		Attack.SPIT:
			state = State.SPIT_WINDUP
			windup = 0.6
		Attack.CHARGE:
			state = State.CHARGE_WINDUP
			windup = 0.8
		Attack.RAIN:
			state = State.RAIN_WINDUP
	_timer = windup
	_windup_length = windup
	telegraph(windup)


## Where the boss stands, on the floor.
func feet() -> Vector2:
	return global_position + Vector2(0, body_size.y / 2.0)


func _slam() -> void:
	get_tree().call_group("cameras", "shake", 12.0)
	Sound.play("boss_slam")
	var speed := 520.0 if phase < 3 else 650.0
	for side in [-1, 1]:
		var wave := BossAttacks.Shockwave.new()
		wave.setup(feet() + Vector2(side * (body_size.x / 2.0 + 30.0), -1.0), side, speed, wave_damage)
		get_parent().add_child(wave)
	var near := Rect2(feet() + Vector2(-body_size.x / 2.0 - 100.0, -120.0), Vector2(body_size.x + 200.0, 120.0))
	for hurtbox in Harm.hurtboxes_in_rect(get_world_2d(), near, Harm.HEROES):
		var side := 1.0 if hurtbox.global_position.x >= global_position.x else -1.0
		hurtbox.take_hit(Hit.make(slam_damage, Vector2(side * 700.0, -500.0), global_position))


func _spit() -> void:
	var hero := nearest_hero(4000.0)
	if hero == null:
		return
	Sound.play("boss_spit")
	var count := 3 if phase < 3 else 5
	var start := global_position + Vector2(facing * body_size.x * 0.3, -body_size.y * 0.35)
	var flight_time := 0.9
	for i in count:
		var target := Vector2(hero.global_position.x + (i - (count - 1) / 2.0) * 150.0, feet().y - 10.0)
		var offset := target - start
		var launch := Vector2(offset.x / flight_time,
			(offset.y - 0.5 * BossAttacks.Glob.GRAVITY * flight_time * flight_time) / flight_time)
		var glob := BossAttacks.Glob.new()
		glob.setup(Layers.Team.ENEMIES, start, launch, launch.length(), glob_damage, 300.0,
			Vector2(28, 28), BossAttacks.SLUDGE_COLOR, 0, 3.0)
		get_parent().add_child(glob)


func _rain() -> void:
	var spots: Array[float] = []
	var hero := nearest_hero(4000.0)
	if hero != null:
		spots.append(hero.global_position.x)
	for i in 4:
		spots.append(randf_range(_bounds.x + 60.0, _bounds.y - 60.0))
	for i in spots.size():
		var drop := BossAttacks.Drop.new()
		drop.setup(Vector2(spots[i], feet().y), 0.9 + i * 0.15, rain_damage)
		get_parent().add_child(drop)


func _summon_walkers() -> void:
	var level := get_parent() as Level
	if level == null:
		return
	for side in [-1, 1]:
		var x := clampf(global_position.x + side * 420.0, _bounds.x + 60.0, _bounds.y - 60.0)
		var walker := level.spawn_enemy("w", Vector2(x, feet().y))
		if walker != null:
			walker.stun_timer = 0.6
			walker.telegraph(0.6)
			_minions.append(walker)


## The arena walls left and right of the boss (found once, on the first frame).
func _find_bounds() -> void:
	if _bounds != Vector2.ZERO:
		return
	var space := get_world_2d().direct_space_state
	var y := feet().y - 30.0
	var result := Vector2(global_position.x - 900.0, global_position.x + 900.0)
	for side in [-1, 1]:
		var ray := PhysicsRayQueryParameters2D.create(Vector2(global_position.x, y),
			Vector2(global_position.x + side * 3000.0, y), Layers.WORLD, [get_rid()])
		var hit := space.intersect_ray(ray)
		if not hit.is_empty():
			if side < 0:
				result.x = hit["position"].x
			else:
				result.y = hit["position"].x
	_bounds = result


func _update_look() -> void:
	super._update_look()
	if is_dazed() and _flash_timer <= 0.0:
		_body.color = DAZED_COLOR
		if _sprite != null:
			Flash.set_flash(_sprite, DAZED_COLOR, 0.45)


func _on_died() -> void:
	for minion in _minions:
		if is_instance_valid(minion) and not minion.is_queued_for_deletion() and minion.is_alive():
			minion.health.damage(minion.health.current)
	get_tree().call_group("cameras", "shake", 20.0)
	var level := get_parent() as Level
	if level != null and level.music_track != "":
		Sound.music(level.music_track)
	super._on_died()


## The body moves like a heap of sludge: it rolls and sways as it crawls,
## rears up tall before a slam and splats down after it, swells and leans back
## before spitting, crouches and trembles before a charge and leans into it,
## pulses before the geysers, roars stretched up, wobbles while dazed.
func _animate_sprite() -> void:
	super._animate_sprite()
	var t := Time.get_ticks_msec() / 1000.0
	var windup := 1.0 - clampf(_timer / maxf(_windup_length, 0.01), 0.0, 1.0)
	var stretch := 0.0  # taller and thinner (+) or flatter and wider (-)
	var lean := 0.0  # towards where it faces (+)
	var lift := 0.0
	var shake := 0.0
	var swell := 0.0
	match state:
		State.IDLE:
			var moving := absf(velocity.x) > 1.0
			stretch = 0.05 * sin(t * (7.0 if moving else 2.5))
			lean = 0.06 * sin(t * 3.5) if moving else 0.0
		State.ROAR:
			stretch = 0.16
			shake = 5.0
		State.SLAM_WINDUP:
			stretch = 0.22 * windup
			lift = 30.0 * windup
			lean = -0.08 * windup
		State.SPIT_WINDUP:
			swell = 0.1 * windup
			lean = -0.18 * windup
		State.CHARGE_WINDUP:
			stretch = -0.16 * windup
			lean = 0.15 * windup
			shake = 4.0 * windup
		State.CHARGE:
			stretch = -0.08 + 0.06 * sin(t * 22.0)
			lean = 0.22
		State.DAZED:
			lean = 0.12 * sin(t * 5.0)
			stretch = -0.1
		State.RAIN_WINDUP:
			swell = 0.06 * (0.5 + 0.5 * sin(t * 18.0)) * windup
			stretch = 0.08 * windup
		State.RECOVER:
			# Splat after a slam, a jolt after a spit.
			var after := clampf(_timer / 0.8, 0.0, 1.0)
			if _last_attack == Attack.SLAM:
				stretch = -0.22 * after
			elif _last_attack == Attack.SPIT:
				lean = 0.15 * after
	_sprite.scale = _art_scale * Vector2(1.0 - stretch * 0.6 + swell, 1.0 + stretch + swell)
	# Keep the bottom on the floor while it stretches.
	var tall := art_drawn_size().y
	_sprite.position += Vector2(randf_range(-shake, shake), -(stretch + swell) * tall * 0.5 - lift)
	_sprite.rotation += facing * lean
	_ooze.speed_scale = 1.4 if absf(velocity.x) > 1.0 or state == State.CHARGE else 0.6
