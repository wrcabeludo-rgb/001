extends "res://tests/test_harness.gd"
## Headless co-op checks on the Polygon level, run by CI:
##   godot --headless --path game res://tests/coop_test.tscn
## Two heroes driven by scripted devices, added through Level.spawn_player().

## The Polygon's main floor top is y = 1260; the plateau top is y = 900.
const GROUND_Y := 1260.0 - Player.SIZE.y / 2
const PLATEAU_Y := 900.0 - Player.SIZE.y / 2

var _level: Level
var _a: Player
var _b: Player


func _init() -> void:
	room_scene = preload("res://scenes/coop_level.tscn")


func _run_all() -> void:
	_level = _room as Level
	await _test_camera_zooms_out()
	await _test_screen_edges_hold_heroes()
	await _test_fall_respawns_next_to_partner()
	await _test_team_respawns_at_checkpoint()
	await _test_late_joiner_appears_next_to_partner()
	await _test_heroes_swap_on_any_level()
	_test_gamepad_announced_twice()


func _test_camera_zooms_out() -> void:
	await _pair(Vector2(120, GROUND_Y), Vector2(1700, GROUND_Y))
	await _frames(60)
	var view := _level.camera.visible_rect()
	_check(_level.camera.zoom.x < 0.95, "камера отдаляется, когда герои расходятся (zoom %.2f)" % _level.camera.zoom.x)
	_check(view.has_point(_a.global_position) and view.has_point(_b.global_position), "оба героя в кадре")


func _test_screen_edges_hold_heroes() -> void:
	await _pair(Vector2(120, GROUND_Y), Vector2(3300, PLATEAU_Y))
	await _frames(30)
	var view := _level.camera.visible_rect()
	var distance := absf(_b.global_position.x - _a.global_position.x)
	_check(is_equal_approx(_level.camera.zoom.x, CoopCamera.MIN_ZOOM),
		"камера отдаляется только до предела (zoom %.2f)" % _level.camera.zoom.x)
	_check(distance <= view.size.x, "края экрана не дают разойтись дальше (%.0f px при ширине кадра %.0f)" % [distance, view.size.x])


func _test_fall_respawns_next_to_partner() -> void:
	# Hero B starts right above the first pit (columns 21..24).
	await _pair(Vector2(600, GROUND_Y), Vector2(1380, GROUND_Y))
	for i in 150:
		await _frames(1)
		if not _b.is_alive():
			break
	_check(not _b.is_alive(), "падение в пропасть — гибель")
	_check(_level.respawn_time_left(1) > 0.0, "погибший ждёт возвращения")
	await _frames(int(Level.RESPAWN_DELAY * 60.0) + 20)
	_check(_b.is_alive() and _b.health.current == _b.health.maximum, "через 3 секунды герой возвращается с полным здоровьем")
	_check(_b.global_position.distance_to(_a.global_position) < 30.0,
		"герой возвращается рядом с напарником (%.0f px)" % _b.global_position.distance_to(_a.global_position))


func _test_team_respawns_at_checkpoint() -> void:
	# The first checkpoint stands at column 9 (x = 570).
	await _pair(Vector2(570, GROUND_Y), Vector2(800, GROUND_Y))
	await _frames(5)
	var checkpoint := _level.active_checkpoint
	_check(checkpoint != null and checkpoint.active, "контрольная точка загорается, когда герой до неё дошёл")
	_a.global_position = Vector2(1000, GROUND_Y)
	_level.snap_camera()
	await _frames(3)
	_a.kill()
	_b.kill()
	await _frames(2)
	_check(not _a.is_alive() and not _b.is_alive(), "оба героя погибли")
	await _frames(int(Level.TEAM_RESPAWN_DELAY * 60.0) + 20)
	var both_back := _a.is_alive() and _b.is_alive()
	_check(both_back, "команда возвращается после гибели обоих")
	if both_back and checkpoint != null:
		var a_ok := _a.global_position.distance_to(checkpoint.respawn_point(0)) < 5.0
		var b_ok := _b.global_position.distance_to(checkpoint.respawn_point(1)) < 5.0
		_check(a_ok and b_ok, "команда возвращается к контрольной точке")
		_check(_a.health.current == _a.health.maximum and _b.health.current == _b.health.maximum,
			"после возвращения у героев полное здоровье")


func _test_late_joiner_appears_next_to_partner() -> void:
	_clear()
	await _frames(1)
	var input_a := PlayerInput.scripted()
	_extra_inputs = [input_a]
	_a = _level.spawn_player(0, input_a, Heroes.Id.SHOOTER)
	_a.global_position = Vector2(2000, GROUND_Y)
	_level.snap_camera()
	await _frames(10)
	var input_b := PlayerInput.scripted()
	_extra_inputs.append(input_b)
	_b = _level.spawn_player(1, input_b, Heroes.Id.SWORDSMAN)
	_check(_b.global_position.distance_to(_a.global_position) < 5.0,
		"второй игрок появляется рядом с первым (%.0f px)" % _b.global_position.distance_to(_a.global_position))


func _test_heroes_swap_on_any_level() -> void:
	_clear()
	await _frames(1)
	# Joined players as PlayerManager sees them (the test polls the scripted devices).
	var input_a := PlayerInput.scripted()
	var input_b := PlayerInput.scripted()
	_extra_inputs = [input_a, input_b]
	PlayerManager.players[0] = input_a
	PlayerManager.players[1] = input_b
	PlayerManager.heroes[0] = Heroes.Id.SHOOTER
	PlayerManager.heroes[1] = Heroes.Id.SWORDSMAN
	_a = _level.spawn_player(0, input_a, Heroes.Id.SHOOTER)
	_b = _level.spawn_player(1, input_b, Heroes.Id.SWORDSMAN)
	await _frames(3)
	input_a.set_virtual("down", true)
	input_a.set_virtual("extra", true)
	await _frames(2)
	input_a.set_virtual("extra", false)
	input_a.set_virtual("down", false)
	await _frames(2)
	_check(_a.hero == Heroes.Id.SWORDSMAN and _b.hero == Heroes.Id.SHOOTER,
		"вниз + доп. на «Полигоне»: игроки меняются героями")
	PlayerManager.players[0] = null
	PlayerManager.players[1] = null


## Two fresh heroes at the given places (they stand still: nothing is pressed).
func _pair(at_a: Vector2, at_b: Vector2) -> void:
	_clear()
	await _frames(1)
	var input_a := PlayerInput.scripted()
	var input_b := PlayerInput.scripted()
	_extra_inputs = [input_a, input_b]
	_a = _level.spawn_player(0, input_a, Heroes.Id.SHOOTER)
	_b = _level.spawn_player(1, input_b, Heroes.Id.SWORDSMAN)
	for pair in [[_a, at_a], [_b, at_b]]:
		pair[0].global_position = pair[1]
		pair[0].last_safe_position = pair[1]
	# Heroes were teleported: move the camera at once, or the screen edges would pull them back.
	_level.snap_camera()
	await _frames(3)


func _clear() -> void:
	for slot in [0, 1]:
		_level.remove_player(slot)


## Windows can announce the same gamepad again; its player must keep the
## device object that is still being read.
func _test_gamepad_announced_twice() -> void:
	PlayerManager._on_joy_connection_changed(7, true)
	var first: PlayerInput = PlayerManager._gamepads[7]
	PlayerManager._on_joy_connection_changed(7, true)
	_check(PlayerManager._gamepads[7] == first, "повторное подключение того же геймпада не подменяет его")
	PlayerManager._on_joy_connection_changed(7, false)
