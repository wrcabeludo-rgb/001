class_name Projectile
extends Area2D
## A bullet: flies straight, stops at walls, damages the other team's hurtboxes.
## `pierce` is how many extra targets it can pass through. Its look
## (ProjectileLook) is a bolt for heroes and a slime glob for monsters unless
## `style` is set before it enters the tree; it bursts into sparks or drops.

var velocity := Vector2.ZERO
var damage := 1
var knockback := 300.0
var pierce := 0
var lifetime := 1.0
## How it looks; -1 picks by team (heroes: a bolt, monsters: slime).
var style := -1

var _already_hit := {}
var _team: Layers.Team
var _size := Vector2.ZERO
var _color := Color.WHITE


func setup(team: Layers.Team, start: Vector2, direction: Vector2, speed: float, p_damage: int,
		p_knockback: float, size: Vector2, color: Color, p_pierce := 0, p_lifetime := 1.0) -> void:
	position = start
	velocity = direction.normalized() * speed
	rotation = velocity.angle()
	damage = p_damage
	knockback = p_knockback
	pierce = p_pierce
	lifetime = p_lifetime
	collision_layer = 0
	collision_mask = Layers.WORLD | Layers.target_hurtboxes(team)
	monitorable = false

	var rect := RectangleShape2D.new()
	rect.size = size
	var collision := CollisionShape2D.new()
	collision.shape = rect
	add_child(collision)

	_team = team
	_size = size
	_color = color
	body_entered.connect(_on_body_entered)


func _ready() -> void:
	var look := ProjectileLook.new()
	look.style = (ProjectileLook.Style.BOLT if _team == Layers.Team.PLAYERS else ProjectileLook.Style.SLIME) \
		if style < 0 else style
	look.color = _color
	look.size = _size
	add_child(look)


func _physics_process(delta: float) -> void:
	position += velocity * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	for area in get_overlapping_areas():
		var hurtbox := area as Hurtbox
		if hurtbox == null or _already_hit.has(hurtbox):
			continue
		_already_hit[hurtbox] = true
		var push := velocity.normalized() * knockback + Vector2(0, -knockback * 0.4)
		if hurtbox.take_hit(Hit.make(damage, push, global_position)):
			if pierce <= 0:
				_burst()
				queue_free()
				return
			pierce -= 1


func _on_body_entered(_body: Node2D) -> void:
	_burst()
	queue_free()


## Sparks (or drops of slime) where it hit.
func _burst() -> void:
	if not is_inside_tree():
		return
	var at := global_position - velocity.normalized() * 6.0
	if _team == Layers.Team.PLAYERS and style != ProjectileLook.Style.SLIME:
		Fx.burst(get_parent(), at, [Color(1, 1, 1), _color, Color(_color, 0.0)], 8, 300.0, 2.5, 0.25, 500.0)
	else:
		Fx.burst(get_parent(), at, [_color, Color(_color.darkened(0.4), 0.0)], 10, 220.0, 3.5, 0.45, 900.0, false)
