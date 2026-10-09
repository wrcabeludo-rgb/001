extends "res://tests/test_harness.gd"
## Headless checks of zone 2-3 "Насосная станция": the chase with the giant
## loader, the world 2 boss and its phases, finishing the world. Run by CI:
##   godot --headless --path game res://tests/world2_test.tscn

const SURFACE := 1560.0
const STAND_Y := SURFACE - Player.SIZE.y / 2.0
## The chase starts at column 382; the boss hall gates are at 503 and 557.
const CHASE_X := 382 * 60.0
const ARENA_LEFT := 503 * 60.0
const ARENA_RIGHT := 558 * 60.0

var _level: Level


func _init() -> void:
	room_scene = preload("res://scenes/pumping_level.tscn")


func _run_all() -> void:
	_level = _room as Level
	await _test_chase()
	await _test_team_wipe_resets_chase()
	await _test_boss_fight()
	await _test_exit_finishes_world()


func _chase() -> Chase:
	for child in _level.get_children():
		if child is Chase:
			return child
	return null


func _boss() -> LoaderBoss:
	for node in get_tree().get_nodes_in_group("bosses"):
		if node is LoaderBoss and not node.is_queued_for_deletion() and node.is_alive():
			return node
	return null


func _test_chase() -> void:
	var chase := _chase()
	await _spawn(Heroes.Id.SHOOTER, Vector2(CHASE_X - 120.0, STAND_Y))
	await _frames(10)
	var idle := not chase.running
	_player.global_position.x = CHASE_X + 60.0
	await _frames(5)
	_check(idle and chase.running and chase.front_x() < CHASE_X, "за линией погони сзади появляется погрузчик")
	var front := chase.front_x()
	await _frames(60)
	_check(chase.front_x() > front + 150.0, "погрузчик едет за героями (%.0f px за секунду)" % (chase.front_x() - front))
	# Standing still, the hero is caught: hurt and flung out in front.
	var health := _player.health.current
	await _wait_for(func() -> bool: return _player.health.current < health, 900)
	await _frames(5)
	_check(_player.health.current < health and _player.global_position.x > chase.front_x(),
		"догнал — ранит и отбрасывает героя вперёд, а не за себя")
	_player.global_position.x = ARENA_LEFT + 300.0
	await _wait_for(func() -> bool: return chase.finished, 1800)
	_check(chase.finished and chase.front_x() <= ARENA_LEFT + 60.0, "погоня кончается у ворот зала босса")


func _test_team_wipe_resets_chase() -> void:
	var chase := _chase()
	_level.reset_enemies()
	_level.reset_mechanics()
	await _frames(2)
	_check(not chase.running and not chase.finished, "команда пала — погоня начнётся заново")
	for node in get_tree().get_nodes_in_group("crates"):
		node.queue_free()


func _test_boss_fight() -> void:
	await _spawn(Heroes.Id.SWORDSMAN, Vector2(ARENA_LEFT + 600.0, STAND_Y))
	await _wait_for(func() -> bool: return _boss() != null, 60)
	var boss := _boss()
	_check(boss != null, "в зале появляется Погрузчик «Люмена»")
	if boss == null:
		return
	# The claw: a red mark first, then it comes down on the hero.
	var marked := false
	var health := _player.health.current
	boss._start_attack(LoaderBoss.Attack.CLAW, _player)
	for i in 300:
		await _frames(1)
		_player.global_position.x = ARENA_LEFT + 600.0
		marked = marked or boss._mark.visible
		if _player.health.current < health and boss.state == LoaderBoss.State.STUCK:
			break
	_check(marked and _player.health.current < health, "манипулятор: сначала красная метка, потом удар")
	_player.revive(_player.global_position, 30.0)
	# Phase 2: armour; the open core takes extra damage.
	boss.health.damage(boss.health.maximum / 3 + 1)
	await _wait_for(func() -> bool: return boss.phase == 2, 300)
	var before := boss.health.current
	boss.state = LoaderBoss.State.IDLE
	boss.receive_hit(Hit.make(10, Vector2.ZERO, boss.global_position))
	var armoured := before - boss.health.current
	boss.state = LoaderBoss.State.STUCK
	boss._timer = 1.0
	before = boss.health.current
	boss.receive_hit(Hit.make(10, Vector2.ZERO, boss.global_position))
	var open := before - boss.health.current
	_check(boss.phase == 2 and armoured <= 3 and open >= 15,
		"во второй фазе броня держит удар (%d), а открытый реактор — нет (%d)" % [armoured, open])
	# Phase 3: rams across the hall.
	boss.state = LoaderBoss.State.IDLE
	boss.health.damage(boss.health.current - boss.health.maximum / 4)
	await _wait_for(func() -> bool: return boss.phase == 3, 300)
	await _wait_for(func() -> bool: return boss.state == LoaderBoss.State.IDLE, 300)
	boss._start_attack(LoaderBoss.Attack.RAM, _player)
	var rammed := false
	for i in 900:
		await _frames(1)
		if boss.state == LoaderBoss.State.RAM:
			rammed = true
			break
	_check(boss.phase == 3 and rammed, "в третьей фазе погрузчик идёт на таран")
	boss.health.damage(boss.health.current)
	await _wait_for(func() -> bool: return not _gates_closed(), 300)
	_check(_boss() == null and not _gates_closed(), "погрузчик повержен — ворота открываются")


func _gates_closed() -> bool:
	for child in _level.get_children():
		if child is Door and child.gate and child.position.x > ARENA_LEFT - 60.0 and not child.is_open:
			return true
	return false


func _test_exit_finishes_world() -> void:
	await _spawn(Heroes.Id.SHOOTER, Vector2(ARENA_RIGHT + 300.0, STAND_Y))
	_input.set_virtual("right", true)
	await _wait_for(func() -> bool: return _level.completed, 300)
	_input.set_virtual("right", false)
	_check(_level.completed and _level.next_scene.ends_with("world2_ending.tscn"),
		"выход из насосной — комикс конца второго мира")


func _wait_for(condition: Callable, max_frames: int) -> void:
	for i in max_frames:
		if condition.call():
			return
		await _frames(1)
