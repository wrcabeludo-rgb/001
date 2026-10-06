class_name Hazard
extends Node2D
## Spikes or acid along a row of tiles. Touching it hurts a hero and throws
## them up and towards the nearer edge, so they can always climb out.

enum Kind { SPIKES, ACID }

const SPIKE_COLOR := Color(0.78, 0.8, 0.86)
const ACID_COLOR := Color(0.45, 1.0, 0.25, 0.75)
const SPIKE_HEIGHT := 26.0
const ACID_DEPTH := 40.0

var kind: Kind = Kind.SPIKES
var damage := 2
var throw_up := 900.0
var throw_side := 380.0
## The dangerous area in world coordinates.
var rect := Rect2()

var _surface: ColorRect


## `cells` is the row of tiles; the danger fills its bottom part.
func setup(p_kind: Kind, cells: Rect2) -> void:
	kind = p_kind
	var height := SPIKE_HEIGHT if kind == Kind.SPIKES else ACID_DEPTH
	rect = Rect2(cells.position.x, cells.end.y - height, cells.size.x, height)
	if kind == Kind.ACID:
		throw_up = 1000.0


func _ready() -> void:
	if kind == Kind.SPIKES:
		var x := rect.position.x
		while x < rect.end.x - 1.0:
			add_child(Harm.spike(Vector2(x, rect.end.y), 20.0, SPIKE_HEIGHT, SPIKE_COLOR))
			x += 20.0
	else:
		_surface = Harm.box(rect.position, rect.size, ACID_COLOR)
		add_child(_surface)


func _physics_process(_delta: float) -> void:
	if _surface != null:
		_surface.color.a = 0.65 + 0.15 * sin(Time.get_ticks_msec() * 0.004)
	for hurtbox in Harm.hurtboxes_in_rect(get_world_2d(), rect, Harm.HEROES):
		var x := hurtbox.global_position.x
		var side := -1.0 if x - rect.position.x < rect.end.x - x else 1.0
		hurtbox.take_hit(Hit.make(damage, Vector2(side * throw_side, -throw_up), hurtbox.global_position))
