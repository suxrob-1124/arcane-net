class_name RoomData
extends Resource

enum RoomType { START, COMBAT, ELITE, REWARD, BOSS }

@export var type: RoomType = RoomType.COMBAT
@export var display_name: String = ""
@export var difficulty_tier: int = 1
@export var base_enemy_count: int = 3
@export var possible_enemies: Array[EnemyData] = []
@export var loot_table: Array[Resource] = []
@export var tags: Array[StringName] = []
