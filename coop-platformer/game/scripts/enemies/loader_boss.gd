class_name LoaderBoss
extends Enemy
## World 2 boss, the giant Lumen loader, fought in the pump hall after the
## chase. It cannot be pushed or stunned; every attack is announced.
## Phase 1: the claw slams down where a hero stands (a red mark on the floor
##          shows where), and crates are thrown down from above.
## Phase 2 (below 2/3 health): its armour closes — hits barely scratch it —
##          but after a claw slam the claw is stuck in the floor for a moment
##          and the reactor on its back is open: then it takes extra damage.
## Phase 3 (below 1/3 health): it burns, and rams across the hall.
## Its health grows with the number of heroes.

enum State { IDLE, ROAR, CLAW_WINDUP, STUCK, THROW_WINDUP, RAM_WINDUP, RAM, DAZED, RECOVER }
enum Attack { CLAW, THROW, RAM }

const DISPLAY_NAME := "Погрузчик «Люмена»"
const MARK_COLOR := Color(1.0, 0.2, 0.15)
const ARMOUR := 0.3
const OPEN_CORE := 1.5

@export var walk_speed := 70.0
@export var ram_speed := 720.0
@export var claw_damage := 4
@export var claw_width := 170.0
@export var health_per_extra_hero := 0.5

var state := State.IDLE
var phase := 1

var _timer := 1.5
var _claw_x := 0.0
var _floor_y := 0.0
var _mark: Node2D
var _last_attack := -1
var _look: LoaderLook


func _init() -> void:
	max_health = 170
	body_size = Vector2(240, 220)
	color = ROBOT_COLOR.darkened(0.25)
	contact_damage = 3
	contact_knockback = 650.0
	knockback_resistance = 1.0
	health_drop_chance = 1.0
	ammo_drop_chance = 1.0
	scrap_min = 14
	scrap_max = 18
	art = "boss_loader"
	art_height = 340.0


func _ready() -> void:
	super._ready()
	add_to_group("bosses")
	super_armor = true
	can_be_shocked = false
	Sound.music("boss_2")
	if _sprite == null:
		# Until its picture is drawn: the same machine as in the chase.
		_body.visible = false
		_eye.visible = false
		_look = LoaderLook.new()
		_look.size = Vector2(body_size.x * 1.5, body_size.y * 1.3)
		_look.position = Vector2(0, body_size.y / 2.0 - _look.size.y / 2.0)
		add_child(_look)
	_mark = ClawMark.new()
	_mark.visible = false
	_mark.top_level = true
	add_child(_mark)
	var heroes := 0
	for node in get_tree().get_nodes_in_group("players"):
		if node is Player and node.is_alive():
			heroes += 1
	health.reset(roundi(health.maximum * (1.0 + health_per_extra_hero * maxi(heroes - 1, 0))))


func display_name() -> String:
	return DISPLAY_NAME


func is_core_open() -> bool:
	return state == State.STUCK and phase >= 2


func cooldown() -> float:
	return [1.4, 1.1, 0.8][phase - 1]


func receive_hit(hit: Hit) -> bool:
	if phase >= 2 and is_alive():
		if is_core_open():
			hit.damage = roundi(hit.damage * OPEN_CORE)
		else:
			hit.damage = maxi(1, roundi(hit.damage * ARMOUR))
			Fx.burst(get_parent(), hit.source_position.lerp(global_position, 0.6),
				[Color(1, 1, 0.8), Color(1.0, 0.7, 0.3), Color(1.0, 0.4, 0.1, 0.0)], 6, 300.0, 2.5, 0.2, 600.0)
	return super.receive_hit(hit)


func _think(delta: float) -> void:
	_timer -= delta
	if is_on_floor():
		_floor_y = global_position.y + body_size.y / 2.0
	var wanted := 1 if health.ratio() > 2.0 / 3.0 else (2 if health.ratio() > 1.0 / 3.0 else 3)
	if wanted > phase and state in [State.IDLE, State.RECOVER]:
		_enter_phase(wanted)
		return
	var hero := nearest_hero(4000.0)
	match state:
		State.IDLE:
			velocity.x = 0.0
			if hero == null:
				return
			var dx := hero.global_position.x - global_position.x
			facing = 1 if dx >= 0.0 else -1
			if absf(dx) > 360.0:
				velocity.x = facing * walk_speed * (1.0 + 0.3 * (phase - 1))
			if _timer <= 0.0:
				_start_attack(_pick_attack(), hero)
		State.ROAR:
			velocity.x = 0.0
			if _timer <= 0.0:
				_idle(0.6)
		State.CLAW_WINDUP:
			velocity.x = 0.0
			if _timer <= 0.0:
				_claw()
		State.STUCK:
			velocity.x = 0.0
			if _timer <= 0.0:
				_mark.visible = false
				_idle(cooldown())
		State.THROW_WINDUP:
			velocity.x = 0.0
			if _timer <= 0.0:
				_throw()
				state = State.RECOVER
				_timer = 0.6
		State.RAM_WINDUP:
			velocity.x = -facing * 60.0
			if _timer <= 0.0:
				state = State.RAM
				_timer = 2.4
				contact_damage = 4
		State.RAM:
			velocity.x = facing * ram_speed
			if wall_ahead(facing) or _timer <= 0.0:
				state = State.DAZED
				_timer = 1.5
				velocity.x = 0.0
				contact_damage = 3
				get_tree().call_group("cameras", "shake", 14.0)
				Sound.play("boss_slam", 0.0)
		State.DAZED:
			velocity.x = 0.0
			if _timer <= 0.0:
				_idle(cooldown())
		State.RECOVER:
			velocity.x = 0.0
			if _timer <= 0.0:
				_idle(cooldown())


