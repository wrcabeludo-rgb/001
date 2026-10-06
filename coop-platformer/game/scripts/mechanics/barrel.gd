class_name Barrel
extends StaticBody2D
## An explosive barrel. Any hit — from a hero or an enemy — lights the fuse
## (it blinks), then it blows up: everyone nearby, heroes and enemies alike,
## takes damage and is thrown away, and other barrels in the blast go off too.
## Heroes can stand on it. It comes back when the team restarts at a checkpoint.

enum State { READY, FUSE, GONE }

const SIZE := Vector2(48, 80)
const COLOR := Color(0.85, 0.25, 0.15)
const BLAST_COLOR := Color(1.0, 0.7, 0.2, 0.8)

@export var fuse_time := 0.45
@export var chain_fuse_time := 0.15
@export var blast_radius := 170.0
@export var damage := 4
@export var blast_knockback := 850.0

var state := State.READY

var _timer := 0.0
var _collision: CollisionShape2D
var _look: ColorRect
var _art: Sprite2D
var _hurtboxes: Array[Hurtbox] = []


func _ready() -> void:
	add_to_group("resettable")
	collision_layer = Layers.WORLD
	var shape := RectangleShape2D.new()
	shape.size = SIZE
	_collision = CollisionShape2D.new()
	_collision.shape = shape
	add_child(_collision)
	_look = Harm.box(-SIZE / 2.0, SIZE, COLOR)
	add_child(_look)
	_art = Harm.prop_sprite("barrel", SIZE)
	if _art != null:
		_look.color = Color.TRANSPARENT
		_look.add_child(_art)
		_art.position += SIZE / 2.0
	else:
		_look.add_child(Harm.box(Vector2(0, 16), Vector2(SIZE.x, 8), Color(0.95, 0.8, 0.2)))
		_look.add_child(Harm.box(Vector2(0, 46), Vector2(SIZE.x, 8), Color(0.95, 0.8, 0.2)))
	# Both sides can set it off: heroes' attacks and enemies' shots.
	for team in [Layers.Team.ENEMIES, Layers.Team.PLAYERS]:
		var hurtbox := Hurtbox.new()
		add_child(hurtbox)
		hurtbox.setup(team, SIZE, self)
		_hurtboxes.append(hurtbox)


func receive_hit(_hit: Hit) -> bool:
	if state != State.READY:
		return false
	light(fuse_time)
	return true


func light(time: float) -> void:
	if state != State.READY:
		return
	state = State.FUSE
	_timer = time


func _physics_process(delta: float) -> void:
	if state != State.FUSE:
		return
	_timer -= delta
	var blink := int(_timer * 16.0) % 2 == 0
	if _art != null:
		Flash.set_flash(_art, Color.WHITE, 0.8 if blink else 0.0)
	else:
		_look.color = Color.WHITE if blink else COLOR
	if _timer <= 0.0:
		explode()


func explode() -> void:
	state = State.GONE
	_look.visible = false
	_collision.set_deferred("disabled", true)
	for hurtbox in _hurtboxes:
		hurtbox.set_deferred("monitorable", false)
	var already := {}
	for hurtbox in Harm.hurtboxes_in_circle(get_world_2d(), global_position, blast_radius, Harm.EVERYONE):
		var target := hurtbox.receiver
		if target == self or already.has(target):
			continue
		already[target] = true
		if target is Barrel:
			target.light(chain_fuse_time)
			continue
		var away := (hurtbox.global_position - global_position).normalized()
		var push := Vector2(signf(away.x) if away.x != 0.0 else 1.0, 0.0) * blast_knockback + Vector2(0, -420)
		hurtbox.take_hit(Hit.make(damage, push, global_position))
	_show_blast()
	Sound.play("explosion")
	get_tree().call_group("cameras", "shake", 16.0)


## Back in place (after the team restarts at a checkpoint).
func reset() -> void:
	state = State.READY
	_look.visible = true
	if _art != null:
		Flash.set_flash(_art, Color.WHITE, 0.0)
	else:
		_look.color = COLOR
	_collision.set_deferred("disabled", false)
	for hurtbox in _hurtboxes:
		hurtbox.set_deferred("monitorable", true)


func _show_blast() -> void:
	var blast := Polygon2D.new()
	var points := PackedVector2Array()
	for i in 24:
		points.append(Vector2.from_angle(TAU * i / 24.0) * blast_radius)
	blast.polygon = points
	blast.color = BLAST_COLOR
	blast.scale = Vector2.ONE * 0.3
	add_child(blast)
	var tween := blast.create_tween()
	tween.tween_property(blast, "scale", Vector2.ONE, 0.15)
	tween.tween_property(blast, "modulate:a", 0.0, 0.3)
	tween.tween_callback(blast.queue_free)
