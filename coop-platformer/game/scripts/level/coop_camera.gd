class_name CoopCamera
extends Camera2D
## Keeps every living hero in view: centres on them, zooms out as they spread
## apart (down to MIN_ZOOM) and never shows outside the level bounds when it
## can avoid it. Once fully zoomed out, the screen edges hold the heroes back
## (Level clamps them to visible_rect()).

## The farthest the camera zooms out (0.7 shows about 1.4x of a normal screen).
const MIN_ZOOM := 0.7
## Space kept between the heroes and the screen edge, in world pixels.
const PADDING := Vector2(320, 240)
const FOLLOW_SPEED := 8.0
const ZOOM_SPEED := 3.0

## The level area in world coordinates.
var bounds := Rect2()


func _ready() -> void:
	anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
	position_smoothing_enabled = false


## Moves and zooms towards the heroes; `instant` jumps there (after a respawn).
func follow(heroes: Array[Player], delta: float, instant := false) -> void:
	if heroes.is_empty():
		return
	var box := Rect2(heroes[0].global_position, Vector2.ZERO)
	for hero in heroes:
		box = box.expand(hero.global_position)

	var base := base_size()
	var need := box.size + PADDING * 2.0
	var target_zoom := clampf(minf(base.x / need.x, base.y / need.y), MIN_ZOOM, 1.0)
	var new_zoom := target_zoom if instant else lerpf(zoom.x, target_zoom, 1.0 - exp(-ZOOM_SPEED * delta))
	zoom = Vector2(new_zoom, new_zoom)

	var half := base / new_zoom / 2.0
	var center := box.get_center()
	center.x = _clamp_axis(center.x, half.x, bounds.position.x, bounds.end.x)
	center.y = _clamp_axis(center.y, half.y, bounds.position.y, bounds.end.y)
	position = center if instant else position.lerp(center, 1.0 - exp(-FOLLOW_SPEED * delta))


## The part of the world currently on screen.
func visible_rect() -> Rect2:
	var size := base_size() / zoom.x
	return Rect2(global_position - size / 2.0, size)


## The game's design resolution: what the screen shows at zoom 1.
static func base_size() -> Vector2:
	return Vector2(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height")
	)


static func _clamp_axis(value: float, half: float, low: float, high: float) -> float:
	if high - low <= half * 2.0:
		return (low + high) / 2.0
	return clampf(value, low + half, high - half)
