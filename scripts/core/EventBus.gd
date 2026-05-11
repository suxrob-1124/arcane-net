extends Node

@warning_ignore_start("unused_signal")

signal player_died(player: Node3D, cause: StringName, position: Vector3)
signal room_cleared(room_id: String)
signal skill_picked(skill_id: StringName)
signal enemy_died(enemy: Node3D, position: Vector3, xp_reward: int)
signal level_up_triggered(new_level: int)
signal echo_acted(action_name: StringName)
signal game_over()

const DEBUG_LOG: bool = false


func _ready() -> void:
	if not DEBUG_LOG:
		return
	enemy_died.connect(func(e: Node3D, p: Vector3, xp: int) -> void:
		print("[EventBus] enemy_died: ", e, " @ ", p, " xp=", xp))
	player_died.connect(func(pl: Node3D, c: StringName, p: Vector3) -> void:
		print("[EventBus] player_died: ", pl, " cause=", c, " @ ", p))
	level_up_triggered.connect(func(lvl: int) -> void:
		print("[EventBus] level_up_triggered: lvl=", lvl))
	game_over.connect(func() -> void:
		print("[EventBus] game_over"))