func _pick_attack() -> int:
	var options := [Attack.CLAW, Attack.CLAW, Attack.THROW]
	if phase == 3:
		options.append(Attack.RAM)
		options.append(Attack.RAM)
	var choice: int = options.pick_random()
	if choice == _last_attack and choice != Attack.CLAW:
		choice = Attack.CLAW
	_last_attack = choice
	return choice


func _start_attack(attack: int, hero: Player) -> void:
	match attack:
		Attack.CLAW:
			state = State.CLAW_WINDUP
			_timer = 1.0 if phase < 3 else 0.8
			_claw_x = hero.global_position.x
			_mark.global_position = Vector2(_claw_x, _floor_y)
			(_mark as ClawMark).width = claw_width
			_mark.visible = true
			telegraph(_timer)
		Attack.THROW:
			state = State.THROW_WINDUP
			_timer = 0.7
			telegraph(_timer)
		Attack.RAM:
			state = State.RAM_WINDUP
			_timer = 0.9
			telegraph(_timer)


## The claw comes down on the mark; in phase 2+ it sticks in the floor, the
## reactor opens and the boss takes extra damage for a moment.
func _claw() -> void:
	var rect := Rect2(_claw_x - claw_width / 2.0, _floor_y - 220.0, claw_width, 220.0)
	for hurtbox in Harm.hurtboxes_in_rect(get_world_2d(), rect, Harm.HEROES):
		var side := -1.0 if hurtbox.global_position.x < _claw_x else 1.0
		hurtbox.take_hit(Hit.make(claw_damage, Vector2(side * 650.0, -450.0), Vector2(_claw_x, _floor_y)))
	Fx.burst(get_parent(), Vector2(_claw_x, _floor_y), [Color(1, 0.95, 0.7), Color(1.0, 0.6, 0.2), Color(1.0, 0.3, 0.1, 0.0)],
		24, 600.0, 3.0, 0.4, 900.0, true, Vector2.UP, 80.0)
	Fx.burst(get_parent(), Vector2(_claw_x, _floor_y), [Color(0.55, 0.5, 0.45, 0.8), Color(0.5, 0.45, 0.4, 0.0)], 14, 260.0,
		14.0, 0.7, -40.0, false, Vector2.UP, 80.0)
	Sound.play("boss_slam", 0.0)
	get_tree().call_group("cameras", "shake", 10.0)
	punch(Vector2(0.12, -0.1))
	state = State.STUCK
	_timer = 2.2 if phase >= 2 else 0.8
	if phase >= 2:
		Sound.play("charge_ready", 0.0, 0.0, 0.6)


## Crates rain down on and around the heroes.
func _throw() -> void:
	var count := 2 + phase
	var heroes := get_tree().get_nodes_in_group("players")
	for i in count:
		var hero := heroes.pick_random() as Player
		if hero == null:
			continue
		var crate := CrateChute.FallingCrate.new()
		crate.position = Vector2(hero.global_position.x + randf_range(-260.0, 260.0) * (1 if i > 0 else 0),
			_floor_y - 760.0 - i * 90.0)
		get_parent().add_child(crate)
	Sound.play("kick", 0.1, 0.0, 0.5)
	punch(Vector2(-0.08, 0.12))


func _enter_phase(next: int) -> void:
	phase = next
	state = State.ROAR
	_timer = 1.4
	velocity.x = 0.0
	Sound.play("boss_roar", 0.0, 0.0, 0.6)
	get_tree().call_group("cameras", "shake", 12.0)
	var level := get_parent() as Level
	if level != null:
		level.show_toast("Броня закрылась! Бей, когда манипулятор застрянет" if phase == 2 else "Погрузчик горит — берегись тарана!", 3.5)
	if phase == 3 and _flames == null:
		_flames = _make_flames()
		_flames.emitting = true


func _idle(delay: float) -> void:
	state = State.IDLE
	_timer = delay


## Burning in phase 3 is only for show: the fire does not hurt the boss.
func _update_status(delta: float) -> void:
	super._update_status(delta)
	if _flames != null:
		_flames.emitting = true


func _update_look() -> void:
	super._update_look()
	if _sprite != null and is_core_open():
		Flash.set_flash(_sprite, Color(1.0, 0.6, 0.2), 0.25 + 0.2 * sin(Time.get_ticks_msec() * 0.02))
	if _look != null:
		_look.scale.x = float(facing)
		_look.modulate = Color(1.6, 1.6, 1.6) if _flash_timer > 0.0 else (
			Color(1.4, 0.9, 0.6) if is_core_open() or (is_telegraphing() and int(Time.get_ticks_msec() / 80) % 2 == 0) else Color.WHITE)


func _on_died() -> void:
	_mark.visible = false
	get_tree().call_group("cameras", "shake", 16.0)
	Fx.explosion(get_parent(), global_position, 160.0)
	super._on_died()


## The red mark on the floor where the claw will come down.
class ClawMark:
	extends Node2D

	var width := 170.0

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.02)
		draw_rect(Rect2(-width / 2.0, -10.0, width, 10.0), Color(LoaderBoss.MARK_COLOR, 0.5 + 0.4 * pulse))
		draw_rect(Rect2(-width / 2.0, -260.0, width, 250.0), Color(LoaderBoss.MARK_COLOR, 0.08 + 0.08 * pulse))


## The stand-in machine drawn like the chase loader.
class LoaderLook:
	extends Node2D

	var size := Vector2(360, 290)
	var _time := 0.0

	func _process(delta: float) -> void:
		_time += delta
		queue_redraw()

	func _draw() -> void:
		Chase.draw_loader(self, size, _time)
