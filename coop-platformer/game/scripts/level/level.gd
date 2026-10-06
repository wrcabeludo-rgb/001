class_name Level
extends Node2D
## A playable area built from an ASCII map, with the co-op rules:
## heroes join and leave at any time (a late joiner appears next to the partner),
## the co-op camera keeps everyone in view and its edges hold heroes back,
## falling below the screen kills, a fallen hero returns next to the partner
## after RESPAWN_DELAY, and when everyone is down the team restarts at the
## last checkpoint with full health.
##
## Map legend: '#' wall, '1' / '2' start of player 1 / 2, 'C' checkpoint,
## 'D' training dummy, 'T' turret. Objects stand on the bottom of their cell.

const TILE := 60
const COLOR_WALL := Color(0.35, 0.37, 0.42)
## A fallen hero comes back next to the living partner after this many seconds.
const RESPAWN_DELAY := 3.0
## When everyone is down, the team restarts at the checkpoint after this delay.
const TEAM_RESPAWN_DELAY := 1.5
## A hero this far below the bottom of the screen is lost.
const FALL_MARGIN := 80.0

## Off in automated tests that need a quiet level.
var spawn_targets := true
## The co-op camera; off for single-screen rooms.
var use_coop_camera := true
## Scene that F2 switches to; empty = none.
var other_scene := ""

## Hero of each joined slot.
var players := {}
var camera: CoopCamera
var active_checkpoint: Checkpoint
var hud: CanvasLayer

var _spawn_points := {}
## Seconds left before a fallen hero returns, by slot.
var _respawn_timers := {}
var _team_respawn_timer := -1.0
var _huds: Array[HeroHud] = []
var _toast: Label
var _toast_time := 0.0


## Overridden by each level: the rows of its ASCII map.
func get_map() -> Array:
	return []


func _ready() -> void:
	# Runs after the heroes have moved, so screen edges and falls see final positions.
	process_priority = 10
	_build_level()
	_build_hud()
	if use_coop_camera:
		camera = CoopCamera.new()
		camera.bounds = level_rect()
		add_child(camera)
		camera.make_current()
	PlayerManager.player_joined.connect(_on_player_joined)
	PlayerManager.player_left.connect(remove_player)
	PlayerManager.hero_changed.connect(_on_hero_changed)
	for slot in PlayerManager.MAX_PLAYERS:
		if PlayerManager.players[slot] != null:
			_on_player_joined(slot)
	_snap_camera()


func level_rect() -> Rect2:
	var map := get_map()
	return Rect2(0, 0, map[0].length() * TILE, map.size() * TILE)


## Adds a hero for `slot`. Also used directly by automated tests.
func spawn_player(slot: int, input: PlayerInput, hero: Heroes.Id) -> Player:
	var player := Player.new()
	player.name = "Player%d" % (slot + 1)
	player.setup(slot, input, hero)
	player.position = _entry_point(slot)
	add_child(player)
	player.died.connect(_on_player_died)
	players[slot] = player
	return player


func remove_player(slot: int) -> void:
	if players.has(slot):
		players[slot].queue_free()
		players.erase(slot)
	_respawn_timers.erase(slot)
	# If the one who left was the last hero standing, the rest restart at the checkpoint.
	if not players.is_empty() and alive_players().is_empty() and _team_respawn_timer < 0.0:
		_team_respawn_timer = TEAM_RESPAWN_DELAY


func alive_players() -> Array[Player]:
	var result: Array[Player] = []
	for player in players.values():
		if is_instance_valid(player) and player.is_alive():
			result.append(player)
	return result


## Seconds until the hero of `slot` returns, or -1 if they are not waiting.
func respawn_time_left(slot: int) -> float:
	if _team_respawn_timer >= 0.0:
		return _team_respawn_timer
	return _respawn_timers.get(slot, -1.0)


func _physics_process(delta: float) -> void:
	_update_respawns(delta)
	if camera != null:
		camera.follow(alive_players(), delta)
		_hold_heroes_on_screen()
	_check_falls()


func _process(delta: float) -> void:
	for slot in PlayerManager.MAX_PLAYERS:
		_huds[slot].show_player(players.get(slot), respawn_time_left(slot))
	_toast_time -= delta
	_toast.modulate.a = clampf(_toast_time, 0.0, 1.0)


func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.physical_keycode == KEY_F2 and other_scene != "":
		get_tree().change_scene_to_file(other_scene)


## Where a hero (re)enters: next to a living partner, else at the checkpoint, else at the start.
func _entry_point(slot: int) -> Vector2:
	var partner := _alive_partner(slot)
	if partner != null:
		return partner.last_safe_position
	if active_checkpoint != null:
		return active_checkpoint.respawn_point(slot)
	return _spawn_points.get(slot, _spawn_points.get(0, Vector2(TILE * 2, TILE * 2)))


func _alive_partner(slot: int) -> Player:
	for other_slot in players:
		if other_slot != slot and players[other_slot].is_alive():
			return players[other_slot]
	return null


