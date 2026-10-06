class_name DebrisSpot
extends Node2D
## A cracked piece of ceiling. When a hero walks below it, it shakes and dusts
## (warning), then a chunk falls. The chunk hurts anyone it lands on, heroes and
## enemies alike, and breaks on the floor. A new chunk forms after a while.

enum State { READY, WARNING, FALLING, REFORMING }

const ROCK_SIZE := Vector2(48, 40)
const ROCK_COLOR := Color(0.5, 0.46, 0.42)
const GRAVITY := 2200.0

@export var trigger_width := 80.0
@export var warning_time := 0.6
@export var reform_time := 2.5
@export var damage := 2
@export var knockback := Vector2(320, -380)

var state := State.READY

var _timer := 0.0
var _rock: ColorRect
var _rock_velocity := 0.0
var _crack: ColorRect


## `ceiling` is the point under the ceiling the chunk hangs from.
func setup(ceiling: Vector2) -> void:
	position = ceiling


func _ready() -> void:
	_crack = Harm.box(Vector2(-30, -4), Vector2(60, 8), Color(0.2, 0.18, 0.18))
	add_child(_crack)
	_rock = Harm.box(Vector2(-ROCK_SIZE.x / 2.0, 0), ROCK_SIZE, ROCK_COLOR)
	add_child(_rock)


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
			_rock.color = Color.WHITE if int(_timer * 12.0) % 2 == 0 else ROCK_COLOR
			if _timer <= 0.0:
				state = State.FALLING
				_rock.position.x = -ROCK_SIZE.x / 2.0
				_rock.color = ROCK_COLOR
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
	var dust := Harm.box(rock_rect().position - global_position - Vector2(10, 0), ROCK_SIZE + Vector2(20, 0), Color(0.6, 0.55, 0.5, 0.7))
	add_child(dust)
	var tween := dust.create_tween()
	tween.tween_property(dust, "modulate:a", 0.0, 0.4)
	tween.tween_callback(dust.queue_free)


func _hero_below() -> bool:
	for node in get_tree().get_nodes_in_group("players"):
		var hero := node as Player
		if hero != null and hero.is_alive() and hero.global_position.y > global_position.y \
				and absf(hero.global_position.x - global_position.x) < trigger_width:
			return true
	return false
