class_name Chase
extends Node2D
## The chase of world 2: once a hero passes the trigger, a giant loader smashes
## its way into the hall behind the team and rolls after them, crushing the
## factory and throwing crates ahead. A hero it catches is hurt and flung
## forward (never trapped behind it). It stops at the end of the chase (the
## boss hall gate) and drives off; a team wipe sets the chase back.

const LOOK_SIZE := Vector2(560, 420)
const BODY := Color(0.36, 0.4, 0.48)
const DARK := Color(0.17, 0.18, 0.22)
const HAZARD_YELLOW := Color(1.0, 0.79, 0.24)
const VISOR := Color(1.0, 0.15, 0.12)

@export var speed := 250.0
## Faster when the team runs far ahead, so the pressure never lets up.
@export var catch_up_speed := 430.0
@export var throw_interval := 2.4
@export var damage := 2

## World x of the trigger line, where the loader appears and where it stops.
var trigger_x := 0.0
var start_x := 0.0
var stop_x := 0.0
## World y of the floor the loader rolls on.
var floor_y := 0.0

var running := false
var finished := false

var _x := 0.0
var _throw_timer := 0.0
var _shake_timer := 0.0
var _time := 0.0
var _art: Sprite2D
var _dust: CPUParticles2D
var _smoke: CPUParticles2D
## Half the machine's width (the drawing's, once it is drawn).
var _half_width := LOOK_SIZE.x / 2.0


func setup(p_trigger_x: float, p_start_x: float, p_stop_x: float, p_floor_y: float) -> void:
	trigger_x = p_trigger_x
	start_x = p_start_x
	stop_x = p_stop_x
	floor_y = p_floor_y


func _ready() -> void:
	add_to_group("resettable")
	z_index = 5
	var path := "res://assets/art/enemies/boss_loader.png"
	if ResourceLoader.exists(path):
		_art = Sprite2D.new()
		_art.texture = load(path)
		_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		_art.flip_h = true
		var factor := LOOK_SIZE.y / _art.texture.get_height()
		_art.scale = Vector2(factor, factor)
		add_child(_art)
		var drawn := _art.texture.get_size() * factor
		_half_width = drawn.x / 2.0
		# Flipped to face right: the stacks are at the back, on the left.
		_smoke = Fx.smoke(14, 30.0)
		_smoke.position = Vector2(-0.36 * drawn.x, -0.2 * drawn.y)
		_smoke.emitting = false
		add_child(_smoke)
	_dust = CPUParticles2D.new()
	_dust.amount = 30
	_dust.lifetime = 0.9
	_dust.local_coords = false
	_dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_dust.emission_rect_extents = Vector2(30, LOOK_SIZE.y * 0.4)
	_dust.direction = Vector2(1, -0.5)
	_dust.spread = 40.0
	_dust.initial_velocity_min = 150.0
	_dust.initial_velocity_max = 420.0
	_dust.gravity = Vector2(0, 900)
	_dust.scale_amount_min = 4.0
	_dust.scale_amount_max = 12.0
	_dust.color_ramp = Fx.ramp([Color(0.6, 0.58, 0.55, 0.9), Color(0.4, 0.38, 0.36, 0.0)])
	_dust.emitting = false
	add_child(Fx.soften(_dust))
	visible = false


## The loader's front (its forks), in world x.
func front_x() -> float:
	return _x + _half_width


func reset() -> void:
	running = false
	finished = false
	visible = false
	_dust.emitting = false
	if _smoke != null:
		_smoke.emitting = false


func _physics_process(delta: float) -> void:
	if finished:
		return
	var heroes := _alive_heroes()
	if not running:
		for hero in heroes:
			if hero.global_position.x > trigger_x:
				_start()
				break
		return
	_time += delta
	# Faster while the slowest hero is far ahead.
	var slowest := INF
	for hero in heroes:
		slowest = minf(slowest, hero.global_position.x)
	var pace := catch_up_speed if slowest - front_x() > 1100.0 else speed
	_x += pace * delta
	position = Vector2(_x, floor_y - LOOK_SIZE.y / 2.0)
	for hero in heroes:
		if hero.global_position.x - Player.SIZE.x / 2.0 < front_x():
			hero.receive_hit(Hit.make(damage, Vector2(1100, -650), Vector2(front_x() - 100.0, hero.global_position.y)))
			# Never left behind the machine: always thrown out in front.
			if hero.global_position.x < front_x() + 30.0:
				hero.global_position.x = front_x() + 30.0
				hero.velocity.x = maxf(hero.velocity.x, 900.0)
	_throw_timer -= delta
	if _throw_timer <= 0.0:
		_throw_timer = throw_interval
		_throw(heroes)
	_shake_timer -= delta
	if _shake_timer <= 0.0:
		_shake_timer = 0.5
		get_tree().call_group("cameras", "shake", 3.0)
		Sound.play("crumble", 0.15, -4.0, 0.7)
	if front_x() >= stop_x:
		_finish()
	queue_redraw()


