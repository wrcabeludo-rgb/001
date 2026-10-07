class_name Rubble
## Drawn bits of broken stone and concrete: a chunk of the ceiling, flying
## shards and cracks.


## A jagged chunk of the ceiling, centred on (0, 0) and about `size` big,
## textured with the zone's own wall (`texture`, tinted like the walls), with a
## darker underside, a lit top edge and a dark outline; `flash` lights it up.
class Rock:
	extends Node2D

	var size := Vector2(56, 46)
	var flash := false
	var seed_value := 1
	var texture: Texture2D
	var tint := Color(0.55, 0.53, 0.56)
	var _shape := PackedVector2Array()

	func _ready() -> void:
		texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		_shape = Rubble.jagged(size / 2.0, 12, seed_value, 0.72)

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		Rubble.draw_stone(self, _shape, texture, tint.lightened(0.6) if flash else tint, global_position)


## A small broken-off piece flying away: spins, falls, bounces once off the
## floor at `floor_y` (world), then fades.
class Shard:
	extends Node2D

	var velocity := Vector2.ZERO
	var spin := 0.0
	var floor_y := 1e9
	var texture: Texture2D
	var tint := Color(0.55, 0.53, 0.56)
	var _shape := PackedVector2Array()
	var _age := 0.0
	var _bounced := false

	func setup(radius: float, seed_value: int) -> void:
		_shape = Rubble.jagged(Vector2(radius, radius * 0.8), 6, seed_value, 0.55)

	func _ready() -> void:
		texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED

	func _process(delta: float) -> void:
		_age += delta
		velocity.y += 2200.0 * delta
		position += velocity * delta
		rotation += spin * delta
		if global_position.y > floor_y and velocity.y > 0.0:
			global_position.y = floor_y
			if _bounced:
				velocity = Vector2.ZERO
				spin = 0.0
			else:
				_bounced = true
				velocity = Vector2(velocity.x * 0.5, -velocity.y * 0.3)
				spin *= 0.5
		modulate.a = clampf(1.6 - _age, 0.0, 1.0)
		if _age > 1.6:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		Rubble.draw_stone(self, _shape, texture, tint, Vector2.ZERO)


## A jagged closed outline around (0, 0) with radii `half`.
static func jagged(half: Vector2, corners: int, seed_value: int, roughness: float) -> PackedVector2Array:
	var random := RandomNumberGenerator.new()
	random.seed = seed_value
	var shape := PackedVector2Array()
	for i in corners:
		var angle := TAU * i / corners + random.randf_range(-0.2, 0.2)
		var reach := random.randf_range(roughness, 1.0)
		shape.append(Vector2(cos(angle) * half.x, sin(angle) * half.y) * reach)
	return shape


## A stone: the wall texture (lined up with the world at `world_at`, like the
## walls), a shaded underside, a lit top edge and an outline.
static func draw_stone(item: CanvasItem, shape: PackedVector2Array, texture: Texture2D, tint: Color,
		world_at: Vector2) -> void:
	if texture != null:
		var uvs := PackedVector2Array()
		for point in shape:
			uvs.append((point + world_at) / 420.0)
		item.draw_colored_polygon(shape, tint, uvs, texture)
	else:
		item.draw_colored_polygon(shape, tint)
	# Darker underside.
	var lower := PackedVector2Array()
	for point in shape:
		lower.append(Vector2(point.x, maxf(point.y, 0.0)))
	item.draw_colored_polygon(lower, Color(0, 0, 0, 0.35))
	# A lit upper edge.
	var top := PackedVector2Array()
	for point in shape:
		if point.y < 0.0:
			top.append(point * 0.92)
	if top.size() > 1:
		item.draw_polyline(top, Color(1, 0.95, 0.85, 0.35), 3.0)
	item.draw_polyline(shape + PackedVector2Array([shape[0]]), Color(0.06, 0.05, 0.05, 0.9), 2.5)


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
