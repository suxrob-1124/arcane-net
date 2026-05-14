## Grants the player a brief invulnerability window when an enemy telegraph is active.
## Calls add_invuln_source() on the player and releases it after SHIELD_DURATION seconds.
class_name ShieldAction
extends SpectatorAction

## Seconds the invulnerability window lasts after the shield is applied.
const SHIELD_DURATION: float = 1.5
## HP ratio below which Shield is suppressed so mana is reserved for HealAction.
const HP_FLOOR: float = 0.50
## HP ratio above which Shield is skipped — player has enough buffer, save mana for later.
const HP_CEILING: float = 0.85


func _init() -> void:
	action_name = &"shield"
	mana_cost = 60.0


## Returns true while boss_casting_aoe is active and HP is in [HP_FLOOR, HP_CEILING].
## Outside this window Shield either wastes mana (high HP) or competes with Heal (low HP).
func can_execute(ctx: Dictionary) -> bool:
	var hp: float = ctx.get("player_hp_ratio", 1.0)
	return ctx.get("boss_casting_aoe", false) \
		and hp >= HP_FLOOR \
		and hp <= HP_CEILING


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
