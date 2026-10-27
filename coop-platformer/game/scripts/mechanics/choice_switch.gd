class_name ChoiceSwitch
extends Node2D
## One of the two great switches at the Heart (the finale). A hero votes by
## hitting it (sword, shot or kick); a vote can be changed by hitting the other
## switch. When every hero in the game has voted for the same switch, the
## choice is made: the level ends with that ending.

signal voted(switch: ChoiceSwitch, slot: int)

const OFF_COLOR := Color(0.3, 0.75, 1.0)
const KEEP_COLOR := Color(1.0, 0.18, 0.53)

## "off" — put out the Heart; "keep" — let it burn.
var choice := "off"
## Slots of the heroes whose vote is here.
var votes: Array[int] = []

var _hurtbox: Hurtbox
var _label: Label
var _caption: Label
var _art: Sprite2D


func _ready() -> void:
	_hurtbox = Hurtbox.new()
	_hurtbox.position = Vector2(0, -80)
	add_child(_hurtbox)
	_hurtbox.setup(Layers.Team.ENEMIES, Vector2(80, 160), self)
	_art = Harm.prop_sprite("choice_lever", Vector2.ZERO)
	if _art != null:
		var factor := 180.0 / _art.texture.get_height()
		_art.scale = Vector2(factor, factor)
		_art.position = Vector2(0, -90)
		add_child(_art)
	_caption = _make_label(26, -250)
	_caption.text = "ПОГАСИТЬ" if choice == "off" else "ОСТАВИТЬ"
	_caption.add_theme_color_override("font_color", color())
	_label = _make_label(24, -215)


func color() -> Color:
	return OFF_COLOR if choice == "off" else KEEP_COLOR


func _make_label(size: int, y: float) -> Label:
	var label := Label.new()
	label.position = Vector2(-120, y)
	label.size = Vector2(240, 32)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	add_child(label)
	return label


func receive_hit(hit: Hit) -> bool:
	var slot := _nearest_slot(hit.source_position)
	if slot < 0 or votes.has(slot):
		return false
	votes.append(slot)
	Sound.play("lever", 0.0)
	voted.emit(self, slot)
	return true


func remove_vote(slot: int) -> void:
	votes.erase(slot)


func _nearest_slot(at: Vector2) -> int:
	var best := -1
	var best_distance := INF
	for node in get_tree().get_nodes_in_group("players"):
		var hero := node as Player
		if hero == null or not hero.is_alive():
			continue
		var distance := hero.global_position.distance_to(at)
		if distance < best_distance:
			best_distance = distance
			best = hero.slot
	return best


func _process(_delta: float) -> void:
	var names := PackedStringArray()
	for slot in votes:
		names.append("P%d" % (slot + 1))
	_label.text = " ".join(names)
	_label.add_theme_color_override("font_color", color())
	queue_redraw()


func _draw() -> void:
	if _art != null:
		return
	draw_rect(Rect2(-30, -40, 60, 40), Color(0.15, 0.15, 0.2))
	draw_rect(Rect2(-8, -170, 16, 130), Color(0.3, 0.3, 0.36))
	var lean := 0.6 if votes.is_empty() else -0.6
	draw_line(Vector2(0, -60), Vector2(0, -60) + Vector2(sin(lean), -cos(lean)) * 110.0, color(), 12.0)
	draw_circle(Vector2(0, -180), 10.0, color() if not votes.is_empty() else color().darkened(0.5))
