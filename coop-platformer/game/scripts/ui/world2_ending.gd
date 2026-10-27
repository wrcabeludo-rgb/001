extends "res://scripts/ui/comic_player.gd"
## Comic after world 2 (story: STORY.md, "После мира 2"), then the trader. Panels without art
## yet show only their caption on black.

const ART := "res://assets/art/comics/%s.png"


func _init() -> void:
	next_scene = "res://scenes/shop.tscn"
	panels = [
		{"image": _art("world2_end_01"), "caption": "В ночь Вспышки он стоял на посту у «Сердца».", "zoom": "in"},
		{"image": _art("world2_end_02"), "caption": "Осталась последняя дорога — наверх.", "zoom": "out"},
	]


static func _art(name: String) -> Texture2D:
	var path := ART % name
	return load(path) if ResourceLoader.exists(path) else null
