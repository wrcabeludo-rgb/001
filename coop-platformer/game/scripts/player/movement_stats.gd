class_name MovementStats
extends Resource
## Movement tuning for one hero. Distances are in pixels, times in seconds.
## Edit the .tres files in resources/heroes/ or tune live with the F1 panel.

@export_group("Бег")
@export var run_speed := 430.0
@export var ground_accel := 4500.0
@export var ground_decel := 5000.0
@export var air_accel := 3000.0
@export var air_decel := 1500.0

@export_group("Прыжок")
@export var jump_height := 170.0
@export var jump_time_to_apex := 0.36
## Gravity is multiplied by this while falling, so jumps feel snappy.
@export var fall_gravity_multiplier := 1.6
@export var max_fall_speed := 1300.0
## Releasing jump early multiplies upward speed by this.
@export var jump_cut := 0.45
## Grace time to jump after running off a ledge.
@export var coyote_time := 0.1
## A jump pressed this long before landing still happens.
@export var jump_buffer := 0.12

@export_group("Двойной прыжок")
@export var air_jumps := 0
@export var air_jump_height := 130.0

@export_group("Стены")
@export var wall_jump_enabled := true
@export var wall_slide_speed := 200.0
@export var wall_jump_height := 150.0
@export var wall_jump_speed_x := 520.0
## Horizontal control is ignored this long after a wall jump.
@export var wall_jump_lock_time := 0.15
@export var wall_coyote_time := 0.08

@export_group("Рывок")
@export var dash_enabled := false
@export var dash_speed := 1150.0
@export var dash_time := 0.16
@export var dash_cooldown := 0.4
@export var air_dashes := 1

@export_group("Лестницы и канаты")
@export var climb_speed := 280.0
## Jumping off a ladder or rope reaches this fraction of a normal jump.
@export var climb_jump_factor := 0.8


## Gravity while rising, derived from jump height and time to apex.
func rise_gravity() -> float:
	return 2.0 * jump_height / (jump_time_to_apex * jump_time_to_apex)


## Upward (negative) velocity that reaches the given height under rise gravity.
func velocity_for_height(height: float) -> float:
	return -sqrt(2.0 * rise_gravity() * height)
