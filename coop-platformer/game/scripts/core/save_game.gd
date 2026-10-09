extends Node
## Progress and settings on disk (autoload SaveGame), in user://save.json.
## Each hero (not each player) keeps their own scrap, purchases and weapon
## choice: whoever plays the Gunner uses the Gunner's wallet and upgrades.

const VERSION := 1

## Zones in order: scene, title; "ending" — the comic shown after the last
## zone of a world (instead of the trader).
const ZONES := [
	{"id": "1-1", "scene": "res://scenes/slums_level.tscn", "title": "Мир 1-1 · Трущобы"},
	{"id": "1-2", "scene": "res://scenes/metro_level.tscn", "title": "Мир 1-2 · Затопленное метро"},
	{"id": "1-3", "scene": "res://scenes/drain_level.tscn", "title": "Мир 1-3 · Главный сток",
		"ending": "res://scenes/world1_ending.tscn"},
	{"id": "2-1", "scene": "res://scenes/assembly_level.tscn", "title": "Мир 2-1 · Сборочный цех"},
	{"id": "2-2", "scene": "res://scenes/foundry_level.tscn", "title": "Мир 2-2 · Литейная"},
	{"id": "2-3", "scene": "res://scenes/pumping_level.tscn", "title": "Мир 2-3 · Насосная станция",
		"ending": "res://scenes/world2_ending.tscn"},
]

var path := "user://save.json"
var data := {}


func _ready() -> void:
	load_data()
	apply_settings()


func defaults() -> Dictionary:
	return {
		"version": VERSION,
		"started": false,
		"difficulty": GameSettings.Difficulty.NORMAL,
		## How many zones are open (1 = only the first).
		"unlocked": 1,
		## Zone the "Continue" button leads to (index into ZONES).
		"next_zone": 0,
		"best_times": {},
		## Secret id -> true.
		"secrets": {},
		"heroes": {
			str(Heroes.Id.SHOOTER): {"scrap": 0, "items": [], "weapon": "rifle"},
			str(Heroes.Id.SWORDSMAN): {"scrap": 0, "items": [], "weapon": "blade"},
		},
		"settings": {"master": 1.0, "music": 0.7, "sfx": 0.9, "fullscreen": false, "shake": true},
	}


func load_data() -> void:
	data = defaults()
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_merge(data, parsed)


func save() -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))


## Forgets all progress (settings stay).
func new_game(difficulty: GameSettings.Difficulty) -> void:
	var settings: Dictionary = data["settings"]
	data = defaults()
	data["settings"] = settings
	data["started"] = true
	data["difficulty"] = difficulty
	GameSettings.difficulty = difficulty
	save()


func has_progress() -> bool:
	return data["started"]


func hero(id: Heroes.Id) -> Dictionary:
	return data["heroes"][str(id)]


func scrap(id: Heroes.Id) -> int:
	return int(hero(id)["scrap"])


func set_scrap(id: Heroes.Id, value: int) -> void:
	hero(id)["scrap"] = maxi(value, 0)


func has_item(id: Heroes.Id, item: String) -> bool:
	return item in hero(id)["items"]


func add_item(id: Heroes.Id, item: String) -> void:
	if not has_item(id, item):
		hero(id)["items"].append(item)


## How many of the listed items the hero owns (for stacked upgrades).
func count_items(id: Heroes.Id, items: Array) -> int:
	var count := 0
	for item in items:
		if has_item(id, item):
			count += 1
	return count


func weapon(id: Heroes.Id) -> String:
	return hero(id)["weapon"]


func set_weapon(id: Heroes.Id, value: String) -> void:
	hero(id)["weapon"] = value


func zone_index(zone_id: String) -> int:
	for i in ZONES.size():
		if ZONES[i]["id"] == zone_id:
			return i
	return -1


## A zone was finished: open the next one and remember the time.
func complete_zone(zone_id: String, seconds: float) -> void:
	var index := zone_index(zone_id)
	if index < 0:
		return
	data["unlocked"] = clampi(maxi(int(data["unlocked"]), index + 2), 1, ZONES.size())
	data["next_zone"] = mini(index + 1, ZONES.size() - 1)
	var best: float = data["best_times"].get(zone_id, INF)
	data["best_times"][zone_id] = minf(best, seconds)
	save()


func find_secret(secret_id: String) -> void:
	data["secrets"][secret_id] = true


func secret_found(secret_id: String) -> bool:
	return data["secrets"].has(secret_id)


func setting(key: String) -> Variant:
	return data["settings"][key]


func set_setting(key: String, value: Variant) -> void:
	data["settings"][key] = value
	apply_settings()


func apply_settings() -> void:
	var settings: Dictionary = data["settings"]
	Sound.set_volume("Master", settings["master"])
	Sound.set_volume("Music", settings["music"])
	Sound.set_volume("SFX", settings["sfx"])
	GameSettings.difficulty = int(data["difficulty"]) as GameSettings.Difficulty
	if DisplayServer.get_name() != "headless":
		var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if settings["fullscreen"] else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != mode:
			DisplayServer.window_set_mode(mode)


## Copies saved values over the defaults, so new keys added later keep their default.
static func _merge(target: Dictionary, source: Dictionary) -> void:
	for key in source:
		if target.has(key) and target[key] is Dictionary and source[key] is Dictionary:
			_merge(target[key], source[key])
		else:
			target[key] = source[key]
