extends Control
## The scrap trader between zones. One list for both heroes: the top row
## switches between the Gunner's and the Swordsman's goods (left / right),
## each hero pays from their own wallet. In co-op players take turns.

const TITLE_FONT := preload("res://assets/fonts/RussoOne-Regular.ttf")
const BACKDROP := preload("res://assets/art/ui/shop_bg.png")
const GROUND := preload("res://assets/art/tiles/1-1_ground.png")
const TRADER := preload("res://assets/art/props/trader.png")
## Pictures of the goods (art/ui/<name>.png); an item without one shows the
## weapon in hand instead.
const ITEM_ICONS := {
	"shotgun": "weapon_shotgun", "heavy_blade": "weapon_heavy_blade", "armor1": "item_armor1",
	"armor2": "item_armor2", "pouch": "item_pouch", "quick_charge": "item_quick_charge",
	"quick_dash": "item_quick_dash", "iron_block": "item_iron_block",
}
const WEAPON_ICONS := {
	"rifle": "weapon_rifle", "shotgun": "weapon_shotgun", "blade": "weapon_blade", "heavy": "weapon_heavy_blade",
}
const STALL_SCALE := 0.82
## The street level: the stall stands on it.
const STREET_Y := 900.0
## Lanterns in the stall picture (pixels of trader.png) and their light colour.
const LANTERNS := [
	[Vector2(180, 130), Color(1.0, 0.55, 0.2)], [Vector2(255, 285), Color(1.0, 0.55, 0.2)],
	[Vector2(365, 145), Color(1.0, 0.7, 0.35)], [Vector2(320, 205), Color(0.3, 0.9, 1.0)],
	[Vector2(705, 170), Color(0.3, 0.9, 1.0)], [Vector2(845, 250), Color(0.3, 0.9, 1.0)],
]
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
## The showcase above the stall: a big picture of the chosen row's item.
var _show_icon: TextureRect
var _show_glow: TextureRect
var _show_caption: Label
## For each menu row: [icon name or "", caption, owned].
var _rows: Array = []
var _lights: Array[TextureRect] = []
var _time := 0.0


func _ready() -> void:
	_build_street()
	add_child(Harm.box(Vector2(80, 40), Vector2(980, 860), Color(0.03, 0.03, 0.05, 0.78)))
	var title := Label.new()
	title.text = "ЛАВКА СТАРЬЁВЩИКА"
	title.position = Vector2(120, 60)
	title.add_theme_font_override("font", TITLE_FONT)
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.45))
	add_child(title)
	var quote := Label.new()
	quote.text = "«%s»" % LINES.pick_random()
	quote.position = Vector2(1100, 330)
	quote.size = Vector2(740, 80)
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
	_menu.size = Vector2(940, 640)
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
	_build_showcase()
	_menu.selection_changed.connect(func(index: int) -> void:
		_hint.text = _menu.hint()
		_show_row(index))
	_menu.back.connect(_leave)

	# Start with the hero of the first joined player.
	for slot in PlayerManager.MAX_PLAYERS:
		if PlayerManager.players[slot] != null:
			hero = PlayerManager.heroes[slot]
			break
	_build()
	Sound.music("shop")


## A night street in the slums: the houses far behind (blurred), the trader's
## stall standing on the ground of zone 1-1 with a shadow under it, its
## lanterns lighting the stall and the ground, ash in the air, dark corners.
func _build_street() -> void:
	var backdrop := TextureRect.new()
	backdrop.texture = BACKDROP
	backdrop.size = Vector2(1920, 1080)
	add_child(backdrop)
	var street := TextureRect.new()
	street.texture = GROUND
	street.stretch_mode = TextureRect.STRETCH_TILE
	street.position = Vector2(0, STREET_Y)
	street.size = Vector2(1920, 1080 - STREET_Y)
	street.modulate = Color(0.5, 0.46, 0.5)
	add_child(street)
	# The far edge of the street fades into the dark.
	add_child(_gradient_rect(Rect2(0, STREET_Y, 1920, 70), Color(0, 0, 0, 0.75), Color(0, 0, 0, 0.0), false))

	var size := TRADER.get_size() * STALL_SCALE
	var stall_at := Vector2(1890 - size.x, STREET_Y + 26 - size.y)
	add_child(_glow(Rect2(stall_at.x - 40, STREET_Y - 30, size.x + 80, 110), Color(0, 0, 0, 0.7), false))
	# The light of the lanterns pooling on the ground in front of the counter.
	var pool := _glow(Rect2(stall_at.x + 60, STREET_Y - 10, size.x - 60, 150), Color(1.0, 0.55, 0.25, 0.28), true)
	add_child(pool)
	_lights.append(pool)
	var stall := TextureRect.new()
	stall.texture = TRADER
	stall.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stall.size = size
	stall.position = stall_at
	# The same night as the street around it.
	stall.modulate = Color(0.9, 0.86, 0.92)
	add_child(stall)
	for lantern in LANTERNS:
		var at: Vector2 = stall_at + lantern[0] * STALL_SCALE
		var light := _glow(Rect2(at - Vector2(110, 110), Vector2(220, 220)), Color(lantern[1], 0.4), true)
		add_child(light)
		_lights.append(light)

	var ash := CPUParticles2D.new()
	ash.position = Vector2(960, -20)
	ash.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	ash.emission_rect_extents = Vector2(1000, 10)
	ash.amount = 60
	ash.lifetime = 14.0
	ash.preprocess = 14.0
	ash.direction = Vector2(0.2, 1)
	ash.spread = 20.0
	ash.initial_velocity_min = 40.0
	ash.initial_velocity_max = 90.0
	ash.gravity = Vector2(6, 4)
	ash.scale_amount_min = 1.5
	ash.scale_amount_max = 3.0
	ash.color = Color(0.75, 0.72, 0.7, 0.5)
	add_child(ash)
	# Dark corners pull the eye to the middle.
	add_child(_glow(Rect2(-480, -270, 2880, 1620), Color(0, 0, 0, 0.0), false, Color(0, 0, 0, 0.7)))


