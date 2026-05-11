class_name EchoCompanion
extends Node

@onready var mana: ManaComponent = $ManaComponent

@export var scan_interval: float = 0.5
@export var min_delay: float = 0.5
@export var max_delay: float = 1.5

var actions: Array[SpectatorAction] = []

var _is_acting: bool = false

signal companion_acted(action_name: String)
signal companion_personality_changed(new_personality: String)


func _ready() -> void:
	actions = [HealAction.new(), ShieldAction.new(), DamageSpikeAction.new()]
	var timer := Timer.new()
	timer.wait_time = scan_interval
	timer.one_shot = false
	timer.timeout.connect(_on_scan)
	add_child(timer)
	timer.start()


func _on_scan() -> void:
	if _is_acting:
		return
	if not SpectatorState.echo_should_be_active():
		return
	var ctx := _build_context()
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
		"boss_casting_aoe": false,
		"highest_hp_enemy_ratio": highest_hp_ratio,
		"highest_hp_enemy": highest_hp_enemy,
	}


func _pick_action(ctx: Dictionary) -> SpectatorAction:
	for action in actions:
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
	action.execute(ctx)
	var name_str := String(action.action_name)
	companion_acted.emit(name_str)
	EventBus.echo_acted.emit(action.action_name)
	_is_acting = false
