class_name Conveyor
extends StaticBody2D
## A conveyor belt: a solid strip of floor whose surface moves. Everyone standing
## on it (heroes, enemies, crates) is carried along at `speed`; walking against
## it is slow. A belt that ends over a pit throws whoever dawdles into it.

const FRAME_COLOR := Color(0.2, 0.22, 0.27)
const BELT_COLOR := Color(0.07, 0.07, 0.09)
const RIB_COLOR := Color(0.3, 0.31, 0.35)
const HAZARD_YELLOW := Color(1.0, 0.79, 0.24)
const BELT_HEIGHT := 16.0
const RIB_SPACING := 24.0
const ROLLER_SPACING := 60.0

@export var speed := 200.0

## 1 = to the right, -1 = to the left.
var direction := 1
## The cells of the belt in parent coordinates.
var rect := Rect2()

var _shift := 0.0
var _art: Control
var _art_strip: TextureRect


func setup(cells: Rect2, p_direction: int, p_speed := 200.0) -> void:
	rect = cells
	direction = p_direction
	speed = p_speed


func _ready() -> void:
	collision_layer = Layers.WORLD
	collision_mask = 0
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.position = rect.get_center()
	add_child(collision)
	_apply_speed()
	var path := "res://assets/art/props/conveyor.png"
	if ResourceLoader.exists(path):
		# The drawn belt, repeated along the run and sliding with the belt.
		_art = Control.new()
		_art.clip_contents = true
		_art.position = rect.position
		_art.size = Vector2(rect.size.x, rect.size.y)
		_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_art)
		_art_strip = TextureRect.new()
		_art_strip.texture = load(path)
		_art_strip.stretch_mode = TextureRect.STRETCH_TILE
		_art_strip.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var factor := rect.size.y / _art_strip.texture.get_height()
		_art_strip.scale = Vector2(factor, factor)
		_art_strip.size = Vector2((rect.size.x / factor) + _art_strip.texture.get_width() * 2.0,
			_art_strip.texture.get_height())
		_art_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_art.add_child(_art_strip)


## Turns the belt around (a lever can do it).
func reverse() -> void:
	direction = -direction
	_apply_speed()


func _apply_speed() -> void:
	constant_linear_velocity = Vector2(direction * speed, 0.0)


func _process(delta: float) -> void:
	_shift = fmod(_shift + direction * speed * delta, 1000000.0)
	if _art_strip != null:
		var width := _art_strip.texture.get_width() * _art_strip.scale.x
		_art_strip.position.x = fposmod(_shift, width) - width
	else:
		queue_redraw()


func _draw() -> void:
	if _art != null:
		return
	var top := rect.position
	var width := rect.size.x
	# Frame with hazard stripes, rollers under the belt.
	draw_rect(Rect2(top + Vector2(0, BELT_HEIGHT), Vector2(width, rect.size.y - BELT_HEIGHT)), FRAME_COLOR)
	var stripe_y := top.y + rect.size.y - 12.0
	var x := 0.0
	while x < width:
		var stripe := PackedVector2Array([Vector2(top.x + x, stripe_y + 10), Vector2(top.x + x + 10, stripe_y),
			Vector2(top.x + x + 20, stripe_y), Vector2(top.x + x + 10, stripe_y + 10)])
		draw_colored_polygon(stripe, HAZARD_YELLOW.darkened(0.15))
		x += 24.0
	var roller := ROLLER_SPACING / 2.0
	while roller < width:
		var center := top + Vector2(roller, BELT_HEIGHT + 12.0)
		draw_circle(center, 9.0, Color(0.35, 0.37, 0.42))
		var spin := _shift / 9.0
		draw_line(center, center + Vector2.from_angle(spin) * 8.0, Color(0.15, 0.15, 0.18), 2.0)
		roller += ROLLER_SPACING
	# The belt: black rubber with ribs that run in the belt's direction.
	draw_rect(Rect2(top, Vector2(width, BELT_HEIGHT)), BELT_COLOR)
	var rib := fposmod(_shift, RIB_SPACING)
	while rib < width:
		draw_rect(Rect2(top + Vector2(rib, 2), Vector2(5, BELT_HEIGHT - 5)), RIB_COLOR)
		rib += RIB_SPACING
	draw_rect(Rect2(top, Vector2(width, 2)), Color(0.5, 0.52, 0.58))
	# Arrows along the frame show which way it runs.
	var arrow := 90.0
	while arrow < width - 30.0:
		var tip := top + Vector2(arrow, BELT_HEIGHT + 30.0)
		var back := -direction * 10.0
		draw_colored_polygon(PackedVector2Array([tip + Vector2(-back, 0), tip + Vector2(back, -8),
			tip + Vector2(back, 8)]), Color(HAZARD_YELLOW, 0.8))
		arrow += 180.0
