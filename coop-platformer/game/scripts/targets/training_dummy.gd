class_name TrainingDummy
extends Node2D
## A practice target: takes hits, shows a health bar and floating damage numbers,
## flinches when hit and comes back a moment after it is destroyed.

const SIZE := Vector2(52, 100)
const COLOR := Color(0.55, 0.35, 0.6)
const RESPAWN_TIME := 2.0

@export var max_health := 20
@export var body_size := SIZE

var health: Health

var _body: ColorRect
var _bar_fill: ColorRect
var _hurtbox: Hurtbox
var _flash_timer := 0.0
var _flinch := 0.0
var _respawn_timer := 0.0


func _ready() -> void:
	health = Health.new()
	add_child(health)
	health.reset(max_health)
	health.died.connect(_on_died)

	_body = ColorRect.new()
	_body.size = body_size
	_body.position = -body_size / 2
	_body.color = COLOR
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_body)

	var bar_back := ColorRect.new()
	bar_back.size = Vector2(body_size.x + 10, 8)
	bar_back.position = Vector2(-bar_back.size.x / 2, -body_size.y / 2 - 18)
	bar_back.color = Color(0, 0, 0, 0.6)
	add_child(bar_back)
	_bar_fill = ColorRect.new()
	_bar_fill.size = bar_back.size
	_bar_fill.position = bar_back.position
	_bar_fill.color = Color(1.0, 0.18, 0.53)
	add_child(_bar_fill)

	_hurtbox = Hurtbox.new()
	add_child(_hurtbox)
	_hurtbox.setup(Layers.Team.ENEMIES, body_size, self)


func receive_hit(hit: Hit) -> bool:
	if health.is_dead():
		return false
	health.damage(hit.damage)
	_flash_timer = 0.08
	_flinch = signf(hit.knockback.x) * 10.0
	_show_damage(hit.damage)
	return true


func _process(delta: float) -> void:
	_flash_timer -= delta
	_flinch = move_toward(_flinch, 0.0, 80.0 * delta)
	_body.color = Color.WHITE if _flash_timer > 0.0 else COLOR
	_body.position = -body_size / 2 + Vector2(_flinch, 0)
	_bar_fill.size.x = (body_size.x + 10) * health.ratio()

	if health.is_dead():
		_respawn_timer -= delta
		if _respawn_timer <= 0.0:
			health.reset(max_health)
			visible = true
			_hurtbox.set_deferred("monitorable", true)


func _on_died() -> void:
	visible = false
	_respawn_timer = RESPAWN_TIME
	_hurtbox.set_deferred("monitorable", false)


func _show_damage(amount: int) -> void:
	var label := Label.new()
	label.text = str(amount)
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	label.position = Vector2(randf_range(-30, 10), -body_size.y / 2 - 50)
	get_parent().add_child(label)
	label.global_position = global_position + label.position
	var tween := label.create_tween()
	tween.tween_property(label, "position:y", label.position.y - 50, 0.6)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.6)
	tween.tween_callback(label.queue_free)
