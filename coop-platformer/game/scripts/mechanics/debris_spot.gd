class_name DebrisSpot
extends Node2D
## A cracked piece of ceiling. When a hero walks below it, it shakes and dusts
## (warning), then a chunk falls. The chunk hurts anyone it lands on, heroes and
## enemies alike, and breaks on the floor. A new chunk forms after a while.

enum State { READY, WARNING, FALLING, REFORMING }

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
var _dust: CPUParticles2D


## `ceiling` is the point under the ceiling the chunk hangs from.
func setup(ceiling: Vector2) -> void:
	position = ceiling


func _ready() -> void:
	var cracks := Rubble.Cracks.new()
	cracks.width = 70.0
	cracks.count = 4
	cracks.seed_value = int(position.x)
	cracks.position = Vector2(0, -2)
	cracks.rotation = PI  # spreading up into the ceiling
	add_child(cracks)
	_rock = Rubble.Rock.new()
	_rock.size = ROCK_SIZE
	_rock.seed_value = int(position.x) + 7
	_rock.position = Vector2(-ROCK_SIZE.x / 2.0, 0)
	add_child(_rock)
	# Dust trickling down while it is about to fall.
	_dust = CPUParticles2D.new()
	_dust.emitting = false
	_dust.amount = 14
	_dust.lifetime = 0.8
	_dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_dust.emission_rect_extents = Vector2(ROCK_SIZE.x / 2.0, 2)
	_dust.direction = Vector2.DOWN
	_dust.spread = 15.0
	_dust.initial_velocity_min = 20.0
	_dust.initial_velocity_max = 60.0
	_dust.gravity = Vector2(0, 300)
	_dust.scale_amount_min = 1.5
	_dust.scale_amount_max = 3.0
	_dust.color_ramp = Fx.ramp([Color(0.65, 0.6, 0.55, 0.8), Color(0.6, 0.55, 0.5, 0.0)])
	add_child(Fx.soften(_dust))


## The falling chunk's area in world coordinates.
func rock_rect() -> Rect2:
	return Rect2(global_position + _rock.position, ROCK_SIZE)


func _physics_process(delta: float) -> void:
	match state:
		State.READY:
			if _hero_below():
				state = State.WARNING
				_timer = warning_time
		State.WARNING:
			_timer -= delta
			_rock.position.x = -ROCK_SIZE.x / 2.0 + randf_range(-3, 3)
			_rock.flash = int(_timer * 12.0) % 2 == 0
			_dust.emitting = true
			if _timer <= 0.0:
				state = State.FALLING
				_rock.position.x = -ROCK_SIZE.x / 2.0
				_rock.flash = false
				_dust.emitting = false
				_rock_velocity = 0.0
		State.FALLING:
			_fall(delta)
		State.REFORMING:
			_timer -= delta
			if _timer <= 0.0:
				state = State.READY
				_rock.position = Vector2(-ROCK_SIZE.x / 2.0, 0)
				_rock.visible = true


func _fall(delta: float) -> void:
	_rock_velocity = minf(_rock_velocity + GRAVITY * delta, 1400.0)
	var step := _rock_velocity * delta
	var bottom := rock_rect().end.y
	var ray := PhysicsRayQueryParameters2D.create(Vector2(global_position.x, bottom - 2.0),
		Vector2(global_position.x, bottom + step), Layers.GROUND)
	var landed := not get_world_2d().direct_space_state.intersect_ray(ray).is_empty()
	_rock.position.y += step
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
	# Stone bits bouncing off and a puff of dust.
	var at := rock_rect().get_center() + Vector2(0, ROCK_SIZE.y * 0.3)
	Fx.burst(get_parent(), at, [Color(0.5, 0.46, 0.42), Color(0.35, 0.32, 0.3, 0.0)], 12, 360.0, 5.0, 0.7, 1400.0, false,
		Vector2.UP, 70.0)
	Fx.burst(get_parent(), at, [Color(0.6, 0.55, 0.5, 0.7), Color(0.55, 0.5, 0.45, 0.0)], 14, 160.0, 10.0, 0.6, -40.0,
		false, Vector2.UP, 80.0)


func _hero_below() -> bool:
	for node in get_tree().get_nodes_in_group("players"):
		var hero := node as Player
		if hero != null and hero.is_alive() and hero.global_position.y > global_position.y \
				and absf(hero.global_position.x - global_position.x) < trigger_width:
			return true
	return false
