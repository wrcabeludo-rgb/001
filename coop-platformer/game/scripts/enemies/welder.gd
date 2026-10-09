class_name Welder
extends Walker
## Welding robot, the factory's foot soldier: weak, but there are many. Walks
## and chases like a walker; when a hero is right in front of it, it raises the
## torch (warning) and sprays a short burst of fire.

enum State { WALK, WINDUP, BURN, RECOVER }

const FLAME_COLOR := Color(1.0, 0.6, 0.2)

@export var torch_reach := 110.0
@export var windup_time := 0.45
@export var burn_time := 0.35
@export var recover_time := 0.5
@export var torch_damage := 2

var state := State.WALK

var _timer := 0.0
var _torch: Hitbox


func _init() -> void:
	max_health = 5
	body_size = Vector2(56, 84)
	color = ROBOT_COLOR
	contact_damage = 1
	art = "welder"
	art_height = 120.0
	walk_speed = 90.0
	chase_speed = 180.0


func _ready() -> void:
	super._ready()
	_torch = Hitbox.new()
	add_child(_torch)
	_torch.setup(Layers.Team.ENEMIES, Vector2(96, 44), Vector2(70, -6), FLAME_COLOR)
	_torch.show_flash = false


func _think(delta: float) -> void:
	_timer -= delta
	match state:
		State.WALK:
			var hero := hero_in_line(torch_reach, 70.0)
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
				state = State.BURN
				_timer = burn_time
				_torch.activate(burn_time, torch_damage, Vector2(380, -220), facing)
				var nozzle := global_position + Vector2(facing * 34.0, -6.0)
				Fx.burst(get_parent(), nozzle, [Color(1, 1, 0.85), FLAME_COLOR, Color(0.8, 0.15, 0.05, 0.0)], 22,
					420.0, 9.0, 0.3, -120.0, true, Vector2(facing, 0), 18.0)
				Sound.play("flame", 0.1, -6.0, 1.3)
				punch(Vector2(0.1, -0.06))
		State.BURN:
			velocity.x = 0.0
			if _timer <= 0.0:
				state = State.RECOVER
				_timer = recover_time
		State.RECOVER:
			velocity.x = 0.0
			if _timer <= 0.0:
				state = State.WALK


func _on_interrupted() -> void:
	state = State.WALK
