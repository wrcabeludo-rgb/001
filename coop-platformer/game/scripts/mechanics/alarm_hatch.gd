class_name AlarmHatch
extends Node2D
## A security room hatch in a wall (world 3): on an alarm its lamp spins red
## and guards run out of it.

const LAMP := Color(1.0, 0.2, 0.15)


var _flash := 0.0
var _next := 0


func _ready() -> void:
	var art := Harm.prop_sprite("alarm_hatch", Vector2(80, 160))
	if art != null:
		var factor := 160.0 / art.texture.get_height()
		art.scale = Vector2(factor, factor)
		art.position = Vector2(0, -80)
		add_child(art)


## Sends out `count` guards, one after another.
func release(count: int) -> void:
	_flash = 2.0
	var level := get_parent() as Level
	if level == null:
		return
	for i in count:
		var letter: String = ["N", "y"][_next % 2]
		_next += 1
		var guard := level.spawn_enemy(letter, global_position + Vector2(i * 50.0 - 25.0, 0))
		if guard != null:
			guard.facing = 1 if i % 2 == 0 else -1
	Sound.play("door", 0.0)


func _process(delta: float) -> void:
	_flash -= delta
	queue_redraw()


func _draw() -> void:
	if get_child_count() == 0:
		draw_rect(Rect2(-40, -160, 80, 160), Color(0.18, 0.18, 0.23))
		draw_rect(Rect2(-34, -150, 68, 150), Color(0.25, 0.25, 0.3))
	var on := _flash > 0.0 and int(_flash * 8.0) % 2 == 0
	draw_circle(Vector2(0, -172), 9.0, LAMP if on else LAMP.darkened(0.7))
	if on:
		draw_circle(Vector2(0, -172), 22.0, Color(LAMP, 0.25))
