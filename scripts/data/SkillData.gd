class_name SkillData
extends Resource

enum Rarity { COMMON, RARE, EPIC, LEGENDARY }

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var rarity: Rarity = Rarity.COMMON
@export var max_stacks: int = 5

@export var evolves_into: SkillData

@export var conflicts_with: Array[StringName] = []
@export var requires_skills: Array[StringName] = []

@export var implementation_scene: PackedScene
