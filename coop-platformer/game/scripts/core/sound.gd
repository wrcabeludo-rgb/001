extends Node
## Sound effects and music (autoload Sound). Sounds live in assets/audio/sfx
## (tools/sfx_import.py, a couple from tools/audio_synth.py), music loops in
## assets/audio/music (tools/music_import.py).
##   Sound.play("jump")        — a sound effect (slight random pitch)
##   Sound.music("zone_1_1")   — crossfade to a music loop
## Music and effects have their own volume buses ("Music", "SFX").

const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_DIR := "res://assets/audio/music/"
const VOICES := 20
const FADE_TIME := 1.2
## Per-sound loudness in dB, so frequent sounds do not drown out the rest.
const VOLUME := {
	"jump": -10.0, "double_jump": -13.0, "land": -10.0, "shoot": -8.0, "dash": -6.0,
	"telegraph": -10.0, "menu_move": -12.0, "menu_select": -8.0, "pickup_ammo": -10.0,
	"pickup_scrap": -9.0, "charge_ready": -10.0, "laser": -14.0, "flame": -9.0, "hit": -6.0,
	"slash": -3.0, "block": -8.0, "lever": -6.0, "door": -6.0, "crumble": -7.0, "flamer": -9.0, "shock": -4.0,
}
## A sound does not restart more often than this (a burst of hits stays one sound).
const MIN_INTERVAL := 0.04

var music_name := ""

var _voices: Array[AudioStreamPlayer] = []
var _next_voice := 0
var _cache := {}
var _last_played := {}
var _music_players: Array[AudioStreamPlayer] = []
var _active_music := 0
## Without a sound card (headless automated tests) streams are never mixed and
## outlive the engine, so nothing is played there.
var _silent := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_silent = DisplayServer.get_name() == "headless"
	for bus_name in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus_name) < 0:
			AudioServer.add_bus()
			var index := AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus_name)
			AudioServer.set_bus_send(index, "Master")
	for i in VOICES:
		var voice := AudioStreamPlayer.new()
		voice.bus = "SFX"
		add_child(voice)
		_voices.append(voice)
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.bus = "Music"
		player.volume_db = -80.0
		add_child(player)
		_music_players.append(player)


## `pitch` below 1 makes a sound lower and heavier (the heavy blade).
func play(sound_name: String, pitch_jitter := 0.06, volume_offset := 0.0, pitch := 1.0) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if _silent or now - _last_played.get(sound_name, -1.0) < MIN_INTERVAL:
		return
	var stream := _load(SFX_DIR + sound_name + ".wav")
	if stream == null:
		return
	_last_played[sound_name] = now
	var voice := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % VOICES
	voice.stream = stream
	voice.volume_db = VOLUME.get(sound_name, 0.0) + volume_offset
	voice.pitch_scale = pitch * (1.0 + randf_range(-pitch_jitter, pitch_jitter))
	voice.play()


## Crossfades to a looping track; the same track keeps playing.
func music(track: String) -> void:
	if track == music_name:
		return
	music_name = track
	var old := _music_players[_active_music]
	_active_music = 1 - _active_music
	var new := _music_players[_active_music]
	var stream: AudioStreamOggVorbis = null
	if not _silent:
		stream = _load(MUSIC_DIR + track + ".ogg") as AudioStreamOggVorbis
	if stream != null:
		stream.loop = true
		new.stream = stream
		new.volume_db = -40.0
		new.play()
		create_tween().tween_property(new, "volume_db", 0.0, FADE_TIME)
	var fade := create_tween()
	fade.tween_property(old, "volume_db", -80.0, FADE_TIME)
	fade.tween_callback(old.stop)


func stop_music() -> void:
	music_name = ""
	for player in _music_players:
		create_tween().tween_property(player, "volume_db", -80.0, FADE_TIME)


## Volume of a bus ("Master", "Music" or "SFX") from 0 to 1.
func set_volume(bus_name: String, value: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index >= 0:
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(value, 0.0001)))
		AudioServer.set_bus_mute(index, value <= 0.001)


func get_volume(bus_name: String) -> float:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0 or AudioServer.is_bus_mute(index):
		return 0.0
	return db_to_linear(AudioServer.get_bus_volume_db(index))


func _load(path: String) -> AudioStream:
	if not _cache.has(path):
		_cache[path] = load(path) if ResourceLoader.exists(path) else null
	return _cache[path]


## Stop everything before the game closes, so no playing stream outlives the engine.
func _exit_tree() -> void:
	for player in _voices + _music_players:
		player.stop()
		player.stream = null
	_cache.clear()
