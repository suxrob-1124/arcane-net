extends Node

signal player_died()
signal room_cleared(room_id: String)
signal skill_picked(skill_id: StringName)
signal enemy_died(enemy_instance: Node)
signal level_up_triggered(new_level: int)
