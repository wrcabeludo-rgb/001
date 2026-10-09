class_name RepairDrone
extends Enemy
## Maintenance drone: flies after the other robots and repairs the damaged ones
## with a green beam. It has no attack — destroy it first. A shock (or any
## stun) stops the repairs.

const BEAM_COLOR := Color(0.4, 1.0, 0.55)

@export var speed := 170.0
@export var beam_range := 230.0
@export var heal_interval := 0.6

var _target: Enemy
var _heal_timer := 0.0
var _time := 0.0
var _beam: Line2D


func _init() -> void:
	max_health = 4
	body_size = Vector2(46, 34)
	color = Color(0.7, 0.75, 0.8)
	contact_damage = 1
	uses_gravity = false
	art = "repair_drone"
	art_height = 76.0
	art_centered = true
	scrap_min = 2
	scrap_max = 3


func _ready() -> void:
	super._ready()
	_beam = Line2D.new()
	_beam.width = 5.0
	_beam.default_color = Color(BEAM_COLOR, 0.7)
	_beam.material = Fx.additive()
	_beam.visible = false
	add_child(_beam)


func is_repairing() -> bool:
	return _beam.visible


func _think(delta: float) -> void:
	_time += delta
	_heal_timer -= delta
	_target = _pick_target()
	_beam.visible = false
	if _target == null:
		velocity = velocity.move_toward(Vector2(0, sin(_time * 2.0) * 20.0), 400.0 * delta)
		return
	var hover := _target.global_position + Vector2(sin(_time * 1.3) * 50.0, -_target.body_size.y / 2.0 - 110.0)
	var to_hover := hover - global_position
	velocity = to_hover.limit_length(speed) if to_hover.length() > 10.0 else Vector2.ZERO
	facing = 1 if _target.global_position.x >= global_position.x else -1
	var damaged := _target.health.current < _target.health.maximum
	if damaged and global_position.distance_to(_target.global_position) < beam_range:
		_beam.visible = true
		_beam.points = PackedVector2Array([Vector2(0, 12), _target.global_position - global_position])
		_beam.default_color = Color(BEAM_COLOR, 0.45 + 0.35 * absf(sin(_time * 12.0)))
		if _heal_timer <= 0.0:
			_heal_timer = heal_interval
			_target.health.heal(1)


## The most damaged robot nearby, or else the closest one to follow.
func _pick_target() -> Enemy:
	var best: Enemy = null
	var best_score := INF
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy == null or enemy == self or not enemy.is_alive() or enemy is RepairDrone or enemy is SludgeBoss:
			continue
		var distance := enemy.global_position.distance_to(global_position)
		if distance > 900.0:
			continue
		var missing := enemy.health.maximum - enemy.health.current
		var score := distance - missing * 120.0
		if score < best_score:
			best_score = score
			best = enemy
	return best
