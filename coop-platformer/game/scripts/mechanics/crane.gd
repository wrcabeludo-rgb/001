class_name Crane
extends MovingPlatform
## A platform hanging on two cables from a trolley that runs along a rail under
## the ceiling. It shuttles like a moving platform, a little slower, and its
## cables sway as it starts and stops.

const RAIL_COLOR := Color(0.85, 0.65, 0.15)
const CABLE_COLOR := Color(0.12, 0.12, 0.14)

## The rail's height (world y) above the platform.
var rail_y := 0.0

var _sway := 0.0
var _last_x := 0.0
## The drawn trolley and platform (null until drawn): the cables between them
## are drawn here, so the crane can hang at any height.
var _top: Sprite2D
var _bottom: Sprite2D

## Where the parts sit in their drawings: the rail's middle (share of the top
## picture's height), the deck (share of the bottom one), the cables (share of
## the bottom one's width from its middle).
const RAIL_AT := 0.35
const DECK_AT := 0.6
const CABLE_AT := 0.262


func _ready() -> void:
	speed = 130.0
	pause_time = 1.0
	super._ready()
	_last_x = position.x
	var bottom_path := "res://assets/art/props/crane_bottom.png"
	var top_path := "res://assets/art/props/crane_top.png"
	if not ResourceLoader.exists(bottom_path) or not ResourceLoader.exists(top_path):
		return
	for child in get_children():
		if child is Control:
			child.visible = false
	_bottom = _part(bottom_path)
	var factor := width * 1.15 / _bottom.texture.get_width()
	_bottom.scale = Vector2(factor, factor)
	var height := _bottom.texture.get_height() * factor
	_bottom.position = Vector2(0, (0.5 - DECK_AT) * height)
	_top = _part(top_path)
	_top.scale = Vector2(factor, factor)
	_top.z_index = 1


func _part(path: String) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = load(path)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(sprite)
	return sprite


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	var moved := position.x - _last_x
	_last_x = position.x
	_sway = lerpf(_sway, clampf(-moved * 0.6, -14.0, 14.0), 4.0 * delta)
	if _top != null:
		var top_height := _top.texture.get_height() * _top.scale.y
		_top.position = Vector2(_sway, rail_y - position.y - 7.0 + (0.5 - RAIL_AT) * top_height)
	queue_redraw()


func _draw() -> void:
	var up := rail_y - position.y
	# The rail between the two ends, fixed in the world.
	var from := minf(point_a.x, point_b.x) - width / 2.0 - position.x
	var to := maxf(point_a.x, point_b.x) + width / 2.0 - position.x
	draw_rect(Rect2(from, up - 14.0, to - from, 14.0), RAIL_COLOR.darkened(0.35))
	draw_rect(Rect2(from, up - 14.0, to - from, 4.0), RAIL_COLOR)
	if _bottom != null:
		# Two steel cables from the trolley's pulleys down to the shackles.
		var bottom_width := _bottom.texture.get_width() * _bottom.scale.x
		var shackles := _bottom.position.y - _bottom.texture.get_height() * _bottom.scale.y / 2.0 + 4.0
		var pulleys := _top.position.y + _top.texture.get_height() * _top.scale.y / 2.0 - 6.0
		for side in [-1.0, 1.0]:
			var x: float = side * CABLE_AT * bottom_width
			draw_line(Vector2(x + _sway, pulleys), Vector2(x, shackles), Color(0.25, 0.25, 0.27), 4.0)
			draw_line(Vector2(x + _sway - 1.0, pulleys), Vector2(x - 1.0, shackles), Color(0.55, 0.55, 0.58), 1.5)
		return
	# The trolley and the cables down to the platform.
	draw_rect(Rect2(-40, up, 80, 22), Color(0.3, 0.32, 0.38))
	draw_circle(Vector2(-26, up), 8.0, Color(0.2, 0.2, 0.24))
	draw_circle(Vector2(26, up), 8.0, Color(0.2, 0.2, 0.24))
	for side in [-1.0, 1.0]:
		var bottom := Vector2(side * (width / 2.0 - 14.0), 0.0)
		draw_line(Vector2(side * 24.0 + _sway, up + 22.0), bottom, CABLE_COLOR, 3.0)
