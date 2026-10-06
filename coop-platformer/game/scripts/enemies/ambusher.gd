class_name Ambusher
extends Walker
## Mutant ambusher: hangs under a ceiling, dark and hard to spot. When a hero
## passes below, it shakes for a moment (warning) and drops; after landing it
## behaves like a walker.

enum State { HANGING, WINDUP, DROPPED }

@export var trigger_width := 90.0
@export var windup_time := 0.35

var state := State.HANGING

var _timer := 0.0
var _hang_position := Vector2.ZERO


func _init() -> void:
	super._init()
	max_health = 5
	body_size = Vector2(50, 50)
	color = MUTANT_COLOR.darkened(0.45)
	uses_gravity = false
	art = "ambusher"
	art_height = 90.0


func _ready() -> void:
	super._ready()
	_hang_position = global_position


func _think(delta: float) -> void:
	match state:
		State.HANGING:
			velocity = Vector2.ZERO
			global_position = _hang_position
			var hero := nearest_hero(900.0)
			if hero != null and absf(hero.global_position.x - global_position.x) < trigger_width \
					and hero.global_position.y > global_position.y:
				state = State.WINDUP
				_timer = windup_time
				telegraph(windup_time)
		State.WINDUP:
			_timer -= delta
			global_position = _hang_position + Vector2(randf_range(-3, 3), 0)
			if _timer <= 0.0:
				state = State.DROPPED
				uses_gravity = true
				global_position = _hang_position
		State.DROPPED:
			super._think(delta)


## A hit knocks a hanging ambusher down at once.
func _on_interrupted() -> void:
	if state != State.DROPPED:
		state = State.DROPPED
		uses_gravity = true


## Hanging, it is drawn upside down against the ceiling.
func _animate_sprite() -> void:
	super._animate_sprite()
	var hanging := state != State.DROPPED
	_sprite.flip_v = hanging
	if hanging:
		var drawn := _sprite.texture.get_height() * _sprite.scale.y
		_sprite.position = Vector2(0, -body_size.y / 2.0 + drawn / 2.0)
		_sprite.rotation = 0.0
