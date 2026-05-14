## Tracks player XP and level progression.
## Listens to EventBus.enemy_died, accumulates XP, and fires level-up events
## both locally and through EventBus so SkillManager can respond.
class_name ExperienceComponent
extends Node

## Emitted every time XP is added. [current] and [required] allow progress-bar updates.
signal xp_gained(amount: int, current: int, required: int)

## Emitted once per level gained. Also triggers EventBus.level_up_triggered.
signal level_up(new_level: int)

const XP_BASE := 100.0
const XP_EXP := 1.5
## Safety cap to avoid infinite loops if XP formula or rewards are misconfigured.
const MAX_LEVELS_PER_CALL := 100

@export var current_level: int = 1
var current_xp: int = 0


func _ready() -> void:
	EventBus.enemy_died.connect(_on_enemy_died)


func _on_enemy_died(_enemy: Node3D, _position: Vector3, xp_reward: int) -> void:
	add_xp(xp_reward)


## Adds [amount] XP and resolves any resulting level-ups in a single call.
## Emits [xp_gained] immediately, then [level_up] for each level crossed.
func add_xp(amount: int) -> void:
	current_xp += amount
	xp_gained.emit(amount, current_xp, get_required_xp(current_level))

	var iterations: int = 0
	while current_xp >= get_required_xp(current_level) and iterations < MAX_LEVELS_PER_CALL:
		current_xp -= get_required_xp(current_level)
		current_level += 1
		level_up.emit(current_level)
		EventBus.level_up_triggered.emit(current_level)
		iterations += 1

	if iterations > 0:
		xp_gained.emit(0, current_xp, get_required_xp(current_level))


## Returns the XP threshold to reach the next level from [level].
## Uses an exponential curve: XP_BASE * level ^ XP_EXP.
func get_required_xp(level: int) -> int:
	return int(round(XP_BASE * pow(float(level), XP_EXP)))
