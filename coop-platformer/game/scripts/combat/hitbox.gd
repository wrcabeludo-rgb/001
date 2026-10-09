class_name Hitbox
extends Area2D
## A melee attack area. While active it damages the other team's hurtboxes,
## each target at most once per activation. Shown as a translucent flash.

signal landed(hurtbox: Hurtbox)

var damage := 1
## Knockback for an attack facing right; x is mirrored by the attack direction.
var knockback := Vector2.ZERO
var direction := 1

## Where the area sits for an attack facing right (x is mirrored).
var offset := Vector2.ZERO
## False when the attack draws its own effect (a slash arc) instead of the flash.
var show_flash := true
## Passed on to every hit (see Hit): seconds of burning / of electric stun.
var burn := 0.0
var shock := 0.0
var _active_time := 0.0
var _already_hit := {}
var _shape: CollisionShape2D
var _flash: ColorRect


func setup(team: Layers.Team, size: Vector2, p_offset: Vector2, color: Color) -> void:
	collision_layer = 0
	collision_mask = Layers.target_hurtboxes(team)
	monitorable = false
	offset = p_offset

	var rect := RectangleShape2D.new()
	rect.size = size
	_shape = CollisionShape2D.new()
	_shape.shape = rect
	add_child(_shape)

	_flash = ColorRect.new()
	_flash.size = size
	_flash.color = Color(color, 0.45)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.visible = false
	add_child(_flash)
	_place()


func activate(duration: float, p_damage: int, p_knockback: Vector2, p_direction: int) -> void:
	damage = p_damage
	knockback = p_knockback
	direction = p_direction
	_already_hit.clear()
	_active_time = duration
	_place()
	_flash.visible = show_flash


func is_active() -> bool:
	return _active_time > 0.0


func _physics_process(delta: float) -> void:
	if _active_time <= 0.0:
		return
	_active_time -= delta
	for area in get_overlapping_areas():
		var hurtbox := area as Hurtbox
		if hurtbox == null or _already_hit.has(hurtbox):
			continue
		_already_hit[hurtbox] = true
		var hit := Hit.make(damage, Vector2(knockback.x * direction, knockback.y), global_position)
		hit.burn = burn
		hit.shock = shock
		if hurtbox.take_hit(hit):
			landed.emit(hurtbox)
	if _active_time <= 0.0:
		_flash.visible = false


func _place() -> void:
	var position_offset := Vector2(offset.x * direction, offset.y)
	_shape.position = position_offset
	_flash.position = position_offset - _flash.size / 2.0
