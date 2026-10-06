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
