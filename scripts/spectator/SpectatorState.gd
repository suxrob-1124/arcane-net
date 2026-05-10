extends Node

const ECHO_THRESHOLD: int = 3

var human_spectator_count: int = 0


func echo_should_be_active() -> bool:
	return GameState.player_count >= 1 and human_spectator_count < ECHO_THRESHOLD
