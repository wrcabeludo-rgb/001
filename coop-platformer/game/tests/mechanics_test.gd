extends "res://tests/test_harness.gd"
## Headless checks of the level mechanics, placed one by one in the quiet test
## room (open space: columns 24..28, floor top y = 1020). Run by CI:
##   godot --headless --path game res://tests/mechanics_test.tscn

const FLOOR_TOP := 1020.0
## Middle of column 26 of the test room.
const COL_X := 1590.0

var _level: Level
var _things: Array[Node] = []


func _run_all() -> void:
	_level = _room as Level
	await _test_one_way_platform()
	await _test_ladder()
	await _test_rope()
	await _test_moving_platform_carries()
	await _test_lift()
	await _test_crumbling_block()
	await _test_spikes_throw_up()
	await _test_acid()
	await _test_laser_warns_then_burns()
	await _test_flamethrower()
	await _test_debris()
	await _test_barrel()
	await _test_cover()
	await _test_lever_opens_door()
	await _test_arena()
	await _test_team_wipe_restores_mechanics()
	await _test_conveyor()
	await _test_crates_ride_conveyor()
	await _test_press()
	await _test_steam_vent()
	await _test_electro_floor()
	await _test_molten()
	await _test_crane()


func _test_one_way_platform() -> void:
	_clear()
	# Row 15: top at y = 900, 120 above the floor.
	var body := _add(_one_way_body()) as StaticBody2D
	_level.add_one_way(body, Rect2(1440, 900, 300, 60))
	await _spawn(Heroes.Id.SWORDSMAN, Vector2(COL_X, FLOOR_Y))
	await _press("jump", 20)
	await _frames(40)
	_check(_player.is_on_floor() and _feet() < 905.0, "на площадку запрыгивают снизу насквозь (ноги на %.0f)" % _feet())
	_input.set_virtual("down", true)
	await _press("jump")
	_input.set_virtual("down", false)
	await _frames(40)
	_check(_player.is_on_floor() and _feet() > 1015.0, "вниз + прыжок — спрыгнуть с площадки (ноги на %.0f)" % _feet())


func _test_ladder() -> void:
	_clear()
	# Rungs in rows 12..16 of column 26; the ledge is row 11 (top y = 660).
	var body := _add(_one_way_body()) as StaticBody2D
	_level.add_one_way(body, Rect2(1560, 660, 60, 60))
	_add_climbable(Climbable.Kind.LADDER, Rect2(1560, 720, 60, 300))
	await _spawn(Heroes.Id.SHOOTER, Vector2(COL_X - 20, FLOOR_Y))
	_input.set_virtual("up", true)
	await _frames(5)
	var grabbed := _player.is_climbing()
	await _frames(80)
	_input.set_virtual("up", false)
	await _frames(10)
	_check(grabbed, "вверх у лестницы — герой хватается за неё")
	_check(not _player.is_climbing() and _player.is_on_floor() and absf(_feet() - 660.0) < 3.0,
		"по лестнице герой поднимается на площадку наверху (ноги на %.0f)" % _feet())
	_input.set_virtual("down", true)
	await _frames(20)
	var down_grab := _player.is_climbing() and _feet() > 670.0
	await _frames(70)
	_input.set_virtual("down", false)
	await _frames(5)
	_check(down_grab and _feet() > 1015.0 and not _player.is_climbing(), "сверху вниз по лестнице до пола")
	_input.set_virtual("up", true)
	await _frames(25)
	_input.set_virtual("up", false)
	await _press("jump")
	await _frames(5)
	_check(not _player.is_climbing() and _player.velocity.y < 0.0, "прыжок отпускает лестницу")


func _test_rope() -> void:
	_clear()
	_add_climbable(Climbable.Kind.ROPE, Rect2(1560, 600, 60, 240))
	await _spawn(Heroes.Id.SWORDSMAN, Vector2(COL_X, 800))
	var y := _player.global_position.y
	await _frames(30)
	_check(_player.is_climbing() and absf(_player.global_position.y - y) < 4.0, "герой в воздухе цепляется за канат и висит")
	_input.set_virtual("right", true)
	await _press("jump")
	await _frames(20)
	_input.set_virtual("right", false)
	_check(not _player.is_climbing() and _player.global_position.x > COL_X + 40.0, "прыжок с каната в сторону")


