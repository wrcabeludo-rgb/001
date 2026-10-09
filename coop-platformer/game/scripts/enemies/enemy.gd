class_name Enemy
extends CharacterBody2D
## Base for every enemy: health, knockback and hit-stun, damage on touch,
## a clear warning before attacks (blinking + "!"), loot when destroyed.
## Each enemy type overrides _think() with its behaviour.

signal died(enemy: Enemy)

const TELEGRAPH_COLOR := Color(1.0, 0.95, 0.4)
const GRAVITY := 2600.0
const MAX_FALL_SPEED := 1300.0

## Faction colours (CONCEPT.md, block 5): mutants are green, robots steel blue.
const MUTANT_COLOR := Color(0.42, 0.7, 0.3)
const ROBOT_COLOR := Color(0.5, 0.58, 0.7)

## Burning (the flamethrower): 1 damage every half second while it lasts.
const BURN_TICK := 0.5
const BURN_DAMAGE := 1
const BURN_COLOR := Color(1.0, 0.5, 0.15)
## After an electric stun the enemy cannot be stunned again for this long.
const SHOCK_IMMUNITY := 3.0
## Enemies that cannot be stunned (bosses) take this much more from shocks.
const SHOCK_RESIST_DAMAGE := 1.5

@export var max_health := 6
@export var body_size := Vector2(56, 70)
@export var color := MUTANT_COLOR
@export var contact_damage := 2
@export var contact_knockback := 420.0
## 0 = flies back from every hit, 1 = does not move at all.
@export var knockback_resistance := 0.0
@export var hit_stun := 0.2
@export var uses_gravity := true
## Picture in assets/art/enemies (without ".png"); empty = a coloured box.
## The picture faces left. Its height on screen is `art_height`; the area
## where the enemy can be hit grows to the picture's size.
@export var art := ""
@export var art_height := 100.0
## Flyers have the picture centred on the body; walkers stand it on the floor.
@export var art_centered := false
@export_group("Добыча")
@export var health_drop_chance := 0.25
@export var ammo_drop_chance := 0.3
@export var scrap_min := 1
@export var scrap_max := 2

var health: Health
var facing := -1
var stun_timer := 0.0
## While true, hits do not interrupt the enemy (a heavy one mid-attack).
var super_armor := false
## False for bosses: an electric hit does more damage instead of stunning.
var can_be_shocked := true

var _burn_timer := 0.0
var _burn_tick := 0.0
var _shock_timer := 0.0
var _shock_immunity := 0.0
var _flames: CPUParticles2D
var _sparks: Electric.Sparks

var _flash_timer := 0.0
var _telegraph_timer := 0.0
var _body: ColorRect
var _eye: ColorRect
var _alert: Label
var _hurtbox: Hurtbox
var _contact: Area2D
var _sprite: Sprite2D
var _sprite_rest := Vector2.ZERO
var _anim_time := 0.0
## The picture's scale at rest; the animation squashes and stretches it.
var _base_scale := Vector2.ONE
## A squash that springs back: x wider (+) / narrower, y taller (+) / shorter.
var _squash := Vector2.ZERO
var _hit_tilt := 0.0
var _was_on_floor := true



