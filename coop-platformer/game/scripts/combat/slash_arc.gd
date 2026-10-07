class_name SlashArc
extends Node2D
## The trail of a swing: a crescent that sweeps from one angle to another and
## fades. Angles are in radians for a hero facing right (0 = ahead, -PI/2 =
## up); `side` mirrors it for a hero facing left. Lives on the hero, so it
## follows them during the swing.

var radius := 70.0
var thickness := 16.0
var from_angle := -1.0
var to_angle := 1.0
var color := Color(1.0, 0.6, 0.25)
var side := 1
var life := 0.2

var _age := 0.0


static func make(p_radius: float, p_thickness: float, p_from: float, p_to: float, p_color: Color,
		p_side: int, p_life: float) -> SlashArc:
	var arc := SlashArc.new()
	arc.radius = p_radius
	arc.thickness = p_thickness
	arc.from_angle = p_from
	arc.to_angle = p_to
	arc.color = p_color
	arc.side = p_side
	arc.life = p_life
	return arc


func _ready() -> void:
	z_index = 2
	scale.x = side
	# Light adds up: the trail glows over dark backgrounds.
	var glow := CanvasItemMaterial.new()
	glow.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = glow


func _process(delta: float) -> void:
	_age += delta
	if _age >= life:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var t := _age / life
	# The edge sweeps through the first half; the whole trail fades in the second.
	var reach := clampf(t / 0.45, 0.0, 1.0)
	var fade := 1.0 - clampf((t - 0.35) / 0.65, 0.0, 1.0)
	var head := lerpf(from_angle, to_angle, ease(reach, 0.4))
	var tail := lerpf(from_angle, head, clampf((t - 0.15) / 0.6, 0.0, 1.0))
	if absf(head - tail) < 0.02:
		return
	# Outer glow, then the bright blade edge.
	_crescent(tail, head, radius + thickness * 0.4, thickness * 1.8, Color(color, 0.25 * fade))
	_crescent(tail, head, radius, thickness, Color(color, 0.85 * fade))
	_crescent(tail, head, radius + thickness * 0.25, thickness * 0.35, Color(1, 1, 0.9, 0.9 * fade))


## A crescent between two angles that is thickest at the leading end.
func _crescent(tail: float, head: float, r: float, width: float, fill: Color) -> void:
	var steps := 18
	var outer := PackedVector2Array()
	var inner := PackedVector2Array()
	for i in steps + 1:
		var k := float(i) / steps
		var angle := lerpf(tail, head, k)
		var w := width * (0.15 + 0.85 * k)
		outer.append(Vector2.from_angle(angle) * (r + w * 0.5))
		inner.append(Vector2.from_angle(angle) * (r - w * 0.5))
	inner.reverse()
	draw_colored_polygon(outer + inner, fill)
