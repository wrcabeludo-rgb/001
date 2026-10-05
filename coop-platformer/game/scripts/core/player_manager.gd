extends Node
## Knows which input device and which hero belong to which player.
##
## Drop-in / drop-out: an unused device joins by pressing jump or Start,
## a player leaves by holding Start. Registered as the PlayerManager autoload.

signal player_joined(slot: int)
signal player_left(slot: int)
signal hero_changed(slot: int)

const MAX_PLAYERS := 2
const LEAVE_HOLD_TIME := 1.5

## PlayerInput for each slot, or null when the slot is free.
var players: Array = []
## Heroes.Id for each joined slot. Two players never share a hero.
var heroes: Array = []

var _keyboards: Array[PlayerInput] = []
var _gamepads := {}
var _leave_timers: Array[float] = []


func _ready() -> void:
	# Poll devices before any player reads them in the same physics frame.
	process_priority = -100
	players.resize(MAX_PLAYERS)
	heroes.resize(MAX_PLAYERS)
	_leave_timers.resize(MAX_PLAYERS)
	_leave_timers.fill(0.0)
	_keyboards = [
		PlayerInput.keyboard("Клавиатура (левая)", PlayerInput.KEYBOARD_LEFT),
		PlayerInput.keyboard("Клавиатура (правая)", PlayerInput.KEYBOARD_RIGHT),
	]
	for device_id in Input.get_connected_joypads():
		_gamepads[device_id] = PlayerInput.gamepad(device_id)
	Input.joy_connection_changed.connect(_on_joy_connection_changed)


func _physics_process(delta: float) -> void:
	for device in all_devices():
		device.poll()
	_handle_joining()
	_handle_leaving(delta)


func all_devices() -> Array[PlayerInput]:
	var devices: Array[PlayerInput] = []
	devices.append_array(_keyboards)
	for device in _gamepads.values():
		devices.append(device)
	return devices


func gamepad_count() -> int:
	return _gamepads.size()


## Switches the slot to the other hero if nobody else plays it.
func swap_hero(slot: int) -> void:
	var wanted := Heroes.other(heroes[slot])
	if _hero_taken(wanted, slot):
		return
	heroes[slot] = wanted
	hero_changed.emit(slot)


## Slows the whole game for a moment (hit feedback). Lives here because the
## autoload is never freed, so time always returns to normal.
func hitstop(duration: float, time_scale: float) -> void:
	Engine.time_scale = time_scale
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0


func remove_player(slot: int) -> void:
	if players[slot] == null:
		return
	players[slot] = null
	_leave_timers[slot] = 0.0
	player_left.emit(slot)


func _handle_joining() -> void:
	for device in all_devices():
		if players.has(device):
			continue
		if not (device.just_pressed("jump") or device.just_pressed("start")):
			continue
		var slot := players.find(null)
		if slot == -1:
			return
		device.consume()
		players[slot] = device
		heroes[slot] = Heroes.Id.SWORDSMAN if _hero_taken(Heroes.Id.SHOOTER, slot) else Heroes.Id.SHOOTER
		player_joined.emit(slot)


func _hero_taken(hero: Heroes.Id, except_slot: int) -> bool:
	for slot in MAX_PLAYERS:
		if slot != except_slot and players[slot] != null and heroes[slot] == hero:
			return true
	return false


func _handle_leaving(delta: float) -> void:
	for slot in MAX_PLAYERS:
		var device: PlayerInput = players[slot]
		if device == null:
			continue
		if not device.is_held("start"):
			_leave_timers[slot] = 0.0
			continue
		_leave_timers[slot] += delta
		if _leave_timers[slot] >= LEAVE_HOLD_TIME:
			remove_player(slot)


func _on_joy_connection_changed(device_id: int, connected: bool) -> void:
	if connected:
		_gamepads[device_id] = PlayerInput.gamepad(device_id)
		return
	var device: PlayerInput = _gamepads.get(device_id)
	_gamepads.erase(device_id)
	var slot := players.find(device)
	if device != null and slot != -1:
		remove_player(slot)
