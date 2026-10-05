class_name HeroCombat
extends Node2D
## Base for a hero's attacks. The Player owns one and calls update() every
## physics frame after moving. Overridden by ShooterCombat and SwordsmanCombat.

var player: Player
var stats: CombatStats


func setup(p_player: Player) -> void:
	player = p_player
	stats = p_player.combat_stats


func update(_delta: float) -> void:
	pass


## Movement speed is multiplied by this (e.g. slower while blocking).
func speed_multiplier() -> float:
	return 1.0


## Lets the hero reduce an incoming hit (blocking). Returns the hit to apply.
func modify_hit(hit: Hit) -> Hit:
	return hit


## True while the hero should glow (e.g. a ready charged shot).
func is_glowing() -> bool:
	return false
