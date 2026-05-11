extends Node

const ECHO_THRESHOLD: int = 3

signal spectator_mode_entered()
signal spectator_mode_exited()

var human_spectator_count: int = 0
var current_mana: float = 100.0
var cooldowns_map: Dictionary = {}


func echo_should_be_active() -> bool:
	return GameState.player_count >= 1 and human_spectator_count < ECHO_THRESHOLD


func enter_spectator_mode() -> void:
	GameState.current_mode = GameState.Mode.SPECTATOR
	spectator_mode_entered.emit()


func exit_spectator_mode() -> void:
	spectator_mode_exited.emit()
