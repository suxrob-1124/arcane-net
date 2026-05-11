extends Node

signal player_died(player: Node3D, cause: StringName, position: Vector3)
signal room_cleared(room_id: String)
signal skill_picked(skill_id: StringName)
signal enemy_died(enemy: Node3D, position: Vector3, xp_reward: int)
signal level_up_triggered(new_level: int)
signal echo_acted(action_name: StringName)
signal game_over()
