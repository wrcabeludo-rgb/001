class_name Grenadier
extends Walker
## Lumen security grenadier: keeps its distance and lobs grenades in an arc at
## the heroes; a grenade blinks on the ground and blows up a moment later.

@export var throw_range := 650.0
@export var windup_time := 0.5
@export var cooldown := 2.2

var _timer := 1.0
var _winding := false
var _target: Player


func _init() -> void:
	max_health = 9
	body_size = Vector2(60, 92)
	color = Color(0.28, 0.24, 0.3)
	contact_damage = 1
	art = "grenadier"
	art_height = 132.0
	walk_speed = 60.0
	chase_speed = 0.0
	sight = 650.0
	scrap_min = 2
	scrap_max = 3


func _think(delta: float) -> void:
	_timer -= delta
	var hero := nearest_hero(throw_range)
	if _winding:
		velocity.x = 0.0
		if _timer <= 0.0:
			_winding = false
			_timer = cooldown
			_throw()
		return
	if hero == null:
		patrol(walk_speed)
		return
	_target = hero
	facing = 1 if hero.global_position.x >= global_position.x else -1
	velocity.x = 0.0
	if _timer <= 0.0:
		_winding = true
		_timer = windup_time
		telegraph(windup_time)


func _throw() -> void:
	if _target == null or not is_instance_valid(_target):
		return
	var grenade := Grenade.new()
	var start := global_position + Vector2(facing * 20.0, -50.0)
	grenade.position = start
	var flight := 0.85
	var to := _target.global_position + Vector2(0, Player.SIZE.y / 2.0) - start
	grenade.velocity = Vector2(to.x / flight, to.y / flight - 0.5 * Grenade.GRAVITY * flight)
	get_parent().add_child(grenade)
	Sound.play("kick", 0.1, -4.0, 1.5)
	punch(Vector2(0.08, -0.06))


func _on_interrupted() -> void:
	_winding = false
	_timer = cooldown * 0.5


## A grenade: flies in an arc, rolls to a stop, blinks, then explodes.
class Grenade:
	extends CharacterBody2D

	const GRAVITY := 1600.0
	const FUSE := 1.3
	const RADIUS := 110.0
	const DAMAGE := 3

	var _age := 0.0
	var _art: Sprite2D

	func _ready() -> void:
		collision_layer = 0
		collision_mask = Layers.GROUND
		var shape := CircleShape2D.new()
		shape.radius = 9.0
		var collision := CollisionShape2D.new()
		collision.shape = shape
		add_child(collision)
		var path := "res://assets/art/props/grenade.png"
		if ResourceLoader.exists(path):
			_art = Sprite2D.new()
			_art.texture = load(path)
			_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			_art.scale = Vector2(0.5, 0.5)
			add_child(_art)

	func _physics_process(delta: float) -> void:
		_age += delta
		if _art != null:
			_art.rotation += velocity.x * delta * 0.02
		velocity.y = minf(velocity.y + GRAVITY * delta, 1200.0)
		if is_on_floor():
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
		move_and_slide()
		if is_on_wall():
			velocity.x = -velocity.x * 0.4
		if _age >= FUSE:
			Fx.explosion(get_parent(), global_position, RADIUS * 0.55)
			Sound.play("explosion", 0.1, -4.0, 1.2)
			get_tree().call_group("cameras", "shake", 5.0)
			for hurtbox in Harm.hurtboxes_in_rect(get_world_2d(), Rect2(global_position - Vector2(RADIUS, RADIUS),
					Vector2(RADIUS, RADIUS) * 2.0), Harm.HEROES):
				var push := (hurtbox.global_position - global_position).normalized() * 500.0 + Vector2(0, -350)
				hurtbox.take_hit(Hit.make(DAMAGE, push, global_position))
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var blink := _age > FUSE * 0.4 and int(_age * (6.0 if _age < FUSE * 0.75 else 14.0)) % 2 == 0
		if _art != null:
			# The drawing flashes white as the fuse runs down.
			_art.modulate = Color(2.2, 1.6, 2.0) if blink else Color.WHITE
			return
		draw_circle(Vector2.ZERO, 9.0, Color(0.2, 0.2, 0.25))
		draw_circle(Vector2(0, -3), 4.0, Color(1.0, 0.18, 0.53) if blink else Color(0.5, 0.1, 0.3))
