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
var _art: Sprite2D


func _ready() -> void:
	speed = 130.0
	pause_time = 1.0
	super._ready()
	_last_x = position.x
	var path := "res://assets/art/props/crane.png"
	if ResourceLoader.exists(path):
		# The drawing's platform sits at its bottom; its trolley at the top.
		for child in get_children():
			if child is Control:
				child.visible = false
		_art = Sprite2D.new()
		_art.texture = load(path)
		_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var factor := width * 1.1 / _art.texture.get_width()
		_art.scale = Vector2(factor, (position.y - rail_y + THICKNESS) / _art.texture.get_height())
		_art.position = Vector2(0, -(position.y - rail_y) / 2.0 + THICKNESS / 2.0)
		add_child(_art)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	var moved := position.x - _last_x
	_last_x = position.x
	_sway = lerpf(_sway, clampf(-moved * 0.6, -14.0, 14.0), 4.0 * delta)
	queue_redraw()


func _draw() -> void:
	var up := rail_y - position.y
	# The rail between the two ends, fixed in the world.
	var from := minf(point_a.x, point_b.x) - width / 2.0 - position.x
	var to := maxf(point_a.x, point_b.x) + width / 2.0 - position.x
	draw_rect(Rect2(from, up - 14.0, to - from, 14.0), RAIL_COLOR.darkened(0.35))
	draw_rect(Rect2(from, up - 14.0, to - from, 4.0), RAIL_COLOR)
	if _art != null:
		return
	# The trolley and the cables down to the platform.
	draw_rect(Rect2(-40, up, 80, 22), Color(0.3, 0.32, 0.38))
	draw_circle(Vector2(-26, up), 8.0, Color(0.2, 0.2, 0.24))
	draw_circle(Vector2(26, up), 8.0, Color(0.2, 0.2, 0.24))
	for side in [-1.0, 1.0]:
		var bottom := Vector2(side * (width / 2.0 - 14.0), 0.0)
		draw_line(Vector2(side * 24.0 + _sway, up + 22.0), bottom, CABLE_COLOR, 3.0)
