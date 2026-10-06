extends "res://tests/test_harness.gd"
## Headless enemy and loot checks in the quiet test room, run by CI:
##   godot --headless --path game res://tests/enemy_test.tscn

const HERO_X := 1450.0
const FLOOR_TOP := 1020.0

var _enemies: Array[Node] = []


func _run_all() -> void:
	await _test_walker_stays_on_platform()
	await _test_walker_touch_hurts()
	await _test_enemy_drops_scrap()
	await _test_pickups_go_to_who_needs_them()
	await _test_charger_warns_then_charges()
	await _test_heavy_warns_then_slams()
	await _test_dash_passes_through_enemies()
	await _test_drone_dives()
	await _test_turret_warns_then_fires()
	await _test_ambusher_drops()
	await _test_level_brings_enemies_back()


func _test_walker_stays_on_platform() -> void:
	_clear()
	# Platform at columns 16..18 of the test room: x 960..1140, top y 660.
	var walker := _enemy(Walker.new(), 1050.0, 660.0)
	var low := 99999.0
	var high := -99999.0
	for i in 240:
		await _frames(1)
		low = minf(low, walker.global_position.x)
		high = maxf(high, walker.global_position.x)
	_check(high - low > 40.0, "ходок патрулирует (прошёл %.0f px)" % (high - low))
	_check(walker.is_on_floor() and low >= 960.0 and high <= 1140.0, "ходок не падает с платформы")


func _test_walker_touch_hurts() -> void:
	_clear()
	await _spawn(Heroes.Id.SHOOTER, Vector2(HERO_X, FLOOR_Y))
	_enemy(Walker.new(), 1650.0)
	for i in 120:
		await _frames(1)
		if _player.health.current < _player.health.maximum:
			break
	_check(_player.health.current < _player.health.maximum, "ходок бежит к герою и ранит касанием")


func _test_enemy_drops_scrap() -> void:
	_clear()
	await _spawn(Heroes.Id.SHOOTER, Vector2(400, FLOOR_Y))
	var walker := _enemy(Walker.new(), 1650.0)
	await _frames(2)
	walker.receive_hit(Hit.make(100, Vector2.ZERO, walker.global_position))
	await _frames(3)
	var scrap := 0
	for pickup in get_tree().get_nodes_in_group("pickups"):
		if pickup.kind == Pickup.Kind.SCRAP:
			scrap += pickup.amount
	_check(not is_instance_valid(walker) or walker.is_queued_for_deletion(), "ходок погибает")
	_check(scrap >= 1, "из врага выпадает лом (%d)" % scrap)


func _test_pickups_go_to_who_needs_them() -> void:
	_clear()
	await _spawn(Heroes.Id.SWORDSMAN, Vector2(HERO_X, FLOOR_Y))
	_player.health.damage(5)
	var hurt := _player.health.current
	var kit := _pickup(Pickup.Kind.HEALTH, 3, _player.global_position)
	var ammo := _pickup(Pickup.Kind.AMMO, 5, _player.global_position)
	await _frames(20)
	_check(_player.health.current == hurt + 3 and not is_instance_valid(kit), "аптечку забирает раненый герой")
	_check(is_instance_valid(ammo), "патроны мечник не подбирает — они остаются стрелку")

	var shooter_input := PlayerInput.scripted()
	_extra_inputs.append(shooter_input)
	var shooter := _make_hero(Heroes.Id.SHOOTER, _player.global_position, shooter_input, 1)
	var gun := shooter.combat as ShooterCombat
	gun.ammo = 3
	await _frames(20)
	_check(gun.ammo == 8 and not is_instance_valid(ammo), "стрелок подбирает патроны")
	shooter.queue_free()


func _test_charger_warns_then_charges() -> void:
	_clear()
	await _spawn(Heroes.Id.SHOOTER, Vector2(HERO_X, FLOOR_Y))
	var charger := _enemy(Charger.new(), 1800.0) as Charger
	var early := 0.0
	var late := 0.0
	var warned := false
	for i in 80:
		await _frames(1)
		warned = warned or charger.is_telegraphing()
		if i < 25:
			early = maxf(early, absf(charger.velocity.x))
		else:
			late = maxf(late, absf(charger.velocity.x))
	_check(warned, "рывковый мигает перед атакой")
	_check(early < 300.0 and late > 800.0, "сначала предупреждение, потом рывок (%.0f → %.0f px/с)" % [early, late])


