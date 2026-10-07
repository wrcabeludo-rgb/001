extends "res://tests/test_harness.gd"
## Not a test: close-ups of the heroes' action poses in the empty test room
## (crouch, kick with the first swing, the second and third swings, block,
## wall slide). Needs a display:
##   xvfb-run -a godot --path game res://tests/pose_shot.tscn -- /tmp/pose

var _out := "/tmp/pose"
var _camera: Camera2D


func _run_all() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		_out = args[0]
	await _spawn(Heroes.Id.SHOOTER, Vector2(OPEN_X - 90, FLOOR_Y))
	var partner := _spawn_extra(Heroes.Id.SWORDSMAN, Vector2(OPEN_X + 90, FLOOR_Y))
	var sword: PlayerInput = _extra_inputs[0]
	_camera = Camera2D.new()
	_camera.zoom = Vector2(2.6, 2.6)
	_camera.position = Vector2(OPEN_X, FLOOR_Y - 30)
	_room.add_child(_camera)
	_camera.make_current()
	await _frames(20)
	await _save("idle")
	_input.set_virtual("down", true)
	sword.set_virtual("down", true)
	await _frames(12)
	await _save("crouch")
	_input.set_virtual("down", false)
	sword.set_virtual("down", false)
	await _frames(20)
	_input.set_virtual("skill", true)
	sword.set_virtual("attack", true)
	await _frames(5)
	await _save("kick_slash1")
	_input.set_virtual("skill", false)
	sword.set_virtual("attack", false)
	for tag in ["slash2", "slash3"]:
		await _frames(9)
		sword.set_virtual("attack", true)
		await _frames(5)
		await _save(tag)
		sword.set_virtual("attack", false)
	await _frames(40)
	sword.set_virtual("extra", true)
	await _frames(8)
	await _save("block")
	sword.set_virtual("extra", false)
	# Wall slide: the Gunner against the room's right wall (x = 1860), in the air.
	_player.global_position = Vector2(1860.0 - Player.SIZE.x / 2.0 - 1.0, 200.0)
	_input.set_virtual("right", true)
	_camera.position = Vector2(1780, 300)
	await _frames(20)
	await _save("wall")
	_input.set_virtual("right", false)
	var _keep := partner


func _save(tag: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s_%s.png" % [_out, tag])
	print("saved ", tag)
