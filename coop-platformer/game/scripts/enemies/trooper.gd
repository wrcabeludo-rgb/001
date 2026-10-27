class_name Trooper
extends Walker
## Lumen security trooper: light and fast. It runs at the heroes and, close
## up, crouches (warning) and lunges with its electric baton.

@export var lunge_reach := 260.0
@export var windup_time := 0.35
@export var lunge_speed := 780.0
@export var lunge_time := 0.28
@export var recover_time := 0.6

enum State { RUN, WINDUP, LUNGE, RECOVER }

var state := State.RUN

var _timer := 0.0
var _baton: Hitbox


func _init() -> void:
	max_health = 5
	body_size = Vector2(48, 88)
	color = Color(0.3, 0.26, 0.36)
	contact_damage = 1
	art = "trooper"
	art_height = 124.0
	walk_speed = 120.0
	chase_speed = 280.0
	sight = 600.0


func _ready() -> void:
	super._ready()
	_baton = Hitbox.new()
	add_child(_baton)
	_baton.setup(Layers.Team.ENEMIES, Vector2(70, 50), Vector2(44, -6), Color(1.0, 0.3, 0.6))
	_baton.show_flash = false


func _think(delta: float) -> void:
	_timer -= delta
	match state:
		State.RUN:
			var hero := hero_in_line(lunge_reach, 80.0)
			if hero == null:
				super._think(delta)
				return
			facing = 1 if hero.global_position.x >= global_position.x else -1
			velocity.x = 0.0
			state = State.WINDUP
			_timer = windup_time
			telegraph(windup_time)
		State.WINDUP:
			velocity.x = 0.0
			if _timer <= 0.0:
				state = State.LUNGE
				_timer = lunge_time
				_baton.activate(lunge_time, 2, Vector2(520, -280), facing)
				Sound.play("shock", 0.1, -6.0, 1.3)
		State.LUNGE:
			velocity.x = facing * lunge_speed if ground_ahead(facing) else 0.0
			if _timer <= 0.0:
				state = State.RECOVER
				_timer = recover_time
		State.RECOVER:
			velocity.x = move_toward(velocity.x, 0.0, 2400.0 * delta)
			if _timer <= 0.0:
				state = State.RUN


func _on_interrupted() -> void:
	state = State.RECOVER
	_timer = recover_time
