class_name HeroHud
extends Control
## One player's panel in a screen corner: hero name, health bar, ammo for the Gunner.

const BAR_SIZE := Vector2(300, 18)

var _name: Label
var _bar_fill: ColorRect
var _health_text: Label
var _ammo: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name = Label.new()
	_name.add_theme_font_size_override("font_size", 24)
	add_child(_name)

	var bar_back := ColorRect.new()
	bar_back.position = Vector2(0, 36)
	bar_back.size = BAR_SIZE
	bar_back.color = Color(0, 0, 0, 0.55)
	add_child(bar_back)
	_bar_fill = ColorRect.new()
	_bar_fill.position = bar_back.position
	_bar_fill.size = BAR_SIZE
	add_child(_bar_fill)

	_health_text = Label.new()
	_health_text.position = Vector2(BAR_SIZE.x + 10, 28)
	_health_text.add_theme_font_size_override("font_size", 20)
	add_child(_health_text)

	_ammo = Label.new()
	_ammo.position = Vector2(0, 58)
	_ammo.add_theme_font_size_override("font_size", 20)
	add_child(_ammo)


## Shows `player`, or hides the panel when the slot is empty. While the hero is
## down, `respawn_left` is the number of seconds until they return.
func show_player(player: Player, respawn_left := -1.0) -> void:
	visible = player != null and player.health != null
	if not visible:
		return
	var color: Color = Heroes.COLORS[player.hero]
	_name.text = "P%d  %s" % [player.slot + 1, Heroes.NAMES[player.hero]]
	_name.add_theme_color_override("font_color", color)
	_bar_fill.color = color
	_bar_fill.size.x = BAR_SIZE.x * player.health.ratio()
	_health_text.text = "%d / %d" % [player.health.current, player.health.maximum]
	if not player.is_alive():
		_ammo.visible = true
		_ammo.text = "Вернётся через %.1f с" % respawn_left if respawn_left >= 0.0 else "Ждёт напарника"
		return
	var shooter := player.combat as ShooterCombat
	_ammo.visible = true
	var parts := PackedStringArray()
	if shooter != null:
		parts.append(ShopItems.weapon_name(player.hero, shooter.weapon))
		parts.append("Патроны: %d" % shooter.ammo)
	parts.append("Лом: %d" % player.total_scrap())
	for power in player.powers:
		parts.append("%s %d" % [Player.POWER_NAMES[power], ceili(player.powers[power])])
	_ammo.text = "   ".join(parts)
