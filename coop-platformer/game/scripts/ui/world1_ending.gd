extends "res://scripts/ui/comic_player.gd"
## Comic after world 1 and the way into world 2 (story: STORY.md, "После
## мира 1"), then the trader. Panels without art yet show only their caption.

const ART := "res://assets/art/comics/%s.png"


func _init() -> void:
	next_scene = "res://scenes/shop.tscn"
	panels = [
		{"image": _art("world1_end_01"), "caption": "Трубы ведут на заводы «Люмена». Они всё ещё работают.", "zoom": "in"},
		{"image": _art("world1_end_02"), "caption": "— Я здесь уже был, — сказал Мечник.", "zoom": "out"},
		{"image": _art("world2_intro_01"), "caption": "Цеха работают сами. Двадцать лет — без единого человека.", "zoom": "in"},
		{"image": _art("world2_intro_02"), "caption": "Охранный робот узнал пропуск Мечника… и пропустил его.", "zoom": "out"},
	]


static func _art(name: String) -> Texture2D:
	var path := ART % name
	return load(path) if ResourceLoader.exists(path) else null
