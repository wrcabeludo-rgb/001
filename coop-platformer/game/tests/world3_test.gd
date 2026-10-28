extends "res://tests/test_harness.gd"
## Headless checks of zone 3-3 "Ядро «Сердца»": the commander of the Lumen
## security and his phases, the comic after him, and the choice at the Heart
## (alone and together). Run by CI:
##   godot --headless --path game res://tests/world3_test.tscn

const SURFACE := 1560.0
const STAND_Y := SURFACE - Player.SIZE.y / 2.0
## The boss hall gates are at columns 324 and 378; the switches at 395 and 412.
const ARENA_LEFT := 324 * 60.0
const OFF_X := 395.5 * 60.0
const KEEP_X := 412.5 * 60.0

var _level: Level


func _init() -> void:
	room_scene = preload("res://scenes/tower_core_level.tscn")


func _run_all() -> void:
	_level = _room as Level
	await _test_commander()
	await _test_choice_together()
	await _test_choice_alone()
	await _test_choice_partner_down()


func _boss() -> Commander:
	for node in get_tree().get_nodes_in_group("bosses"):
		if node is Commander and not node.is_queued_for_deletion() and node.is_alive():
			return node
	return null


func _bullets() -> int:
	return _level.get_children().filter(func(n: Node) -> bool: return n is Projectile and not n.is_queued_for_deletion()).size()


func _test_commander() -> void:
	await _spawn(Heroes.Id.SWORDSMAN, Vector2(ARENA_LEFT + 500.0, STAND_Y))
	await _wait_for(func() -> bool: return _boss() != null, 60)
	var boss := _boss()
	_check(boss != null, "в зале появляется Командир охраны")
	if boss == null:
		return
	_player.revive(_player.global_position, 60.0)
	boss._start_attack(Commander.Attack.GUN, _player)
	var seen := {}
	for i in 150:
		await _frames(1)
		for n in _level.get_children():
			if n is Projectile:
				seen[n.get_instance_id()] = true
	_check(seen.size() >= 6, "Командир стреляет очередями (%d пуль)" % seen.size())
	await _wait_for(func() -> bool: return boss.state == Commander.State.IDLE, 200)
	boss.health.damage(boss.health.maximum / 3 + 2)
	await _wait_for(func() -> bool: return boss.phase == 2, 200)
	await _frames(5)
	var riflemen := get_tree().get_nodes_in_group("enemies").filter(func(n: Node) -> bool: return n is Rifleman).size()
	_check(boss.phase == 2 and riflemen == 2, "во второй фазе Командир зовёт двух автоматчиков (%d)" % riflemen)
	for node in get_tree().get_nodes_in_group("enemies"):
		if node is Rifleman:
			node.queue_free()
	await _wait_for(func() -> bool: return boss.state == Commander.State.IDLE, 200)
	var ground := boss.global_position.y
	boss._start_attack(Commander.Attack.ROCKETS, _player)
	var marks := 0
	var highest := ground
	for i in 120:
		await _frames(1)
		highest = minf(highest, boss.global_position.y)
		marks = maxi(marks, _level.get_children().filter(func(n: Node) -> bool: return n is Commander.Mark).size())
	_check(ground - highest > 200.0 and marks >= 4, "Командир взлетает и ставит метки ракет (%d)" % marks)
	await _wait_for(func() -> bool: return boss.state == Commander.State.IDLE and boss.is_on_floor(), 300)
	_check(boss.is_on_floor(), "после ракет Командир приземляется")
	boss.health.damage(boss.health.current - boss.health.maximum / 4)
	await _wait_for(func() -> bool: return boss.phase == 3, 200)
	await _wait_for(func() -> bool: return boss.state == Commander.State.IDLE, 200)
	boss._start_attack(Commander.Attack.ROCKETS, _player)
	# The zone's own Heart vents send waves too: count only the ones born at the boss.
	var waves := {}
	for i in 240:
		await _frames(1)
		for n in _level.get_children():
			if n is HeartPulse.Wave and absf(n.global_position.x - boss.global_position.x) < 40.0:
				waves[n.get_instance_id()] = true
	_check(boss.phase == 3 and waves.size() == 2, "в третьей фазе приземление бьёт волнами в обе стороны")
	boss.health.damage(boss.health.current)
	await _wait_for(func() -> bool: return get_tree().paused, 120)
	_check(get_tree().paused, "после победы над Командиром — комикс")
	var comics := _level.find_children("*", "Control", true, false).filter(func(n: Node) -> bool: return n.has_signal("finished"))
	if not comics.is_empty():
		comics[0].finished.emit()
	get_tree().paused = false
	await _frames(5)


func _test_choice_together() -> void:
	await _spawn(Heroes.Id.SHOOTER, Vector2(OFF_X - 60.0, STAND_Y))
	var partner := _spawn_extra(Heroes.Id.SWORDSMAN, Vector2(KEEP_X - 60.0, STAND_Y))
	_level.players[0] = _player
	_level.players[1] = partner
	_level.snap_camera()
	await _frames(5)
	_input.set_virtual("right", true)
	await _frames(2)
	_input.set_virtual("right", false)
	await _press("skill")
	_extra_inputs[0].set_virtual("attack", true)
	await _frames(2)
	_extra_inputs[0].set_virtual("attack", false)
	await _frames(20)
	_check(not _level.completed, "вдвоём разные рубильники — выбор не срабатывает")
	partner.global_position = Vector2(OFF_X - 60.0, STAND_Y)
	await _frames(30)
	_extra_inputs[0].set_virtual("attack", true)
	await _frames(2)
	_extra_inputs[0].set_virtual("attack", false)
	await _frames(20)
	_check(_level.completed and SaveGame.data["ending"] == "off" and _level.next_scene.ends_with("ending.tscn"),
		"оба выбрали «Погасить» — концовка «Погасить»")
	partner.queue_free()
	_level.players.erase(1)


func _test_choice_alone() -> void:
	var level := preload("res://scenes/tower_core_level.tscn").instantiate() as Level
	level.spawn_targets = false
	_room.queue_free()
	_room = level
	add_child(level)
	_level = level
	await _spawn(Heroes.Id.SHOOTER, Vector2(KEEP_X - 70.0, STAND_Y))
	_level.players[0] = _player
	_level.snap_camera()
	await _frames(5)
	await _press("skill")
	await _frames(20)
	_check(_level.completed and SaveGame.data["ending"] == "keep", "один герой бьёт «Оставить» — концовка «Оставить»")


## A fallen partner does not hold the choice back: the hero still standing decides.
func _test_choice_partner_down() -> void:
	var level := preload("res://scenes/tower_core_level.tscn").instantiate() as Level
	level.spawn_targets = false
	_room.queue_free()
	_room = level
	add_child(level)
	_level = level
	SaveGame.data["completed"] = false
	await _spawn(Heroes.Id.SHOOTER, Vector2(OFF_X - 70.0, STAND_Y))
	var partner := _spawn_extra(Heroes.Id.SWORDSMAN, Vector2(OFF_X - 200.0, STAND_Y))
	_level.players[0] = _player
	_level.players[1] = partner
	_level.snap_camera()
	await _frames(5)
	partner.kill()
	await _frames(2)
	await _press("skill")
	await _frames(20)
	_check(_level.completed and SaveGame.data["ending"] == "off" and SaveGame.data["completed"],
		"напарник погиб — выбор у «Сердца» делает тот, кто стоит на ногах")
	partner.queue_free()
	_level.players.erase(1)


func _wait_for(condition: Callable, max_frames: int) -> void:
	for i in max_frames:
		if condition.call():
			return
		await _frames(1)
