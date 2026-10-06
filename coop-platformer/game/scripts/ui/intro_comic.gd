extends "res://scripts/ui/comic_player.gd"
## Opening comic (story: STORY.md, "Вступление"). Leads into the first level.

func _init() -> void:
	next_scene = "res://scenes/slums_level.tscn"
	panels = [
		{
			"image": preload("res://assets/art/comics/intro_01.png"),
			"caption": "Двадцать лет назад «Люмен» зажёг «Сердце». Город сиял ярче звёзд.",
		},
		{
			"image": preload("res://assets/art/comics/intro_02.png"),
			"caption": "Потом была Вспышка.",
			"shake": true,
		},
		{
			"image": preload("res://assets/art/comics/intro_03.png"),
			"caption": "Город сгорел. Но свет не погас. И вместе со светом пришла жижа.",
		},
		{
			"image": preload("res://assets/art/comics/intro_04.png"),
			"caption": "Двое идут туда, где всё началось.",
		},
	]
