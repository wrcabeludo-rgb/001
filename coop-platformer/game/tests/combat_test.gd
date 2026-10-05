extends "res://tests/test_harness.gd"
## Headless combat checks, run by CI:
##   godot --headless --path game res://tests/combat_test.tscn
## Heroes stand on the floor at x = 1450 facing right; targets are placed around them.

const HERO_X := 1450.0
const DUMMY_HEALTH := 20

var _dummies: Array[TrainingDummy] = []


func _run_all() -> void:
	await _test_shot_hits_dummy()
	await _test_charged_shot()
	await _test_charged_shot_needs_ammo()
	await _test_aim_up()
	await _test_kick()
	await _test_kick_pushes_harder_than_shot()
	await _test_sword_combo()
	await _test_up_slash()
	await _test_block_front_and_back()
	await _test_invulnerability()
	await _test_no_friendly_fire()
	await _test_time_scale_restored()


func _test_shot_hits_dummy() -> void:
	await _spawn(Heroes.Id.SHOOTER, Vector2(HERO_X, FLOOR_Y))
	var dummy := await _dummy(Vector2(1750, 0))
	await _press("attack")
	await _frames(30)
	_check(dummy.health.current == DUMMY_HEALTH - _player.combat_stats.shot_damage,
		"выстрел стрелка попадает в манекен (здоровье %d)" % dummy.health.current)


func _test_charged_shot() -> void:
	await _spawn(Heroes.Id.SHOOTER, Vector2(HERO_X, FLOOR_Y))
	var dummy := await _dummy(Vector2(1750, 0))
	var shooter := _player.combat as ShooterCombat
	var ammo_before := shooter.ammo
	await _press("attack", 45)
	await _frames(30)
	var stats := _player.combat_stats
	var expected := DUMMY_HEALTH - stats.shot_damage - stats.charged_damage
	_check(dummy.health.current == expected,
		"заряженный выстрел: здоровье манекена %d, ожидалось %d" % [dummy.health.current, expected])
	_check(shooter.ammo == ammo_before - stats.charged_cost,
		"заряженный выстрел тратит патроны (%d → %d)" % [ammo_before, shooter.ammo])


func _test_charged_shot_needs_ammo() -> void:
	await _spawn(Heroes.Id.SHOOTER, Vector2(HERO_X, FLOOR_Y))
	var dummy := await _dummy(Vector2(1750, 0))
	var shooter := _player.combat as ShooterCombat
	shooter.ammo = 0
	await _press("attack", 45)
	await _frames(30)
	_check(dummy.health.current == DUMMY_HEALTH - _player.combat_stats.shot_damage,
		"без патронов заряженного выстрела нет (здоровье %d)" % dummy.health.current)


func _test_aim_up() -> void:
	await _spawn(Heroes.Id.SHOOTER, Vector2(OPEN_X, FLOOR_Y))
	_input.set_virtual("up", true)
	await _press("attack")
	_input.set_virtual("up", false)
	var shot := _newest_projectile()
	_check(shot != null and shot.velocity.y < 0.0 and absf(shot.velocity.x) < 1.0,
		"вверх + атака стреляет вертикально вверх")


func _test_kick() -> void:
	await _spawn(Heroes.Id.SHOOTER, Vector2(HERO_X, FLOOR_Y))
	var dummy := await _dummy(Vector2(HERO_X + 70, 0))
	await _press("skill")
	await _frames(12)
	_check(dummy.health.current == DUMMY_HEALTH - _player.combat_stats.kick_damage,
		"пинок стрелка бьёт вплотную (здоровье %d)" % dummy.health.current)


func _test_kick_pushes_harder_than_shot() -> void:
	await _spawn(Heroes.Id.SHOOTER, Vector2(HERO_X, FLOOR_Y))
	var dummy := await _dummy(Vector2(HERO_X + 70, 0))
	await _press("skill")
	var kick_push := await _max_push(dummy, 20)
	dummy = await _dummy(Vector2(1750, 0))
	await _press("attack")
	var shot_push := await _max_push(dummy, 30)
	_check(kick_push > 60.0 and kick_push > shot_push * 4.0,
		"пинок отталкивает сильнее выстрела (%.0f px против %.0f px)" % [kick_push, shot_push])


