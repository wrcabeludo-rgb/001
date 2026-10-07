class_name Rubble
## Drawn bits of broken stone and concrete: a jagged chunk of rock and cracks.


## A jagged boulder filling `size` (top-left at 0, 0), with a lit top and a
## dark underside; `flash` turns it white (about to fall).
class Rock:
	extends Node2D

	var size := Vector2(48, 40)
	var flash := false
	var seed_value := 1
	var _shape := PackedVector2Array()

	func _ready() -> void:
		var random := RandomNumberGenerator.new()
		random.seed = seed_value
		var middle := size / 2.0
		for i in 11:
			var angle := TAU * i / 11.0 + random.randf_range(-0.15, 0.15)
			var reach := random.randf_range(0.78, 1.0)
			_shape.append(middle + Vector2(cos(angle) * middle.x, sin(angle) * middle.y) * reach)

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var base := Color(0.46, 0.42, 0.39)
		if flash:
			draw_colored_polygon(_shape, Color(0.95, 0.92, 0.88))
			return
		draw_colored_polygon(_shape, base.darkened(0.35))
		# The lit upper part, a little smaller and higher.
		var top := PackedVector2Array()
		for point in _shape:
			top.append(size / 2.0 + (point - size / 2.0) * 0.8 + Vector2(-2, -4))
		draw_colored_polygon(top, base)
		draw_line(size * Vector2(0.3, 0.35), size * Vector2(0.55, 0.6), base.darkened(0.5), 2.0)
		draw_line(size * Vector2(0.55, 0.6), size * Vector2(0.7, 0.5), base.darkened(0.5), 2.0)
		draw_polyline(_shape + PackedVector2Array([_shape[0]]), Color(0.12, 0.1, 0.1), 2.0)


## Dark jagged cracks spreading from (0, 0) across a surface `size` wide.
class Cracks:
	extends Node2D

	var width := 60.0
	var count := 3
	var seed_value := 1
	var color := Color(0.08, 0.07, 0.07, 0.9)
	var _lines: Array[PackedVector2Array] = []

	func _ready() -> void:
		var random := RandomNumberGenerator.new()
		random.seed = seed_value
		for i in count:
			var line := PackedVector2Array([Vector2(random.randf_range(-width * 0.2, width * 0.2), 0)])
			var heading := Vector2.from_angle(random.randf_range(0.6, 2.5))
			for step in 5:
				heading = heading.rotated(random.randf_range(-0.6, 0.6))
				line.append(line[line.size() - 1] + heading * width * 0.14)
			_lines.append(line)

	func _draw() -> void:
		for line in _lines:
			draw_polyline(line, color, 3.0)
