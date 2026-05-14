## Global signal hub for decoupled communication between unrelated systems.
## Emit signals here instead of creating direct references between nodes.
## All signals are typed to enforce contract at connection sites.
extends Node

@warning_ignore_start("unused_signal")

## Emitted when the player dies. [cause] is a StringName tag (e.g. &"enemy", &"fall").
signal player_died(player: Node3D, cause: StringName, position: Vector3)

## Emitted when all enemies in a room are defeated. [room_id] matches RoomNode.room_id.
signal room_cleared(room_id: String)

## Emitted when the player picks a skill from the level-up screen. [skill_id] matches SkillData.id.
signal skill_picked(skill_id: StringName)

## Emitted on enemy death. [xp_reward] is forwarded to ExperienceComponent.
signal enemy_died(enemy: Node3D, position: Vector3, xp_reward: int)

## Emitted after ExperienceComponent resolves a level-up. [new_level] is the level reached.
signal level_up_triggered(new_level: int)

## Emitted when EchoCompanion executes a spectator action. [action_name] matches SpectatorAction.action_name.
signal echo_acted(action_name: StringName)

## Emitted when the run ends with no continue option available.
signal game_over()

## Emitted when an enemy begins its attack telegraph. [duration] matches the telegraph timer length.
signal enemy_telegraph_started(enemy: Node3D, duration: float)

const DEBUG_LOG: bool = true


func _ready() -> void:
	if not DEBUG_LOG:
		return
	enemy_died.connect(func(e: Node3D, p: Vector3, xp: int) -> void:
		print("[EventBus] enemy_died: ", e, " @ ", p, " xp=", xp))
	player_died.connect(func(pl: Node3D, c: StringName, p: Vector3) -> void:
		print("[EventBus] player_died: ", pl, " cause=", c, " @ ", p))
	level_up_triggered.connect(func(lvl: int) -> void:
		print("[EventBus] level_up_triggered: lvl=", lvl))
	game_over.connect(func() -> void:
		print("[EventBus] game_over"))
