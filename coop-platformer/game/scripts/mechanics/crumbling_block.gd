class_name CrumblingBlock
extends StaticBody2D
## A cracked block: a moment after a hero steps on it, it shakes and falls
## apart, then comes back after a few seconds (once nobody is in the way).

enum State { SOLID, SHAKING, GONE }

const COLOR := Color(0.55, 0.45, 0.4)

@export var shake_time := 0.5
@export var return_time := 3.0

var state := State.SOLID
var size := Vector2(60, 60)

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
	for i in 3:
		_look.add_child(Harm.box(Vector2(10 + i * 16, 14 + (i % 2) * 20), Vector2(4, 22), COLOR.darkened(0.45)))


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
