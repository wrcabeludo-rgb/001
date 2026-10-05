class_name Projectile
extends Area2D
## A bullet: flies straight, stops at walls, damages the other team's hurtboxes.
## `pierce` is how many extra targets it can pass through.

var velocity := Vector2.ZERO
var damage := 1
var knockback := 300.0
var pierce := 0
var lifetime := 1.0

var _already_hit := {}


func setup(team: Layers.Team, start: Vector2, direction: Vector2, speed: float, p_damage: int,
		p_knockback: float, size: Vector2, color: Color, p_pierce := 0, p_lifetime := 1.0) -> void:
	position = start
	velocity = direction.normalized() * speed
	rotation = velocity.angle()
	damage = p_damage
	knockback = p_knockback
	pierce = p_pierce
	lifetime = p_lifetime
	collision_layer = 0
	collision_mask = Layers.WORLD | Layers.target_hurtboxes(team)
	monitorable = false

	var rect := RectangleShape2D.new()
	rect.size = size
	var collision := CollisionShape2D.new()
	collision.shape = rect
	add_child(collision)

	var visual := ColorRect.new()
	visual.size = size
	visual.position = -size / 2.0
	visual.color = color
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(visual)

	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position += velocity * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	for area in get_overlapping_areas():
		var hurtbox := area as Hurtbox
		if hurtbox == null or _already_hit.has(hurtbox):
			continue
		_already_hit[hurtbox] = true
		var push := velocity.normalized() * knockback + Vector2(0, -knockback * 0.4)
		if hurtbox.take_hit(Hit.make(damage, push, global_position)):
			if pierce <= 0:
				queue_free()
				return
			pierce -= 1


func _on_body_entered(_body: Node2D) -> void:
	queue_free()