## The size of the monster's picture on screen.
func art_drawn_size() -> Vector2:
	if _sprite == null:
		return body_size
	return _sprite.texture.get_size() * _sprite.scale

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = Layers.ENEMY_BODIES
	collision_mask = Layers.GROUND

	var shape := RectangleShape2D.new()
	shape.size = body_size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)

	_body = ColorRect.new()
	_body.size = body_size
	_body.position = -body_size / 2
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_body)
	_eye = ColorRect.new()
	_eye.size = Vector2(10, 10)
	_eye.color = Color(1.0, 0.25, 0.3)
	_eye.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_eye)

	_alert = Label.new()
	_alert.text = "!"
	_alert.add_theme_font_size_override("font_size", 40)
	_alert.add_theme_color_override("font_color", TELEGRAPH_COLOR)
	_alert.position = Vector2(-8, -body_size.y / 2 - 56)
	_alert.visible = false
	add_child(_alert)

	health = Health.new()
	add_child(health)
	health.reset(GameSettings.enemy_health(max_health))
	health.died.connect(_on_died)

	_hurtbox = Hurtbox.new()
	add_child(_hurtbox)
	var hurt_size := body_size
	var art_path := "res://assets/art/enemies/%s.png" % art
	if art != "" and ResourceLoader.exists(art_path):
		_sprite = Sprite2D.new()
		_sprite.texture = load(art_path)
		_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var factor := art_height / _sprite.texture.get_height()
		_sprite.scale = Vector2(factor, factor)
		_base_scale = _sprite.scale
		var drawn := art_drawn_size()
		# Standing on the same floor as the body.
		_sprite_rest = Vector2.ZERO if art_centered else Vector2(0, body_size.y / 2.0 - drawn.y / 2.0)
		_sprite.position = _sprite_rest
		_sprite.material = Flash.material()
		add_child(_sprite)
		move_child(_sprite, _body.get_index())
		_body.visible = false
		_eye.visible = false
		hurt_size = Vector2(maxf(body_size.x, drawn.x * 0.6), maxf(body_size.y, drawn.y * (0.6 if art_centered else 0.95)))
		_hurtbox.position = Vector2.ZERO if art_centered else Vector2(0, body_size.y / 2.0 - hurt_size.y / 2.0)
		_alert.position.y = body_size.y / 2.0 - drawn.y - 50.0
	_hurtbox.setup(Layers.Team.ENEMIES, hurt_size, self)

	_contact = Area2D.new()
	_contact.collision_layer = 0
	_contact.collision_mask = Layers.PLAYER_HURTBOXES
	_contact.monitorable = false
	var contact_shape := RectangleShape2D.new()
	contact_shape.size = body_size * 0.9
	var contact_collision := CollisionShape2D.new()
	contact_collision.shape = contact_shape
	_contact.add_child(contact_collision)
	add_child(_contact)


func is_alive() -> bool:
	return health != null and not health.is_dead()


func receive_hit(hit: Hit) -> bool:
	if not is_alive():
		return false
	var resisted := hit.shock > 0.0 and not can_be_shocked
	health.damage(roundi(hit.damage * SHOCK_RESIST_DAMAGE) if resisted else hit.damage)
	_flash_timer = 0.1
	if hit.burn > 0.0 and is_alive():
		ignite(hit.burn)
		# A jet of fire licks the enemy many times a second: it burns, but is not
		# thrown about or stopped by every lick.
		_flash_timer = 0.04
		return true
	# Flinch: squashed by the blow and knocked back a little.
	_squash = Vector2(0.14, -0.16)
	_hit_tilt = clampf(hit.knockback.x / 2000.0, -0.3, 0.3)
	if is_alive():
		Sound.play("hit")
	if not super_armor and is_alive():
		velocity = hit.knockback * (1.0 - knockback_resistance)
		stun_timer = hit_stun
		_on_interrupted()
	if hit.shock > 0.0 and is_alive():
		shock(hit.shock)
	return true


func is_burning() -> bool:
	return _burn_timer > 0.0


func is_shocked() -> bool:
	return _shock_timer > 0.0


## Sets the enemy on fire for `duration` seconds (a new flame restarts the time).
func ignite(duration: float) -> void:
	if _burn_timer <= 0.0:
		_burn_tick = BURN_TICK
	_burn_timer = duration


## Stuns with electricity for `duration` seconds, through any armour; then the
## enemy shrugs off shocks for a while. Bosses are not stunned.
func shock(duration: float) -> void:
	if not can_be_shocked or _shock_immunity > 0.0 or not is_alive():
		return
	_shock_timer = duration
	_shock_immunity = duration + SHOCK_IMMUNITY
	stun_timer = maxf(stun_timer, duration)
	_telegraph_timer = 0.0
	_on_interrupted()


func is_telegraphing() -> bool:
	return _telegraph_timer > 0.0


## Starts the warning before an attack: the enemy blinks and shows "!".
func telegraph(duration: float) -> void:
	_telegraph_timer = duration
	Sound.play("telegraph", 0.0)


