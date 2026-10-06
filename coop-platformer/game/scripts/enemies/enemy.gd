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

@export var max_health := 6
@export var body_size := Vector2(56, 70)
@export var color := MUTANT_COLOR
@export var contact_damage := 2
@export var contact_knockback := 420.0
## 0 = flies back from every hit, 1 = does not move at all.
@export var knockback_resistance := 0.0
@export var hit_stun := 0.2
@export var uses_gravity := true
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

var _flash_timer := 0.0
var _telegraph_timer := 0.0
var _body: ColorRect
var _eye: ColorRect
var _alert: Label
var _hurtbox: Hurtbox
var _contact: Area2D


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
	_hurtbox.setup(Layers.Team.ENEMIES, body_size, self)

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
	health.damage(hit.damage)
	_flash_timer = 0.1
	if not super_armor and is_alive():
		velocity = hit.knockback * (1.0 - knockback_resistance)
		stun_timer = hit_stun
		_on_interrupted()
	return true


func is_telegraphing() -> bool:
	return _telegraph_timer > 0.0


## Starts the warning before an attack: the enemy blinks and shows "!".
func telegraph(duration: float) -> void:
	_telegraph_timer = duration


func _physics_process(delta: float) -> void:
	if not is_alive():
		return
	stun_timer -= delta
	_flash_timer -= delta
	_telegraph_timer -= delta
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
	var look := color
	if _flash_timer > 0.0:
		look = Color.WHITE
	elif is_telegraphing() and int(Time.get_ticks_msec() / 80) % 2 == 0:
		look = TELEGRAPH_COLOR
	_body.color = look
	_alert.visible = is_telegraphing()
	_eye.position = Vector2(facing * (body_size.x / 2.0 - 14.0) - 5.0, -body_size.y / 2.0 + 12.0)


func _on_died() -> void:
	_drop_loot()
	died.emit(self)
	queue_free()


func _drop_loot() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var drops: Array = []
	if randf() < GameSettings.health_drop_chance(health_drop_chance):
		drops.append([Pickup.Kind.HEALTH, 3])
	if randf() < ammo_drop_chance:
		drops.append([Pickup.Kind.AMMO, 5])
	var scrap := randi_range(scrap_min, scrap_max)
	if scrap > 0:
		drops.append([Pickup.Kind.SCRAP, scrap])
	for i in drops.size():
		var pickup := Pickup.new()
		var launch := Vector2(randf_range(-160.0, 160.0), randf_range(-520.0, -380.0))
		pickup.setup(drops[i][0], drops[i][1], global_position, launch)
		parent.add_child.call_deferred(pickup)
