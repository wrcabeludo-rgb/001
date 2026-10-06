extends "res://tests/test_harness.gd"
## Headless checks of the meta game: saving, shop goods and what they change,
## the shotgun, power-ups, secret rooms and the pause menu. Run by CI:
##   godot --headless --path game res://tests/meta_test.tscn


func _run_all() -> void:
	await _test_save_round_trip()
	await _test_shop_goods_change_heroes()
	await _test_shotgun()
	await _test_heavy_blade()
	await _test_power_ups()
	await _test_secret_room()
	await _test_pause_menu()


func _test_save_round_trip() -> void:
	SaveGame.new_game(GameSettings.Difficulty.HARD)
	SaveGame.set_scrap(Heroes.Id.SHOOTER, 77)
	SaveGame.add_item(Heroes.Id.SWORDSMAN, "armor1")
	SaveGame.complete_zone("1-1", 600.0)
	SaveGame.data = {}
	SaveGame.load_data()
	_check(SaveGame.scrap(Heroes.Id.SHOOTER) == 77 and SaveGame.has_item(Heroes.Id.SWORDSMAN, "armor1"),
		"лом и покупки сохраняются и загружаются")
	_check(int(SaveGame.data["unlocked"]) == 2 and int(SaveGame.data["next_zone"]) == 1,
		"пройденная зона открывает следующую")
	_check(GameSettings.difficulty == GameSettings.Difficulty.HARD, "сложность сохраняется")
	SaveGame.new_game(GameSettings.Difficulty.NORMAL)
	_check(SaveGame.scrap(Heroes.Id.SHOOTER) == 0 and int(SaveGame.data["unlocked"]) == 1, "новая игра сбрасывает прогресс")


func _test_shop_goods_change_heroes() -> void:
	SaveGame.new_game(GameSettings.Difficulty.NORMAL)
	await _spawn(Heroes.Id.SWORDSMAN, Vector2(OPEN_X, FLOOR_Y))
	var plain_health := _player.health.maximum
	SaveGame.add_item(Heroes.Id.SWORDSMAN, "armor1")
	SaveGame.add_item(Heroes.Id.SWORDSMAN, "armor2")
	await _spawn(Heroes.Id.SWORDSMAN, Vector2(OPEN_X, FLOOR_Y))
	_check(_player.health.maximum == plain_health + 4, "броня I и II дают +4 к здоровью (%d)" % _player.health.maximum)
	SaveGame.add_item(Heroes.Id.SHOOTER, "pouch")
	await _spawn(Heroes.Id.SHOOTER, Vector2(OPEN_X, FLOOR_Y))
	var gun := _player.combat as ShooterCombat
	_check(gun.max_ammo() == gun.stats.max_ammo + 20 and gun.ammo == gun.max_ammo(),
		"подсумок: больше патронов и полный запас на старте")


func _test_shotgun() -> void:
	SaveGame.new_game(GameSettings.Difficulty.NORMAL)
	SaveGame.add_item(Heroes.Id.SHOOTER, "shotgun")
	await _spawn(Heroes.Id.SHOOTER, Vector2(OPEN_X, FLOOR_Y))
	var gun := _player.combat as ShooterCombat
	_check(gun.weapon == "rifle", "в начале в руках винтовка")
	await _press("extra")
	_check(gun.weapon == "shotgun", "доп. — сменить оружие на дробовик")
	var ammo := gun.ammo
	await _press("attack")
	await _frames(1)
	_check(_projectiles() == 5 and gun.ammo == ammo - 1, "дробовик: веер из 5 дробин за 1 патрон (%d)" % _projectiles())
	_clear_projectiles()


func _test_heavy_blade() -> void:
	SaveGame.new_game(GameSettings.Difficulty.NORMAL)
	SaveGame.add_item(Heroes.Id.SWORDSMAN, "heavy_blade")
	SaveGame.set_weapon(Heroes.Id.SWORDSMAN, "heavy")
	await _spawn(Heroes.Id.SWORDSMAN, Vector2(OPEN_X, FLOOR_Y))
	var sword := _player.combat as SwordsmanCombat
	_check(sword.heavy and sword._damage(3) == 5, "тяжёлый клинок бьёт сильнее (3 → %d)" % sword._damage(3))


func _test_power_ups() -> void:
	SaveGame.new_game(GameSettings.Difficulty.NORMAL)
	await _spawn(Heroes.Id.SHOOTER, Vector2(OPEN_X, FLOOR_Y))
	var item := Pickup.new()
	item.setup(Pickup.Kind.POWER, 1, _player.global_position, Vector2.ZERO)
	item.power = "rage"
	_room.add_child(item)
	await _frames(5)
	_check(_player.has_power("rage") and _player.damage_multiplier() == 2.0, "усилитель «Ярость» удваивает урон")
	_player.give_power("shield")
	var health := _player.health.current
	_player.receive_hit(Hit.make(3, Vector2.ZERO, _player.global_position))
	_check(_player.health.current == health, "под «Щитом» урона нет")
	_player.powers.clear()


func _test_secret_room() -> void:
	SaveGame.new_game(GameSettings.Difficulty.NORMAL)
	await _spawn(Heroes.Id.SHOOTER, Vector2(OPEN_X - 300.0, FLOOR_Y))
	var level := _room as Level
	var cells: Array[Rect2] = [Rect2(OPEN_X - 30.0, 960.0, 60.0, 60.0)]
	var secret := SecretArea.new()
	secret.setup("test#0", cells)
	secret.found.connect(level._on_secret_found)
	level.secrets_total += 1
	_room.add_child(secret)
	await _frames(5)
	var hidden := not secret.is_found
	_player.global_position = Vector2(OPEN_X, FLOOR_Y)
	await _frames(5)
	_check(hidden and secret.is_found and level.secrets_found == 1 and SaveGame.secret_found("test#0"),
		"тайник находится, когда герой заходит за ложную стену")
	secret.queue_free()


func _test_pause_menu() -> void:
	var level := _room as Level
	var device := PlayerInput.scripted()
	_extra_inputs.append(device)
	PlayerManager.players[1] = device
	PlayerManager.heroes[1] = Heroes.Id.SWORDSMAN
	level.spawn_player(1, device, Heroes.Id.SWORDSMAN)
	await _frames(2)
	device.set_virtual("start", true)
	await _frames(2)
	device.set_virtual("start", false)
	var paused := get_tree().paused
	var menu_open := false
	for child in level.get_children():
		menu_open = menu_open or child is PauseMenu
	get_tree().paused = false
	for child in level.get_children():
		if child is PauseMenu:
			child.queue_free()
	_check(paused and menu_open, "Start ставит игру на паузу и открывает меню")
	level.remove_player(1)
	PlayerManager.players[1] = null


func _projectiles() -> int:
	var count := 0
	for child in _room.get_children():
		if child is Projectile and not child.is_queued_for_deletion():
			count += 1
	return count


func _clear_projectiles() -> void:
	for child in _room.get_children():
		if child is Projectile:
			child.queue_free()
