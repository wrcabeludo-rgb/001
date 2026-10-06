class_name Arena
extends Node
## A fight in the middle of a level: when a hero walks in, the gates on both
## sides close (a partner left outside is brought in), waves of enemies appear,
## and the gates open once the last wave is beaten. If the whole team falls,
## the arena opens and starts over the next time.

signal cleared

enum State { WAITING, FIGHT, CLEARED }

## Enemies appear blinking and frozen for this long, so the heroes can react.
const SPAWN_WARNING := 0.8
## How far past a gate a hero must walk to start the fight.
const TRIGGER_DEPTH := 90.0

var state := State.WAITING
var wave := 0

var _level: Level
var _gates: Array[Door] = []
var _left_x := 0.0
var _right_x := 0.0
## Each wave: Array of [enemy letter, floor point].
var _waves: Array = []
## Enemies of the current wave. Untyped on purpose: an enemy can be freed
## between two checks, and a freed object must not pass through a typed slot.
var _alive: Array = []
## Where each enemy of the wave appeared, by instance id.
var _spawn_points := {}


func setup(level: Level, left_gate: Door, right_gate: Door, waves: Array) -> void:
	_level = level
	_gates = [left_gate, right_gate]
	_left_x = left_gate.global_position.x
	_right_x = right_gate.global_position.x
	_waves = waves


func _ready() -> void:
	add_to_group("resettable")


func _physics_process(_delta: float) -> void:
	match state:
		State.WAITING:
			var hero := _hero_inside()
			if hero != null:
				_start(hero)
		State.FIGHT:
			_track_wave()
			if _alive.is_empty():
				_next_wave()


## Forgets beaten enemies (they may already be freed, so they are checked as
## plain objects) and brings back any that ended up outside the arena.
func _track_wave() -> void:
	var still: Array = []
	for item in _alive:
		if not is_instance_valid(item):
			continue
		var enemy := item as Enemy
		if enemy == null or enemy.is_queued_for_deletion() or not enemy.is_alive():
			continue
		still.append(enemy)
		var x := enemy.global_position.x
		if x < _left_x or x > _right_x or enemy.global_position.y > _level.level_rect().end.y:
			enemy.global_position = _spawn_points.get(enemy.get_instance_id(), enemy.global_position)
			enemy.velocity = Vector2.ZERO
	if still.size() != _alive.size():
		_alive = still
		if not _alive.is_empty():
			_level.show_toast("Осталось врагов: %d" % _alive.size())


func wave_count() -> int:
	return _waves.size()


## Opens up and waits again (the team restarted at a checkpoint).
func reset() -> void:
	if state != State.FIGHT:
		return
	state = State.WAITING
	_alive.clear()
	_spawn_points.clear()
	for gate in _gates:
		gate.open()


func _start(hero: Player) -> void:
	state = State.FIGHT
	wave = -1
	Sound.play("arena", 0.0)
	for gate in _gates:
		gate.close()
	for other in _heroes():
		if other != hero and not _is_inside(other):
			other.global_position = hero.last_safe_position
			other.velocity = Vector2.ZERO
	_level.snap_camera()
	_next_wave()


func _next_wave() -> void:
	wave += 1
	if wave >= _waves.size():
		state = State.CLEARED
		for gate in _gates:
			gate.open()
		_level.show_toast("Арена пройдена!")
		cleared.emit()
		return
	_level.show_toast("Арена! Волна %d из %d" % [wave + 1, _waves.size()])
	for spot in _waves[wave]:
		var enemy := _level.spawn_enemy(spot[0], spot[1])
		if enemy == null:
			continue
		enemy.stun_timer = SPAWN_WARNING
		enemy.telegraph(SPAWN_WARNING)
		_alive.append(enemy)
		_spawn_points[enemy.get_instance_id()] = enemy.global_position


func _hero_inside() -> Player:
	for hero in _heroes():
		var x := hero.global_position.x
		if x > _left_x + TRIGGER_DEPTH and x < _right_x - TRIGGER_DEPTH:
			return hero
	return null


func _heroes() -> Array[Player]:
	var result: Array[Player] = []
	for node in get_tree().get_nodes_in_group("players"):
		var hero := node as Player
		if hero != null and hero.is_alive():
			result.append(hero)
	return result


func _is_inside(hero: Player) -> bool:
	return hero.global_position.x > _left_x and hero.global_position.x < _right_x
