extends "res://tests/test_harness.gd"
## Not a test: renders frames of a level with heroes and enemies into PNG files,
## to look at the art without the game window. Needs a display (xvfb-run):
##   xvfb-run -a godot --path game res://tests/screenshot.tscn -- out=/tmp/shot

var _out := "/tmp/shot"


func _init() -> void:
	room_scene = preload("res://scenes/slums_level.tscn")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("out="):
			_out = arg.substr(4)


func _run_all() -> void:
	var level := _room as Level
	await _spawn(Heroes.Id.SHOOTER, Vector2(600, 25 * 60 - 48 + 60))
	var partner := _spawn_extra(Heroes.Id.SWORDSMAN, Vector2(760, 26 * 60 - 48))
	for letter in ["w", "c"]:
		level.spawn_enemy(letter, Vector2(1000 + (0 if letter == "w" else 220), 26 * 60))
	var hanging := level.spawn_enemy("a", Level.cell_floor(14, 20))
	var _keep := [partner, hanging]
	level.camera.follow([_player, partner], 0.0, true)
	await _frames(20)
	await _save("idle")
	_input.set_virtual("right", true)
	_extra_inputs[0].set_virtual("right", true)
	await _frames(14)
	await _save("run")
	_input.set_virtual("jump", true)
	await _frames(10)
	await _save("jump")
	_input.set_virtual("attack", true)
	_extra_inputs[0].set_virtual("attack", true)
	await _frames(3)
	await _save("attack")


func _save(tag: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s_%s.png" % [_out, tag])
	print("saved ", tag)
