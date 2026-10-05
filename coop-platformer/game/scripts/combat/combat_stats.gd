class_name CombatStats
extends Resource
## Combat tuning for one hero. Damage is in hit points, times in seconds,
## speeds and knockback in pixels per second.

@export_group("Здоровье")
@export var max_health := 10
## Invulnerability after being hit (the hero blinks).
@export var hurt_invulnerability := 0.8
## Loss of control after being hit.
@export var hurt_stun := 0.25

@export_group("Стрелок: выстрел")
@export var fire_cooldown := 0.16
@export var shot_damage := 1
@export var shot_speed := 1400.0
@export var shot_lifetime := 0.7
@export var shot_knockback := 120.0

@export_group("Стрелок: заряженный выстрел")
## How long attack must be held before release fires a charged shot.
@export var charge_time := 0.6
@export var charged_damage := 6
@export var charged_cost := 2
@export var charged_pierce := 3
@export var charged_knockback := 600.0
@export var start_ammo := 20
@export var max_ammo := 40

@export_group("Стрелок: пинок")
@export var kick_damage := 1
@export var kick_knockback := 1100.0
@export var kick_cooldown := 0.45

@export_group("Мечник: удары")
@export var slash1_damage := 3
@export var slash2_damage := 3
@export var slash3_damage := 5
@export var up_slash_damage := 3
@export var swing_time := 0.2
## After a swing ends, the next attack press continues the combo within this time.
@export var combo_window := 0.3
@export var slash_knockback := 300.0
@export var finisher_knockback := 800.0

@export_group("Мечник: блок")
## Damage taken from the front while blocking is multiplied by this.
@export var block_damage_multiplier := 0.25
@export var block_knockback_multiplier := 0.3
@export var block_speed_multiplier := 0.45
