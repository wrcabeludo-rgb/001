class_name Commander
extends Enemy
## World 3 boss: the commander of the Lumen security in a heavy exosuit with a
## jet pack. It cannot be pushed or stunned; every attack is announced.
## Phase 1: bursts from the arm gun; a jet dash across the arena (low — jump it).
## Phase 2 (below 2/3 health): calls two riflemen; flies up and rains rockets
##          on red marks on the floor, then lands.
## Phase 3 (below 1/3 health): the suit overheats: landings slam the floor with
##          energy waves both ways; rockets come more often.
## Its health grows with the number of heroes.

enum State { IDLE, ROAR, GUN_WINDUP, GUN, DASH_WINDUP, DASH, RISE, ROCKETS, LAND, RECOVER }
enum Attack { GUN, DASH, ROCKETS }

const DISPLAY_NAME := "Командир охраны «Люмена»"
const BULLET_COLOR := Color(1.0, 0.75, 0.3)
const JET := Color(1.0, 0.55, 0.9)

@export var walk_speed := 90.0
@export var dash_speed := 820.0
@export var health_per_extra_hero := 0.5

var state := State.IDLE
var phase := 1

var _timer := 1.5
var _shots := 0
var _target: Player
var _last_attack := -1
var _ground_y := 0.0
var _jet: CPUParticles2D
var _marks: Array[Node2D] = []


func _init() -> void:
	max_health = 190
	body_size = Vector2(100, 190)
	color = Color(0.18, 0.17, 0.22)
	contact_damage = 3
	contact_knockback = 620.0
	knockback_resistance = 1.0
	health_drop_chance = 1.0
	ammo_drop_chance = 1.0
	scrap_min = 16
	scrap_max = 20
	art = "boss_commander"
	art_height = 290.0


func _ready() -> void:
	super._ready()
	add_to_group("bosses")
	super_armor = true
	can_be_shocked = false
	Sound.music("boss_3")
	_jet = CPUParticles2D.new()
	_jet.position = Vector2(0, -body_size.y * 0.1)
	_jet.amount = 30
	_jet.lifetime = 0.35
	_jet.local_coords = false
	_jet.direction = Vector2.DOWN
	_jet.spread = 12.0
	_jet.initial_velocity_min = 300.0
	_jet.initial_velocity_max = 480.0
	_jet.scale_amount_min = 8.0
	_jet.scale_amount_max = 16.0
	_jet.color_ramp = Fx.ramp([Color(1, 1, 1), JET, Color(0.6, 0.1, 0.4, 0.0)])
	_jet.material = Fx.additive()
	_jet.emitting = false
	add_child(Fx.soften(_jet))
	var heroes := 0
	for node in get_tree().get_nodes_in_group("players"):
		if node is Player and node.is_alive():
			heroes += 1
	health.reset(roundi(health.maximum * (1.0 + health_per_extra_hero * maxi(heroes - 1, 0))))


func display_name() -> String:
	return DISPLAY_NAME


func cooldown() -> float:
	return [1.3, 1.0, 0.75][phase - 1]


func _think(delta: float) -> void:
	_timer -= delta
	if is_on_floor():
		_ground_y = global_position.y + body_size.y / 2.0
	var wanted := 1 if health.ratio() > 2.0 / 3.0 else (2 if health.ratio() > 1.0 / 3.0 else 3)
	if wanted > phase and state in [State.IDLE, State.RECOVER]:
		_enter_phase(wanted)
		return
	var hero := nearest_hero(4000.0)
	_jet.emitting = state in [State.DASH, State.RISE, State.ROCKETS]
	match state:
		State.IDLE:
			velocity.x = 0.0
			if hero == null:
				return
			facing = 1 if hero.global_position.x >= global_position.x else -1
			if absf(hero.global_position.x - global_position.x) > 420.0:
				velocity.x = facing * walk_speed
			if _timer <= 0.0:
				_start_attack(_pick_attack(), hero)
		State.ROAR, State.RECOVER:
			velocity.x = 0.0
			if _timer <= 0.0:
				_idle(cooldown())
		State.GUN_WINDUP:
			velocity.x = 0.0
			if _timer <= 0.0:
				state = State.GUN
				_shots = 5 + phase
				_timer = 0.0
		State.GUN:
			velocity.x = 0.0
			if _timer <= 0.0:
				_shoot()
				_shots -= 1
				_timer = 0.11
				if _shots <= 0:
					_recover(0.5)
		State.DASH_WINDUP:
			velocity.x = -facing * 50.0
			if _timer <= 0.0:
				state = State.DASH
				_timer = 1.4
				contact_damage = 4
				Sound.play("dash", 0.0, 2.0, 0.6)
		State.DASH:
			velocity.x = facing * dash_speed
			if wall_ahead(facing) or _timer <= 0.0:
				velocity.x = 0.0
				contact_damage = 3
				get_tree().call_group("cameras", "shake", 8.0)
				_recover(0.9)
		State.RISE:
			velocity = Vector2(0, -420.0)
			if _timer <= 0.0:
				velocity = Vector2.ZERO
				state = State.ROCKETS
				_timer = 1.0
				_mark_targets()
		State.ROCKETS:
			velocity = Vector2(sin(Time.get_ticks_msec() * 0.003) * 60.0, 0)
			if _timer <= 0.0:
				_fire_rockets()
				state = State.LAND
				uses_gravity = true
				_timer = 2.0
		State.LAND:
			velocity.x = 0.0
			if is_on_floor() or _timer <= 0.0:
				if phase >= 3:
					_slam()
				_recover(0.8)


