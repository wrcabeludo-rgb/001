class_name ShieldGuard
extends Walker
## Security robot with a tall riot shield: from the front it cannot be hurt —
## shots and blades bounce off with sparks. Hit it from behind or from above,
## or knock the shield out with the shock baton: an electric hit switches the
## shield off for a while. When a hero is close in front it jabs with a baton.

enum State { WALK, WINDUP, JAB, RECOVER }

const SHIELD_COLOR := Color(0.25, 0.27, 0.33)
const SHIELD_LIGHT := Color(1.0, 0.18, 0.53)
## How long the shield stays off after an electric hit.
const SHIELD_DOWN_TIME := 4.0

@export var jab_reach := 120.0
@export var windup_time := 0.5
@export var recover_time := 0.6
@export var jab_damage := 2

var state := State.WALK

var _timer := 0.0
var _shield_down := 0.0
var _jab: Hitbox
var _shield: Node2D


func _init() -> void:
	max_health = 10
	body_size = Vector2(64, 96)
	color = ROBOT_COLOR.darkened(0.1)
	contact_damage = 2
	knockback_resistance = 0.6
	art = "shield_guard"
	art_height = 130.0
	walk_speed = 60.0
	chase_speed = 110.0
	scrap_min = 2
	scrap_max = 3


func _ready() -> void:
	super._ready()
	_jab = Hitbox.new()
	add_child(_jab)
	_jab.setup(Layers.Team.ENEMIES, Vector2(90, 40), Vector2(80, -10), Electric.COLOR)
	_jab.show_flash = false
	if _sprite == null:
		_shield = ShieldLook.new()
		_shield.size = Vector2(16, body_size.y * 1.05)
		add_child(_shield)


func is_shielded() -> bool:
	return _shield_down <= 0.0


func receive_hit(hit: Hit) -> bool:
	if not is_alive():
		return false
	if hit.shock > 0.0 and is_shielded():
		_shield_down = SHIELD_DOWN_TIME
		Sound.play("shock", 0.05, 0.0, 0.7)
		var sparks := Electric.Arc.new()
		sparks.position = global_position + Vector2(facing * 36.0, -40.0)
		sparks.to = Vector2(0, 80)
		get_parent().add_child(sparks)
	var from_front := signf(hit.source_position.x - global_position.x) == float(facing)
	var from_above := hit.source_position.y < global_position.y - body_size.y * 0.75
	if is_shielded() and from_front and not from_above:
		Sound.play("block", 0.1, -2.0, 1.3)
		var at := global_position + Vector2(facing * 36.0, clampf(hit.source_position.y - global_position.y, -50.0, 30.0))
		Fx.burst(get_parent(), at, [Color(1, 1, 0.8), Color(1.0, 0.7, 0.3), Color(1.0, 0.4, 0.1, 0.0)], 10, 380.0,
			2.5, 0.25, 600.0, true, Vector2(facing, -0.4), 50.0)
		velocity.x = -facing * 90.0
		punch(Vector2(-0.06, 0.04))
		return true
	return super.receive_hit(hit)


func _think(delta: float) -> void:
	_timer -= delta
	match state:
		State.WALK:
			var hero := hero_in_line(jab_reach, 80.0)
			if hero == null:
				super._think(delta)
				return
			facing = 1 if hero.global_position.x >= global_position.x else -1
			velocity.x = 0.0
			state = State.WINDUP
			_timer = windup_time
			telegraph(windup_time)
		State.WINDUP:
			velocity.x = 0.0
			if _timer <= 0.0:
				state = State.JAB
				_timer = 0.15
				_jab.activate(0.15, jab_damage, Vector2(520, -260), facing)
				velocity.x = facing * 260.0
				Sound.play("kick", 0.1, -2.0, 1.2)
		State.JAB:
			if _timer <= 0.0:
				state = State.RECOVER
				_timer = recover_time
		State.RECOVER:
			velocity.x = 0.0
			if _timer <= 0.0:
				state = State.WALK


func _on_interrupted() -> void:
	state = State.WALK


func _physics_process(delta: float) -> void:
	_shield_down -= delta
	super._physics_process(delta)
	if _shield != null:
		_shield.position = Vector2(facing * (body_size.x / 2.0 + 4.0), 0)
		_shield.visible = is_shielded()
	elif _sprite != null and not is_shielded():
		# Shield off: it flickers grey.
		_sprite.modulate = Color(0.75, 0.75, 0.8) if int(_shield_down * 8.0) % 2 == 0 else Color.WHITE
	elif _sprite != null:
		_sprite.modulate = Color.WHITE


## The shield of the placeholder body: a dark slab with a magenta light strip.
class ShieldLook:
	extends Node2D

	var size := Vector2(16, 100)

	func _draw() -> void:
		draw_rect(Rect2(-size / 2.0, size), ShieldGuard.SHIELD_COLOR)
		draw_rect(Rect2(Vector2(-2, -size.y / 2.0 + 10.0), Vector2(4, size.y - 20.0)), ShieldGuard.SHIELD_LIGHT)
