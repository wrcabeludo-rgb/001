class_name LoaderBrute
extends Heavy
## Cargo loader robot: a bigger, tougher heavy. It walks slowly and swings its
## forklift claw down in front of it (long warning, cannot be interrupted).


func _init() -> void:
	max_health = 26
	body_size = Vector2(100, 112)
	color = ROBOT_COLOR.darkened(0.2)
	contact_damage = 2
	knockback_resistance = 0.9
	art = "loader_brute"
	art_height = 170.0
	scrap_min = 4
	scrap_max = 6
	health_drop_chance = 0.6
	walk_speed = 60.0
	slam_reach = 190.0
	windup_time = 0.85
	slam_damage = 4
	smoke_stack = Vector2(0.8, 0.13)
