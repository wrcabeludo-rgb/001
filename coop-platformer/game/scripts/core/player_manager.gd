extends Node
## Knows which input device and which hero belong to which player.
##
## Drop-in / drop-out: an unused device joins by pressing jump or Start,
## a player leaves through the pause menu (Start). Registered as the PlayerManager autoload.

signal player_joined(slot: int)
signal player_left(slot: int)
signal hero_changed(slot: int)

const MAX_PLAYERS := 2

## PlayerInput for each slot, or null when the slot is free.
var players: Array = []
## Heroes.Id for each joined slot. Two players never share a hero.
var heroes: Array = []

var _keyboards: Array[PlayerInput] = []
var _gamepads := {}


func _ready() -> void:
	# Poll devices before any player reads them in the same physics frame.
	process_priority = -100
	process_mode = Node.PROCESS_MODE_ALWAYS
	players.resize(MAX_PLAYERS)
	heroes.resize(MAX_PLAYERS)
	_keyboards = [
		PlayerInput.keyboard("Клавиатура (левая)", PlayerInput.KEYBOARD_LEFT),
		PlayerInput.keyboard("Клавиатура (правая)", PlayerInput.KEYBOARD_RIGHT),
	]
	for device_id in Input.get_connected_joypads():
		_gamepads[device_id] = PlayerInput.gamepad(device_id)
	Input.joy_connection_changed.connect(_on_joy_connection_changed)


func _physics_process(_delta: float) -> void:
	_sync_gamepads()
	for device in all_devices():
		device.poll()
	# Menus keep working while the game is paused, but nobody joins then.
	if not get_tree().paused:
		_handle_joining()


func all_devices() -> Array[PlayerInput]:
	var devices: Array[PlayerInput] = []
	devices.append_array(_keyboards)
	for device in _gamepads.values():
		devices.append(device)
	return devices


func gamepad_count() -> int:
	return _gamepads.size()


## Switches the slot to the other hero. If the partner plays that hero,
## the two players trade heroes.
func swap_hero(slot: int) -> void:
	var wanted := Heroes.other(heroes[slot])
	for other in MAX_PLAYERS:
		if other != slot and players[other] != null and heroes[other] == wanted:
			heroes[other] = heroes[slot]
			heroes[slot] = wanted
			hero_changed.emit(other)
			hero_changed.emit(slot)
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
	player_left.emit(slot)


func _handle_joining() -> void:
	for device in all_devices():
		if players.has(device):
			continue
		if not (device.just_pressed("jump") or device.just_pressed("start")):
			continue
		if join(device) == -1:
			return


## Gives the device a free player slot (and a hero nobody plays); returns the
## slot, or -1 when both are taken.
func join(device: PlayerInput) -> int:
	var slot := players.find(null)
	if slot == -1 or players.has(device):
		return -1
	device.consume()
	players[slot] = device
	heroes[slot] = Heroes.Id.SWORDSMAN if _hero_taken(Heroes.Id.SHOOTER, slot) else Heroes.Id.SHOOTER
	player_joined.emit(slot)
	return slot


func _hero_taken(hero: Heroes.Id, except_slot: int) -> bool:
	for slot in MAX_PLAYERS:
		if slot != except_slot and players[slot] != null and heroes[slot] == hero:
			return true
	return false


## Picks up gamepads whose connection signal was missed (some drivers only
## show up a moment after start) and drops the ones that are gone.
func _sync_gamepads() -> void:
	var connected := Input.get_connected_joypads()
	for device_id in connected:
		if not _gamepads.has(device_id):
			_on_joy_connection_changed(device_id, true)
	for device_id in _gamepads.keys():
		if not connected.has(device_id):
			_on_joy_connection_changed(device_id, false)


func _on_joy_connection_changed(device_id: int, connected: bool) -> void:
	if connected:
		# Windows may announce a gamepad again (e.g. when a second identical one
		# is plugged in): keep the same device object, or its player would be
		# left holding one that is no longer polled.
		if not _gamepads.has(device_id):
			_gamepads[device_id] = PlayerInput.gamepad(device_id)
		return
	var device: PlayerInput = _gamepads.get(device_id)
	_gamepads.erase(device_id)
	var slot := players.find(device)
	if device != null and slot != -1:
		remove_player(slot)