func _test_moving_platform_carries() -> void:
	_clear()
	var platform := MovingPlatform.new()
	platform.setup(MovingPlatform.Mode.SHUTTLE, Vector2(1320, 940), Vector2(1700, 940), 180)
	platform.pause_time = 0.0
	_add(platform)
	await _spawn(Heroes.Id.SHOOTER, Vector2(1320, 940 - Player.SIZE.y / 2.0 - 1.0))
	await _frames(90)
	_check(_player.is_on_floor() and _player.global_position.x > 1500.0 and absf(_feet() - platform.position.y) < 3.0,
		"движущаяся платформа везёт героя (x %.0f)" % _player.global_position.x)


func _test_lift() -> void:
	_clear()
	var lift := MovingPlatform.new()
	lift.setup(MovingPlatform.Mode.LIFT, Vector2(COL_X, 1000), Vector2(COL_X, 640), 180)
	_add(lift)
	await _frames(40)
	_check(lift.position.y == 1000.0, "лифт без героя стоит внизу")
	await _spawn(Heroes.Id.SWORDSMAN, Vector2(COL_X, 1000 - Player.SIZE.y / 2.0 - 1.0))
	await _frames(120)
	_check(absf(lift.position.y - 640.0) < 1.0 and absf(_feet() - 640.0) < 4.0, "лифт поднимает стоящего на нём героя")
	_player.global_position = Vector2(1400, FLOOR_Y)
	await _frames(200)
	_check(lift.position.y > 990.0, "пустой лифт уезжает вниз")


func _test_crumbling_block() -> void:
	_clear()
	var block := CrumblingBlock.new()
	block.setup(Rect2(1560, 900, 60, 60))
	_add(block)
	await _spawn(Heroes.Id.SHOOTER, Vector2(COL_X, 900 - Player.SIZE.y / 2.0 - 1.0))
	await _frames(10)
	var held := _player.is_on_floor() and block.state == CrumblingBlock.State.SHAKING
	await _frames(40)
	_check(held, "рушащийся блок сначала держит и трясётся")
	_check(block.state == CrumblingBlock.State.GONE and _feet() > 1000.0, "через полсекунды блок рушится, герой падает")
	_player.global_position = Vector2(1300, FLOOR_Y)
	await _frames(int(block.return_time * 60.0) + 10)
	_check(block.state == CrumblingBlock.State.SOLID, "через несколько секунд блок возвращается")


func _test_spikes_throw_up() -> void:
	_clear()
	var spikes := Hazard.new()
	spikes.setup(Hazard.Kind.SPIKES, Rect2(1440, 960, 300, 60))
	_add(spikes)
	await _spawn(Heroes.Id.SHOOTER, Vector2(1480, 900))
	var lowest := 0.0
	var hurt := false
	for i in 40:
		await _frames(1)
		hurt = hurt or _player.health.current < _player.health.maximum
		if hurt:
			lowest = minf(lowest, _player.velocity.y)
	_check(hurt and lowest < -500.0, "шипы ранят и подбрасывают вверх")
	_check(_player.velocity.x < 0.0 or _player.global_position.x < 1480.0, "шипы отбрасывают к ближнему краю")


func _test_acid() -> void:
	_clear()
	var acid := Hazard.new()
	acid.setup(Hazard.Kind.ACID, Rect2(1440, 960, 300, 60))
	_add(acid)
	await _spawn(Heroes.Id.SWORDSMAN, Vector2(1700, 900))
	await _frames(30)
	_check(_player.health.current < _player.health.maximum, "кислота ранит")


func _test_laser_warns_then_burns() -> void:
	_clear()
	var laser := Laser.new()
	laser.off_time = 0.2
	laser.setup(Vector2(COL_X, 600), 420.0)
	_add(laser)
	await _spawn(Heroes.Id.SHOOTER, Vector2(COL_X, FLOOR_Y))
	await _frames(20)
	var warned := laser.state == Laser.State.WARNING and _player.health.current == _player.health.maximum
	await _frames(40)
	_check(warned, "лазер сначала мигает тонкой линией и не ранит")
	_check(_player.health.current < _player.health.maximum, "потом луч ранит")


