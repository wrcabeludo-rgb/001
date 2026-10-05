class_name Health
extends Node
## Hit points of a hero, enemy or target.

signal changed(current: int, maximum: int)
signal died

var maximum := 10
var current := 10


func reset(new_maximum := -1) -> void:
	if new_maximum > 0:
		maximum = new_maximum
	current = maximum
	changed.emit(current, maximum)


func damage(amount: int) -> void:
	if is_dead() or amount <= 0:
		return
	current = maxi(0, current - amount)
	changed.emit(current, maximum)
	if current == 0:
		died.emit()


func heal(amount: int) -> void:
	if is_dead():
		return
	current = mini(maximum, current + amount)
	changed.emit(current, maximum)


func is_dead() -> bool:
	return current <= 0


func ratio() -> float:
	return float(current) / float(maximum)
