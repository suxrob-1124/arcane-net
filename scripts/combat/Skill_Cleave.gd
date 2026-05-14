## Cleave skill implementation node. Instantiated by SkillManager under `skill_host_path`
## when the player picks the Cleave SkillData. Currently a stub — only tracks stack count.
class_name SkillCleave
extends Node

@export var data: SkillData
var stacks: int = 0

func _ready() -> void:
	assert(data != null, "SkillCleave: data not injected by SkillManager")

## Increments stack count. Called by SkillManager when the same skill is picked again.
func add_stack() -> void:
	stacks += 1
	push_warning("Skill_Cleave: stacks=%d" % stacks)
