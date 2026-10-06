extends Node
## Not a test: renders the title screen into a PNG (needs xvfb-run).

func _ready() -> void:
	var title: Control = load("res://scenes/title.tscn").instantiate()
	add_child(title)
	for i in 90:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_cmdline_user_args()[0])
	get_tree().quit()
