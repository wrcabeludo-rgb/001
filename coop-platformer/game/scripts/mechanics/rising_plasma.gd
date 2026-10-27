class_name RisingPlasma
extends Node2D
## The Heart's plasma filling the lift shaft from below (zone 3-2). Once a hero
## climbs above the start, it rises steadily; touching it hurts and throws the
## hero up. It never falls far behind the slowest hero, and after a team wipe
## it sinks back below the checkpoint.

const COLOR := Color(1.0, 0.25, 0.6)
const HOT := Color(1.0, 0.85, 0.95)

@export var speed := 45.0
## It never lags more than this below the lowest hero.
@export var max_lag := 760.0
@export var damage := 2

## Left and right edge of the shaft (world x) and the start (world y of the surface).
var left := 0.0
var right := 0.0
var start_y := 0.0
var surface := 0.0
var running := false

var _time := 0.0


func setup(p_left: float, p_right: float, p_start_y: float) -> void:
	left = p_left
	right = p_right
	start_y = p_start_y
	surface = p_start_y


func _ready() -> void:
	add_to_group("resettable")
	z_index = 4


## After a team wipe: back below the checkpoint (or the start), waiting again.
func reset() -> void:
	running = false
	var level := get_parent() as Level
	var floor_y := start_y
	if level != null and level.active_checkpoint != null:
		floor_y = minf(start_y, level.active_checkpoint.global_position.y + 420.0)
	surface = floor_y


func _physics_process(delta: float) -> void:
	_time += delta
	var lowest := -INF
	var any := false
	for node in get_tree().get_nodes_in_group("players"):
		var hero := node as Player
		if hero == null or not hero.is_alive() or hero.global_position.x < left or hero.global_position.x > right:
			continue
		any = true
		lowest = maxf(lowest, hero.global_position.y)
	if not running and any and lowest < surface - 260.0:
		running = true
		Sound.play("boss_roar", 0.0, -6.0, 1.6)
		var level := get_parent() as Level
		if level != null:
			level.show_toast("Плазма поднимается — наверх!", 2.5)
	if running:
		surface -= speed * delta
		if any:
			surface = minf(surface, lowest + max_lag)
	for hurtbox in Harm.hurtboxes_in_rect(get_world_2d(), Rect2(left, surface, right - left, 4000.0), Harm.HEROES):
		hurtbox.take_hit(Hit.make(damage, Vector2(0, -1250.0), Vector2(hurtbox.global_position.x, surface + 40.0)))
	queue_redraw()


func _draw() -> void:
	var waves := PackedVector2Array()
	var steps := int((right - left) / 24.0)
	for i in steps + 1:
		var x := left + (right - left) * float(i) / steps
		waves.append(Vector2(x, surface + 6.0 * sin(_time * 3.0 + x * 0.03)))
	var body := waves.duplicate()
	body.append(Vector2(right, surface + 3000.0))
	body.append(Vector2(left, surface + 3000.0))
	draw_colored_polygon(body, Color(COLOR, 0.75))
	draw_polyline(waves, HOT, 5.0)
	draw_rect(Rect2(left, surface + 40.0, right - left, 3000.0), Color(0.45, 0.05, 0.25, 0.6))
