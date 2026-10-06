class_name Layers
## Physics layer bits and combat teams. A hitbox only looks for the other team's
## hurtboxes, so friendly fire is impossible by construction.

enum Team { PLAYERS, ENEMIES }

const WORLD := 1
const PLAYER_BODIES := 2
const ENEMY_BODIES := 4
const PLAYER_HURTBOXES := 8
const ENEMY_HURTBOXES := 16
## Platforms that can be jumped through from below and dropped through (down + jump).
const ONE_WAY := 32
## Everything a hero or an enemy can stand on.
const GROUND := WORLD | ONE_WAY


static func hurtbox_layer(team: Team) -> int:
	return PLAYER_HURTBOXES if team == Team.PLAYERS else ENEMY_HURTBOXES


static func target_hurtboxes(team: Team) -> int:
	return ENEMY_HURTBOXES if team == Team.PLAYERS else PLAYER_HURTBOXES
