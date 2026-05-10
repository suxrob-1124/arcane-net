class_name SkillCleave
extends Node

@export var data: SkillData
var stacks: int = 0

func _ready() -> void:
	assert(data != null, "SkillCleave: data not injected by SkillManager")

func add_stack() -> void:
	stacks += 1
	push_warning("Skill_Cleave: stacks=%d" % stacks)
