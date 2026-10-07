class_name Heavy
extends Enemy
## Heavy robot: slow, armoured, barely moved by hits. When a hero is right in
## front of it, it raises its arms for a long, clearly visible swing (it cannot
## be interrupted then) and slams the ground in front of it. The swing shows:
## it rears back and stretches up during the windup, then lunges and squashes
## down; the slam cracks the floor with dust, chips and a shock ring.

enum State { WALK, WINDUP, SLAM, RECOVER }

const SLAM_COLOR := Color(1.0, 0.4, 0.3)

@export var walk_speed := 70.0
@export var slam_reach := 170.0
@export var windup_time := 0.75
@export var recover_time := 0.6
@export var slam_damage := 4

var state := State.WALK

var _timer := 0.0
var _slam: Hitbox
var _art_scale := Vector2.ONE


func _init() -> void:
	max_health = 20
	body_size = Vector2(84, 104)
	color = ROBOT_COLOR.darkened(0.15)
	contact_damage = 2
	knockback_resistance = 0.85
	art = "brute"
	art_height = 150.0
	scrap_min = 3
	scrap_max = 5
	health_drop_chance = 0.5


func _ready() -> void:
	super._ready()
	_slam = Hitbox.new()
	add_child(_slam)
	_slam.setup(Layers.Team.ENEMIES, Vector2(150, 90), Vector2(100, 6), SLAM_COLOR)
	_slam.show_flash = false
	if _sprite != null:
		_art_scale = _sprite.scale


func _think(delta: float) -> void:
	_timer -= delta
	match state:
		State.WALK:
			var hero := hero_in_line(slam_reach, 110.0)
			if hero == null:
				patrol(walk_speed)
				return
			facing = 1 if hero.global_position.x >= global_position.x else -1
			velocity.x = 0.0
			state = State.WINDUP
			_timer = windup_time
			super_armor = true
			telegraph(windup_time)
		State.WINDUP:
			velocity.x = 0.0
			if _timer <= 0.0:
				state = State.SLAM
				_timer = 0.15
				_slam.activate(0.15, slam_damage, Vector2(750, -420), facing)
				_show_slam()
		State.SLAM:
			if _timer <= 0.0:
				state = State.RECOVER
				_timer = recover_time
				super_armor = false
		State.RECOVER:
			velocity.x = 0.0
			if _timer <= 0.0:
				state = State.WALK


## Where the fists hit: dust, flying chips, a ring of shock and a shake.
func _show_slam() -> void:
	var ground := global_position + Vector2(facing * 100.0, body_size.y / 2.0)
	Fx.burst(get_parent(), ground, [Color(0.55, 0.5, 0.45, 0.8), Color(0.5, 0.45, 0.4, 0.0)], 18, 260.0, 14.0, 0.7,
		-40.0, false, Vector2.UP, 80.0)
	Fx.burst(get_parent(), ground, [Color(0.45, 0.4, 0.36), Color(0.3, 0.28, 0.26, 0.0)], 14, 520.0, 5.0, 0.7,
		1500.0, false, Vector2.UP, 60.0)
	var ring := Fx.Flare.new()
	ring.position = ground
	ring.radius = 110.0
	ring.life = 0.22
	ring.color = Color(1.0, 0.85, 0.6)
	get_parent().add_child(ring)
	Sound.play("boss_slam", 0.1, -8.0)
	get_tree().call_group("cameras", "shake", 7.0)


## The swing on the picture: rear back and stretch, then lunge and squash.
func _animate_sprite() -> void:
	super._animate_sprite()
	var lean := 0.0
	var stretch := 0.0
	var shift := 0.0
	match state:
		State.WINDUP:
			var t := 1.0 - clampf(_timer / windup_time, 0.0, 1.0)
			lean = -0.22 * t
			stretch = 0.1 * t
			shift = -10.0 * t
		State.SLAM:
			lean = 0.3
			stretch = -0.14
			shift = 26.0
		State.RECOVER:
			var t := clampf(_timer / recover_time, 0.0, 1.0)
			lean = 0.3 * t
			stretch = -0.14 * t
			shift = 26.0 * t
	# The picture faces left; flipped when facing right.
	_sprite.rotation += facing * lean
	_sprite.scale = _art_scale * Vector2(1.0 - stretch * 0.5, 1.0 + stretch)
	_sprite.position += Vector2(facing * shift, -stretch * art_height * 0.5)
