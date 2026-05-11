class_name EnemyData
extends Resource

@export var enemy_scene: PackedScene
@export var enemy_name: String = "Base Enemy"
@export var enemy_id: StringName = &"enemy"
@export var max_hp: int = 30
@export var move_speed: float = 4.0
@export var melee_damage: int = 10
@export var xp_reward: int = 10
@export var chase_radius: float = 10.0
@export var attack_radius: float = 1.5
@export var attack_telegraph: float = 0.5
