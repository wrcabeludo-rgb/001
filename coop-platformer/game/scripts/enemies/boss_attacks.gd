class_name BossAttacks
## Pieces of the Sludge Master's attacks: a shockwave running along the floor,
## a lobbed glob of sludge that leaves a puddle of acid, and geysers of sludge
## bursting out of the floor at marked spots.

const SLUDGE_COLOR := Color(0.45, 0.95, 0.25)


## A wave that runs along the floor from `start` (a point on the floor) in
## `direction` until it hits a wall or runs out of distance. Jump over it.
class Shockwave:
	extends Node2D

	const SIZE := Vector2(130, 60)

	var direction := 1
	var speed := 520.0
	var damage := 3
	var distance_left := 1600.0

	func setup(start: Vector2, p_direction: int, p_speed: float, p_damage: int) -> void:
		position = start
		direction = p_direction
		speed = p_speed
		damage = p_damage

	func _ready() -> void:
		var look := SlimeLook.Wave.new()
		look.size = SIZE
		look.scale.x = direction
		add_child(look)

	func area() -> Rect2:
		return Rect2(global_position + Vector2(-SIZE.x / 2.0, -SIZE.y), SIZE)

	func _physics_process(delta: float) -> void:
		var step := speed * delta
		var ahead := global_position + Vector2(direction * (SIZE.x / 2.0 + step), -SIZE.y / 2.0)
		var ray := PhysicsRayQueryParameters2D.create(global_position + Vector2(0, -SIZE.y / 2.0), ahead, Layers.WORLD)
		if not get_world_2d().direct_space_state.intersect_ray(ray).is_empty() or distance_left <= 0.0:
			queue_free()
			return
		position.x += direction * step
		distance_left -= step
		for hurtbox in Harm.hurtboxes_in_rect(get_world_2d(), area(), Harm.HEROES):
			hurtbox.take_hit(Hit.make(damage, Vector2(direction * 450.0, -650.0), global_position))


## A glob of sludge thrown in an arc. Where it lands, it leaves a puddle of
## acid for a few seconds.
class Glob:
	extends Projectile

	const GRAVITY := 1500.0
	const PUDDLE_TIME := 2.5
	const PUDDLE_WIDTH := 120.0

	func _physics_process(delta: float) -> void:
		velocity.y += GRAVITY * delta
		rotation = velocity.angle()
		super._physics_process(delta)

	func _on_body_entered(_body: Node2D) -> void:
		_leave_puddle()
		_burst()
		queue_free()

	func _leave_puddle() -> void:
		var parent := get_parent()
		if parent == null:
			return
		var from := global_position + Vector2(0, -30)
		var ray := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, 120), Layers.GROUND)
		var hit := get_world_2d().direct_space_state.intersect_ray(ray)
		if hit.is_empty():
			return
		var floor_y: float = hit["position"].y
		var puddle := Hazard.new()
		puddle.setup(Hazard.Kind.ACID, Rect2(global_position.x - PUDDLE_WIDTH / 2.0, floor_y - 60.0, PUDDLE_WIDTH, 60.0))
		puddle.damage = 1
		puddle.throw_up = 600.0
		parent.add_child.call_deferred(puddle)
		parent.get_tree().create_timer(PUDDLE_TIME).timeout.connect(puddle.queue_free)


## A geyser of sludge bursting out of the floor: first the floor tiles darken
## and bubble where it will come up, then a fountain shoots up, hangs a moment
## and sinks back. Jump away from the bubbling spot.
class Drop:
	extends Node2D

	const WIDTH := 90.0
	const HEIGHT := 520.0
	## How long the fountain takes to shoot up, stands, and sinks back.
	const RISE := 0.12
	const HOLD := 0.3
	const SINK := 0.25

	var delay := 0.9
	var damage := 3
	var _time := 0.0
	var _mark: SlimeLook.Mark
	var _geyser: SlimeLook.Geyser

	## `floor_point` is roughly where it comes up; it snaps to the floor surface.
	func setup(floor_point: Vector2, p_delay: float, p_damage: int) -> void:
		position = floor_point
		delay = p_delay
		damage = p_damage

	func _ready() -> void:
		var ray := PhysicsRayQueryParameters2D.create(global_position + Vector2(0, -80), global_position + Vector2(0, 200),
			Layers.GROUND)
		var hit := get_world_2d().direct_space_state.intersect_ray(ray)
		if not hit.is_empty():
			global_position.y = hit["position"].y
		_mark = SlimeLook.Mark.new()
		_mark.width = WIDTH
		_mark.delay = delay
		add_child(_mark)

	## How high the fountain stands now (0 before it comes up).
	func height() -> float:
		var t := _time - delay
		if t < 0.0:
			return 0.0
		if t < RISE:
			return HEIGHT * ease(t / RISE, 0.4)
		if t < RISE + HOLD:
			return HEIGHT * (1.0 - 0.04 * sin(t * 40.0))
		return HEIGHT * clampf(1.0 - (t - RISE - HOLD) / SINK, 0.0, 1.0)

	func _physics_process(delta: float) -> void:
		_time += delta
		if _time < delay:
			return
		if _geyser == null:
			_geyser = SlimeLook.Geyser.new()
			_geyser.width = WIDTH
			add_child(_geyser)
			get_tree().call_group("cameras", "shake", 3.0)
		_geyser.height = height()
		var area := Rect2(global_position + Vector2(-WIDTH / 2.0, -height()), Vector2(WIDTH, height()))
		if _time - delay < RISE + HOLD:
			for hurtbox in Harm.hurtboxes_in_rect(get_world_2d(), area, Harm.HEROES):
				var side := 1.0 if hurtbox.global_position.x >= global_position.x else -1.0
				hurtbox.take_hit(Hit.make(damage, Vector2(side * 400.0, -500.0), hurtbox.global_position))
		if _time > delay + RISE + HOLD + SINK + 0.3:
			queue_free()
