class_name SettingsEntries
## The settings page, shared by the title screen and the pause menu:
## volumes, screen shake and full screen. Every change is saved at once.

const STEP := 0.1


static func build(on_back: Callable) -> Array:
	return [
		_volume("Общая громкость", "master"),
		_volume("Музыка", "music"),
		_volume("Эффекты", "sfx"),
		_toggle("Тряска экрана", "shake"),
		_toggle("Полный экран", "fullscreen"),
		{"text": "Назад", "action": on_back},
	]


static func _volume(title: String, key: String) -> Dictionary:
	return {
		"text": func() -> String: return "%s: %d%%" % [title, roundi(float(SaveGame.setting(key)) * 100.0)],
		"adjust": func(direction: int) -> void:
			var value := clampf(snappedf(float(SaveGame.setting(key)) + direction * STEP, STEP), 0.0, 1.0)
			SaveGame.set_setting(key, value)
			SaveGame.save(),
		"hint": "Влево / вправо — тише / громче",
	}


static func _toggle(title: String, key: String) -> Dictionary:
	var flip := func(_direction := 1) -> void:
		SaveGame.set_setting(key, not bool(SaveGame.setting(key)))
		SaveGame.save()
	return {
		"text": func() -> String: return "%s: %s" % [title, "вкл" if SaveGame.setting(key) else "выкл"],
		"adjust": flip,
		"action": flip,
		"hint": "Прыжок или влево / вправо — переключить",
	}
