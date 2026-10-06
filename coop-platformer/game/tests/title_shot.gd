extends Node
## Not a test: renders a menu screen into a PNG (needs xvfb-run).
## Arguments: the PNG path, then optionally the scene name (title by default).

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var scene := args[1] if args.size() > 1 else "title"
	var title: Node = load("res://scenes/%s.tscn" % scene).instantiate()
	add_child(title)
	for i in 90:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(args[0])
	get_tree().quit()
