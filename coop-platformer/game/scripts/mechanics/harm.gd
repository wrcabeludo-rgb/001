class_name Harm
## Helpers for level dangers: find the hurtboxes inside a shape right now,
## without waiting a physics frame for an Area2D to notice them.

const HEROES := Layers.PLAYER_HURTBOXES
const EVERYONE := Layers.PLAYER_HURTBOXES | Layers.ENEMY_HURTBOXES


## Hurtboxes (of the layers in `mask`) overlapping a rectangle given in world coordinates.
static func hurtboxes_in_rect(world: World2D, rect: Rect2, mask: int) -> Array[Hurtbox]:
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	return _query(world, shape, Transform2D(0.0, rect.get_center()), mask)


static func hurtboxes_in_circle(world: World2D, center: Vector2, radius: float, mask: int) -> Array[Hurtbox]:
	var shape := CircleShape2D.new()
	shape.radius = radius
	return _query(world, shape, Transform2D(0.0, center), mask)


static func _query(world: World2D, shape: Shape2D, at: Transform2D, mask: int) -> Array[Hurtbox]:
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = at
	query.collision_mask = mask
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var result: Array[Hurtbox] = []
	for hit in world.direct_space_state.intersect_shape(query, 32):
		var hurtbox := hit["collider"] as Hurtbox
		if hurtbox != null and not result.has(hurtbox):
			result.append(hurtbox)
	return result


## A filled triangle pointing up, used for spikes.
static func spike(at: Vector2, width: float, height: float, color: Color) -> Polygon2D:
	var polygon := Polygon2D.new()
	polygon.polygon = PackedVector2Array([at, at + Vector2(width / 2.0, -height), at + Vector2(width, 0)])
	polygon.color = color
	return polygon


static func box(at: Vector2, size: Vector2, color: Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.position = at
	rect.size = size
	rect.color = color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect
