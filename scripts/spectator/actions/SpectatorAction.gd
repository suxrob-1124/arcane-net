## Base class for spectator/Echo abilities. Subclasses override `can_execute` and `execute`.
## Personal cooldown is tracked here — callers should check `is_off_cooldown()` before picking
## an action and call `mark_used()` after a successful cast.
class_name SpectatorAction
extends RefCounted

var action_name: StringName = &""
var mana_cost: float = 0.0
## Personal cooldown in seconds after a successful cast. 0 = no cooldown.
var cooldown_seconds: float = 0.0

var _cooldown_until_ms: int = 0


## Returns true if the action's ability-specific conditions are met. Does NOT check cooldown
## or mana — callers must verify those separately.
func can_execute(_ctx: Dictionary) -> bool:
	return false


func execute(_ctx: Dictionary) -> void:
	pass


## Returns true if the action's personal cooldown has elapsed.
func is_off_cooldown() -> bool:
	return Time.get_ticks_msec() >= _cooldown_until_ms


## Registers a cast: starts the personal cooldown timer if `cooldown_seconds > 0`.
func mark_used() -> void:
	if cooldown_seconds > 0.0:
		_cooldown_until_ms = Time.get_ticks_msec() + int(cooldown_seconds * 1000.0)