func _physics_process(delta: float) -> void:
	if not is_alive():
		return
	stun_timer -= delta
	_flash_timer -= delta
	_telegraph_timer -= delta
	_update_status(delta)
	if not is_alive():
		return
	if uses_gravity and not is_on_floor():
		velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)
	if stun_timer > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 1800.0 * delta)
		if not uses_gravity:
			velocity.y = move_toward(velocity.y, 0.0, 1800.0 * delta)
	else:
		_think(delta)
	move_and_slide()
	_deal_contact_damage()
	_update_look()


## Burning ticks away health; flames and sparks show what is going on.
func _update_status(delta: float) -> void:
	_shock_timer -= delta
	_shock_immunity -= delta
	if _burn_timer > 0.0:
		_burn_timer -= delta
		_burn_tick -= delta
		if _burn_tick <= 0.0:
			_burn_tick += BURN_TICK
			_flash_timer = maxf(_flash_timer, 0.05)
			health.damage(BURN_DAMAGE)
			if not is_alive():
				return
	if _burn_timer > 0.0 and _flames == null:
		_flames = _make_flames()
	if _flames != null:
		_flames.emitting = _burn_timer > 0.0
	if _shock_immunity > 0.0 and _sparks == null:
		_sparks = Electric.Sparks.new()
		_sparks.size = _status_area().size
		_sparks.position = _status_area().get_center()
		add_child(_sparks)
	if _sparks != null:
		# Full crackle while stunned, then dying sparks while it cannot be stunned again.
		_sparks.strength = 1.0 if _shock_timer > 0.0 else clampf(_shock_immunity / SHOCK_IMMUNITY, 0.0, 1.0) * 0.35


## Where the enemy is on screen (its picture, or its body), relative to it.
func _status_area() -> Rect2:
	var drawn := art_drawn_size()
	var center := _sprite_rest if _sprite != null else Vector2.ZERO
	return Rect2(center - drawn * 0.35, drawn * 0.7)


func _make_flames() -> CPUParticles2D:
	var area := _status_area()
	var flames := CPUParticles2D.new()
	flames.position = area.get_center() + Vector2(0, area.size.y * 0.2)
	flames.amount = 18
	flames.lifetime = 0.55
	flames.local_coords = false
	flames.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	flames.emission_rect_extents = Vector2(area.size.x * 0.45, area.size.y * 0.3)
	flames.direction = Vector2.UP
	flames.spread = 15.0
	flames.initial_velocity_min = 40.0
	flames.initial_velocity_max = 110.0
	flames.gravity = Vector2(0, -260)
	flames.scale_amount_min = 10.0
	flames.scale_amount_max = 22.0
	flames.scale_amount_curve = Curve.new()
	flames.scale_amount_curve.add_point(Vector2(0, 0.6))
	flames.scale_amount_curve.add_point(Vector2(0.3, 1.0))
	flames.scale_amount_curve.add_point(Vector2(1, 0.1))
	flames.color_ramp = Fx.ramp([Color(1, 0.95, 0.6), Color(1.0, 0.55, 0.12), Color(0.85, 0.18, 0.05, 0.6),
		Color(0.2, 0.15, 0.15, 0.0)])
	flames.material = Fx.additive()
	flames.z_index = 2
	add_child(Fx.soften(flames))
	return flames


## The enemy's behaviour for one physics frame (not called while stunned).
func _think(_delta: float) -> void:
	pass


## Called when a hit interrupts the enemy (not under super armor).
func _on_interrupted() -> void:
	pass


## Walks back and forth, turning at walls and at the edge of a platform.
func patrol(speed: float) -> void:
	if is_on_floor() and (wall_ahead(facing) or not ground_ahead(facing)):
		facing = -facing
	velocity.x = facing * speed


## The closest living hero within `max_distance`, or null.
func nearest_hero(max_distance: float) -> Player:
	var best: Player = null
	var best_distance := max_distance
	for node in get_tree().get_nodes_in_group("players"):
		var hero := node as Player
		if hero == null or not hero.is_alive():
			continue
		var distance := global_position.distance_to(hero.global_position)
		if distance < best_distance:
			best_distance = distance
			best = hero
	return best


## A hero roughly at the same height and within `reach` horizontally.
func hero_in_line(reach: float, height_tolerance := 100.0) -> Player:
	var hero := nearest_hero(reach + height_tolerance)
	if hero == null:
		return null
	var offset := hero.global_position - global_position
	if absf(offset.x) <= reach and absf(offset.y) <= height_tolerance:
		return hero
	return null


