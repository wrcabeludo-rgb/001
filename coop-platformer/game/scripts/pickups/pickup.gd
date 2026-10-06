class_name Pickup
extends Area2D
## Loot dropped by enemies: a health kit, ammo or scrap. It pops out, falls to
## the floor and is taken by the first hero who can use it (ammo only by the
## Gunner, a health kit only by a hurt hero). It blinks and vanishes after a while.

enum Kind { HEALTH, AMMO, SCRAP, POWER }

const SIZE := Vector2(26, 26)
const LIFETIME := 15.0
const GRAVITY := 2000.0
const LOOKS := {
	Kind.HEALTH: [Color(0.95, 0.25, 0.3), "+"],
	Kind.AMMO: [Color(0.3, 0.9, 1.0), "П"],
	Kind.SCRAP: [Color(0.7, 0.7, 0.75), "Л"],
	Kind.POWER: [Color.WHITE, "?"],
}

var kind: Kind = Kind.SCRAP
## For a power-up: "rage", "shield" or "haste" (see Player.POWER_TIME).
var power := ""

const POWER_GLYPHS := {"rage": "Я", "shield": "Щ", "haste": "С"}
var amount := 1
var velocity := Vector2.ZERO
## Placed on the map by the level designer: never blinks out.
var permanent := false

var _age := 0.0
var _landed := false


func setup(p_kind: Kind, p_amount: int, at: Vector2, launch: Vector2) -> void:
	kind = p_kind
	amount = p_amount
	position = at
	velocity = launch


func _ready() -> void:
	add_to_group("pickups")
	collision_layer = 0
	collision_mask = Layers.PLAYER_BODIES
	monitorable = false
	var shape := RectangleShape2D.new()
	shape.size = SIZE + Vector2(10, 10)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)

	var box := ColorRect.new()
	box.size = SIZE
	box.position = -SIZE / 2
	box.color = LOOKS[kind][0] if kind != Kind.POWER else Player.POWER_COLORS.get(power, Color.WHITE)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	var sign_label := Label.new()
	sign_label.text = LOOKS[kind][1] if kind != Kind.POWER else POWER_GLYPHS.get(power, "?")
	sign_label.size = SIZE
	sign_label.position = -SIZE / 2 + Vector2(0, -4)
	sign_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sign_label.add_theme_font_size_override("font_size", 20)
	sign_label.add_theme_color_override("font_color", Color(0.05, 0.05, 0.08))
	add_child(sign_label)


func _physics_process(delta: float) -> void:
	if not permanent:
		_age += delta
	if _age > LIFETIME:
		queue_free()
		return
	modulate.a = 0.3 if _age > LIFETIME - 3.0 and int(_age * 8.0) % 2 == 0 else 1.0
	if not _landed:
		_fall(delta)
	for body in get_overlapping_bodies():
		var hero := body as Player
		if hero != null and hero.is_alive() and _give_to(hero):
			Sound.play(["pickup_health", "pickup_ammo", "pickup_scrap", "charge_ready"][kind], 0.0)
			queue_free()
			return


func _fall(delta: float) -> void:
	velocity.y = minf(velocity.y + GRAVITY * delta, 1200.0)
	velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
	var motion := velocity * delta
	var space := get_world_2d().direct_space_state
	# Stop at walls sideways, land on the floor below.
	var side := PhysicsRayQueryParameters2D.create(global_position,
		global_position + Vector2(motion.x + signf(motion.x) * SIZE.x / 2.0, 0.0), Layers.WORLD)
	if motion.x != 0.0 and not space.intersect_ray(side).is_empty():
		velocity.x = 0.0
		motion.x = 0.0
	if motion.y > 0.0:
		var down := PhysicsRayQueryParameters2D.create(global_position,
			global_position + Vector2(0.0, motion.y + SIZE.y / 2.0), Layers.GROUND)
		var hit := space.intersect_ray(down)
		if not hit.is_empty():
			global_position.y = hit["position"].y - SIZE.y / 2.0
			global_position.x += motion.x
			_landed = true
			return
	global_position += motion


## Returns true if the hero took it.
func _give_to(hero: Player) -> bool:
	match kind:
		Kind.HEALTH:
			if hero.health.current >= hero.health.maximum:
				return false
			hero.health.heal(amount)
		Kind.AMMO:
			var shooter := hero.combat as ShooterCombat
			if shooter == null or shooter.ammo >= shooter.max_ammo():
				return false
			shooter.add_ammo(amount)
		Kind.SCRAP:
			hero.scrap += amount
		Kind.POWER:
			hero.give_power(power)
			var level := get_parent() as Level
			if level != null:
				level.show_toast("P%d: %s" % [hero.slot + 1, Player.POWER_NAMES.get(power, power)])
	return true
