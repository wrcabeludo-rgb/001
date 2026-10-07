class_name DebrisSpot
extends Node2D
## A cracked piece of ceiling. When a hero walks below it, it shakes and dusts
## and a shadow grows on the floor (warning), then a chunk breaks off, tumbles
## down and shatters into bouncing shards and dust. The chunk hurts anyone it
## lands on, heroes and enemies alike. A dark hole stays in the ceiling until a
## new chunk forms. The chunk is made of the zone's own wall texture.

enum State { READY, WARNING, FALLING, REFORMING }

## The chunk's hit area (the drawing is a little bigger and jagged).
const ROCK_SIZE := Vector2(48, 40)
const GRAVITY := 2200.0

@export var trigger_width := 80.0
@export var warning_time := 0.6
@export var reform_time := 2.5
@export var damage := 2
@export var knockback := Vector2(320, -380)

var state := State.READY

var _timer := 0.0
var _rock: Rubble.Rock
var _rock_velocity := 0.0
var _spin := 0.0
var _dust: CPUParticles2D
var _trail: CPUParticles2D
var _floor_y := 0.0
var _texture: Texture2D
var _hole := PackedVector2Array()


## `ceiling` is the point under the ceiling the chunk hangs from.
func setup(ceiling: Vector2) -> void:
	position = ceiling


func _ready() -> void:
	var level := get_parent() as Level
	if level != null:
		_texture = level.wall_texture
	var cracks := Rubble.Cracks.new()
	cracks.width = 80.0
	cracks.count = 5
	cracks.seed_value = int(position.x)
	cracks.position = Vector2(0, -2)
	cracks.rotation = PI  # spreading up into the ceiling
	add_child(cracks)
	_rock = Rubble.Rock.new()
	_rock.seed_value = int(position.x) + 7
	_rock.texture = _texture
	add_child(_rock)
	_hole = Rubble.jagged(Vector2(26, 12), 9, int(position.x) + 3, 0.6)
	_dust = _particles(14, 0.8, Vector2(ROCK_SIZE.x / 2.0, 2), Vector2.DOWN, 20.0, 60.0, 300.0)
	_dust.color_ramp = Fx.ramp([Color(0.65, 0.6, 0.55, 0.8), Color(0.6, 0.55, 0.5, 0.0)])
	_trail = _particles(16, 0.5, Vector2(ROCK_SIZE.x / 3.0, 6), Vector2.UP, 0.0, 30.0, -40.0)
	_trail.local_coords = false
	_trail.color_ramp = Fx.ramp([Color(0.6, 0.55, 0.5, 0.5), Color(0.55, 0.5, 0.45, 0.0)])
	_reset_rock()
	# Where the chunk will land, for its shadow.
	var ray := PhysicsRayQueryParameters2D.create(global_position + Vector2(0, 10), global_position + Vector2(0, 3000),
		Layers.GROUND)
	var hit := get_world_2d().direct_space_state.intersect_ray(ray)
	_floor_y = (hit["position"].y if not hit.is_empty() else global_position.y + 600.0) - global_position.y


func _particles(amount: int, lifetime: float, extents: Vector2, direction: Vector2, low: float, high: float,
		gravity: float) -> CPUParticles2D:
	var particles := CPUParticles2D.new()
	particles.emitting = false
	particles.amount = amount
	particles.lifetime = lifetime
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = extents
	particles.direction = direction
	particles.spread = 20.0
	particles.initial_velocity_min = low
	particles.initial_velocity_max = high
	particles.gravity = Vector2(0, gravity)
	particles.scale_amount_min = 3.0
	particles.scale_amount_max = 7.0
	add_child(Fx.soften(particles))
	return particles


## The falling chunk's area in world coordinates.
func rock_rect() -> Rect2:
	return Rect2(global_position + _rock.position - ROCK_SIZE / 2.0, ROCK_SIZE)


func _reset_rock() -> void:
	_rock.position = Vector2(0, ROCK_SIZE.y / 2.0)
	_rock.rotation = 0.0
	_rock.visible = true


