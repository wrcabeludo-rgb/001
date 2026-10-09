extends "res://tests/test_harness.gd"
## Headless checks of the meta game: saving, shop goods and what they change,
## the shotgun, power-ups, secret rooms, the pause menu and the hero select. Run by CI:
##   godot --headless --path game res://tests/meta_test.tscn


func _run_all() -> void:
	await _test_save_round_trip()
	await _test_shop_goods_change_heroes()
	await _test_shotgun()
	await _test_heavy_blade()
	await _test_new_weapons_on_sale()
	await _test_flamethrower()
	await _test_shock_baton()
	await _test_power_ups()
	await _test_secret_room()
	await _test_pause_menu()
	await _test_shop_showcase()
	await _test_hero_select_alone()
	await _test_hero_select_two_players()


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
	# Holding attack with the shotgun must not also fire a charged shot.
	SaveGame.add_item(Heroes.Id.SHOOTER, "quick_charge")
	await _frames(40)
	ammo = gun.ammo
	await _press("attack", 50)
	await _frames(2)
	_check(gun.ammo == ammo - 1, "дробовик не тратит патроны на заряженный выстрел (%d → %d)" % [ammo, gun.ammo])
	_clear_projectiles()
	gun.ammo = 1
	await _frames(40)
	await _press("attack")
	await _frames(2)
	_check(gun.weapon == "rifle" and gun.ammo == 0, "кончились патроны — в руках снова винтовка")
	_clear_projectiles()


func _test_heavy_blade() -> void:
	SaveGame.new_game(GameSettings.Difficulty.NORMAL)
	SaveGame.add_item(Heroes.Id.SWORDSMAN, "heavy_blade")
	SaveGame.set_weapon(Heroes.Id.SWORDSMAN, "heavy")
	await _spawn(Heroes.Id.SWORDSMAN, Vector2(OPEN_X, FLOOR_Y))
	var sword := _player.combat as SwordsmanCombat
	_check(sword.heavy and sword._damage(3) == 5, "тяжёлый клинок бьёт сильнее (3 → %d)" % sword._damage(3))


func _test_new_weapons_on_sale() -> void:
	SaveGame.new_game(GameSettings.Difficulty.NORMAL)
	var flamer: Dictionary = ShopItems.ITEMS[Heroes.Id.SHOOTER].filter(func(item: Dictionary) -> bool:
		return item["id"] == "flamethrower")[0]
	var closed := not ShopItems.is_on_sale(flamer)
	SaveGame.complete_zone("1-3", 300.0)
	_check(closed and ShopItems.is_on_sale(flamer), "огнемёт продаётся только после босса мира 1")


## A walker that stands still and does not hurt, with plenty of health.
func _target(x: float) -> Walker:
	var walker := Walker.new()
	walker.max_health = 100
	walker.walk_speed = 0.0
	walker.chase_speed = 0.0
	walker.contact_damage = 0
	walker.position = Vector2(x, 1020.0 - walker.body_size.y / 2.0)
	_room.add_child(walker)
	return walker


func _test_flamethrower() -> void:
	SaveGame.new_game(GameSettings.Difficulty.NORMAL)
	SaveGame.add_item(Heroes.Id.SHOOTER, "flamethrower")
	SaveGame.set_weapon(Heroes.Id.SHOOTER, "flamer")
	await _spawn(Heroes.Id.SHOOTER, Vector2(OPEN_X, FLOOR_Y))
	var gun := _player.combat as ShooterCombat
	var walker := _target(OPEN_X + 180.0)
	await _frames(3)
	var ammo := gun.ammo
	await _press("attack", 30)
	var licked := walker.health.current
	_check(walker.is_burning() and licked < 100, "струя огнемёта поджигает врага (здоровье %d)" % licked)
	_check(gun.ammo == ammo - 2, "огнемёт тратит патрон в четверть секунды (%d → %d)" % [ammo, gun.ammo])
	await _frames(200)
	var burnt := licked - walker.health.current
	_check(not walker.is_burning() and burnt >= 5 and burnt <= 6,
		"враг горит 3 секунды и теряет %d здоровья" % burnt)
	gun.ammo = 1
	await _press("attack", 30)
	_check(gun.weapon == "rifle" and gun.ammo == 0, "кончились патроны у огнемёта — снова винтовка")
	walker.queue_free()


