class_name Heavy
extends Enemy
## Heavy robot: slow, armoured, barely moved by hits. When a hero is right in
## front of it, it raises its arms for a long, clearly visible swing (it cannot
## be interrupted then) and slams the ground in front of it.

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
		State.SLAM:
			if _timer <= 0.0:
				state = State.RECOVER
				_timer = recover_time
				super_armor = false
		State.RECOVER:
			velocity.x = 0.0
			if _timer <= 0.0:
				state = State.WALK