func _test_sword_combo() -> void:
	await _spawn(Heroes.Id.SWORDSMAN, Vector2(HERO_X, FLOOR_Y))
	var dummy := await _dummy(Vector2(HERO_X + 80, 0))
	for i in 3:
		await _press("attack")
		await _frames(13)
	await _frames(30)
	var stats := _player.combat_stats
	var expected := DUMMY_HEALTH - stats.slash1_damage - stats.slash2_damage - stats.slash3_damage
	_check(dummy.health.current == expected,
		"серия из трёх ударов мечника: здоровье %d, ожидалось %d" % [dummy.health.current, expected])


func _test_up_slash() -> void:
	await _spawn(Heroes.Id.SWORDSMAN, Vector2(HERO_X, FLOOR_Y))
	var dummy := await _dummy(Vector2(HERO_X, 0), 860.0)
	_input.set_virtual("up", true)
	await _press("attack")
	_input.set_virtual("up", false)
	await _frames(20)
	_check(dummy.health.current == DUMMY_HEALTH - _player.combat_stats.up_slash_damage,
		"удар вверх попадает в цель над головой (здоровье %d)" % dummy.health.current)


func _test_block_front_and_back() -> void:
	await _spawn(Heroes.Id.SWORDSMAN, Vector2(HERO_X, FLOOR_Y))
	var stats := _player.combat_stats
	_input.set_virtual("extra", true)
	await _frames(3)
	var front := Hit.make(4, Vector2(-300, -100), Vector2(HERO_X + 100, FLOOR_Y))
	_player.receive_hit(front)
	var after_front := _player.health.current
	await _frames(20)
	var back := Hit.make(4, Vector2(300, -100), Vector2(HERO_X - 100, FLOOR_Y))
	_player.receive_hit(back)
	_input.set_virtual("extra", false)
	_check(after_front == stats.max_health - roundi(4 * stats.block_damage_multiplier),
		"блок спереди снижает урон (здоровье %d из %d)" % [after_front, stats.max_health])
	_check(_player.health.current == after_front - 4, "удар в спину блок не держит")


func _test_invulnerability() -> void:
	await _spawn(Heroes.Id.SHOOTER, Vector2(HERO_X, FLOOR_Y))
	var hit := Hit.make(2, Vector2.ZERO, Vector2(HERO_X + 100, FLOOR_Y))
	var first := _player.receive_hit(hit)
	var second := _player.receive_hit(Hit.make(2, Vector2.ZERO, Vector2(HERO_X + 100, FLOOR_Y)))
	_check(first and not second and _player.health.current == _player.combat_stats.max_health - 2,
		"после попадания герой ненадолго неуязвим")


func _test_no_friendly_fire() -> void:
	await _spawn(Heroes.Id.SHOOTER, Vector2(HERO_X, FLOOR_Y))
	var partner := _spawn_extra(Heroes.Id.SWORDSMAN, Vector2(HERO_X + 150, FLOOR_Y))
	await _frames(3)
	await _press("attack")
	await _frames(30)
	_check(partner.health.current == partner.combat_stats.max_health, "выстрел не ранит напарника")
	partner.queue_free()


func _test_time_scale_restored() -> void:
	await _frames(30)
	_check(is_equal_approx(Engine.time_scale, 1.0), "после замираний при ударе время идёт нормально")


## A fresh training dummy standing on the floor (or floating at `center_y`).
func _dummy(at: Vector2, center_y := 1020.0 - TrainingDummy.SIZE.y / 2) -> TrainingDummy:
	for old in _dummies:
		if is_instance_valid(old):
			old.queue_free()
	_dummies.clear()
	var dummy := TrainingDummy.new()
	dummy.position = Vector2(at.x, center_y)
	_room.add_child(dummy)
	_dummies.append(dummy)
	await _frames(2)
	return dummy


## The largest sideways push of the dummy over the next `frames` frames.
func _max_push(dummy: TrainingDummy, frames: int) -> float:
	var largest := 0.0
	for i in frames:
		await _frames(1)
		largest = maxf(largest, absf(dummy.push()))
	return largest


func _newest_projectile() -> Projectile:
	var newest: Projectile = null
	for child in _room.get_children():
		if child is Projectile and not child.is_queued_for_deletion():
			newest = child
	return newest
