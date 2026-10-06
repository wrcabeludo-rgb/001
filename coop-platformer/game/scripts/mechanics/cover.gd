class_name Cover
extends StaticBody2D
## A barricade to hide behind: it stops bullets from both sides and can be
## jumped over. Enemy fire slowly breaks it (it darkens as it weakens). It comes
## back when the team restarts at a checkpoint.

const SIZE := Vector2(56, 110)
const COLOR := Color(0.42, 0.5, 0.45)

@export var max_health := 10
## After a hit it ignores further hits for this long (so a touch cannot shred it).
@export var hit_cooldown := 0.3

var health: Health

var _cooldown := 0.0
var _collision: CollisionShape2D
var _look: ColorRect
var _hurtbox: Hurtbox


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
	_look.add_child(Harm.box(Vector2(0, 0), Vector2(SIZE.x, 8), COLOR.lightened(0.3)))
	health = Health.new()
	add_child(health)
	health.reset(max_health)
	health.died.connect(_on_broken)
	# Only enemy attacks wear it down.
	_hurtbox = Hurtbox.new()
	add_child(_hurtbox)
	_hurtbox.setup(Layers.Team.PLAYERS, SIZE, self)


func receive_hit(hit: Hit) -> bool:
	if health.is_dead() or _cooldown > 0.0:
		return false
	_cooldown = hit_cooldown
	health.damage(hit.damage)
	return true


func _physics_process(delta: float) -> void:
	_cooldown -= delta
	_look.color = COLOR.darkened(0.6 * (1.0 - health.ratio()))


func _on_broken() -> void:
	_look.visible = false
	_collision.set_deferred("disabled", true)
	_hurtbox.set_deferred("monitorable", false)


func reset() -> void:
	health.reset(max_health)
	_look.visible = true
	_collision.set_deferred("disabled", false)
	_hurtbox.set_deferred("monitorable", true)