func _test_flamethrower() -> void:
	_clear()
	var flamer := Flamethrower.new()
	flamer.idle_time = 0.2
	flamer.setup(Vector2(1460, 980), 1, 250.0)
	_add(flamer)
	await _spawn(Heroes.Id.SWORDSMAN, Vector2(1620, FLOOR_Y))
	await _frames(20)
	var warned := flamer.state == Flamethrower.State.WARNING and _player.health.current == _player.health.maximum
	await _frames(50)
	_check(warned, "огнемёт сначала искрит")
	_check(_player.health.current < _player.health.maximum and _player.global_position.x > 1620.0, "огонь ранит и отбрасывает")


func _test_debris() -> void:
	_clear()
	var debris := DebrisSpot.new()
	debris.setup(Vector2(COL_X, 600))
	_add(debris)
	await _spawn(Heroes.Id.SHOOTER, Vector2(COL_X, FLOOR_Y))
	await _frames(15)
	var warned := debris.state == DebrisSpot.State.WARNING
	for i in 60:
		await _frames(1)
		if _player.health.current < _player.health.maximum:
			break
	_check(warned, "обломок сначала трясётся над героем")
	_check(_player.health.current < _player.health.maximum, "упавший обломок ранит")


func _test_barrel() -> void:
	_clear()
	var barrel := _barrel(1500.0)
	var other := _barrel(1650.0)
	var walker := _add(Walker.new()) as Walker
	walker.position = Vector2(1580, FLOOR_TOP - walker.body_size.y / 2.0)
	walker.walk_speed = 0.0
	walker.chase_speed = 0.0
	await _spawn(Heroes.Id.SWORDSMAN, Vector2(1380, FLOOR_Y))
	await _frames(2)
	var walker_health := walker.health.current
	barrel.receive_hit(Hit.make(1, Vector2.ZERO, barrel.global_position))
	await _frames(45)
	_check(barrel.state == Barrel.State.GONE, "бочка взрывается после удара")
	_check(not is_instance_valid(walker) or walker.health.current < walker_health, "взрыв ранит врага")
	_check(_player.health.current < _player.health.maximum, "взрыв ранит героя рядом")
	_check(other.state == Barrel.State.GONE, "взрыв поджигает соседнюю бочку")


func _test_cover() -> void:
	_clear()
	var cover := _add(Cover.new()) as Cover
	cover.position = Vector2(1500, FLOOR_TOP - Cover.SIZE.y / 2.0)
	await _spawn(Heroes.Id.SHOOTER, Vector2(1420, FLOOR_Y))
	var bullet := Projectile.new()
	bullet.setup(Layers.Team.ENEMIES, Vector2(1740, 980), Vector2.LEFT, 600.0, 2, 300.0, Vector2(20, 20), Color.RED, 0, 3.0)
	_add(bullet)
	await _frames(60)
	_check(_player.health.current == _player.health.maximum, "укрытие закрывает от пуль")
	_check(cover.health.current < cover.health.maximum, "пули понемногу разбивают укрытие")


func _test_lever_opens_door() -> void:
	_clear()
	var door := Door.new()
	door.setup(Rect2(1620, 780, 60, 240))
	_add(door)
	var lever := Lever.new()
	lever.position = Vector2(1380, FLOOR_TOP)
	lever.door = door
	_add(lever)
	await _spawn(Heroes.Id.SWORDSMAN, Vector2(1500, FLOOR_Y))
	_input.set_virtual("right", true)
	await _frames(50)
	var blocked := _player.global_position.x < 1620.0
	_input.set_virtual("right", false)
	lever.receive_hit(Hit.make(1, Vector2.ZERO, lever.global_position))
	_input.set_virtual("right", true)
	await _frames(50)
	_input.set_virtual("right", false)
	_check(blocked, "закрытая дверь не пускает")
	_check(door.is_open and _player.global_position.x > 1680.0, "удар по рычагу открывает дверь")