func _physics_process(delta: float) -> void:
	match state:
		State.READY:
			if _hero_below():
				state = State.WARNING
				_timer = warning_time
		State.WARNING:
			_timer -= delta
			_rock.position.x = randf_range(-3, 3)
			_rock.flash = int(_timer * 12.0) % 2 == 0
			_dust.emitting = true
			if _timer <= 0.0:
				state = State.FALLING
				_rock.position.x = 0.0
				_rock.flash = false
				_dust.emitting = false
				_trail.emitting = true
				_rock_velocity = 0.0
				_spin = randf_range(-5.0, 5.0)
		State.FALLING:
			_fall(delta)
		State.REFORMING:
			_timer -= delta
			if _timer <= 0.0:
				state = State.READY
				_reset_rock()
	_trail.position = _rock.position
	queue_redraw()


func _fall(delta: float) -> void:
	_rock_velocity = minf(_rock_velocity + GRAVITY * delta, 1400.0)
	var step := _rock_velocity * delta
	var bottom := rock_rect().end.y
	var ray := PhysicsRayQueryParameters2D.create(Vector2(global_position.x, bottom - 2.0),
		Vector2(global_position.x, bottom + step), Layers.GROUND)
	var landed := not get_world_2d().direct_space_state.intersect_ray(ray).is_empty()
	_rock.position.y += step
	_rock.rotation += _spin * delta
	for hurtbox in Harm.hurtboxes_in_rect(get_world_2d(), rock_rect(), Harm.EVERYONE):
		var side := 1.0 if hurtbox.global_position.x >= global_position.x else -1.0
		hurtbox.take_hit(Hit.make(damage, Vector2(side * knockback.x, knockback.y), global_position))
		landed = true
	if landed:
		_break()


func _break() -> void:
	state = State.REFORMING
	Sound.play("crumble")
	_timer = reform_time
	_rock.visible = false
	_trail.emitting = false
	var at := rock_rect().get_center()
	var floor_world := global_position.y + _floor_y - 4.0
	# Shards of the same stone tumbling away and bouncing.
	for i in 7:
		var shard := Rubble.Shard.new()
		shard.setup(randf_range(6.0, 13.0), int(at.x) + i * 13)
		shard.texture = _texture
		shard.position = at + Vector2(randf_range(-14, 14), randf_range(-10, 6))
		shard.velocity = Vector2(randf_range(-320, 320), randf_range(-620, -260))
		shard.spin = randf_range(-12.0, 12.0)
		shard.floor_y = floor_world
		get_parent().add_child(shard)
	Fx.burst(get_parent(), at + Vector2(0, ROCK_SIZE.y * 0.3), [Color(0.62, 0.57, 0.52, 0.75), Color(0.55, 0.5, 0.45, 0.0)],
		16, 200.0, 16.0, 0.8, -40.0, false, Vector2.UP, 85.0)
	get_tree().call_group("cameras", "shake", 4.0)


func _draw() -> void:
	# The hole left in the ceiling.
	if state == State.FALLING or state == State.REFORMING:
		draw_colored_polygon(_hole, Color(0.03, 0.03, 0.04, 0.95))
	# The shadow on the floor: grows while the chunk shakes, darkens as it falls.
	var strength := 0.0
	if state == State.WARNING:
		strength = 0.35 * (1.0 - _timer / warning_time)
	elif state == State.FALLING:
		strength = 0.35 + 0.4 * clampf(_rock.position.y / maxf(_floor_y, 1.0), 0.0, 1.0)
	if strength > 0.0:
		draw_set_transform(Vector2(0, _floor_y - 2.0), 0.0, Vector2(1.0, 0.22))
		draw_circle(Vector2.ZERO, 34.0, Color(0, 0, 0, strength))
		draw_circle(Vector2.ZERO, 22.0, Color(0, 0, 0, strength * 0.8))
		draw_set_transform(Vector2.ZERO)


func _hero_below() -> bool:
	for node in get_tree().get_nodes_in_group("players"):
		var hero := node as Player
		if hero != null and hero.is_alive() and hero.global_position.y > global_position.y \
				and absf(hero.global_position.x - global_position.x) < trigger_width:
			return true
	return false
