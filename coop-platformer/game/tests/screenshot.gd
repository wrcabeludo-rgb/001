extends "res://tests/test_harness.gd"
## Not a test: renders frames of a level with heroes and enemies into PNG files,
## to look at the art without the game window. Needs a display (xvfb-run):
##   xvfb-run -a godot --path game res://tests/screenshot.tscn -- out=/tmp/shot

var _out := "/tmp/shot"
## Where the heroes stand: column and the row of the floor surface.
var _spot := Vector2i(10, 26)
## Enemy letters to line up (lineup=W,G,K), instead of the default lineup.
var _lineup: PackedStringArray = []


func _init() -> void:
	room_scene = preload("res://scenes/slums_level.tscn")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("out="):
			_out = arg.substr(4)
		elif arg.begins_with("scene="):
			room_scene = load("res://scenes/%s.tscn" % arg.substr(6))
		elif arg.begins_with("lineup="):
			_lineup = arg.substr(7).split(",")
		elif arg.begins_with("spot="):
			var parts := arg.substr(5).split(",")
			_spot = Vector2i(int(parts[0]), int(parts[1]))


func _run_all() -> void:
	var level := _room as Level
	var floor_y := _spot.y * 60.0
	var x := (_spot.x + 0.5) * 60.0
	await _spawn(Heroes.Id.SHOOTER, Vector2(x, floor_y - 48))
	var partner := _spawn_extra(Heroes.Id.SWORDSMAN, Vector2(x + 160, floor_y - 48))
	if OS.get_cmdline_user_args().has("live"):
		# The map's own enemies around the spot instead of the lineup.
		var map := level.get_map()
		for row in map.size():
			for col in range(maxi(0, _spot.x - 10), mini(map[row].length(), _spot.x + 30)):
				level.spawn_enemy(map[row][col], Level.cell_floor(col, row))
	elif _lineup.size() > 0:
		# Chosen enemies in a row; fliers float, ceiling turrets hang from row 10.
		for i in _lineup.size():
			var at := Vector2(x + 300 + i * 190, floor_y)
			if _lineup[i] in ["R", "n", "f"]:
				at.y -= 260
			elif _lineup[i] == "t":
				at.y = 11 * 60.0
			level.spawn_enemy(_lineup[i], at)
	else:
		var lineup := ["w", "c", "h", "g"]
		for i in lineup.size():
			level.spawn_enemy(lineup[i], Vector2(x + 380 + i * 200, floor_y))
		level.spawn_enemy("f", Vector2(x + 560, floor_y - 320))
	if OS.get_cmdline_user_args().has("props"):
		for i in 3:
			var post := Checkpoint.new()
			post.position = Vector2(x - 200 + i * 40, floor_y)
			level.add_child(post)
		var exit := LevelExit.new()
		exit.position = Vector2(x - 420, floor_y)
		level.add_child(exit)
		var lever := Lever.new()
		lever.position = Vector2(x + 90, floor_y)
		level.add_child(lever)
		var door := Door.new()
		door.setup(Rect2(x - 560, floor_y - 240, 60, 240))
		level.add_child(door)
		var gate := Door.new()
		gate.setup(Rect2(x - 640, floor_y - 240, 60, 240), true)
		level.add_child(gate)
	if OS.get_cmdline_user_args().has("boss"):
		level.spawn_enemy("B", Vector2(x + 900, floor_y))
	var hanging := null if OS.get_cmdline_user_args().has("live") else level.spawn_enemy("a", Vector2(x + 260, floor_y - 300))
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
