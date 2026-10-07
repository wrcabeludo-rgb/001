class_name Climbable
extends Node2D
## A ladder or a rope. A hero grabs it with up (or down from the top of a
## ladder), climbs with up/down and jumps off with jump. A hero in the air
## grabs a rope just by touching it. The top of a ladder always has a ledge
## to step onto (Level adds a one-way platform there).

enum Kind { LADDER, ROPE }

const LADDER_COLOR := Color(0.62, 0.5, 0.32)
const ROPE_COLOR := Color(0.78, 0.7, 0.5)
## How far from the middle of a ladder or rope a hero can still grab it.
const REACH := 34.0

var kind: Kind = Kind.LADDER
## Where the hero's feet can be while climbing, in world coordinates. On a
## ladder it reaches one tile above the topmost rung (the ledge); a hero hangs
## from a rope by the hands, so the feet go a little below its end.
var feet_area := Rect2()

var _cells := Rect2()


func setup(p_kind: Kind, cells: Rect2, tile: float) -> void:
	kind = p_kind
	_cells = cells
	if kind == Kind.LADDER:
		feet_area = Rect2(cells.position.x, cells.position.y - tile, cells.size.x, cells.size.y + tile)
	else:
		feet_area = Rect2(cells.position.x, cells.position.y + Player.SIZE.y, cells.size.x,
			maxf(cells.size.y - Player.SIZE.y, 0.0) + Player.SIZE.y / 2.0)


func _ready() -> void:
	add_to_group("climbables")
	var middle := _cells.get_center().x
	if kind == Kind.ROPE:
		var rope := RopeLook.new()
		rope.position = Vector2(middle, _cells.position.y)
		rope.length = _cells.size.y
		add_child(rope)
		return
	var picture := Harm.tiled_prop("ladder", Vector2.ZERO, Vector2(1, _cells.size.y))
	if picture != null:
		# One ladder wide, as tall as the rungs on the map.
		var width := picture.texture.get_width() * 0.5
		picture.size.x = picture.texture.get_width()
		picture.position = Vector2(middle - width / 2.0, _cells.position.y)
		add_child(picture)
		return
	for side in [-1, 1]:
		_bar(Vector2(middle + side * 18 - 3, _cells.position.y), Vector2(6, _cells.size.y), LADDER_COLOR)
	var y := _cells.position.y + 10
	while y < _cells.end.y:
		_bar(Vector2(middle - 18, y), Vector2(36, 5), LADDER_COLOR)
		y += 24


func center_x() -> float:
	return feet_area.get_center().x


## True if a hero whose feet are at `feet` can hold on here.
func reaches(feet: Vector2) -> bool:
	return absf(feet.x - center_x()) < REACH and feet.y >= feet_area.position.y - 0.5 \
		and feet.y <= feet_area.end.y + 0.5


func _bar(at: Vector2, size: Vector2, color: Color) -> void:
	var bar := ColorRect.new()
	bar.position = at
	bar.size = size
	bar.color = color
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)


## A braided rope hanging from a ring, swaying a little at the bottom.
class RopeLook:
	extends Node2D

	var length := 300.0
	var _time := 0.0

	func _process(delta: float) -> void:
		_time += delta
		queue_redraw()

	func _draw() -> void:
		var sway := sin(_time * 1.6) * 4.0
		var dark := ROPE_COLOR.darkened(0.45)
		var points := PackedVector2Array()
		var steps := maxi(4, int(length / 24.0))
		for i in steps + 1:
			var k := float(i) / steps
			points.append(Vector2(sway * k * k, length * k))
		draw_polyline(points, dark, 8.0)
		draw_polyline(points, ROPE_COLOR, 5.0)
		# The twist: short dark strokes slanting across the rope.
		var y := 6.0
		while y < length - 4.0:
			var k := y / length
			var x := sway * k * k
			draw_line(Vector2(x - 3, y - 3), Vector2(x + 3, y + 3), dark, 2.0)
			y += 9.0
		draw_arc(Vector2(0, -2), 7.0, 0.0, TAU, 16, Color(0.45, 0.45, 0.5), 3.0)
		draw_circle(Vector2(sway, length), 5.0, dark)
