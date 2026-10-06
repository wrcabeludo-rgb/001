extends "res://scripts/ui/comic_player.gd"
## Comic after world 1 (story: STORY.md, "После мира 1"). Panels without art
## yet show only their caption on black.

const ART := "res://assets/art/comics/world1_end_%02d.png"


func _init() -> void:
	next_scene = "res://scenes/title.tscn"
	panels = [
		{"image": _art(1), "caption": "Трубы ведут на заводы «Люмена». Они всё ещё работают.", "zoom": "in"},
		{"image": _art(2), "caption": "— Я здесь уже был, — сказал Мечник."},
		{"image": null, "caption": "Конец первого мира. Продолжение следует."},
	]


static func _art(number: int) -> Texture2D:
	var path := ART % number
	return load(path) if ResourceLoader.exists(path) else null
