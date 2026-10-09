class_name ElectroFloor
extends StaticBody2D
## A strip of electrified floor. On a timer: dead, then blue lights flicker
## (warning), then current runs along it and zaps whoever stands on it.

enum State { OFF, WARNING, ON }

const PLATE := Color(0.2, 0.22, 0.27)
const COPPER := Color(0.75, 0.45, 0.25)
const ZAP_HEIGHT := 40.0

@export var off_time := 2.0
@export var warning_time := 0.6
@export var on_time := 1.4
@export var damage := 2

var state := State.OFF
## The floor cells, in parent coordinates.
var rect := Rect2()

var _timer := 0.0
var _bolts: Array[PackedVector2Array] = []
var _bolt_timer := 0.0


func setup(cells: Rect2, phase := 0.0) -> void:
	rect = cells
	_timer = off_time - phase


func _ready() -> void:
	collision_layer = Layers.WORLD
	collision_mask = 0
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.position = rect.get_center()
	add_child(collision)
	var art := Harm.tiled_prop("electro_floor", rect.position, Vector2(rect.size.x, 40.0))
	if art != null:
		add_child(art)


func cycle_time() -> float:
	return off_time + warning_time + on_time


## The dangerous strip just above the floor, in world coordinates.
func zap_rect() -> Rect2:
	return Rect2(global_position + rect.position - Vector2(0, ZAP_HEIGHT), Vector2(rect.size.x, ZAP_HEIGHT))


func _physics_process(delta: float) -> void:
	_timer -= delta
	match state:
		State.OFF:
			if _timer <= 0.0:
				state = State.WARNING
				_timer += warning_time
		State.WARNING:
			if _timer <= 0.0:
				state = State.ON
				_timer += on_time
				Sound.play("shock", 0.1, -6.0, 0.8)
		State.ON:
			for hurtbox in Harm.hurtboxes_in_rect(get_world_2d(), zap_rect(), Harm.HEROES):
				var side := -1.0 if hurtbox.global_position.x < zap_rect().get_center().x else 1.0
				hurtbox.take_hit(Hit.make(damage, Vector2(side * 260.0, -620.0), hurtbox.global_position))
			if _timer <= 0.0:
				state = State.OFF
				_timer += off_time
	_bolt_timer -= delta
	if _bolt_timer <= 0.0:
		_bolt_timer = 0.05
		_bolts.clear()
		if state == State.ON:
			var x := rect.position.x + randf_range(0.0, 50.0)
			while x < rect.end.x - 20.0:
				var length := randf_range(40.0, 90.0)
				var end := minf(x + length, rect.end.x)
				_bolts.append(Electric.bolt(Vector2(x, rect.position.y - 4.0), Vector2(end, rect.position.y - 4.0),
					5, 14.0))
				x = end + randf_range(10.0, 40.0)
	queue_redraw()


func _draw() -> void:
	if get_child_count() < 2:
		draw_rect(rect, PLATE)
		draw_rect(Rect2(rect.position + Vector2(0, 4), Vector2(rect.size.x, 5)), COPPER)
		draw_rect(Rect2(rect.position + Vector2(0, 14), Vector2(rect.size.x, 5)), COPPER.darkened(0.3))
		for end in [rect.position.x, rect.end.x - 14.0]:
			draw_rect(Rect2(end, rect.position.y, 14.0, rect.size.y), Conveyor.HAZARD_YELLOW.darkened(0.2))
	# Blue indicator lights along the strip.
	var lit := state == State.ON or (state == State.WARNING and int(Time.get_ticks_msec() / 80) % 2 == 0)
	var x := rect.position.x + 40.0
	while x < rect.end.x - 20.0:
		draw_circle(Vector2(x, rect.position.y + 28.0), 4.0, Electric.COLOR if lit else Electric.COLOR.darkened(0.7))
		x += 60.0
	if state == State.ON:
		draw_rect(Rect2(rect.position - Vector2(0, 10), Vector2(rect.size.x, 12)), Color(Electric.COLOR, 0.2))
	for points in _bolts:
		Electric.draw_bolt(self, points, 2.0)
