class_name Checkpoint
extends Area2D
## A post that lights up when any hero reaches it. When the whole team is down,
## everyone comes back here. It only remembers the place (no healing on touch).

signal reached(checkpoint: Checkpoint)

const POLE_SIZE := Vector2(14, 150)
const OFF_COLOR := Color(0.3, 0.32, 0.38)
const ON_COLOR := Color(0.55, 1.0, 0.75)

var active := false

var _light: ColorRect


func _ready() -> void:
	collision_layer = 0
	collision_mask = Layers.PLAYER_BODIES
	monitorable = false
	var shape := RectangleShape2D.new()
	shape.size = Vector2(90, POLE_SIZE.y)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.position = Vector2(0, -POLE_SIZE.y / 2)
	add_child(collision)

	var pole := ColorRect.new()
	pole.size = POLE_SIZE
	pole.position = Vector2(-POLE_SIZE.x / 2, -POLE_SIZE.y)
	pole.color = Color(0.22, 0.24, 0.3)
	pole.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pole)
	_light = ColorRect.new()
	_light.size = Vector2(30, 30)
	_light.position = Vector2(-15, -POLE_SIZE.y - 24)
	_light.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_light)
	set_active(false)

	body_entered.connect(_on_body_entered)


func set_active(value: bool) -> void:
	active = value
	_light.color = ON_COLOR if active else OFF_COLOR


## Where a hero of `slot` reappears: player 1 a bit left of the post, player 2 a bit right.
func respawn_point(slot: int) -> Vector2:
	return global_position + Vector2(-40.0 + 80.0 * slot, -Player.SIZE.y / 2)


func _on_body_entered(body: Node2D) -> void:
	if body is Player and not active:
		reached.emit(self)
