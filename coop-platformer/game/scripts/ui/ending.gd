extends "res://scripts/ui/comic_player.gd"
## The ending chosen at the Heart (SaveGame.data["ending"]: "off" or "keep"),
## then the end of the game.

const ART := "res://assets/art/comics/%s.png"


func _init() -> void:
	next_scene = "res://scenes/title.tscn"
	if SaveGame.data.get("ending", "off") == "keep":
		panels = [
			{"image": _art("ending_keep"), "caption": "Город сияет. А в трущобах снова поднимаются тени.", "zoom": "out"},
		]
	else:
		panels = [
			{"image": _art("ending_off"), "caption": "Неон погас. Впервые за двадцать лет над городом зажглись звёзды.", "zoom": "out"},
		]
	panels.append({"image": null, "caption": "Конец. Спасибо, что прошли «Неон и пепел»!"})


static func _art(name: String) -> Texture2D:
	var path := ART % name
	return load(path) if ResourceLoader.exists(path) else null
