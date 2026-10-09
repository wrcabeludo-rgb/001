class_name CrateChute
extends Node2D
## A hatch in the ceiling of the factory: every few seconds (after a blinking
## warning) it drops a heavy crate. A falling crate hurts whoever it lands on;
## a crate on the ground is a step to climb on, and it rides conveyors. Crates
## vanish after a while.

const HATCH_SIZE := Vector2(80, 18)
const LAMP := Color(1.0, 0.75, 0.2)

@export var interval := 3.5
@export var warning_time := 0.6

var _timer := 0.0


func setup(at: Vector2, phase := 0.0) -> void:
	position = at
	_timer = interval - phase


func _physics_process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_timer += interval
		var crate := FallingCrate.new()
		crate.position = position + Vector2(0, HATCH_SIZE.y + FallingCrate.SIZE.y / 2.0)
		get_parent().add_child(crate)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-HATCH_SIZE.x / 2.0, 0, HATCH_SIZE.x, HATCH_SIZE.y), Color(0.16, 0.17, 0.21))
	draw_rect(Rect2(-HATCH_SIZE.x / 2.0, HATCH_SIZE.y - 5, HATCH_SIZE.x, 5), Conveyor.HAZARD_YELLOW.darkened(0.2))
	var warning := _timer < warning_time and int(Time.get_ticks_msec() / 100) % 2 == 0
	draw_circle(Vector2(HATCH_SIZE.x / 2.0 + 10.0, 8.0), 6.0, LAMP if warning else LAMP.darkened(0.7))
	if warning:
		draw_circle(Vector2(HATCH_SIZE.x / 2.0 + 10.0, 8.0), 14.0, Color(LAMP, 0.25))


class FallingCrate:
	extends CharacterBody2D

	const SIZE := Vector2(56, 56)
	const GRAVITY := 2200.0
	const LIFE := 6.0
	const DAMAGE := 2

	var _age := 0.0
	var _landed := false
	var _hit := {}

	func _ready() -> void:
		add_to_group("crates")
		collision_layer = Layers.WORLD
		collision_mask = Layers.GROUND
		var shape := RectangleShape2D.new()
		shape.size = SIZE
		var collision := CollisionShape2D.new()
		collision.shape = shape
		add_child(collision)
		var art := Harm.prop_sprite("crate_lumen", SIZE)
		if art == null:
			art = Harm.prop_sprite("crate", SIZE)
		if art != null:
			var factor := SIZE.x * 1.1 / art.texture.get_width()
			art.scale = Vector2(factor, factor)
			art.position = Vector2(0, SIZE.y / 2.0 - art.texture.get_height() * factor / 2.0)
			add_child(art)

	func _physics_process(delta: float) -> void:
		_age += delta if _landed else 0.0
		if _age > LIFE:
			queue_free()
			return
		# Blinks before it goes.
		visible = _age < LIFE - 1.0 or int(_age * 10.0) % 2 == 0
		velocity.y = minf(velocity.y + GRAVITY * delta, 1400.0)
		velocity.x = 0.0
		var falling_fast := velocity.y > 300.0
		move_and_slide()
		if falling_fast:
			var rect := Rect2(global_position - SIZE / 2.0, SIZE)
			for hurtbox in Harm.hurtboxes_in_rect(get_world_2d(), rect, Harm.HEROES):
				if _hit.has(hurtbox):
					continue
				_hit[hurtbox] = true
				var side := -1.0 if hurtbox.global_position.x < global_position.x else 1.0
				hurtbox.take_hit(Hit.make(DAMAGE, Vector2(side * 420.0, -260.0), global_position))
		if is_on_floor() and not _landed:
			_landed = true
			Sound.play("land", 0.1, -2.0, 0.6)
			Fx.burst(get_parent(), global_position + Vector2(0, SIZE.y / 2.0),
				[Color(0.5, 0.5, 0.52, 0.6), Color(0.4, 0.4, 0.42, 0.0)], 6, 160.0, 8.0, 0.4, -40.0, false,
				Vector2.UP, 80.0)
		if global_position.y > 5000.0:
			queue_free()

	func _draw() -> void:
		if get_child_count() > 1:
			return
		draw_rect(Rect2(-SIZE / 2.0, SIZE), Color(0.3, 0.33, 0.4))
		draw_rect(Rect2(-SIZE / 2.0 + Vector2(5, 5), SIZE - Vector2(10, 10)), Color(0.4, 0.44, 0.52))
		draw_line(-SIZE / 2.0 + Vector2(5, 5), SIZE / 2.0 - Vector2(5, 5), Color(0.3, 0.33, 0.4), 4.0)
		draw_arc(Vector2.ZERO, 9.0, 0.0, TAU, 20, Color(1.0, 0.18, 0.53), 3.0)
