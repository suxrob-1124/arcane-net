## Spectator-mode state and Echo gating. AutoLoad singleton.
## Tracks live human spectator count, mana, and ability cooldowns so the rest of the
## codebase can read a single source of truth via `echo_should_be_active()`.
extends Node

## Maximum number of human spectators before Echo steps back (they cast directly).
const ECHO_THRESHOLD: int = 3

## Emitted when the controller transitions the game into spectator mode.
signal spectator_mode_entered()
## Emitted when leaving spectator mode (not yet wired to respawn logic).
signal spectator_mode_exited()

var human_spectator_count: int = 0
var current_mana: float = 100.0
var cooldowns_map: Dictionary = {}


## True when Echo should pick and execute SpectatorActions — at least one player exists
## and fewer than `ECHO_THRESHOLD` human spectators are watching.
func echo_should_be_active() -> bool:
	return GameState.player_count >= 1 and human_spectator_count < ECHO_THRESHOLD


## Sets `GameState.current_mode = SPECTATOR` and announces the transition.
func enter_spectator_mode() -> void:
	GameState.current_mode = GameState.Mode.SPECTATOR
	spectator_mode_entered.emit()


## Emits `spectator_mode_exited`. Callers are responsible for restoring `GameState.current_mode`.
func exit_spectator_mode() -> void:
	spectator_mode_exited.emit()
