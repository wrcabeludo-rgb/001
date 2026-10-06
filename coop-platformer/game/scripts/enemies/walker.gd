class_name Walker
extends Enemy
## Mutant walker: patrols, turns at walls and ledges; when a hero is close and
## at about the same height, runs at them (but never off a ledge).

@export var walk_speed := 110.0
@export var chase_speed := 220.0
@export var sight := 420.0


func _init() -> void:
	max_health = 6
	body_size = Vector2(56, 70)
	color = MUTANT_COLOR
	contact_damage = 2
	art = "walker"
	art_height = 110.0


func _think(_delta: float) -> void:
	var hero := hero_in_line(sight, 110.0)
	if hero == null:
		patrol(walk_speed)
		return
	if hero.global_position.x != global_position.x:
		facing = 1 if hero.global_position.x > global_position.x else -1
	var blocked := is_on_floor() and (wall_ahead(facing) or not ground_ahead(facing))
	velocity.x = 0.0 if blocked else facing * chase_speed
