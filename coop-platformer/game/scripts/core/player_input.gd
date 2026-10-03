class_name PlayerInput
extends RefCounted
## One input device (half of the keyboard or a gamepad) and its button state.
##
## The state is polled once per physics frame by PlayerManager, so every
## script reading it in the same frame sees the same "just pressed" values.

enum Kind { KEYBOARD, GAMEPAD }

const ACTIONS := ["left", "right", "up", "down", "jump", "attack", "skill", "extra", "start"]
const STICK_DEADZONE := 0.4

## Physical keys, so the layout works regardless of the system language (QWERTY / ЙЦУКЕН).
const KEYBOARD_LEFT := {
	"left": [KEY_A],
	"right": [KEY_D],
	"up": [KEY_W],
	"down": [KEY_S],
	"jump": [KEY_K, KEY_SPACE],
	"attack": [KEY_J],
	"skill": [KEY_L],
	"extra": [KEY_I],
	"start": [KEY_ESCAPE],
}

const KEYBOARD_RIGHT := {
	"left": [KEY_LEFT],
	"right": [KEY_RIGHT],
	"up": [KEY_UP],
	"down": [KEY_DOWN],
	"jump": [KEY_KP_2],
	"attack": [KEY_KP_1],
	"skill": [KEY_KP_3],
	"extra": [KEY_KP_5],
	"start": [KEY_KP_ENTER],
}

const GAMEPAD_BUTTONS := {
	"left": JOY_BUTTON_DPAD_LEFT,
	"right": JOY_BUTTON_DPAD_RIGHT,
	"up": JOY_BUTTON_DPAD_UP,
	"down": JOY_BUTTON_DPAD_DOWN,
	"jump": JOY_BUTTON_A,
	"attack": JOY_BUTTON_X,
	"skill": JOY_BUTTON_B,
	"extra": JOY_BUTTON_Y,
	"start": JOY_BUTTON_START,
}

var kind: Kind
var device_id := -1
var label := ""

var _key_map := {}
var _held := {}
var _prev := {}


static func keyboard(p_label: String, key_map: Dictionary) -> PlayerInput:
	var input := PlayerInput.new()
	input.kind = Kind.KEYBOARD
	input.label = p_label
	input._key_map = key_map
	input._reset_state()
	return input


static func gamepad(p_device_id: int) -> PlayerInput:
	var input := PlayerInput.new()
	input.kind = Kind.GAMEPAD
	input.device_id = p_device_id
	input.label = "Геймпад %d (%s)" % [p_device_id + 1, Input.get_joy_name(p_device_id)]
	input._reset_state()
	return input


func poll() -> void:
	_prev = _held.duplicate()
	for action in ACTIONS:
		_held[action] = _read(action)


## Treat everything currently held as "already pressed", so the press that
## made a player join does not also trigger a jump on the first frame.
func consume() -> void:
	_prev = _held.duplicate()


func is_held(action: String) -> bool:
	return _held[action]


func just_pressed(action: String) -> bool:
	return _held[action] and not _prev[action]


func just_released(action: String) -> bool:
	return _prev[action] and not _held[action]


## Digital direction: each component is -1, 0 or 1 (aiming is 8-directional).
func get_move() -> Vector2:
	return Vector2(
		float(_held["right"]) - float(_held["left"]),
		float(_held["down"]) - float(_held["up"])
	)


func held_actions() -> PackedStringArray:
	var result := PackedStringArray()
	for action in ACTIONS:
		if _held[action]:
			result.append(action)
	return result


func _reset_state() -> void:
	for action in ACTIONS:
		_held[action] = false
		_prev[action] = false


func _read(action: String) -> bool:
	if kind == Kind.KEYBOARD:
		for key in _key_map[action]:
			if Input.is_physical_key_pressed(key):
				return true
		return false

	if Input.is_joy_button_pressed(device_id, GAMEPAD_BUTTONS[action]):
		return true
	match action:
		"left":
			return Input.get_joy_axis(device_id, JOY_AXIS_LEFT_X) < -STICK_DEADZONE
		"right":
			return Input.get_joy_axis(device_id, JOY_AXIS_LEFT_X) > STICK_DEADZONE
		"up":
			return Input.get_joy_axis(device_id, JOY_AXIS_LEFT_Y) < -STICK_DEADZONE
		"down":
			return Input.get_joy_axis(device_id, JOY_AXIS_LEFT_Y) > STICK_DEADZONE
	return false
