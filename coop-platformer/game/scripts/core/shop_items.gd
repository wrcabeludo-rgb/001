class_name ShopItems
## What the trader sells between zones, for each hero. Prices are in scrap.
## "needs": another item that must be bought first.

const ITEMS := {
	Heroes.Id.SHOOTER: [
		{"id": "shotgun", "name": "Дробовик", "price": 40,
			"text": "Второе оружие: веер из пяти дробин вблизи, 1 патрон за выстрел. Доп. — сменить оружие"},
		{"id": "armor1", "name": "Броня I", "price": 20, "text": "+2 к здоровью"},
		{"id": "armor2", "name": "Броня II", "price": 40, "text": "Ещё +2 к здоровью", "needs": "armor1"},
		{"id": "pouch", "name": "Подсумок", "price": 25, "text": "+20 к запасу патронов, с ним начинаешь с полным запасом"},
		{"id": "quick_charge", "name": "Быстрая зарядка", "price": 30, "text": "Заряженный выстрел готов на 40% быстрее"},
	],
	Heroes.Id.SWORDSMAN: [
		{"id": "heavy_blade", "name": "Тяжёлый клинок", "price": 40,
			"text": "Бьёт в 1,6 раза сильнее и дальше, но медленнее. Какой клинок в руке — выбираешь здесь же"},
		{"id": "armor1", "name": "Броня I", "price": 20, "text": "+2 к здоровью"},
		{"id": "armor2", "name": "Броня II", "price": 40, "text": "Ещё +2 к здоровью", "needs": "armor1"},
		{"id": "quick_dash", "name": "Лёгкий рывок", "price": 25, "text": "Рывок перезаряжается вдвое быстрее"},
		{"id": "iron_block", "name": "Стальной блок", "price": 30, "text": "Блок спереди держит почти весь урон"},
	],
}

## Weapons a hero can hold, in switching order, with the item that unlocks them.
const WEAPONS := {
	Heroes.Id.SHOOTER: [["rifle", "Винтовка", ""], ["shotgun", "Дробовик", "shotgun"]],
	Heroes.Id.SWORDSMAN: [["blade", "Клинок", ""], ["heavy", "Тяжёлый клинок", "heavy_blade"]],
}


static func weapon_name(hero: Heroes.Id, weapon_id: String) -> String:
	for weapon in WEAPONS[hero]:
		if weapon[0] == weapon_id:
			return weapon[1]
	return weapon_id


## Weapons the hero owns, in order.
static func owned_weapons(hero: Heroes.Id) -> Array:
	var result: Array = []
	for weapon in WEAPONS[hero]:
		if weapon[2] == "" or SaveGame.has_item(hero, weapon[2]):
			result.append(weapon[0])
	return result
