class_name HeroRig
extends Node2D
## The hero's picture as a cutout puppet: body, back leg and front leg cut
## from one drawing (tools/sprites.py). Legs swing around the hips when
## running, tuck in when jumping; the body bobs, leans into a dash, recoils on
## a shot. Every action has its own pose: crouching (a low wide stance),
## sliding down a wall, climbing, blocking, the Gunner's kick and four
## different sword swings. Placed at the hero's feet.
##
## A pose can also be a drawing: "<hero>_pose_<name>_<n>.png" in the heroes
## folder (made by tools/sprites.py from art_source/heroes/poses). When it
## exists it replaces the puppet for that pose; several numbered pictures
## play as frames.

enum Slash { DOWN, RISING, FINISHER, OVERHEAD }

const ART := "res://assets/art/heroes/"
## The art is drawn at twice the game size, for sharpness when zoomed.
const ART_SCALE := 0.5
const RIG_FILE := "res://assets/art/heroes/rig.json"
const POSE_FILE := "res://assets/art/heroes/poses.json"
const POSES := ["crouch", "wall", "climb", "block", "kick",
	"slash_down", "slash_rising", "slash_finisher", "slash_overhead"]
const SLASH_POSES := ["slash_down", "slash_rising", "slash_finisher", "slash_overhead"]
const KICK_TIME := 0.28
## How far the legs spread in a crouch (radians from straight down) and how
## much the whole hero hunches down (the picture is squeezed at the feet).
const CROUCH_SPREAD := 0.5
const CROUCH_SQUASH := 0.82

## "gunner" or "swordsman".
var art_name := ""

var _body: Sprite2D
var _back_leg: Sprite2D
var _front_leg: Sprite2D
var _back_rest := Vector2.ZERO
var _front_rest := Vector2.ZERO
var _body_rest := Vector2.ZERO
var _leg_length := 80.0
var _phase := 0.0
var _recoil := 0.0
var _lean := 0.0
var _shift := Vector2.ZERO
var _drop := 0.0
var _squash := 1.0
## The current action ("kick" or a slash pose), how long it lasts and has run.
var _action := ""
var _action_length := 0.0
var _action_time := 0.0
## Drawn poses: name -> [textures], and where the feet are in each frame (0..1 across).
var _pose_art := {}
var _pose_anchor := {}
var _pose_sprite: Sprite2D
var _clock := 0.0


## Returns null if the hero has no art yet.
static func create(hero_art: String) -> HeroRig:
	if not ResourceLoader.exists(ART + hero_art + "_body.png") or not FileAccess.file_exists(RIG_FILE):
		return null
	var info: Variant = JSON.parse_string(FileAccess.get_file_as_string(RIG_FILE))
	if not (info is Dictionary and info.has(hero_art)):
		return null
	var rig := HeroRig.new()
	rig.art_name = hero_art
	rig._build(info[hero_art])
	return rig


func _build(info: Dictionary) -> void:
	var size := Vector2(info["size"][0], info["size"][1])
	var back_hip := Vector2(info["back_hip"][0], info["back_hip"][1])
	var front_hip := Vector2(info["front_hip"][0], info["front_hip"][1])
	_leg_length = size.y - (back_hip.y + front_hip.y) / 2.0
	# The picture's anchor: between the hips horizontally, at the soles.
	var anchor := Vector2((back_hip.x + front_hip.x) / 2.0, size.y)
	scale = Vector2.ONE * ART_SCALE
	_back_leg = _part("back_leg", back_hip, anchor)
	_front_leg = _part("front_leg", front_hip, anchor)
	_body = _part("body", Vector2.ZERO, anchor)
	_back_rest = _back_leg.position
	_front_rest = _front_leg.position
	_body_rest = _body.position
	_load_poses()


