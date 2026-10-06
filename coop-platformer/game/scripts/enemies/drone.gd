class_name Drone
extends Enemy
## Robot drone: hovers around its post; when a hero comes close it blinks
## (warning), then dives at where the hero was and flies back up.

enum State { HOVER, WINDUP, DIVE, RETURN }

@export var sight := 520.0
@export var windup_time := 0.55
@export var dive_speed := 720.0
@export var dive_time := 0.75
@export var return_speed := 320.0
@export var cooldown := 1.4

var state := State.HOVER

var _home := Vector2.ZERO
var _time := 0.0
var _timer := 0.0
var _cooldown := 0.0
var _dive_direction := Vector2.ZERO
var _dive_target := Vector2.ZERO


func _init() -> void:
	max_health = 4
	body_size = Vector2(52, 36)
	color = ROBOT_COLOR
	contact_damage = 2
	uses_gravity = false
	art = "flyer"
	art_height = 95.0
	art_centered = true


func _ready() -> void:
	super._ready()
	_home = global_position


func _think(delta: float) -> void:
	_time += delta
	_timer -= delta
	_cooldown -= delta
	match state:
		State.HOVER:
			var bob := _home + Vector2(sin(_time * 1.5) * 60.0, sin(_time * 3.0) * 12.0)
			velocity = (bob - global_position) * 3.0
			var hero := nearest_hero(sight)
			if hero != null and _cooldown <= 0.0:
				state = State.WINDUP
				_timer = windup_time
				_dive_target = hero.global_position
				telegraph(windup_time)
		State.WINDUP:
			velocity = velocity.move_toward(Vector2.ZERO, 1200.0 * delta)
			if _timer <= 0.0:
				state = State.DIVE
				_timer = dive_time
				_dive_direction = (_dive_target - global_position).normalized()
		State.DIVE:
			velocity = _dive_direction * dive_speed
			facing = 1 if _dive_direction.x >= 0.0 else -1
			if _timer <= 0.0 or get_slide_collision_count() > 0:
				state = State.RETURN
		State.RETURN:
			var to_home := _home - global_position
			if to_home.length() < 20.0:
				state = State.HOVER
				_cooldown = cooldown
			velocity = to_home.normalized() * return_speed


func _on_interrupted() -> void:
	if state == State.DIVE or state == State.WINDUP:
		state = State.RETURN