func _test_shock_baton() -> void:
	SaveGame.new_game(GameSettings.Difficulty.NORMAL)
	SaveGame.add_item(Heroes.Id.SWORDSMAN, "shock_baton")
	SaveGame.set_weapon(Heroes.Id.SWORDSMAN, "shock")
	await _spawn(Heroes.Id.SWORDSMAN, Vector2(OPEN_X, FLOOR_Y))
	var sword := _player.combat as SwordsmanCombat
	var walker := _target(OPEN_X + 80.0)
	await _frames(3)
	await _press("attack")
	await _frames(10)
	_check(sword.shocking and walker.is_shocked() and walker.stun_timer > 1.5,
		"удар электрошоком оглушает врага (оглушение %.1f с)" % walker.stun_timer)
	await _frames(115)
	var released := not walker.is_shocked() and walker.stun_timer <= 0.0
	await _press("attack")
	await _frames(10)
	_check(released and not walker.is_shocked(), "оглушение длится 2 секунды, потом 3 секунды иммунитета")
	await _frames(200)
	walker.queue_free()
	# The finisher's discharge jumps to the next enemy.
	var first := _target(OPEN_X + 80.0)
	var second := _target(OPEN_X + 230.0)
	await _frames(3)
	for i in 3:
		await _press("attack")
		await _frames(13)
	_check(first.is_shocked() and second.is_shocked() and second.health.current < 100,
		"третий удар перескакивает разрядом на соседнего врага")
	first.queue_free()
	second.queue_free()
	# A boss is not stunned, but takes more damage from the current.
	var boss := _target(OPEN_X - 300.0)
	boss.can_be_shocked = false
	await _frames(2)
	var hit := Hit.make(4, Vector2.ZERO, boss.global_position)
	hit.shock = 2.0
	boss.receive_hit(hit)
	_check(not boss.is_shocked() and boss.health.current == 94, "босса ток не оглушает, но бьёт в 1,5 раза сильнее")
	boss.queue_free()


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


func _test_hero_select_alone() -> void:
	PlayerManager.players = [_input, null]
	PlayerManager.heroes = [Heroes.Id.SHOOTER, Heroes.Id.SWORDSMAN]
	var screen := await _hero_select()
	await _press("right")
	await _press("jump")
	await _frames(int(HeroSelect.START_DELAY * 60) + 10)
	_check(screen.get_meta("done", false) and PlayerManager.heroes[0] == Heroes.Id.SWORDSMAN,
		"выбор героя: один игрок берёт мечника, и игра идёт дальше")
	screen.queue_free()


func _test_hero_select_two_players() -> void:
	var second := PlayerInput.scripted()
	_extra_inputs.append(second)
	PlayerManager.players = [_input, second]
	PlayerManager.heroes = [Heroes.Id.SHOOTER, Heroes.Id.SWORDSMAN]
	var screen := await _hero_select()
	await _press("jump")
	# The second player tries the Gunner too: it is taken.
	await _press_on(second, "left")
	await _press_on(second, "jump")
	_check(not screen.chosen[1], "выбор героя: занятого стрелка второй игрок взять не может")
	await _press_on(second, "right")
	await _press_on(second, "jump")
	await _frames(int(HeroSelect.START_DELAY * 60) + 10)
	_check(screen.get_meta("done", false) and PlayerManager.heroes == [Heroes.Id.SHOOTER, Heroes.Id.SWORDSMAN],
		"выбор героя: вдвоём — стрелок и мечник, игра идёт дальше")
	screen.queue_free()
	_extra_inputs.erase(second)
	PlayerManager.players = [null, null]


func _test_shop_showcase() -> void:
	SaveGame.new_game(GameSettings.Difficulty.NORMAL)
	var shop: Control = load("res://scenes/shop.tscn").instantiate()
	add_child(shop)
	await _frames(2)
	var at_start: Texture2D = shop._show_icon.texture
	shop._show_row(1)  # the first item of the Gunner: the shotgun
	var shotgun: Texture2D = shop._show_icon.texture
	_check(at_start != null and at_start.resource_path.ends_with("weapon_rifle.png")
		and shotgun != null and shotgun.resource_path.ends_with("weapon_shotgun.png"),
		"лавка показывает оружие в руках и картинку выбранного товара")
	shop.queue_free()
	await _frames(1)


## The hero select screen, staying in place when done.
func _hero_select() -> HeroSelect:
	HeroSelect.next_scene = ""
	var screen := HeroSelect.new()
	screen.heroes_chosen.connect(func() -> void: screen.set_meta("done", true))
	add_child(screen)
	await _frames(2)
	return screen


func _press_on(device: PlayerInput, action: String) -> void:
	device.set_virtual(action, true)
	await _frames(1)
	device.set_virtual(action, false)
	await _frames(1)


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