func _part(part: String, pivot: Vector2, anchor: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = load(ART + art_name + "_" + part + ".png")
	sprite.centered = false
	sprite.offset = -pivot
	sprite.position = pivot - anchor
	sprite.material = Flash.material()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(sprite)
	return sprite


func _load_poses() -> void:
	var anchors: Variant = {}
	if FileAccess.file_exists(POSE_FILE):
		anchors = JSON.parse_string(FileAccess.get_file_as_string(POSE_FILE))
	for pose_name in POSES:
		var frames: Array[Texture2D] = []
		for n in range(1, 9):
			var path := "%s%s_pose_%s_%d.png" % [ART, art_name, pose_name, n]
			if not ResourceLoader.exists(path):
				break
			frames.append(load(path))
		if not frames.is_empty():
			_pose_art[pose_name] = frames
			var feet: Array[float] = []
			for n in frames.size():
				var key := "%s_%s_%d" % [art_name, pose_name, n + 1]
				feet.append(float(anchors.get(key, 0.5)) if anchors is Dictionary else 0.5)
			_pose_anchor[pose_name] = feet
	_pose_sprite = Sprite2D.new()
	_pose_sprite.centered = false
	_pose_sprite.material = Flash.material()
	_pose_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_pose_sprite.visible = false
	add_child(_pose_sprite)


## True if this pose has a drawing (tests and the art pipeline use it).
func has_pose_art(pose_name: String) -> bool:
	return _pose_art.has(pose_name)


## A shot: the body jerks back for a moment.
func recoil() -> void:
	_recoil = 1.0


## The Gunner's kick: the front leg snaps forward.
func kick() -> void:
	_start("kick", KICK_TIME)


## A sword swing of the given kind (Slash) lasting `duration` seconds.
func slash(kind: int, duration: float) -> void:
	_start(SLASH_POSES[kind], maxf(duration, 0.18))


## The pose being shown now (for tests).
func current_pose(player: Player) -> String:
	return _action if _acting() else _state(player)


func _start(action: String, length: float) -> void:
	_action = action
	_action_length = length
	_action_time = 0.0


func _acting() -> bool:
	return _action != "" and _action_time < _action_length


func _state(player: Player) -> String:
	if player.is_climbing():
		return "climb"
	if player.is_dashing():
		return "dash"
	if player.is_wall_sliding():
		return "wall"
	if player.combat != null and player.combat.is_blocking():
		return "block"
	if player.crouching:
		return "crouch"
	if not player.is_on_floor():
		return "air"
	return "run" if absf(player.velocity.x) > 20.0 else "idle"


## Updates the pose from what the hero is doing.
func pose(player: Player, delta: float) -> void:
	scale.x = ART_SCALE * player.facing
	_clock += delta
	_action_time += delta
	var current := current_pose(player)
	if player.is_climbing() and absf(player.velocity.y) > 1.0:
		_phase += absf(player.velocity.y) * delta * 0.03
	if _show_drawing(current):
		return
	var t := _action_time / _action_length if _acting() else 0.0
	# Windup rises over the first quarter; the strike peaks just after it.
	var windup := clampf(t / 0.22, 0.0, 1.0) * (1.0 - clampf((t - 0.22) / 0.15, 0.0, 1.0))
	var strike := clampf((t - 0.18) / 0.15, 0.0, 1.0) * (1.0 - clampf((t - 0.45) / 0.55, 0.0, 1.0))

	var back := 0.0
	var front := 0.0
	var lift := 0.0  # body up (art pixels)
	var drop := 0.0  # hips down, legs spread to match
	var lean := 0.0
	var shift := 0.0  # body forward
	var squash := 1.0
	match current:
		"kick":
			var snap := clampf(t / 0.3, 0.0, 1.0) * (1.0 - clampf((t - 0.55) / 0.45, 0.0, 1.0))
			front = -1.55 * snap
			back = 0.2 * snap
			lean = -0.24 * snap
			shift = -8.0 * snap
		"slash_down":
			lean = -0.12 * windup + 0.26 * strike
			shift = 18.0 * strike
			front = -0.35 * strike
			back = 0.3 * strike
			drop = 8.0 * strike
		"slash_rising":
			lean = 0.14 * windup - 0.18 * strike
			shift = 12.0 * strike
			lift = 10.0 * strike
			front = -0.25 * strike
			back = 0.2 * strike
		"slash_finisher":
			lean = -0.3 * windup + 0.42 * strike
			shift = -10.0 * windup + 34.0 * strike
			front = -0.65 * strike
			back = 0.55 * strike
			drop = 22.0 * strike
		"slash_overhead":
			lean = 0.1 * windup - 0.3 * strike
			lift = 12.0 * strike
			front = -0.15 * strike
		"climb":
			back = sin(_phase) * 0.4
			front = -back
			lift = absf(sin(_phase)) * 8.0
			lean = sin(_phase) * 0.04
		"dash":
			back = 0.6
			front = -0.2
			lean = 0.25
		"wall":
			# Back to the fall, a foot braced on the wall, sliding down.
			front = -0.85
			back = 0.3
			lean = -0.12
			shift = 6.0
			lift = sin(_clock * 40.0) * 1.5
		"block":
			# A braced stance behind the guard.
			front = -0.4
			back = 0.45
			lean = -0.1
			shift = -4.0
			drop = 10.0
		"crouch":
			drop = _leg_length * (1.0 - cos(CROUCH_SPREAD))
			lean = 0.2
			shift = 6.0
			squash = CROUCH_SQUASH
		"air":
			if player.velocity.y < 0.0:
				back = 0.35
				front = -0.45
			else:
				back = 0.15
				front = -0.2
		"run":
			_phase += absf(player.velocity.x) * delta * 0.022
			back = sin(_phase) * 0.55
			front = -back
			lift = absf(sin(_phase)) * 6.0
			lean = 0.06
		_:
			_phase = 0.0
			lift = sin(Time.get_ticks_msec() * 0.003) * 1.5
	# Lowered hips: spread the legs just enough to keep the feet on the floor.
	if drop > 0.0:
		var spread := acos(clampf(1.0 - drop / _leg_length, -1.0, 1.0))
		front = minf(front, -spread)
		back = maxf(back, spread)

	var follow := minf(1.0, delta * 18.0)
	_back_leg.rotation = lerp_angle(_back_leg.rotation, back, follow)
	_front_leg.rotation = lerp_angle(_front_leg.rotation, front, follow)
	_drop = lerpf(_drop, drop, follow)
	_squash = lerpf(_squash, squash, follow)
	scale.y = ART_SCALE * _squash
	_shift.x = lerpf(_shift.x, shift, follow)
	_recoil = move_toward(_recoil, 0.0, delta * 8.0)
	_lean = lerpf(_lean, lean, minf(1.0, delta * 14.0))
	_back_leg.position = _back_rest + Vector2(0, _drop)
	_front_leg.position = _front_rest + Vector2(0, _drop)
	_body.rotation = _lean
	_body.position = _body_rest + Vector2(-_recoil * 10.0 + _shift.x, _drop - lift)


## Shows the drawing for this pose if there is one; false keeps the puppet.
func _show_drawing(pose_name: String) -> bool:
	var frames: Array = _pose_art.get(pose_name, [])
	var drawn := not frames.is_empty()
	_pose_sprite.visible = drawn
	for part in [_body, _back_leg, _front_leg]:
		part.visible = not drawn
	if not drawn:
		return false
	var index := 0
	if pose_name == "climb":
		index = int(_phase / PI) % frames.size()
	elif _acting() and frames.size() > 1:
		# The first frame is the windup, a short third of the action; the rest is the strike.
		var t := _action_time / _action_length
		index = 0 if t < 0.35 else mini(1 + int((t - 0.35) / 0.65 * (frames.size() - 1)), frames.size() - 1)
	else:
		index = int(_clock * 8.0) % frames.size()
	var texture: Texture2D = frames[index]
	_pose_sprite.texture = texture
	_pose_sprite.offset = Vector2(-texture.get_width() * float(_pose_anchor[pose_name][index]), -texture.get_height())
	return true


## Tints the whole puppet (hit flash, charged glow); `amount` 0 = none.
func tint(color: Color, amount: float) -> void:
	for sprite in [_body, _back_leg, _front_leg, _pose_sprite]:
		Flash.set_flash(sprite, color, amount)