func _test_arena() -> void:
	_clear()
	var left := Door.new()
	left.setup(Rect2(1260, 720, 60, 300), true, true)
	var right := Door.new()
	right.setup(Rect2(1800, 720, 60, 300), true, true)
	_add(left)
	_add(right)
	var arena := Arena.new()
	arena.setup(_level, left, right, [[["w", Vector2(1700, FLOOR_TOP)]], [["w", Vector2(1400, FLOOR_TOP)]]])
	_add(arena)
	await _spawn(Heroes.Id.SHOOTER, Vector2(1100, FLOOR_Y))
	var partner := _spawn_extra(Heroes.Id.SWORDSMAN, Vector2(1000, FLOOR_Y))
	_things.append(partner)
	await _frames(10)
	var waited := arena.state == Arena.State.WAITING and left.is_open
	_player.global_position = Vector2(1560, FLOOR_Y)
	_player.last_safe_position = _player.global_position
	await _frames(5)
	_check(waited, "арена ждёт, пока герой не войдёт")
	_check(arena.state == Arena.State.FIGHT and not left.is_open and not right.is_open, "герой вошёл — ворота закрылись")
	_check(partner.global_position.x > 1290.0 and partner.global_position.x < 1800.0, "напарника переносит внутрь")
	for i in 2:
		await _frames(5)
		# Hit after the physics step, like a hero's attack landing after the arena's
		# check: the beaten enemy is already freed when the arena looks again.
		await get_tree().process_frame
		for enemy in get_tree().get_nodes_in_group("enemies"):
			enemy.receive_hit(Hit.make(100, Vector2.ZERO, enemy.global_position))
		await _frames(5)
		if i == 0:
			_check(arena.state == Arena.State.FIGHT and arena.wave == 1, "после первой волны — вторая")
	await _frames(5)
	_check(arena.state == Arena.State.CLEARED and left.is_open and right.is_open, "после последней волны ворота открываются")
	partner.queue_free()


func _test_team_wipe_restores_mechanics() -> void:
	_clear()
	var barrel := _barrel(1500.0)
	barrel.explode()
	await _frames(3)
	_level.reset_mechanics()
	await _frames(3)
	_check(barrel.state == Barrel.State.READY and barrel.visible, "после гибели команды бочки возвращаются")


func _test_conveyor() -> void:
	_clear()
	var belt := Conveyor.new()
	belt.setup(Rect2(1260, 900, 480, 60), 1)
	_add(belt)
	await _spawn(Heroes.Id.SHOOTER, Vector2(1320, 900 - Player.SIZE.y / 2.0 - 1.0))
	await _frames(60)
	var carried := _player.global_position.x - 1320.0
	_check(_player.is_on_floor() and carried > 150.0 and carried < 260.0,
		"конвейер везёт стоящего героя (%.0f px за секунду)" % carried)
	_player.global_position = Vector2(1680, 900 - Player.SIZE.y / 2.0 - 1.0)
	await _frames(10)
	var start := _player.global_position.x
	_input.set_virtual("left", true)
	await _frames(60)
	_input.set_virtual("left", false)
	var walked := start - _player.global_position.x
	_check(walked > 120.0 and walked < 320.0, "против хода ленты идти можно, но медленно (%.0f px за секунду)" % walked)
	# A belt that ends in the air drops whoever stands still.
	_player.global_position = Vector2(1700, 900 - Player.SIZE.y / 2.0 - 1.0)
	await _frames(40)
	_check(_feet() > 960.0, "лента сбрасывает героя с края (ноги на %.0f)" % _feet())


func _test_crates_ride_conveyor() -> void:
	_clear()
	var belt := Conveyor.new()
	belt.setup(Rect2(1260, 900, 480, 60), 1)
	_add(belt)
	var chute := CrateChute.new()
	chute.interval = 10.0
	chute.setup(Vector2(1320, 600), 9.9)
	_add(chute)
	await _frames(40)
	var crates := get_tree().get_nodes_in_group("crates")
	var crate: Node2D = crates[0] if not crates.is_empty() else null
	var landed_x := crate.global_position.x if crate != null else 0.0
	var on_belt := crate != null and absf(crate.global_position.y + 28.0 - 900.0) < 4.0
	await _frames(30)
	_check(on_belt and crate.global_position.x > landed_x + 60.0, "ящик падает из люка на ленту и едет по ней")
	crate.queue_free()
	await _spawn(Heroes.Id.SHOOTER, Vector2(1400, FLOOR_Y))
	belt.queue_free()
	chute.setup(Vector2(1400, 700), 9.95)
	await _frames(30)
	_check(_player.health.current < _player.health.maximum, "падающий ящик ранит героя")
	for node in get_tree().get_nodes_in_group("crates"):
		node.queue_free()


