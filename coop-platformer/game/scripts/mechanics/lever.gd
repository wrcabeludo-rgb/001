class_name Lever
extends Node2D
## A switch on a post. Hit it (sword, shot or kick) to open its door.
## Once pulled it stays pulled.

signal pulled

const POST_COLOR := Color(0.3, 0.3, 0.36)
const OFF_COLOR := Color(1.0, 0.85, 0.3)
const ON_COLOR := Color(0.4, 1.0, 0.55)

var door: Door
var is_pulled := false

var _handle: ColorRect
var _art: Sprite2D
var _hurtbox: Hurtbox


func _ready() -> void:
	add_child(Harm.box(Vector2(-8, -70), Vector2(16, 70), POST_COLOR))
	_handle = Harm.box(Vector2(-20, -90), Vector2(40, 24), OFF_COLOR)
	add_child(_handle)
	_art = Harm.prop_sprite("lever", Vector2.ZERO)
	if _art != null:
		for child in get_children():
			child.visible = false
		add_child(_art)
	_hurtbox = Hurtbox.new()
	_hurtbox.position = Vector2(0, -50)
	add_child(_hurtbox)
	_hurtbox.setup(Layers.Team.ENEMIES, Vector2(50, 100), self)


func receive_hit(_hit: Hit) -> bool:
	if is_pulled:
		return false
	pull()
	return true


func pull() -> void:
	is_pulled = true
	Sound.play("lever")
	_handle.color = ON_COLOR
	_handle.rotation = 0.5
	if _art != null:
		# Pulled: the handle swings the other way, the lamp turns green.
		_art.flip_h = true
		Flash.set_flash(_art, ON_COLOR, 0.25)
	if door != null:
		door.open()
	pulled.emit()