func _test_heavy_warns_then_slams() -> void:
	_clear()
	await _spawn(Heroes.Id.SWORDSMAN, Vector2(HERO_X, FLOOR_Y))
	var heavy := _enemy(Heavy.new(), HERO_X + 130.0) as Heavy
	await _frames(25)
	var during_warning := _player.health.current
	var warned := heavy.is_telegraphing()
	await _frames(60)
	_check(warned and during_warning == _player.health.maximum, "тяжёлый замахивается, пока не бьёт")
	_check(_player.health.current <= _player.health.maximum - heavy.slam_damage, "после замаха — удар по земле")


func _test_dash_passes_through_enemies() -> void:
	_clear()
	await _spawn(Heroes.Id.SWORDSMAN, Vector2(1300, FLOOR_Y))
	var walker := _enemy(Walker.new(), 1400.0) as Walker
	walker.walk_speed = 0.0
	walker.chase_speed = 0.0
	await _frames(2)
	await _press("skill")
	await _frames(14)
	_check(_player.global_position.x > 1440.0, "рывок проносит мечника сквозь врага")
	_check(_player.health.current == _player.health.maximum, "во время рывка враг не ранит")


func _test_drone_dives() -> void:
	_clear()
	await _spawn(Heroes.Id.SHOOTER, Vector2(OPEN_X, FLOOR_Y))
	var drone := _enemy_at(Drone.new(), Vector2(OPEN_X, 700.0)) as Drone
	var lowest := drone.global_position.y
	var warned := false
	for i in 90:
		await _frames(1)
		warned = warned or drone.is_telegraphing()
		lowest = maxf(lowest, drone.global_position.y)
	_check(warned and lowest > 850.0, "дрон мигает и пикирует на героя (до y %.0f)" % lowest)


func _test_turret_warns_then_fires() -> void:
	_clear()
	await _spawn(Heroes.Id.SHOOTER, Vector2(HERO_X, FLOOR_Y))
	_enemy(GunTurret.new(), 1800.0)
	var first_shot := -1
	for i in 150:
		await _frames(1)
		if _enemy_bullets() > 0:
			first_shot = i
			break
	_check(first_shot >= 30, "турель стреляет не сразу, а после зарядки (кадр %d)" % first_shot)


func _test_ambusher_drops() -> void:
	_clear()
	# Platform at columns 12..14: x 720..900, its underside at y = 840.
	var ambusher := _enemy_at(Ambusher.new(), Vector2(810, 840 + 25)) as Ambusher
	await _frames(20)
	var still_hanging := ambusher.global_position.y < 870.0
	await _spawn(Heroes.Id.SHOOTER, Vector2(810, FLOOR_Y))
	await _frames(90)
	_check(still_hanging, "засадник висит, пока внизу никого нет")
	_check(ambusher.state == Ambusher.State.DROPPED and ambusher.is_on_floor(), "засадник падает на героя снизу")


func _test_level_brings_enemies_back() -> void:
	_clear()
	var level := _room as Level
	var walker := level.spawn_enemy("w", Vector2(1650, FLOOR_TOP))
	level._enemy_spots.append(["w", Vector2(1650, FLOOR_TOP)])
	walker.receive_hit(Hit.make(100, Vector2.ZERO, walker.global_position))
	await _frames(3)
	level.reset_enemies()
	await _frames(3)
	var count := 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy.is_queued_for_deletion():
			count += 1
	_check(count == 1, "после гибели команды враги возвращаются (%d)" % count)
	level._enemy_spots.clear()


## An enemy standing on the floor (top at `floor_top`) at `x`.
func _enemy(enemy: Enemy, x: float, floor_top := FLOOR_TOP) -> Enemy:
	return _enemy_at(enemy, Vector2(x, floor_top - enemy.body_size.y / 2.0))


func _enemy_at(enemy: Enemy, at: Vector2) -> Enemy:
	enemy.position = at
	_room.add_child(enemy)
	_enemies.append(enemy)
	return enemy


func _pickup(kind: Pickup.Kind, amount: int, at: Vector2) -> Pickup:
	var pickup := Pickup.new()
	pickup.setup(kind, amount, at, Vector2.ZERO)
	_room.add_child(pickup)
	_enemies.append(pickup)
	return pickup


func _enemy_bullets() -> int:
	var count := 0
	for child in _room.get_children():
		if child is Projectile and not child.is_queued_for_deletion():
			count += 1
	return count


func _clear() -> void:
	for node in _enemies:
		if is_instance_valid(node):
			node.queue_free()
	_enemies.clear()
	for child in _room.get_children():
		if child is Projectile or child is Pickup:
			child.queue_free()
