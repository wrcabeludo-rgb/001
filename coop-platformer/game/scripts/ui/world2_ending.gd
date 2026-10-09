extends "res://scripts/ui/comic_player.gd"
## Comic after world 2 (story: STORY.md, "После мира 2"). Panels without art
## yet show only their caption on black.

const ART := "res://assets/art/comics/%s.png"


func _init() -> void:
	next_scene = "res://scenes/title.tscn"
	panels = [
		{"image": _art("world2_end_01"), "caption": "В ночь Вспышки он стоял на посту у «Сердца».", "zoom": "in"},
		{"image": _art("world2_end_02"), "caption": "Осталась последняя дорога — наверх.", "zoom": "out"},
		{"image": null, "caption": "Конец второго мира. Продолжение следует."},
	]


static func _art(name: String) -> Texture2D:
	var path := ART % name
	return load(path) if ResourceLoader.exists(path) else null
