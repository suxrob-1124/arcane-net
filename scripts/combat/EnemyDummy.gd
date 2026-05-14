## Stationary training-dummy enemy. Joins group `&"enemies"` so projectiles can hit it,
## but has no FSM, HP, or AI — used to validate AttackComponent in playtest scenes.
class_name EnemyDummy
extends StaticBody3D

func _ready() -> void:
	add_to_group(&"enemies")