func wall_ahead(direction: int) -> bool:
	return test_move(global_transform, Vector2(direction * 4.0, 0.0))


func ground_ahead(direction: int) -> bool:
	var from := global_position + Vector2(direction * (body_size.x / 2.0 + 6.0), 0.0)
	var to := from + Vector2(0.0, body_size.y / 2.0 + 24.0)
	var query := PhysicsRayQueryParameters2D.create(from, to, Layers.GROUND)
	return not get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func _deal_contact_damage() -> void:
	if contact_damage <= 0:
		return
	for area in _contact.get_overlapping_areas():
		var hurtbox := area as Hurtbox
		if hurtbox == null:
			continue
		var side := signf(hurtbox.global_position.x - global_position.x)
		if side == 0.0:
			side = float(facing)
		hurtbox.take_hit(Hit.make(contact_damage, Vector2(side * contact_knockback, -300.0), global_position))


func _update_look() -> void:
	if _sprite != null:
		_animate_sprite()
	var look := color
	var flicker := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.025)
	if _flash_timer > 0.0:
		look = Color.WHITE
	elif is_shocked():
		look = Electric.COLOR if flicker > 0.5 else Electric.CORE
	elif is_burning():
		look = color.lerp(BURN_COLOR, 0.4 + 0.3 * flicker)
	elif is_telegraphing() and int(Time.get_ticks_msec() / 80) % 2 == 0:
		look = TELEGRAPH_COLOR
	_body.color = look
	if _sprite != null:
		if _flash_timer > 0.0:
			Flash.set_flash(_sprite, Color.WHITE, 0.8)
		elif is_shocked():
			Flash.set_flash(_sprite, Electric.COLOR, 0.15 + 0.3 * flicker)
		elif is_burning():
			Flash.set_flash(_sprite, BURN_COLOR, 0.2 + 0.25 * flicker)
		elif is_telegraphing() and int(Time.get_ticks_msec() / 80) % 2 == 0:
			Flash.set_flash(_sprite, TELEGRAPH_COLOR, 0.55)
		else:
			Flash.set_flash(_sprite, Color.WHITE, 0.0)
	_alert.visible = is_telegraphing()
	_eye.position = Vector2(facing * (body_size.x / 2.0 - 14.0) - 5.0, -body_size.y / 2.0 + 12.0)


## The picture's motion, made from the one drawing: it faces the way the
## enemy looks, steps with a bob and a squash, breathes when standing, leans
## into a run, stretches when jumping and squashes on landing, pulls back and
## trembles before an attack, flinches when hit; fliers flap. Enemy types add
## their own touches on top.
func _animate_sprite() -> void:
	var delta := get_physics_process_delta_time()
	var speed := absf(velocity.x)
	_anim_time += delta * (2.0 + speed * 0.04)
	_sprite.flip_h = facing > 0
	var on_floor := is_on_floor() or not uses_gravity
	var bob := absf(sin(_anim_time * 2.0)) * minf(speed, 200.0) * 0.03 if on_floor else 0.0
	var stretch := Vector2.ZERO
	var lean := -facing * clampf(speed / 3000.0, 0.0, 0.18)
	var shake := Vector2.ZERO
	if not uses_gravity:
		# Wings beating: the body pumps up and down.
		bob = sin(_anim_time * 1.0) * 4.0
		var flap := sin(Time.get_ticks_msec() * 0.03)
		stretch = Vector2(-0.04 * flap, 0.08 * flap)
	elif not is_on_floor():
		var rise := clampf(-velocity.y / 2200.0, -0.12, 0.16)
		stretch = Vector2(-rise * 0.6, rise)
	elif speed > 20.0:
		var step := sin(_anim_time * 4.0)
		stretch = Vector2(-0.03 * step, 0.05 * step)
	else:
		var breath := sin(Time.get_ticks_msec() * 0.0035 + get_instance_id())
		stretch = Vector2(0.015 * breath, 0.025 * breath)
	if uses_gravity and is_on_floor() and not _was_on_floor:
		_squash = Vector2(0.16, -0.18)
	_was_on_floor = is_on_floor()
	if is_telegraphing():
		# Gathering itself for the attack: rears back, crouches, trembles.
		lean += facing * -0.12
		stretch += Vector2(0.05, -0.07)
		shake = Vector2(randf_range(-2, 2), 0)
	if is_shocked():
		# Jolted by the current: twitching all over.
		shake = Vector2(randf_range(-3, 3), randf_range(-2, 2))
		stretch += Vector2(randf_range(-0.03, 0.03), randf_range(-0.03, 0.03))
	_squash = _squash.move_toward(Vector2.ZERO, delta * 1.2)
	_hit_tilt = move_toward(_hit_tilt, 0.0, delta * 2.0)
	var total := stretch + _squash
	_sprite.scale = _base_scale * (Vector2.ONE + total)
	# Keep the feet on the floor while the picture changes height.
	var lift := 0.0 if art_centered else total.y * art_drawn_size().y * 0.5 / (1.0 + total.y)
	_sprite.position = _sprite_rest + Vector2(0, -bob - lift) + shake
	_sprite.rotation = lean + _hit_tilt


