class_name Searchlight
extends Node2D
## A security searchlight on the ceiling (world 3). Its beam sweeps back and
## forth over the floor. A hero caught in it sets off the alarm: a siren, and a
## moment later two guards run out of the nearest alarm hatch (no more often
## than every `alarm_cooldown` seconds). A hit breaks the lamp for good.

const BEAM := Color(1.0, 0.95, 0.8)
const ALARM := Color(1.0, 0.2, 0.15)

@export var sweep := 260.0
@export var sweep_time := 3.2
@export var beam_width := 110.0
@export var alarm_cooldown := 8.0

## The floor the beam lights (world y) and the hatch the guards come from.
var floor_y := 0.0
var hatch: AlarmHatch
var broken := false

var _time := 0.0
var _cooldown := 0.0
var _alarm := 0.0
var _hurtbox: Hurtbox
var _art: Sprite2D


func setup(at: Vector2, p_floor_y: float) -> void:
	position = at
	floor_y = p_floor_y


func _ready() -> void:
	add_to_group("resettable")
	z_index = 2
	_hurtbox = Hurtbox.new()
	_hurtbox.position = Vector2(0, 18)
	add_child(_hurtbox)
	_hurtbox.setup(Layers.Team.ENEMIES, Vector2(50, 40), self)
	_art = Harm.prop_sprite("searchlight", Vector2.ZERO)
	if _art != null:
		var factor := 70.0 / _art.texture.get_width()
		_art.scale = Vector2(factor, factor)
		_art.position = Vector2(0, _art.texture.get_height() * factor / 2.0)
		add_child(_art)


func receive_hit(_hit: Hit) -> bool:
	if broken:
		return false
	broken = true
	Sound.play("crumble", 0.0, 0.0, 1.6)
	Fx.burst(get_parent(), global_position + Vector2(0, 20), [Color(1, 1, 0.9), Color(0.7, 0.8, 1.0, 0.0)], 14, 300.0, 3.0,
		0.5, 1200.0)
	return true


func reset() -> void:
	broken = false
	_cooldown = 0.0
	_alarm = 0.0


## Where the beam meets the floor now (world x).
func beam_x() -> float:
	return global_position.x + sin(_time / sweep_time * TAU) * sweep


func _physics_process(delta: float) -> void:
	_time += delta
	_cooldown -= delta
	if _alarm > 0.0:
		_alarm -= delta
		if _alarm <= 0.0 and hatch != null:
			hatch.release(2)
	if not broken and _cooldown <= 0.0 and _hero_in_beam():
		_cooldown = alarm_cooldown
		_alarm = 0.9
		Sound.play("telegraph", 0.0, 2.0, 0.7)
		var level := get_parent() as Level
		if level != null:
			level.show_toast("ТРЕВОГА!", 1.5)
	queue_redraw()


func _hero_in_beam() -> bool:
	var x := beam_x()
	for node in get_tree().get_nodes_in_group("players"):
		var hero := node as Player
		if hero == null or not hero.is_alive():
			continue
		var feet := hero.global_position.y + Player.SIZE.y / 2.0
		# The beam widens towards the floor: at the hero's height it is this wide.
		var t := clampf((feet - global_position.y) / maxf(floor_y - global_position.y, 1.0), 0.0, 1.0)
		var half := lerpf(12.0, beam_width / 2.0, t)
		var at := lerpf(global_position.x, x, t)
		if absf(hero.global_position.x - at) < half + Player.SIZE.x / 2.0 and feet <= floor_y + 4.0 \
				and hero.global_position.y > global_position.y:
			return true
	return false


func _draw() -> void:
	if _art == null:
		draw_rect(Rect2(-10, 0, 20, 14), Color(0.2, 0.2, 0.25))
		draw_circle(Vector2(0, 22), 14.0, Color(0.25, 0.25, 0.3))
		draw_circle(Vector2(0, 24), 9.0, BEAM.darkened(0.6) if broken else BEAM)
	if broken:
		return
	var color := ALARM if _cooldown > alarm_cooldown - 2.0 else BEAM
	var bottom := Vector2(beam_x() - global_position.x, floor_y - global_position.y)
	var cone := PackedVector2Array([Vector2(-10, 24), Vector2(10, 24), bottom + Vector2(beam_width / 2.0, 0),
		bottom - Vector2(beam_width / 2.0, 0)])
	draw_colored_polygon(cone, Color(color, 0.13))
	draw_colored_polygon(PackedVector2Array([Vector2(-4, 24), Vector2(4, 24), bottom + Vector2(beam_width * 0.2, 0),
		bottom - Vector2(beam_width * 0.2, 0)]), Color(color, 0.12))
	draw_rect(Rect2(bottom - Vector2(beam_width / 2.0, 6), Vector2(beam_width, 6)), Color(color, 0.35))
