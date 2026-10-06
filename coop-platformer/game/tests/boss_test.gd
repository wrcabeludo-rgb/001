extends "res://tests/test_harness.gd"
## Headless checks of the vertical slice (level 1-1 "Трущобы"): difficulty,
## the boss and its phases, finishing the level. Run by CI:
##   godot --headless --path game res://tests/boss_test.tscn

## The level's floor top (surface row 26) and where a hero stands on it.
const SURFACE := 1560.0
const STAND_Y := SURFACE - Player.SIZE.y / 2.0
## Boss arena: gates at columns 320 and 350.
const ARENA_LEFT := 320 * 60.0
const ARENA_RIGHT := 351 * 60.0

var _level: Level


func _init() -> void:
	room_scene = preload("res://scenes/slums_level.tscn")


func _run_all() -> void:
	_level = _room as Level
	await _test_difficulty()
	await _test_team_wipe_restarts_boss()
	await _test_boss_fight()
	await _test_exit_finishes_level()


func _test_difficulty() -> void:
	GameSettings.difficulty = GameSettings.Difficulty.EASY
	var easy_damage := GameSettings.damage_to_heroes(4)
	var easy_health := GameSettings.enemy_health(20)
	GameSettings.difficulty = GameSettings.Difficulty.HARD
	var hard_damage := GameSettings.damage_to_heroes(4)
	var hard_health := GameSettings.enemy_health(20)
	GameSettings.difficulty = GameSettings.Difficulty.NORMAL
	_check(easy_damage < 4 and hard_damage > 4, "сложность меняет урон по героям (%d / 4 / %d)" % [easy_damage, hard_damage])
	_check(easy_health < 20 and hard_health > 20, "сложность меняет здоровье врагов (%d / 20 / %d)" % [easy_health, hard_health])
	GameSettings.difficulty = GameSettings.Difficulty.EASY
	await _spawn(Heroes.Id.SWORDSMAN, Vector2(40 * 60, 25 * 60 - 48))
	_player.receive_hit(Hit.make(4, Vector2.ZERO, _player.global_position + Vector2(0, 10)))
	_check(_player.health.maximum - _player.health.current == 2, "на лёгкой сложности удар в 4 снимает 2")
	GameSettings.difficulty = GameSettings.Difficulty.NORMAL


func _test_team_wipe_restarts_boss() -> void:
	await _spawn(Heroes.Id.SHOOTER, Vector2(ARENA_LEFT + 200.0, STAND_Y))
	await _frames(5)
	var boss := _boss()
	if boss != null:
		boss.health.damage(boss.health.maximum / 2)
	# What Level does when the whole team is down.
	_level.reset_enemies()
	_level.reset_mechanics()
	_player.global_position = Vector2(ARENA_LEFT - 400.0, STAND_Y)
	await _frames(10)
	_check(_boss() == null and not _gates_closed(), "команда пала — арена открывается, босс уходит")
	_player.global_position = Vector2(ARENA_LEFT + 200.0, STAND_Y)
	await _frames(5)
	boss = _boss()
	_check(boss != null and boss.health.current == boss.health.maximum, "при новой попытке босс снова с полным здоровьем")
	_level.reset_enemies()
	_level.reset_mechanics()
	_player.global_position = Vector2(ARENA_LEFT - 400.0, STAND_Y)
	await _frames(10)


func _test_boss_fight() -> void:
	# A partner waits outside: the arena brings them in, and the boss is tougher for two.
	var partner := _spawn_extra(Heroes.Id.SHOOTER, Vector2(ARENA_LEFT - 300.0, STAND_Y))
	await _spawn(Heroes.Id.SWORDSMAN, Vector2(ARENA_LEFT + 200.0, STAND_Y))
	await _frames(5)
	var boss := _boss()
	_check(boss != null, "герой вошёл на арену — появился босс")
	if boss == null:
		return
	_check(_gates_closed() and partner.global_position.x > ARENA_LEFT, "ворота закрылись, напарник внутри")
	_check(boss.health.maximum == roundi(boss.max_health * 1.5), "вдвоём у босса в полтора раза больше здоровья (%d)" % boss.health.maximum)
	partner.queue_free()
	await _frames(60)
	_check(_level._boss_bar.visible, "наверху экрана полоса здоровья босса")

	# Phase 1: attacks happen and hurt a hero who does not move.
	var hurt := false
	var seen_wave := false
	var seen_glob := false
	for i in 600:
		await _frames(1)
		_player.global_position.x = ARENA_LEFT + 300.0
		for child in _level.get_children():
			seen_wave = seen_wave or child is BossAttacks.Shockwave
			seen_glob = seen_glob or child is BossAttacks.Glob
		hurt = hurt or _player.health.current < _player.health.maximum
		if seen_wave and seen_glob and hurt:
			break
		if not _player.is_alive():
			_player.revive(_player.global_position)
	_check(seen_wave and seen_glob, "первая фаза: удар с волной по полу и плевки жижей")
	_check(hurt, "атаки босса ранят героя")

	# Phase 2 at two thirds: a roar and two walkers.
	boss.health.damage(boss.health.current - int(boss.health.maximum * 0.6))
	await _wait_for(func() -> bool: return boss.phase == 2, 300)
	await _frames(10)
	_check(boss.phase == 2 and _walkers() == 2, "вторая фаза: босс зовёт двух ходоков (%d)" % _walkers())

	# Phase 3 at one third: sludge pours from above.
	boss.health.damage(boss.health.current - int(boss.health.maximum * 0.3))
	var seen_drop := false
	for i in 900:
		await _frames(1)
		if not _player.is_alive():
			_player.revive(_player.global_position)
		for child in _level.get_children():
			seen_drop = seen_drop or child is BossAttacks.Drop
		if seen_drop:
			break
	_check(boss.phase == 3 and seen_drop, "третья фаза: жижа льётся сверху на отмеченные места")

	boss.health.damage(boss.health.current)
	await _frames(10)
	_check(_boss() == null and _walkers() == 0, "босс побеждён, его ходоки тоже")
	_check(not _gates_closed(), "после победы ворота открываются")

	# A beaten boss stays beaten, even after the team restarts at the checkpoint.
	_level.reset_enemies()
	_level.reset_mechanics()
	await _frames(5)
	_check(_boss() == null and not _gates_closed(), "побеждённый босс не возвращается")


func _test_exit_finishes_level() -> void:
	await _spawn(Heroes.Id.SHOOTER, Vector2(357 * 60.0, STAND_Y))
	_input.set_virtual("right", true)
	await _wait_for(func() -> bool: return _level.completed, 180)
	_input.set_virtual("right", false)
	var panel := false
	for child in _level.hud.get_children():
		panel = panel or child is ResultsPanel
	_check(_level.completed and panel, "выход завершает уровень и показывает итоги")


func _boss() -> SludgeBoss:
	for node in get_tree().get_nodes_in_group("bosses"):
		if not node.is_queued_for_deletion() and node.is_alive():
			return node
	return null


func _walkers() -> int:
	var count := 0
	for node in get_tree().get_nodes_in_group("enemies"):
		if node is Walker and not node.is_queued_for_deletion() and node.is_alive():
			count += 1
	return count


func _gates_closed() -> bool:
	for child in _level.get_children():
		if child is Door and child.gate and child.position.x > ARENA_LEFT - 60.0 and child.is_open:
			return false
	return true


func _wait_for(condition: Callable, max_frames: int) -> void:
	for i in max_frames:
		if condition.call():
			return
		await _frames(1)
