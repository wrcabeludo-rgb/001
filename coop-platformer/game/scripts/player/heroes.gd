class_name Heroes
## The two playable heroes and their shared data.

enum Id { SHOOTER, SWORDSMAN }

const NAMES := {
	Id.SHOOTER: "Стрелок",
	Id.SWORDSMAN: "Мечник",
}

const COLORS := {
	Id.SHOOTER: Color(0.3, 0.8, 1.0),
	Id.SWORDSMAN: Color(1.0, 0.6, 0.25),
}

const MOVEMENT := {
	Id.SHOOTER: preload("res://resources/heroes/shooter_movement.tres"),
	Id.SWORDSMAN: preload("res://resources/heroes/swordsman_movement.tres"),
}

const COMBAT := {
	Id.SHOOTER: preload("res://resources/heroes/shooter_combat.tres"),
	Id.SWORDSMAN: preload("res://resources/heroes/swordsman_combat.tres"),
}


static func other(id: Id) -> Id:
	return Id.SWORDSMAN if id == Id.SHOOTER else Id.SHOOTER