func _test_press() -> void:
	_clear()
	var press := Press.new()
	press.up_time = 0.2
	press.setup(Vector2(COL_X, 600), 120.0, 420.0)
	_add(press)
	await _spawn(Heroes.Id.SWORDSMAN, Vector2(COL_X, FLOOR_Y))
	await _frames(20)
	var warned := press.state == Press.State.WARNING and _player.health.current == _player.health.maximum
	await _frames(40)
	_check(warned, "пресс сначала мигает лампой и не ранит")
	_check(_player.health.current == _player.health.maximum - press.hero_damage,
		"пресс бьёт стоящего под ним героя (здоровье %d)" % _player.health.current)
	_check(absf(_player.global_position.x - COL_X) > 40.0, "пресс отбрасывает героя в сторону")


func _test_steam_vent() -> void:
	_clear()
	var vent := SteamVent.new()
	vent.idle_time = 0.1
	vent.warning_time = 0.1
	vent.setup(Vector2(COL_X, FLOOR_TOP))
	_add(vent)
	await _spawn(Heroes.Id.SHOOTER, Vector2(COL_X, FLOOR_Y))
	var highest := FLOOR_TOP
	for i in 70:
		await _frames(1)
		highest = minf(highest, _feet())
	_check(FLOOR_TOP - highest > 280.0 and _player.health.current == _player.health.maximum,
		"паровой клапан подбрасывает героя высоко вверх (на %.0f px) и не ранит" % (FLOOR_TOP - highest))


func _test_electro_floor() -> void:
	_clear()
	var electro := ElectroFloor.new()
	electro.off_time = 0.2
	electro.setup(Rect2(1440, 900, 300, 60))
	_add(electro)
	await _spawn(Heroes.Id.SWORDSMAN, Vector2(1560, 900 - Player.SIZE.y / 2.0 - 1.0))
	await _frames(30)
	var warned := electro.state == ElectroFloor.State.WARNING and _player.health.current == _player.health.maximum
	await _frames(40)
	_check(warned, "электропол сначала мигает и не бьёт")
	_check(_player.health.current < _player.health.maximum, "потом электропол бьёт током стоящего на нём")


func _test_molten() -> void:
	_clear()
	var molten := Hazard.new()
	molten.setup(Hazard.Kind.MOLTEN, Rect2(1440, 960, 300, 60))
	_add(molten)
	await _spawn(Heroes.Id.SWORDSMAN, Vector2(1600, 900))
	var lowest := 0.0
	for i in 30:
		await _frames(1)
		lowest = minf(lowest, _player.velocity.y)
	_check(_player.health.current == _player.health.maximum - 3 and lowest < -900.0,
		"расплав ранит сильнее кислоты и подбрасывает выше")


func _test_crane() -> void:
	_clear()
	var crane := Crane.new()
	crane.setup(MovingPlatform.Mode.SHUTTLE, Vector2(1320, 940), Vector2(1700, 940), 180)
	crane.rail_y = 600.0
	_add(crane)
	crane.pause_time = 0.0
	await _spawn(Heroes.Id.SHOOTER, Vector2(1320, 940 - Player.SIZE.y / 2.0 - 1.0))
	await _frames(120)
	_check(_player.is_on_floor() and _player.global_position.x > 1500.0, "кран везёт героя (x %.0f)" % _player.global_position.x)


func _feet() -> float:
	return _player.global_position.y + Player.SIZE.y / 2.0


func _add(node: Node) -> Node:
	_room.add_child(node)
	_things.append(node)
	return node


func _one_way_body() -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = Layers.ONE_WAY
	body.collision_mask = 0
	return body


func _add_climbable(kind: Climbable.Kind, cells: Rect2) -> Climbable:
	var climbable := Climbable.new()
	climbable.setup(kind, cells, Level.TILE)
	_add(climbable)
	return climbable


func _barrel(x: float) -> Barrel:
	var barrel := Barrel.new()
	barrel.position = Vector2(x, FLOOR_TOP - Barrel.SIZE.y / 2.0)
	_add(barrel)
	return barrel


func _clear() -> void:
	if _player != null:
		_player.free()
		_player = null
	for node in _things:
		if is_instance_valid(node):
			node.queue_free()
	_things.clear()
	for child in _room.get_children():
		if child is Projectile or child is Pickup or child is Enemy:
			child.queue_free()
