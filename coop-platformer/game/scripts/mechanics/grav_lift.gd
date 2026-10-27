class_name GravLift
extends Node2D
## A column of magenta light (world 3): a hero inside floats gently upwards to
## its top, where they can step off. Drifting particles show which way it pulls.

const COLOR := Color(1.0, 0.3, 0.65)
const RISE_SPEED := 330.0

## The column in world coordinates (from the floor up to the ceiling).
var rect := Rect2()

var _motes: CPUParticles2D


func setup(column: Rect2) -> void:
	rect = column


func _ready() -> void:
	_motes = CPUParticles2D.new()
	_motes.position = Vector2(rect.get_center().x, rect.end.y)
	_motes.amount = maxi(8, int(rect.size.y / 30.0))
	_motes.lifetime = rect.size.y / 220.0
	_motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_motes.emission_rect_extents = Vector2(rect.size.x * 0.4, 4)
	_motes.direction = Vector2.UP
	_motes.spread = 3.0
	_motes.initial_velocity_min = 200.0
	_motes.initial_velocity_max = 240.0
	_motes.gravity = Vector2.ZERO
	_motes.scale_amount_min = 3.0
	_motes.scale_amount_max = 6.0
	_motes.color_ramp = Fx.ramp([Color(COLOR, 0.0), Color(COLOR, 0.9), Color(1, 0.9, 1, 0.0)])
	_motes.material = Fx.additive()
	add_child(Fx.soften(_motes))


func _physics_process(_delta: float) -> void:
	for node in get_tree().get_nodes_in_group("players"):
		var hero := node as Player
		if hero == null or not hero.is_alive():
			continue
		var p := hero.global_position
		if p.x > rect.position.x and p.x < rect.end.x and p.y > rect.position.y + 30.0 and p.y < rect.end.y:
			hero.launch(-RISE_SPEED)
	queue_redraw()


func _draw() -> void:
	var pulse := 0.7 + 0.3 * sin(Time.get_ticks_msec() * 0.004)
	draw_rect(rect, Color(COLOR, 0.1 * pulse))
	draw_rect(Rect2(rect.position + Vector2(rect.size.x * 0.3, 0), Vector2(rect.size.x * 0.4, rect.size.y)),
		Color(COLOR, 0.08 * pulse))
	draw_rect(Rect2(Vector2(rect.position.x - 6, rect.end.y - 10), Vector2(rect.size.x + 12, 10)), Color(0.2, 0.2, 0.26))
	draw_rect(Rect2(Vector2(rect.position.x, rect.end.y - 8), Vector2(rect.size.x, 3)), COLOR)
