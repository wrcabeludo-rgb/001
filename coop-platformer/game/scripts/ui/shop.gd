extends Control
## The scrap trader between zones. One list for both heroes: the top row
## switches between the Gunner's and the Swordsman's goods (left / right),
## each hero pays from their own wallet. In co-op players take turns.

const TITLE_FONT := preload("res://assets/fonts/RussoOne-Regular.ttf")
const LINES := [
	"Лом — вот настоящая валюта. Неон его не заменит.",
	"Всё рабочее. Ну, почти всё.",
	"Внизу, в стоке, понадобится кое-что посерьёзнее.",
	"Бери, пока жижа не добралась и до моей лавки.",
]

var hero: Heroes.Id = Heroes.Id.SHOOTER

var _menu: MenuList
var _hint: Label
var _wallet: Label


func _ready() -> void:
	add_child(Harm.box(Vector2.ZERO, Vector2(1920, 1080), Color(0.06, 0.06, 0.09)))
	add_child(Harm.box(Vector2(0, 760), Vector2(1920, 320), Color(0.1, 0.09, 0.12)))
	# The trader (placeholder until the art arrives).
	add_child(Harm.box(Vector2(1460, 420), Vector2(220, 340), Color(0.42, 0.36, 0.3)))
	add_child(Harm.box(Vector2(1380, 640), Vector2(380, 120), Color(0.3, 0.24, 0.2)))
	var title := Label.new()
	title.text = "ЛАВКА СТАРЬЁВЩИКА"
	title.position = Vector2(120, 60)
	title.add_theme_font_override("font", TITLE_FONT)
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.45))
	add_child(title)
	var quote := Label.new()
	quote.text = "«%s»" % LINES.pick_random()
	quote.position = Vector2(1180, 330)
	quote.size = Vector2(700, 80)
	quote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quote.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quote.add_theme_font_size_override("font_size", 26)
	quote.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	add_child(quote)

	_wallet = Label.new()
	_wallet.position = Vector2(120, 170)
	_wallet.add_theme_font_size_override("font_size", 30)
	add_child(_wallet)

	_menu = MenuList.new()
	_menu.position = Vector2(120, 240)
	_menu.size = Vector2(1000, 640)
	_menu.font_size = 36
	_menu.alignment = BoxContainer.ALIGNMENT_BEGIN
	add_child(_menu)
	_hint = Label.new()
	_hint.position = Vector2(120, 930)
	_hint.size = Vector2(1680, 90)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.add_theme_font_size_override("font_size", 28)
	_hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	add_child(_hint)
	_menu.selection_changed.connect(func(_index: int) -> void: _hint.text = _menu.hint())
	_menu.back.connect(_leave)

	# Start with the hero of the first joined player.
	for slot in PlayerManager.MAX_PLAYERS:
		if PlayerManager.players[slot] != null:
			hero = PlayerManager.heroes[slot]
			break
	_build()
	Sound.music("shop")


func _build(select := 0) -> void:
	_wallet.text = "%s · лом: %d" % [Heroes.NAMES[hero], SaveGame.scrap(hero)]
	_wallet.add_theme_color_override("font_color", Heroes.COLORS[hero])
	var entries: Array = []
	entries.append({
		"text": "◀  %s  ▶" % Heroes.NAMES[hero],
		"adjust": func(_direction: int) -> void:
			hero = Heroes.other(hero)
			_build.call_deferred(0),
		"action": func() -> void:
			hero = Heroes.other(hero)
			_build.call_deferred(0),
		"hint": "Влево / вправо — товары другого героя. У каждого героя свой лом",
	})
	for item in ShopItems.ITEMS[hero]:
		entries.append(_item_entry(item))
	var owned := ShopItems.owned_weapons(hero)
	if owned.size() > 1:
		entries.append({
			"text": func() -> String: return "В руках: %s" % ShopItems.weapon_name(hero, SaveGame.weapon(hero)),
			"adjust": func(direction: int) -> void:
				var index := owned.find(SaveGame.weapon(hero))
				SaveGame.set_weapon(hero, owned[wrapi(index + direction, 0, owned.size())])
				SaveGame.save(),
			"hint": "Влево / вправо — какое оружие взять с собой" + ("; в бою стрелок меняет его кнопкой доп." if hero == Heroes.Id.SHOOTER else ""),
		})
	var next: Dictionary = SaveGame.ZONES[int(SaveGame.data["next_zone"])]
	entries.append({"text": "В путь: %s" % next["id"], "action": func() -> void:
		get_tree().change_scene_to_file(next["scene"]), "hint": next["title"]})
	entries.append({"text": "В главное меню", "action": _leave})
	_menu.set_entries(entries, select)
	_hint.text = _menu.hint()


func _item_entry(item: Dictionary) -> Dictionary:
	return {
		"text": func() -> String: return _item_text(item),
		"action": func() -> void: _buy(item),
		"hint": item["text"],
	}


func _item_text(item: Dictionary) -> String:
	if SaveGame.has_item(hero, item["id"]):
		return "%s — есть" % item["name"]
	if item.has("needs") and not SaveGame.has_item(hero, item["needs"]):
		return "%s — %d (сначала %s)" % [item["name"], item["price"], _item_name(item["needs"])]
	return "%s — %d" % [item["name"], item["price"]]


func _item_name(item_id: String) -> String:
	for item in ShopItems.ITEMS[hero]:
		if item["id"] == item_id:
			return item["name"]
	return item_id


func _buy(item: Dictionary) -> void:
	if SaveGame.has_item(hero, item["id"]):
		return
	if item.has("needs") and not SaveGame.has_item(hero, item["needs"]):
		_hint.text = "Сначала нужно купить «%s»" % _item_name(item["needs"])
		Sound.play("block", 0.0)
		return
	if SaveGame.scrap(hero) < item["price"]:
		_hint.text = "Не хватает лома: нужно %d, есть %d" % [item["price"], SaveGame.scrap(hero)]
		Sound.play("block", 0.0)
		return
	SaveGame.set_scrap(hero, SaveGame.scrap(hero) - item["price"])
	SaveGame.add_item(hero, item["id"])
	if item["id"] in ["shotgun", "heavy_blade"]:
		SaveGame.set_weapon(hero, "shotgun" if item["id"] == "shotgun" else "heavy")
	SaveGame.save()
	Sound.play("coin_shop", 0.0)
	_build.call_deferred(_menu.selected)


func _leave() -> void:
	get_tree().change_scene_to_file("res://scenes/title.tscn")
