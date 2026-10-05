extends "res://tests/test_harness.gd"
## Headless movement checks, run by CI:
##   godot --headless --path game res://tests/movement_test.tscn
## Drives a hero with a scripted input device inside the test room.


func _run_all() -> void:
	_test_room_has_no_low_ceilings()
	await _test_run()
	await _test_jump_height()
	await _test_jump_cut()
	await _test_double_jump()
	await _test_no_double_jump_for_swordsman()
	await _test_coyote_time()
	await _test_jump_buffer()
	await _test_dash()
	await _test_wall_slide_and_jump()


## Every gap between a floor and an overhang must fit the hero with room to spare.
func _test_room_has_no_low_ceilings() -> void:
	var map: Array = ROOM_SCRIPT.MAP
	var tile: float = ROOM_SCRIPT.TILE
	var low := PackedStringArray()
	for col in range(1, map[0].length() - 1):
		var row := 1
		while row < map.size() - 1:
			if map[row][col] == "#":
				row += 1
				continue
			var top := row
			while row < map.size() - 1 and map[row][col] != "#":
				row += 1
			var gap := (row - top) * tile
			if map[row][col] == "#" and map[top - 1][col] == "#" and gap < Player.SIZE.y + 30.0:
				low.append("колонка %d, высота %d" % [col, int(gap)])
	_check(low.is_empty(), "в комнате нет проходов ниже роста героя %s" % ", ".join(low))


func _test_run() -> void:
	await _spawn(Heroes.Id.SHOOTER, Vector2(1380, FLOOR_Y))
	var start_x := _player.position.x
	_input.set_virtual("right", true)
	await _frames(30)
	_input.set_virtual("right", false)
	var moved := _player.position.x - start_x
	_check(moved > 150.0, "бег вправо за 0.5 с: смещение %.0f" % moved)


func _test_jump_height() -> void:
	await _spawn(Heroes.Id.SHOOTER, Vector2(OPEN_X, FLOOR_Y))
	var height := await _measure_jump(60)
	var expected := _player.stats.jump_height
	_check(absf(height - expected) < 15.0, "высота прыжка %.0f, ожидалось %.0f" % [height, expected])


func _test_jump_cut() -> void:
	await _spawn(Heroes.Id.SHOOTER, Vector2(OPEN_X, FLOOR_Y))
	var height := await _measure_jump(3)
	_check(height < _player.stats.jump_height * 0.6, "короткое нажатие даёт низкий прыжок: %.0f" % height)


func _test_double_jump() -> void:
	await _spawn(Heroes.Id.SHOOTER, Vector2(OPEN_X, FLOOR_Y))
	var height := await _measure_double_jump()
	_check(height > _player.stats.jump_height + 40.0, "двойной прыжок стрелка: высота %.0f" % height)


func _test_no_double_jump_for_swordsman() -> void:
	await _spawn(Heroes.Id.SWORDSMAN, Vector2(OPEN_X, FLOOR_Y))
	var height := await _measure_double_jump()
	_check(height < _player.stats.jump_height + 15.0, "у мечника нет двойного прыжка: высота %.0f" % height)


func _test_coyote_time() -> void:
	# Ledge at row 9, columns 20..23: top y = 540, right edge x = 1440.
	await _spawn(Heroes.Id.SWORDSMAN, Vector2(1400, 540.0 - Player.SIZE.y / 2))
	_check(_player.is_on_floor(), "герой стоит на уступе перед проверкой «прыжка после края»")
	_input.set_virtual("right", true)
	for i in 60:
		await _frames(1)
		if not _player.is_on_floor():
			break
	await _frames(3)
	_input.set_virtual("jump", true)
	await _frames(2)
	_check(_player.velocity.y < 0.0, "прыжок через 3 кадра после схода с края")
	_input.set_virtual("jump", false)
	_input.set_virtual("right", false)


func _test_jump_buffer() -> void:
	# Swordsman has no air jump, so an early press can only be a buffered ground jump.
	await _spawn(Heroes.Id.SWORDSMAN, Vector2(OPEN_X, FLOOR_Y - 150.0))
	for i in 120:
		await _frames(1)
		if _player.position.y > FLOOR_Y - 25.0:
			break
	_check(not _player.is_on_floor(), "нажатие прыжка происходит ещё в воздухе")
	_input.set_virtual("jump", true)
	await _frames(12)
	_check(_player.position.y < FLOOR_Y - 30.0, "прыжок, нажатый до приземления, срабатывает")
	_input.set_virtual("jump", false)


func _test_dash() -> void:
	await _spawn(Heroes.Id.SWORDSMAN, Vector2(1400, FLOOR_Y))
	var start_x := _player.position.x
	_input.set_virtual("skill", true)
	await _frames(1)
	_input.set_virtual("skill", false)
	_check(_player.is_dashing(), "рывок мечника начинается")
	await _frames(int(_player.stats.dash_time * 60.0) + 2)
	var moved := _player.position.x - start_x
	var expected := _player.stats.dash_speed * _player.stats.dash_time
	_check(moved > expected * 0.8, "рывок: смещение %.0f, ожидалось около %.0f" % [moved, expected])

	await _spawn(Heroes.Id.SHOOTER, Vector2(1400, FLOOR_Y))
	_input.set_virtual("skill", true)
	await _frames(1)
	_input.set_virtual("skill", false)
	_check(not _player.is_dashing(), "у стрелка нет рывка")


func _test_wall_slide_and_jump() -> void:
	# Right outer wall starts at x = 1860; rows 1..8 next to it are open.
	var start := Vector2(1860.0 - Player.SIZE.x / 2 - 1.0, 200.0)
	await _spawn(Heroes.Id.SHOOTER, start)
	_input.set_virtual("right", true)
	await _frames(25)
	_check(_player.velocity.y <= _player.stats.wall_slide_speed + 1.0,
		"скольжение по стене: скорость падения %.0f" % _player.velocity.y)
	var before := _player.position
	_input.set_virtual("jump", true)
	await _frames(6)
	_input.set_virtual("jump", false)
	_input.set_virtual("right", false)
	_check(_player.velocity.x < 0.0 and _player.position.x < before.x - 20.0,
		"прыжок от стены отталкивает влево (x: %.0f → %.0f)" % [before.x, _player.position.x])
	_check(_player.position.y < before.y, "прыжок от стены поднимает вверх")


## Holds jump for `hold_frames`, returns the highest rise above the start.
func _measure_jump(hold_frames: int) -> float:
	var start_y := _player.position.y
	var top_y := start_y
	_input.set_virtual("jump", true)
	for i in 70:
		await _frames(1)
		if i == hold_frames:
			_input.set_virtual("jump", false)
		top_y = minf(top_y, _player.position.y)
	_input.set_virtual("jump", false)
	return start_y - top_y


## Full jump, then a second press near the apex. Returns the highest rise.
func _measure_double_jump() -> float:
	var start_y := _player.position.y
	var top_y := start_y
	_input.set_virtual("jump", true)
	for i in 100:
		await _frames(1)
		if i == 18:
			_input.set_virtual("jump", false)
		elif i == 19:
			_input.set_virtual("jump", true)
		top_y = minf(top_y, _player.position.y)
	_input.set_virtual("jump", false)
	return start_y - top_y
