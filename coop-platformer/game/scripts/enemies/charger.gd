class_name Charger
extends Enemy
## Mutant charger: patrols; when it sees a hero ahead at the same height it
## blinks and steps back (warning), then rushes forward. Hitting a wall or
## reaching a ledge leaves it dazed — the moment to strike back.

enum State { PATROL, WINDUP, CHARGE, DAZED }

@export var walk_speed := 90.0
@export var sight := 650.0
@export var windup_time := 0.6
@export var charge_speed := 950.0
@export var charge_time := 1.4
@export var daze_time := 1.0
@export var charge_damage := 4

var state := State.PATROL
var _dust: CPUParticles2D

var _timer := 0.0
var _normal_damage := 0


func _init() -> void:
	max_health = 8
	body_size = Vector2(66, 62)
	color = MUTANT_COLOR.lightened(0.15)
	contact_damage = 2
	art = "charger"
	art_height = 100.0


func _ready() -> void:
	super._ready()
	_normal_damage = contact_damage


## Dust kicked up from the feet while charging.
func _kick_dust(on: bool) -> void:
	if _dust == null:
		_dust = CPUParticles2D.new()
		_dust.amount = 18
		_dust.lifetime = 0.5
		_dust.local_coords = false
		_dust.position = Vector2(0, body_size.y / 2.0 - 4.0)
		_dust.direction = Vector2.UP
		_dust.spread = 50.0
		_dust.initial_velocity_min = 40.0
		_dust.initial_velocity_max = 120.0
		_dust.gravity = Vector2(0, 200)
		_dust.scale_amount_min = 6.0
		_dust.scale_amount_max = 12.0
		_dust.color_ramp = Fx.ramp([Color(0.6, 0.55, 0.5, 0.6), Color(0.5, 0.45, 0.4, 0.0)])
		add_child(Fx.soften(_dust))
	_dust.emitting = on


func _think(delta: float) -> void:
	_timer -= delta
	match state:
		State.PATROL:
			patrol(walk_speed)
			var hero := hero_in_line(sight, 90.0)
			if hero != null and signf(hero.global_position.x - global_position.x) == float(facing):
				state = State.WINDUP
				_timer = windup_time
				velocity.x = -facing * 120.0
				telegraph(windup_time)
		State.WINDUP:
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			if _timer <= 0.0:
				state = State.CHARGE
				_timer = charge_time
				contact_damage = charge_damage
		State.CHARGE:
			velocity.x = facing * charge_speed
			_kick_dust(is_on_floor())
			var stop := wall_ahead(facing) or (is_on_floor() and not ground_ahead(facing))
			if stop or _timer <= 0.0:
				_daze()
		State.DAZED:
			velocity.x = 0.0
			if _timer <= 0.0:
				state = State.PATROL


func _daze() -> void:
	_kick_dust(false)
	state = State.DAZED
	_timer = daze_time
	velocity.x = 0.0
	contact_damage = _normal_damage
