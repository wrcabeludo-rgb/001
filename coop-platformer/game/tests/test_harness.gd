extends Node
## Shared helpers for headless tests: a quiet test room (no targets), heroes
## driven by scripted input devices, and pass/fail bookkeeping. A test scene
## extends this, overrides _run_all() and exits with code 1 if a check fails.

const ROOM := preload("res://scenes/test_room.tscn")
const ROOM_SCRIPT := preload("res://scripts/test_room.gd")
## Floor top is y = 1020 in the test room; a hero standing on it has this centre.
const FLOOR_Y := 1020.0 - Player.SIZE.y / 2
## Open space with no platforms above (columns 24..28 of the room).
const OPEN_X := 1560.0

## The level the test runs in; a test can pick another one in _init().
var room_scene: PackedScene = ROOM
var _room: Node
## The main hero under test and its input device.
var _input: PlayerInput
var _player: Player
var _extra_inputs: Array[PlayerInput] = []
var _failures := PackedStringArray()
var _checks := 0


func _ready() -> void:
	process_priority = -50
	# Tests never touch the real save: a fresh in-memory one, written elsewhere.
	SaveGame.path = "user://test_save.json"
	SaveGame.data = SaveGame.defaults()
	_room = room_scene.instantiate()
	_room.spawn_targets = false
	add_child(_room)
	await _run_all()
	print("Проверок: %d, провалено: %d" % [_checks, _failures.size()])
	for failure in _failures:
		printerr("FAIL: " + failure)
	get_tree().quit(1 if _failures.size() > 0 else 0)


func _run_all() -> void:
	pass


func _physics_process(_delta: float) -> void:
	# Runs before the heroes (lower priority value), like PlayerManager does.
	if _input != null:
		_input.poll()
	for input in _extra_inputs:
		input.poll()


## Replaces the main hero with a fresh one.
func _spawn(hero: Heroes.Id, at: Vector2) -> void:
	if _player != null:
		_player.free()
	_input = PlayerInput.scripted()
	_player = _make_hero(hero, at, _input, 0)
	await _frames(3)


## A second hero with its own scripted input (for co-op checks).
func _spawn_extra(hero: Heroes.Id, at: Vector2) -> Player:
	var input := PlayerInput.scripted()
	_extra_inputs.append(input)
	return _make_hero(hero, at, input, 1)


func _make_hero(hero: Heroes.Id, at: Vector2, input: PlayerInput, slot: int) -> Player:
	var player := Player.new()
	player.setup(slot, input, hero)
	player.position = at
	_room.add_child(player)
	return player


func _frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


## Holds a button on the main hero's device for `frames` physics frames.
func _press(action: String, frames := 1) -> void:
	_input.set_virtual(action, true)
	await _frames(frames)
	_input.set_virtual(action, false)


func _check(ok: bool, description: String) -> void:
	_checks += 1
	print(("ok   " if ok else "FAIL ") + description)
	if not ok:
		_failures.append(description)
