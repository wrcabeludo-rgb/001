class_name CrumblingBlock
extends StaticBody2D
## A cracked block: a moment after a hero steps on it, it shakes and falls
## apart, then comes back after a few seconds (once nobody is in the way).
## It is drawn with the zone's own wall or ground (`look_material`), cracked.

enum State { SOLID, SHAKING, GONE }

const COLOR := Color(0.55, 0.45, 0.4)

@export var shake_time := 0.5
@export var return_time := 3.0

var state := State.SOLID
var size := Vector2(60, 60)
## The level's terrain material, so the block looks like the walls around it.
var look_material: ShaderMaterial

var _timer := 0.0
var _collision: CollisionShape2D
var _look: ColorRect


func setup(cell: Rect2) -> void:
	position = cell.get_center()
	size = cell.size


func _ready() -> void:
	add_to_group("resettable")
	collision_layer = Layers.WORLD
	var shape := RectangleShape2D.new()
	shape.size = size
	_collision = CollisionShape2D.new()
	_collision.shape = shape
	add_child(_collision)
	_look = Harm.box(-size / 2.0, size, COLOR)
	add_child(_look)
	if look_material != null:
		_look.material = look_material
		_look.color = Color.WHITE
	else:
		_look.add_child(Harm.box(Vector2.ZERO, Vector2(size.x, 6), COLOR.lightened(0.2)))
	var cracks := Rubble.Cracks.new()
	cracks.width = size.x
	cracks.seed_value = int(position.x * 3.0 + position.y)
	cracks.position = Vector2(size.x / 2.0, 0)
	_look.add_child(cracks)


func _physics_process(delta: float) -> void:
	match state:
		State.SOLID:
			if _hero_on_top():
				state = State.SHAKING
				Sound.play("crumble")
				_timer = shake_time
		State.SHAKING:
			_timer -= delta
			_look.position = -size / 2.0 + Vector2(randf_range(-3, 3), randf_range(-2, 2))
			if _timer <= 0.0:
				state = State.GONE
				_timer = return_time
				_look.visible = false
				_collision.set_deferred("disabled", true)
				Fx.burst(get_parent(), global_position, [Color(0.5, 0.44, 0.4), Color(0.35, 0.3, 0.28, 0.0)], 14, 260.0,
					7.0, 0.8, 1300.0, false)
				Fx.burst(get_parent(), global_position, [Color(0.55, 0.5, 0.45, 0.6), Color(0.5, 0.45, 0.4, 0.0)], 10,
					120.0, 12.0, 0.6, -30.0, false)
		State.GONE:
			_timer -= delta
			if _timer <= 0.0 and not _someone_inside():
				reset()


## Back in one piece (also after the team restarts at a checkpoint).
func reset() -> void:
	state = State.SOLID
	_look.position = -size / 2.0
	_look.visible = true
	_collision.set_deferred("disabled", false)


func _hero_on_top() -> bool:
	var top := global_position.y - size.y / 2.0
	for node in get_tree().get_nodes_in_group("players"):
		var hero := node as Player
		if hero == null or not hero.is_alive():
			continue
		var feet := hero.global_position + Vector2(0, Player.SIZE.y / 2.0)
		if absf(feet.y - top) < 4.0 and absf(feet.x - global_position.x) < (size.x + Player.SIZE.x) / 2.0 - 2.0:
			return true
	return false


func _someone_inside() -> bool:
	var area := Rect2(global_position - size / 2.0, size)
	for node in get_tree().get_nodes_in_group("players") + get_tree().get_nodes_in_group("enemies"):
		var body := node as Node2D
		if body != null and area.grow(50.0).has_point(body.global_position):
			return true
	return false
