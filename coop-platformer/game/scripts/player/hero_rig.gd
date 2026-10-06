class_name HeroRig
extends Node2D
## The hero's picture as a cutout puppet: body, back leg and front leg cut
## from one drawing (tools/sprites.py). Legs swing around the hips when
## running, tuck in when jumping; the body bobs, leans into a dash, recoils on
## a shot and lunges with a sword swing. Placed at the hero's feet.

const ART := "res://assets/art/heroes/"
## The art is drawn at twice the game size, for sharpness when zoomed.
const ART_SCALE := 0.5
const RIG_FILE := "res://assets/art/heroes/rig.json"

## "gunner" or "swordsman".
var art_name := ""

var _body: Sprite2D
var _back_leg: Sprite2D
var _front_leg: Sprite2D
var _phase := 0.0
var _kick := 0.0
var _lunge := 0.0
var _lean := 0.0
var _body_rest := Vector2.ZERO


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
	# The picture's anchor: between the hips horizontally, at the soles.
	var anchor := Vector2((back_hip.x + front_hip.x) / 2.0, size.y)
	scale = Vector2.ONE * ART_SCALE
	_back_leg = _part("back_leg", back_hip, anchor)
	_front_leg = _part("front_leg", front_hip, anchor)
	_body = _part("body", Vector2.ZERO, anchor)
	_body_rest = _body.position


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


## A shot: the body jerks back for a moment.
func recoil() -> void:
	_kick = 1.0


## A sword swing: the body lunges forward.
func lunge() -> void:
	_lunge = 1.0


## Updates the pose from what the hero is doing.
func pose(player: Player, delta: float) -> void:
	scale.x = ART_SCALE * player.facing
	var speed := absf(player.velocity.x)
	var on_floor := player.is_on_floor()
	var back := 0.0
	var front := 0.0
	var bob := 0.0
	var lean := 0.0
	if player.is_climbing():
		_phase += absf(player.velocity.y) * delta * 0.03
		back = sin(_phase) * 0.35
		front = -back
	elif player.is_dashing():
		back = 0.6
		front = -0.2
		lean = 0.25
	elif not on_floor:
		if player.velocity.y < 0.0:
			back = 0.35
			front = -0.45
		else:
			back = 0.15
			front = -0.2
	elif speed > 20.0:
		_phase += speed * delta * 0.022
		back = sin(_phase) * 0.55
		front = -back
		bob = absf(sin(_phase)) * 6.0
		lean = 0.06
	else:
		_phase = 0.0
		bob = sin(Time.get_ticks_msec() * 0.003) * 1.5
	_back_leg.rotation = lerp_angle(_back_leg.rotation, back, minf(1.0, delta * 18.0))
	_front_leg.rotation = lerp_angle(_front_leg.rotation, front, minf(1.0, delta * 18.0))
	_kick = move_toward(_kick, 0.0, delta * 8.0)
	_lunge = move_toward(_lunge, 0.0, delta * 5.0)
	_lean = lerpf(_lean, lean + _lunge * 0.18, minf(1.0, delta * 12.0))
	_body.rotation = _lean
	_body.position = _body_rest + Vector2(-_kick * 10.0 + _lunge * 14.0, -bob)


## Tints the whole puppet (hit flash, charged glow); `amount` 0 = none.
func tint(color: Color, amount: float) -> void:
	for sprite in [_body, _back_leg, _front_leg]:
		Flash.set_flash(sprite, color, amount)