func _pick_attack() -> int:
	var options := [Attack.GUN, Attack.DASH]
	if phase >= 2:
		options.append(Attack.ROCKETS)
		options.append(Attack.ROCKETS if phase == 3 else Attack.GUN)
	var choice: int = options.pick_random()
	if choice == _last_attack:
		choice = options[(options.find(choice) + 1) % options.size()]
	_last_attack = choice
	return choice


func _start_attack(attack: int, hero: Player) -> void:
	_target = hero
	match attack:
		Attack.GUN:
			state = State.GUN_WINDUP
			_timer = 0.6
			telegraph(_timer)
		Attack.DASH:
			state = State.DASH_WINDUP
			_timer = 0.8
			telegraph(_timer)
		Attack.ROCKETS:
			state = State.RISE
			_timer = 0.75
			uses_gravity = false
			telegraph(0.5)


func _shoot() -> void:
	if _target == null or not is_instance_valid(_target):
		return
	var muzzle := global_position + Vector2(facing * 60.0, -30.0)
	var bullet := Projectile.new()
	bullet.setup(Layers.Team.ENEMIES, muzzle, (_target.global_position - muzzle).rotated(randf_range(-0.08, 0.08)),
		860.0, 1, 300.0, Vector2(20, 8), BULLET_COLOR, 0, 1.8)
	get_parent().add_child(bullet)
	Sound.play("shoot", 0.1, -8.0, 0.8)
	punch(Vector2(-0.04, 0.02))


## Red marks on the floor where the rockets will hit: under each hero and around.
func _mark_targets() -> void:
	var count := 3 + phase
	var heroes := get_tree().get_nodes_in_group("players")
	for i in count:
		var hero := heroes.pick_random() as Player
		if hero == null:
			continue
		var mark := Mark.new()
		mark.position = Vector2(hero.global_position.x + (0.0 if i < 2 else randf_range(-320.0, 320.0)), _ground_y)
		get_parent().add_child(mark)
		_marks.append(mark)
	Sound.play("charge_ready", 0.0, 0.0, 0.7)


func _fire_rockets() -> void:
	for mark in _marks:
		if is_instance_valid(mark):
			mark.explode()
	_marks.clear()
	Sound.play("explosion", 0.0, -2.0, 0.9)
	get_tree().call_group("cameras", "shake", 9.0)


## Overheated landing: energy waves run out along the floor both ways.
func _slam() -> void:
	for direction in [-1, 1]:
		var wave := HeartPulse.Wave.new()
		wave.setup(Vector2(global_position.x, _ground_y), direction, 520.0, 3)
		get_parent().add_child(wave)
	Sound.play("boss_slam", 0.0)
	get_tree().call_group("cameras", "shake", 12.0)


func _enter_phase(next: int) -> void:
	phase = next
	state = State.ROAR
	_timer = 1.4
	Sound.play("boss_roar", 0.0, 0.0, 0.8)
	get_tree().call_group("cameras", "shake", 10.0)
	var level := get_parent() as Level
	if level != null:
		level.show_toast("Командир взлетает — следи за метками!" if phase == 2 else "Костюм перегрелся — прыгай через волны!", 3.0)
		if phase == 2:
			for dx in [-500.0, 500.0]:
				level.spawn_enemy("N", Vector2(global_position.x + dx, _ground_y))


func _recover(time: float) -> void:
	state = State.RECOVER
	_timer = time


func _idle(delay: float) -> void:
	state = State.IDLE
	_timer = delay


func _on_died() -> void:
	for mark in _marks:
		if is_instance_valid(mark):
			mark.queue_free()
	Fx.explosion(get_parent(), global_position, 140.0)
	get_tree().call_group("cameras", "shake", 16.0)
	super._on_died()


## A red target mark on the floor; a rocket hits it when the commander fires.
class Mark:
	extends Node2D

	const RADIUS := 95.0
	const DAMAGE := 3

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.025)
		draw_arc(Vector2(0, -6), RADIUS * 0.6, 0.0, TAU, 32, Color(1.0, 0.15, 0.2, 0.5 + 0.4 * pulse), 4.0)
		draw_line(Vector2(-RADIUS * 0.7, -6), Vector2(RADIUS * 0.7, -6), Color(1.0, 0.15, 0.2, 0.7), 3.0)
		draw_rect(Rect2(-RADIUS * 0.6, -400, RADIUS * 1.2, 394), Color(1.0, 0.15, 0.2, 0.05 + 0.05 * pulse))

	func explode() -> void:
		Fx.explosion(get_parent(), global_position + Vector2(0, -30), RADIUS * 0.5)
		var area := Rect2(global_position + Vector2(-RADIUS, -RADIUS * 1.6), Vector2(RADIUS * 2.0, RADIUS * 1.6))
		for hurtbox in Harm.hurtboxes_in_rect(get_world_2d(), area, Harm.HEROES):
			var side := -1.0 if hurtbox.global_position.x < global_position.x else 1.0
			hurtbox.take_hit(Hit.make(DAMAGE, Vector2(side * 450.0, -500.0), global_position))
		queue_free()
