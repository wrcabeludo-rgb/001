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
		_bar(Vector2(middle - 3, _cells.position.y), Vector2(6, _cells.size.y), ROPE_COLOR)
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