## A quick jolt of the picture (a spit, a shot): `amount` x wider, y taller.
func punch(amount: Vector2) -> void:
	_squash = amount


func _on_died() -> void:
	Sound.play("enemy_die")
	_leave_corpse()
	_drop_loot()
	died.emit(self)
	queue_free()


## The death: the picture flashes white, topples over away from the hero
## and sinks, fading, while slime and bits burst out. Fliers drop to the ground.
func _leave_corpse() -> void:
	var parent := get_parent()
	if parent == null or _sprite == null:
		return
	var corpse := Sprite2D.new()
	corpse.texture = _sprite.texture
	corpse.flip_h = _sprite.flip_h
	corpse.texture_filter = _sprite.texture_filter
	corpse.global_transform = _sprite.global_transform
	corpse.material = Flash.material()
	Flash.set_flash(corpse, Color.WHITE, 0.9)
	parent.add_child(corpse)
	var fall := 1.35 * (1.0 if _hit_tilt >= 0.0 else -1.0)
	var drop := 0.0 if uses_gravity else 260.0
	var tween := corpse.create_tween().set_parallel()
	tween.tween_method(func(amount: float) -> void: Flash.set_flash(corpse, Color.WHITE, amount), 0.9, 0.0, 0.25)
	tween.tween_property(corpse, "rotation", corpse.rotation + fall, 0.45).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(corpse, "position:y", corpse.position.y + art_drawn_size().y * 0.25 + drop, 0.45) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(corpse, "modulate:a", 0.0, 0.35).set_delay(0.45)
	tween.chain().tween_callback(corpse.queue_free)
	var at := global_position
	# Thrown up and out, short-lived, so they do not sink through the floor.
	Fx.burst(parent, at, [Color(0.6, 1.0, 0.3), Color(0.3, 0.7, 0.1), Color(0.15, 0.35, 0.05, 0.0)], 22, 420.0, 6.0,
		0.45, 1100.0, false, Vector2.UP, 75.0)
	Fx.burst(parent, at, [Color(0.4, 0.25, 0.2), Color(0.25, 0.15, 0.12, 0.0)], 8, 360.0, 5.0, 0.5, 1300.0, false,
		Vector2.UP, 70.0)


func _drop_loot() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var drops: Array = []
	if randf() < GameSettings.health_drop_chance(health_drop_chance):
		drops.append([Pickup.Kind.HEALTH, 3])
	if randf() < ammo_drop_chance:
		drops.append([Pickup.Kind.AMMO, 5])
	# A rare temporary power-up, Contra style.
	if randf() < 0.03:
		drops.append([Pickup.Kind.POWER, 1])
	var scrap := randi_range(scrap_min, scrap_max)
	if scrap > 0:
		drops.append([Pickup.Kind.SCRAP, scrap])
	for i in drops.size():
		var pickup := Pickup.new()
		var launch := Vector2(randf_range(-160.0, 160.0), randf_range(-520.0, -380.0))
		pickup.setup(drops[i][0], drops[i][1], global_position, launch)
		if drops[i][0] == Pickup.Kind.POWER:
			pickup.power = ["rage", "shield", "haste"].pick_random()
		parent.add_child.call_deferred(pickup)
