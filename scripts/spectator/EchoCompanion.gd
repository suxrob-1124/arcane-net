## Spectator-controlled AI ally. Every `scan_interval` it inspects player / enemy state,
## picks the first SpectatorAction whose `can_execute()` passes and mana is sufficient,
## then performs it after a random `[min_delay, max_delay]` delay.
## Gated by `SpectatorState.echo_should_be_active()`.
class_name EchoCompanion
extends Node

const DEBUG_LOG: bool = true
## Scan period in seconds. 4 Hz keeps Echo in sync with Glitch Pup attack cadence (~0.5 s).
const TICK_INTERVAL: float = 0.25

@onready var mana: ManaComponent = $ManaComponent

@export var min_delay: float = 0.5
@export var max_delay: float = 1.5

## Priority-ordered list of actions Echo can pick from. Order matters — first match wins.
var actions: Array[SpectatorAction] = []

var _is_acting: bool = false
var _aoe_alert_until_ms: int = 0
var _last_tick_state: Dictionary = {}

## Emitted right after an action runs. Carries the action's name for UI hooks.
signal companion_acted(action_name: String)
## Reserved for personality-switch events (calm / aggressive Echo modes).
signal companion_personality_changed(new_personality: String)


func _ready() -> void:
	actions = [HealAction.new(), ShieldAction.new(), DamageSpikeAction.new()]
	EventBus.enemy_telegraph_started.connect(_on_enemy_telegraph_started)
	var timer := Timer.new()
	timer.wait_time = TICK_INTERVAL
	timer.one_shot = false
	timer.timeout.connect(_on_scan)
	add_child(timer)
	timer.start()


func _on_enemy_telegraph_started(_enemy: Node3D, duration: float) -> void:
	_aoe_alert_until_ms = Time.get_ticks_msec() + int(duration * 1000.0)


func _on_scan() -> void:
	if _is_acting:
		return
	if not SpectatorState.echo_should_be_active():
		return
	var ctx := _build_context()
	if DEBUG_LOG:
		var tick_state: Dictionary = {
			"mana": int(mana.current_mana),
			"hp": "%.2f" % ctx.get("player_hp_ratio", 1.0),
			"aoe": ctx.get("boss_casting_aoe", false),
		}
		if tick_state != _last_tick_state:
			_last_tick_state = tick_state
			print("[Echo] tick — mana=%.0f hp_ratio=%.2f aoe=%s" % [
				mana.current_mana,
				ctx.get("player_hp_ratio", 1.0),
				str(ctx.get("boss_casting_aoe", false)),
			])
			for a in actions:
				var can: bool = a.can_execute(ctx)
				var afford: bool = mana.can_spend(a.mana_cost)
				var off_cd: bool = a.is_off_cooldown()
				if can and afford and off_cd:
					print("  → WOULD PICK: %s (cost=%.0f)" % [a.action_name, a.mana_cost])
				else:
					var reason: String
					if not off_cd:
						reason = "on cooldown"
					elif not can:
						reason = "can_execute=false"
					else:
						reason = "not enough mana (need %.0f have %.0f)" % [a.mana_cost, mana.current_mana]
					print("  · SKIP %s: %s" % [a.action_name, reason])
	var action := _pick_action(ctx)
	if action != null:
		_perform(action, ctx)


func _build_context() -> Dictionary:
	var player: Node = null
	var players := get_tree().get_nodes_in_group(&"player")
	if not players.is_empty():
		player = players[0]

	var hp_ratio: float = 1.0
	if player != null and player.has_method(&"get_hp_ratio"):
		hp_ratio = player.get_hp_ratio()

	var highest_hp_ratio: float = 0.0
	var highest_hp_enemy: Node = null
	for enemy in get_tree().get_nodes_in_group(&"enemies"):
		if enemy.has_method(&"get_hp_ratio"):
			var ratio: float = enemy.get_hp_ratio()
			if ratio > highest_hp_ratio:
				highest_hp_ratio = ratio
				highest_hp_enemy = enemy

	return {
		"player": player,
		"player_hp_ratio": hp_ratio,
		"boss_casting_aoe": Time.get_ticks_msec() < _aoe_alert_until_ms,
		"highest_hp_enemy_ratio": highest_hp_ratio,
		"highest_hp_enemy": highest_hp_enemy,
	}


func _pick_action(ctx: Dictionary) -> SpectatorAction:
	for action in actions:
		if not action.is_off_cooldown():
			continue
		if mana.can_spend(action.mana_cost) and action.can_execute(ctx):
			return action
	return null


func _perform(action: SpectatorAction, ctx: Dictionary) -> void:
	_is_acting = true
	await get_tree().create_timer(randf_range(min_delay, max_delay)).timeout
	if not mana.can_spend(action.mana_cost):
		_is_acting = false
		return
	mana.spend(action.mana_cost)
	if DEBUG_LOG:
		print("[Echo] EXECUTE: %s (cost=%.0f, mana_left=%.0f)" % [
			action.action_name, action.mana_cost, mana.current_mana,
		])
	action.execute(ctx)
	action.mark_used()
	var name_str := String(action.action_name)
	companion_acted.emit(name_str)
	EventBus.echo_acted.emit(action.action_name)
	_is_acting = false
