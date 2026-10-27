extends "res://scripts/ui/comic_player.gd"
## The ending chosen at the Heart (SaveGame.data["ending"]: "off" or "keep"),
## then the results of the run and the credits.

const ART := "res://assets/art/comics/%s.png"


func _init() -> void:
	next_scene = "res://scenes/final_credits.tscn"
	if SaveGame.data.get("ending", "off") == "keep":
		panels = [
			{"image": _art("ending_keep"), "caption": "Город сияет. А в трущобах снова поднимаются тени.", "zoom": "out"},
		]
	else:
		panels = [
			{"image": _art("ending_off"), "caption": "Неон погас. Впервые за двадцать лет над городом зажглись звёзды.", "zoom": "out"},
		]


static func _art(name: String) -> Texture2D:
	var path := ART % name
	return load(path) if ResourceLoader.exists(path) else null
