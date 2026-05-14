## Grants the player a brief invulnerability window when an enemy telegraph is active.
## Calls add_invuln_source() on the player and releases it after SHIELD_DURATION seconds.
class_name ShieldAction
extends SpectatorAction

## Seconds the invulnerability window lasts after the shield is applied.
const SHIELD_DURATION: float = 1.5


func _init() -> void:
	action_name = &"shield"
	mana_cost = 60.0


## Returns true while boss_casting_aoe is set in [ctx] (driven by enemy_telegraph_started).
func can_execute(ctx: Dictionary) -> bool:
	return ctx.get("boss_casting_aoe", false)


## Applies invulnerability to the player for SHIELD_DURATION seconds via add_invuln_source.
func execute(ctx: Dictionary) -> void:
	var player: Node = ctx.get("player")
	if player == null or not is_instance_valid(player):
		push_warning("EchoCompanion/ShieldAction: player not found in context")
		return
	if not player.has_method(&"add_invuln_source"):
		push_warning("EchoCompanion/ShieldAction: player has no add_invuln_source() method")
		return

	player.add_invuln_source()
	player.get_tree().create_timer(SHIELD_DURATION).timeout.connect(
		func() -> void:
			if is_instance_valid(player):
				player.remove_invuln_source()
	)
