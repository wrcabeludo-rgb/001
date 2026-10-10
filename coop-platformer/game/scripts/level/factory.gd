class_name Factory
## Shared look of the world 2 zones: the painted parallax layers when they are
## drawn, otherwise dark stand-in silhouettes (tools/factory_placeholders.py).


## Parallax layers for `Level.backgrounds`: far and mid, tinted darker than the
## playing field so heroes and robots stand out. `zone` is 1..3.
static func backgrounds(far_path: String, mid_path: String, zone: int) -> Array:
	var far := texture(far_path)
	var mid := texture(mid_path)
	if far == null:
		far = load("res://assets/art/placeholders/factory_far_%d.png" % zone)
	if mid == null:
		mid = load("res://assets/art/placeholders/factory_mid_%d.png" % zone)
	return [[far, 0.1, Color(0.42, 0.42, 0.48)], [mid, 0.3, Color(0.6, 0.6, 0.65)]]


## The texture at `path`, or null while it is not drawn yet.
static func texture(path: String) -> Texture2D:
	return load(path) if ResourceLoader.exists(path) else null


## The factory catwalk for one-way platforms, cranes and shuttles.
const PLATFORM := "res://assets/art/tiles/platform_2.png"


## A zone tile ("2-1_wall"...): the painted one, or the stand-in steel plates.
static func tile(name: String) -> Texture2D:
	var painted := texture("res://assets/art/tiles/%s.png" % name)
	return painted if painted != null else texture("res://assets/art/placeholders/tiles/%s.png" % name)
