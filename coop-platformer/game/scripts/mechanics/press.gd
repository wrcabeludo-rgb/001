class_name Press
extends Node2D
## A stamping press hanging from the ceiling. On a timer: up, then a blinking
## lamp and a hiss (warning), then the plate slams down to the floor, holds,
## and slowly rises. Whoever is under it is crushed: heroes take a heavy hit and
## are thrown out to the side; enemies are smashed.

enum State { UP, WARNING, SLAM, DOWN, RISE }

const STEEL := Color(0.42, 0.45, 0.52)
const DARK := Color(0.18, 0.19, 0.23)
const HAZARD_YELLOW := Color(1.0, 0.79, 0.24)
const LAMP := Color(1.0, 0.2, 0.15)
const PLATE_HEIGHT := 46.0

@export var up_time := 1.6
@export var warning_time := 0.7
@export var slam_time := 0.1
@export var down_time := 0.45
@export var rise_time := 0.9
@export var hero_damage := 4
@export var enemy_damage := 40

var state := State.UP
## Where the plate hangs from (top centre, at the ceiling) and its width.
var top := Vector2.ZERO
var width := 120.0
## How far the plate's bottom travels down to the floor.
var travel := 240.0

var _timer := 0.0
## 0 = up, 1 = down on the floor.
var _drop := 0.0
var _crushed := {}
var _art: Sprite2D


## `phase` shifts the cycle so neighbouring presses take turns.
func setup(p_top: Vector2, p_width: float, p_travel: float, phase := 0.0) -> void:
	top = p_top
	width = p_width
	travel = p_travel
	_timer = up_time - phase


func _ready() -> void:
	var path := "res://assets/art/props/press.png"
	if ResourceLoader.exists(path):
		_art = Sprite2D.new()
		_art.texture = load(path)
		_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		_art.centered = false
		var factor := width / _art.texture.get_width()
		_art.scale = Vector2(factor, factor)
		add_child(_art)


func cycle_time() -> float:
	return up_time + warning_time + slam_time + down_time + rise_time


## The plate's area in world coordinates.
func plate_rect() -> Rect2:
	var bottom := top.y + PLATE_HEIGHT + 12.0 + (travel - PLATE_HEIGHT - 12.0) * _drop
	return Rect2(top.x - width / 2.0, bottom - PLATE_HEIGHT, width, PLATE_HEIGHT)


func is_dangerous() -> bool:
	return state == State.SLAM or state == State.DOWN


func _physics_process(delta: float) -> void:
	_timer -= delta
	match state:
		State.UP:
			_drop = 0.0
			if _timer <= 0.0:
				_next(State.WARNING, warning_time)
				Sound.play("telegraph", 0.0, -6.0, 0.6)
		State.WARNING:
			if _timer <= 0.0:
				_next(State.SLAM, slam_time)
				_crushed.clear()
		State.SLAM:
			_drop = clampf(1.0 - _timer / slam_time, 0.0, 1.0)
			if _timer <= 0.0:
				_drop = 1.0
				_next(State.DOWN, down_time)
				_on_impact()
		State.DOWN:
			_drop = 1.0
			if _timer <= 0.0:
				_next(State.RISE, rise_time)
		State.RISE:
			_drop = clampf(_timer / rise_time, 0.0, 1.0)
			if _timer <= 0.0:
				_next(State.UP, up_time)
	if is_dangerous():
		_crush()
	queue_redraw()


func _next(next_state: State, time: float) -> void:
	state = next_state
	_timer += time


func _crush() -> void:
	var rect := plate_rect()
	for hurtbox in Harm.hurtboxes_in_rect(get_world_2d(), rect, Harm.EVERYONE):
		if _crushed.has(hurtbox):
			continue
		_crushed[hurtbox] = true
		var is_hero := hurtbox.receiver is Player
		var side := -1.0 if hurtbox.global_position.x < rect.get_center().x else 1.0
		var hit := Hit.make(hero_damage if is_hero else enemy_damage, Vector2(side * 700.0, -380.0),
			Vector2(rect.get_center().x, hurtbox.global_position.y))
		hurtbox.take_hit(hit)


func _on_impact() -> void:
	var floor_point := Vector2(top.x, plate_rect().end.y)
	Fx.burst(get_parent(), floor_point, [Color(1, 0.95, 0.7), Color(1.0, 0.6, 0.2), Color(1.0, 0.3, 0.1, 0.0)], 16,
		520.0, 3.0, 0.35, 900.0, true, Vector2.UP, 80.0)
	Fx.burst(get_parent(), floor_point, [Color(0.5, 0.5, 0.52, 0.6), Color(0.4, 0.4, 0.42, 0.0)], 8, 200.0, 12.0,
		0.6, -50.0, false, Vector2.UP, 85.0)
	Sound.play("boss_slam", 0.08, -10.0, 1.3)
	get_tree().call_group("cameras", "shake", 3.0)


func _draw() -> void:
	var rect := plate_rect()
	var local := Rect2(rect.position - position, rect.size)
	var rod_top := top - position
	# The rod from the ceiling to the plate, with two hoses.
	# With the drawing, the rod above it matches the drawing's darker steel.
	var rod := Color(0.62, 0.65, 0.72) if _art == null else Color(0.3, 0.31, 0.34)
	draw_rect(Rect2(rod_top.x - 12.0, rod_top.y, 24.0, local.position.y - rod_top.y), rod)
	draw_rect(Rect2(rod_top.x - 12.0, rod_top.y, 5.0, local.position.y - rod_top.y), rod.lightened(0.3))
	draw_line(rod_top + Vector2(-22, 0), local.position + Vector2(width / 2.0 - 22.0, 0), DARK, 4.0)
	draw_line(rod_top + Vector2(22, 0), local.position + Vector2(width / 2.0 + 22.0, 0), DARK, 4.0)
	draw_rect(Rect2(rod_top.x - width * 0.3, rod_top.y, width * 0.6, 14.0), DARK)
	if _art != null:
		var factor := _art.scale.x
		_art.position = Vector2(local.position.x, local.end.y - _art.texture.get_height() * factor)
		return
	# The plate: heavy steel with hazard stripes on its face and a warning lamp.
	draw_rect(local, STEEL)
	draw_rect(Rect2(local.position, Vector2(local.size.x, 6)), STEEL.lightened(0.25))
	draw_rect(Rect2(local.position + Vector2(0, local.size.y - 6), Vector2(local.size.x, 6)), DARK)
	var x := 6.0
	while x < local.size.x - 18.0:
		var y := local.position.y + 14.0
		draw_colored_polygon(PackedVector2Array([Vector2(local.position.x + x, y + 18),
			Vector2(local.position.x + x + 12, y), Vector2(local.position.x + x + 22, y),
			Vector2(local.position.x + x + 10, y + 18)]), HAZARD_YELLOW)
		x += 26.0
	var blink := state == State.WARNING and int(Time.get_ticks_msec() / 90) % 2 == 0
	var lamp_color := LAMP if blink or is_dangerous() else LAMP.darkened(0.6)
	draw_circle(local.position + Vector2(local.size.x / 2.0, -6.0), 7.0, lamp_color)
	if blink:
		draw_circle(local.position + Vector2(local.size.x / 2.0, -6.0), 16.0, Color(LAMP, 0.25))