func _start() -> void:
	running = true
	visible = true
	_x = start_x
	_throw_timer = 1.2
	position = Vector2(_x, floor_y - LOOK_SIZE.y / 2.0)
	_dust.position = Vector2(_half_width, 0)
	_dust.emitting = true
	if _smoke != null:
		_smoke.emitting = true
	Sound.play("boss_roar", 0.0, 0.0, 0.7)
	Sound.music("boss_2")
	get_tree().call_group("cameras", "shake", 14.0)
	var level := get_parent() as Level
	if level != null:
		level.show_toast("БЕГИ!", 2.5)


## A crate thrown ahead, in an arc, to land near a hero.
func _throw(heroes: Array[Player]) -> void:
	if heroes.is_empty():
		return
	var target: Player = heroes.pick_random()
	var from := Vector2(front_x() - 60.0, floor_y - LOOK_SIZE.y * 0.95)
	var crate := CrateChute.FallingCrate.new()
	crate.position = from
	var flight := 0.9
	var aim_x := target.global_position.x + target.velocity.x * flight * 0.6
	crate.drift = (aim_x - from.x) / flight
	crate.velocity.y = -700.0
	get_parent().add_child(crate)
	Sound.play("kick", 0.1, -2.0, 0.6)


func _finish() -> void:
	finished = true
	running = false
	_dust.emitting = false
	if _smoke != null:
		_smoke.emitting = false
	Fx.burst(get_parent(), Vector2(front_x(), floor_y - 100.0), [Color(0.6, 0.58, 0.55, 0.9), Color(0.4, 0.38, 0.36, 0.0)],
		30, 500.0, 14.0, 1.0, 300.0, false, Vector2.UP, 90.0)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.6)
	tween.tween_callback(_hide)


func _hide() -> void:
	visible = false
	modulate.a = 1.0


func _alive_heroes() -> Array[Player]:
	var result: Array[Player] = []
	for node in get_tree().get_nodes_in_group("players"):
		var hero := node as Player
		if hero != null and hero.is_alive():
			result.append(hero)
	return result


func _draw() -> void:
	if _art != null or not visible:
		return
	Chase.draw_loader(self, LOOK_SIZE, _time)


## Stand-in drawing of the loader until its picture is drawn (also used by the
## boss): tracks, a body with hazard stripes, a cab with a red visor, forks in
## front (facing right), centred on the origin.
static func draw_loader(canvas: CanvasItem, size: Vector2, time: float) -> void:
	canvas.draw_set_transform(Vector2.ZERO, 0.0, size / LOOK_SIZE)
	_draw_loader_shape(canvas, time)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _draw_loader_shape(canvas: CanvasItem, time: float) -> void:
	var half := LOOK_SIZE / 2.0
	# Tracks.
	canvas.draw_rect(Rect2(-half.x, half.y - 90, LOOK_SIZE.x * 0.85, 90), DARK)
	for i in 9:
		var x := -half.x + 30.0 + i * 52.0
		var spin := fmod(time * 6.0 + i, TAU)
		canvas.draw_circle(Vector2(x, half.y - 45), 28.0, Color(0.28, 0.29, 0.33))
		canvas.draw_line(Vector2(x, half.y - 45), Vector2(x, half.y - 45) + Vector2.from_angle(spin) * 24.0, DARK, 4.0)
	# Body and cab.
	canvas.draw_rect(Rect2(-half.x + 10, -half.y + 120, LOOK_SIZE.x * 0.75, LOOK_SIZE.y - 210), BODY)
	canvas.draw_rect(Rect2(-half.x + 10, -half.y + 120, LOOK_SIZE.x * 0.75, 10), BODY.lightened(0.25))
	var x0 := -half.x + 20.0
	while x0 < -half.x + LOOK_SIZE.x * 0.75:
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(x0, half.y - 100), Vector2(x0 + 20, half.y - 130),
			Vector2(x0 + 40, half.y - 130), Vector2(x0 + 20, half.y - 100)]), HAZARD_YELLOW)
		x0 += 50.0
	canvas.draw_rect(Rect2(half.x - 250, -half.y + 20, 150, 120), BODY.darkened(0.15))
	var visor := VISOR if int(time * 6.0) % 2 == 0 else VISOR.darkened(0.3)
	canvas.draw_rect(Rect2(half.x - 235, -half.y + 60, 120, 22), visor)
	# Smoke stack and forks.
	canvas.draw_rect(Rect2(-half.x + 40, -half.y - 10, 36, 140), DARK)
	canvas.draw_rect(Rect2(half.x - 120, half.y - 150, 120, 18), Color(0.55, 0.57, 0.62))
	canvas.draw_rect(Rect2(half.x - 120, half.y - 70, 120, 18), Color(0.55, 0.57, 0.62))
	canvas.draw_rect(Rect2(half.x - 130, half.y - 170, 20, 140), DARK)