func _on_player_joined(slot: int) -> void:
	spawn_player(slot, PlayerManager.players[slot], PlayerManager.heroes[slot])


func _on_hero_changed(slot: int) -> void:
	if players.has(slot):
		players[slot].set_hero(PlayerManager.heroes[slot])


func _on_player_died(player: Player) -> void:
	player.set_active(false)
	_respawn_timers[player.slot] = RESPAWN_DELAY
	if alive_players().is_empty():
		_team_respawn_timer = TEAM_RESPAWN_DELAY


func _update_respawns(delta: float) -> void:
	if _team_respawn_timer >= 0.0:
		_team_respawn_timer -= delta
		if _team_respawn_timer < 0.0:
			_respawn_timers.clear()
			for slot in players:
				var start := _entry_point_without_partner(slot)
				players[slot].revive(start)
			_snap_camera()
		return
	for slot in _respawn_timers.keys():
		_respawn_timers[slot] -= delta
		if _respawn_timers[slot] > 0.0:
			continue
		var partner := _alive_partner(slot)
		if partner != null:
			_respawn_timers.erase(slot)
			players[slot].revive(partner.last_safe_position)


func _entry_point_without_partner(slot: int) -> Vector2:
	if active_checkpoint != null:
		return active_checkpoint.respawn_point(slot)
	return _spawn_points.get(slot, _spawn_points.get(0, Vector2(TILE * 2, TILE * 2)))


## Once the camera cannot zoom out any further, the screen edges work as walls
## on the left, right and top.
func _hold_heroes_on_screen() -> void:
	var view := camera.visible_rect()
	var half := Player.SIZE / 2.0
	for player in alive_players():
		var pos := player.global_position
		var clamped_x := clampf(pos.x, view.position.x + half.x, view.end.x - half.x)
		if clamped_x != pos.x:
			player.global_position.x = clamped_x
			player.velocity.x = 0.0
		if pos.y - half.y < view.position.y:
			player.global_position.y = view.position.y + half.y
			player.velocity.y = maxf(player.velocity.y, 0.0)


func _check_falls() -> void:
	var bottom := level_rect().end.y + FALL_MARGIN
	if camera != null:
		bottom = minf(bottom, camera.visible_rect().end.y + FALL_MARGIN)
	for player in alive_players():
		if player.global_position.y - Player.SIZE.y / 2.0 > bottom:
			player.kill()


func _snap_camera() -> void:
	if camera != null:
		camera.follow(alive_players(), 0.0, true)


func _on_checkpoint_reached(checkpoint: Checkpoint) -> void:
	if active_checkpoint != null:
		active_checkpoint.set_active(false)
	active_checkpoint = checkpoint
	checkpoint.set_active(true)
	show_toast("Контрольная точка")


func show_toast(text: String) -> void:
	_toast.text = text
	_toast_time = 2.0


func _build_level() -> void:
	var walls := StaticBody2D.new()
	walls.name = "Walls"
	add_child(walls)

	var map := get_map()
	for row in map.size():
		var line: String = map[row]
		var col := 0
		while col < line.length():
			var cell := line[col]
			var floor_point := Vector2((col + 0.5) * TILE, (row + 1) * TILE)
			match cell:
				"1", "2":
					_spawn_points[int(cell) - 1] = floor_point - Vector2(0, Player.SIZE.y / 2)
				"C":
					var checkpoint := Checkpoint.new()
					checkpoint.position = floor_point
					add_child(checkpoint)
					checkpoint.reached.connect(_on_checkpoint_reached)
				"D":
					if spawn_targets:
						_add_object(TrainingDummy.new(), floor_point - Vector2(0, TrainingDummy.SIZE.y / 2))
				"T":
					if spawn_targets:
						_add_object(TurretDummy.new(), floor_point - Vector2(0, 25))
			if cell != "#":
				col += 1
				continue
			# Merge a horizontal run of walls into one rectangle.
			var start := col
			while col < line.length() and line[col] == "#":
				col += 1
			_add_wall(walls, Rect2(start * TILE, row * TILE, (col - start) * TILE, TILE))


func _add_wall(walls: StaticBody2D, rect: Rect2) -> void:
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.position = rect.get_center()
	walls.add_child(collision)

	var visual := ColorRect.new()
	visual.position = rect.position
	visual.size = rect.size
	visual.color = COLOR_WALL
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	walls.add_child(visual)


func _add_object(object: Node2D, at: Vector2) -> void:
	object.position = at
	add_child(object)


func _build_hud() -> void:
	hud = CanvasLayer.new()
	add_child(hud)
	for slot in PlayerManager.MAX_PLAYERS:
		var panel := HeroHud.new()
		panel.position = Vector2(80, 70) if slot == 0 else Vector2(1440, 70)
		hud.add_child(panel)
		_huds.append(panel)

	_toast = Label.new()
	_toast.position = Vector2(560, 180)
	_toast.size = Vector2(800, 60)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_theme_font_size_override("font_size", 40)
	_toast.add_theme_color_override("font_color", Checkpoint.ON_COLOR)
	_toast.modulate.a = 0.0
	hud.add_child(_toast)
