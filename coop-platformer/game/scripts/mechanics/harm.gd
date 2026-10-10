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


const PLATFORM_TEXTURE := "res://assets/art/tiles/platform.png"


## The look of a platform plank: the catwalk strip tiled sideways, or a plain bar.
static func plank(at: Vector2, width: float, fallback: Color, texture := PLATFORM_TEXTURE) -> Control:
	if not ResourceLoader.exists(texture):
		return box(at, Vector2(width, 20), fallback)
	var strip := TextureRect.new()
	strip.texture = load(texture)
	strip.stretch_mode = TextureRect.STRETCH_TILE
	strip.position = at
	strip.size = Vector2(width, strip.texture.get_height())
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return strip


## The look of the current world's props: "" (world 1) or "factory" (world 2).
## A prop drawn for it ("checkpoint_factory") replaces the plain one. Set by Level.
static var skin := ""


## Path of a prop's picture, in the current world's look when it has one.
static func prop_path(prop: String) -> String:
	if skin != "":
		var skinned := "res://assets/art/props/%s_%s.png" % [prop, skin]
		if ResourceLoader.exists(skinned):
			return skinned
	return "res://assets/art/props/%s.png" % prop


## A prop's picture from assets/art/props, standing on the bottom of a box of
## `size` centred on the origin (null if the picture is not drawn yet).
static func prop_sprite(prop: String, size: Vector2) -> Sprite2D:
	var path := prop_path(prop)
	if not ResourceLoader.exists(path):
		return null
	var sprite := Sprite2D.new()
	sprite.texture = load(path)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.scale = Vector2(0.5, 0.5)
	sprite.position = Vector2(0, size.y / 2.0 - sprite.texture.get_height() * 0.25)
	sprite.material = Flash.material()
	return sprite


## A picture from assets/art/props repeated over an area (spikes along a pit,
## rungs up a ladder). The art is drawn at twice the game size.
static func tiled_prop(prop: String, at: Vector2, size: Vector2) -> TextureRect:
	var path := "res://assets/art/props/%s.png" % prop
	if not ResourceLoader.exists(path):
		return null
	var strip := TextureRect.new()
	strip.texture = load(path)
	strip.stretch_mode = TextureRect.STRETCH_TILE
	strip.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	strip.position = at
	strip.scale = Vector2(0.5, 0.5)
	strip.size = size * 2.0
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return strip
