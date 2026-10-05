class_name Hit
extends RefCounted
## One attack landing on a target.

var damage := 0
var knockback := Vector2.ZERO
var source_position := Vector2.ZERO
## Set by a defender that blocked it: blocked hits do not stun.
var blocked := false


static func make(p_damage: int, p_knockback: Vector2, p_source_position: Vector2) -> Hit:
	var hit := Hit.new()
	hit.damage = p_damage
	hit.knockback = p_knockback
	hit.source_position = p_source_position
	return hit
