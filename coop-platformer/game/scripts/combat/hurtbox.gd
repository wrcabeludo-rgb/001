class_name Hurtbox
extends Area2D
## The area where its owner can be hit. The owner implements
## receive_hit(hit: Hit) -> bool and returns true if the hit counted.

var receiver: Node

var _collision: CollisionShape2D


func setup(team: Layers.Team, size: Vector2, p_receiver: Node) -> void:
	receiver = p_receiver
	collision_layer = Layers.hurtbox_layer(team)
	collision_mask = 0
	monitoring = false
	monitorable = true
	var shape := RectangleShape2D.new()
	shape.size = size
	_collision = CollisionShape2D.new()
	_collision.shape = shape
	add_child(_collision)


## Changes the area (a crouching hero is lower); `center` is relative to the owner.
func resize(size: Vector2, center: Vector2) -> void:
	(_collision.shape as RectangleShape2D).size = size
	_collision.position = center


func take_hit(hit: Hit) -> bool:
	if receiver == null or not is_instance_valid(receiver):
		return false
	return receiver.receive_hit(hit)
