extends Node
## Choices that last for the whole game session (autoload GameSettings).
## Difficulty changes how hard enemies hit, how tough they are and how often
## they drop health kits.

enum Difficulty { EASY, NORMAL, HARD }

const NAMES := {
	Difficulty.EASY: "Лёгкая",
	Difficulty.NORMAL: "Нормальная",
	Difficulty.HARD: "Сложная",
}
const HINTS := {
	Difficulty.EASY: "Враги бьют вдвое слабее, аптечки падают чаще",
	Difficulty.NORMAL: "Как задумано",
	Difficulty.HARD: "Враги бьют сильнее, они крепче, аптечек меньше",
}
## Damage that heroes take is multiplied by this.
const DAMAGE_TO_HEROES := {Difficulty.EASY: 0.5, Difficulty.NORMAL: 1.0, Difficulty.HARD: 1.5}
## Enemy health is multiplied by this.
const ENEMY_HEALTH := {Difficulty.EASY: 0.75, Difficulty.NORMAL: 1.0, Difficulty.HARD: 1.3}
## The chance of a health kit dropping is multiplied by this.
const HEALTH_DROPS := {Difficulty.EASY: 1.6, Difficulty.NORMAL: 1.0, Difficulty.HARD: 0.6}

var difficulty: Difficulty = Difficulty.NORMAL


func damage_to_heroes(amount: int) -> int:
	if amount <= 0:
		return 0
	return maxi(1, roundi(amount * DAMAGE_TO_HEROES[difficulty]))


func enemy_health(base: int) -> int:
	return maxi(1, roundi(base * ENEMY_HEALTH[difficulty]))


func health_drop_chance(base: float) -> float:
	return clampf(base * HEALTH_DROPS[difficulty], 0.0, 1.0)