## A soft round spot of light (added on top) or shadow; `edge` is the colour at its rim.
func _glow(area: Rect2, color: Color, light: bool, edge := Color(color, 0.0)) -> TextureRect:
	var gradient := Gradient.new()
	gradient.set_color(0, color)
	gradient.set_color(1, edge)
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 0.0) if edge.a == 0.0 else Vector2(1.0, 1.0)
	var rect := TextureRect.new()
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.position = area.position
	rect.size = area.size
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if light:
		var add := CanvasItemMaterial.new()
		add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		rect.material = add
	return rect


## A rectangle fading from `from` (top) to `to` (bottom).
func _gradient_rect(area: Rect2, from: Color, to: Color, _light: bool) -> TextureRect:
	var gradient := Gradient.new()
	gradient.set_color(0, from)
	gradient.set_color(1, to)
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0, 0)
	texture.fill_to = Vector2(0, 1)
	var rect := TextureRect.new()
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.position = area.position
	rect.size = area.size
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


## The lanterns flicker a little.
func _process(delta: float) -> void:
	_time += delta
	for i in _lights.size():
		_lights[i].modulate.a = 0.85 + 0.15 * sin(_time * (2.3 + i * 0.7) + i) * sin(_time * 5.1 + i * 2.0)


func _build(select := 0) -> void:
	_wallet.text = "%s · лом: %d" % [Heroes.NAMES[hero], SaveGame.scrap(hero)]
	_wallet.add_theme_color_override("font_color", Heroes.COLORS[hero])
	var entries: Array = []
	_rows.clear()
	var in_hand := func() -> Array:
		return [WEAPON_ICONS.get(SaveGame.weapon(hero), ""), "В руках: %s" % ShopItems.weapon_name(hero, SaveGame.weapon(hero)), false]
	_rows.append(in_hand)
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
		var icon: String = ITEM_ICONS.get(item["id"], "")
		if not ResourceLoader.exists(_icon_path(icon)):
			_rows.append(in_hand)
		else:
			_rows.append(func() -> Array: return [icon, item["name"], SaveGame.has_item(hero, item["id"])])
	var owned := ShopItems.owned_weapons(hero)
	if owned.size() > 1:
		entries.append({
			"text": func() -> String: return "В руках: %s" % ShopItems.weapon_name(hero, SaveGame.weapon(hero)),
			"adjust": func(direction: int) -> void:
				var index := owned.find(SaveGame.weapon(hero))
				SaveGame.set_weapon(hero, owned[wrapi(index + direction, 0, owned.size())])
				SaveGame.save()
				_show_row(_menu.selected),
			"hint": "Влево / вправо — какое оружие взять с собой" + ("; в бою стрелок меняет его кнопкой доп." if hero == Heroes.Id.SHOOTER else ""),
		})
		_rows.append(in_hand)
	var next: Dictionary = SaveGame.ZONES[int(SaveGame.data["next_zone"])]
	entries.append({"text": "В путь: %s" % next["id"], "action": func() -> void:
		get_tree().change_scene_to_file(next["scene"]), "hint": next["title"]})
	entries.append({"text": "В главное меню", "action": _leave})
	_rows.append(in_hand)
	_rows.append(in_hand)
	_menu.set_entries(entries, select)
	_hint.text = _menu.hint()
	_show_row(_menu.selected)


func _icon_path(icon: String) -> String:
	return "res://assets/art/ui/%s.png" % icon


## The showcase: a soft light in the hero's colour, the picture, a caption.
func _build_showcase() -> void:
	var area := Rect2(1130, 30, 760, 290)
	_show_glow = _glow(Rect2(area.position + Vector2(130, 0), Vector2(500, 260)), Color.WHITE, true)
	add_child(_show_glow)
	_show_icon = TextureRect.new()
	_show_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_show_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_show_icon.position = area.position + Vector2(180, 10)
	_show_icon.size = Vector2(400, 230)
	add_child(_show_icon)
	_show_caption = Label.new()
	_show_caption.position = area.position + Vector2(0, 245)
	_show_caption.size = Vector2(area.size.x, 40)
	_show_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_show_caption.add_theme_font_override("font", TITLE_FONT)
	_show_caption.add_theme_font_size_override("font_size", 30)
	add_child(_show_caption)


func _show_row(index: int) -> void:
	if _show_icon == null or index < 0 or index >= _rows.size():
		return
	var row: Array = _rows[index].call()
	var path := _icon_path(row[0])
	_show_icon.texture = load(path) if row[0] != "" and ResourceLoader.exists(path) else null
	_show_caption.text = row[1] + ("  ✓ есть" if row[2] else "")
	_show_caption.add_theme_color_override("font_color", Heroes.COLORS[hero])
	_show_glow.modulate = Color(Heroes.COLORS[hero], 0.45)


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
