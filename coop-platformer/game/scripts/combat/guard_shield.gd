class_name GuardShield
extends Node2D
## The Swordsman's guard: a glowing arc in front of him while he blocks. It
## flares up when it stops a hit. Drawn for a hero facing right; `scale.x`
## mirrors it.

const RADIUS := 46.0
const SPAN := 1.05
const COLOR := Color(1.0, 0.62, 0.25)

var _flare := 0.0
var _time := 0.0


## A blocked hit: a bright flash and a little bump.
func flare() -> void:
	_flare = 1.0


func _process(delta: float) -> void:
	_time += delta
	_flare = move_toward(_flare, 0.0, delta * 4.0)
	scale.y = 1.0 + 0.12 * _flare
	if visible:
		queue_redraw()


func _draw() -> void:
	var pulse := 0.8 + 0.2 * sin(_time * 9.0)
	var glow := Color(COLOR, (0.18 + 0.4 * _flare) * pulse)
	var edge := Color(COLOR.lightened(0.3 + 0.5 * _flare), 0.75 + 0.25 * _flare)
	_band(RADIUS + 4.0, 26.0 + 14.0 * _flare, glow)
	_band(RADIUS, 9.0, edge)
	_band(RADIUS + 2.0, 3.0, Color(1, 1, 0.92, 0.9))


func _band(r: float, width: float, fill: Color) -> void:
	var steps := 20
	var outer := PackedVector2Array()
	var inner := PackedVector2Array()
	for i in steps + 1:
		var k := float(i) / steps
		var angle := lerpf(-SPAN, SPAN, k)
		# Thinner at the tips.
		var w := width * (0.35 + 0.65 * sin(k * PI))
		outer.append(Vector2.from_angle(angle) * (r + w * 0.5))
		inner.append(Vector2.from_angle(angle) * (r - w * 0.5))
	inner.reverse()
	draw_colored_polygon(outer + inner, fill)
