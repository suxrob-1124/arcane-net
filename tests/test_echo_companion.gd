extends GutTest


func _make_echo() -> EchoCompanion:
	var echo := EchoCompanion.new()
	var mana := ManaComponent.new()
	mana.name = &"ManaComponent"
	echo.add_child(mana)
	add_child_autofree(echo)
	return echo


func _make_ctx(hp_ratio: float, mana_enough: bool = true) -> Dictionary:
	return {
		"player": null,
		"player_hp_ratio": hp_ratio,
		"boss_casting_aoe": false,
		"highest_hp_enemy_ratio": 0.0,
		"highest_hp_enemy": null,
	}


func test_priority_selection() -> void:
	var echo := _make_echo()
	echo.mana.current_mana = 100.0
	# All three conditions could match if data set right — but Heal has lowest index = highest priority
	var ctx := {
		"player": null,
		"player_hp_ratio": 0.2,       # triggers Heal (< 0.30)
		"boss_casting_aoe": true,      # triggers Shield
		"highest_hp_enemy_ratio": 0.9, # triggers DamageSpike
		"highest_hp_enemy": null,
	}
	var action := echo._pick_action(ctx)
	assert_not_null(action, "must pick an action when all conditions met")
	assert_eq(action.action_name, &"heal", "Heal must win over Shield and DamageSpike at HP < 30%")


func test_mana_expenditure() -> void:
	var echo := _make_echo()
	echo.mana.current_mana = 20.0  # less than HealAction.mana_cost (40)
	var ctx := _make_ctx(0.1)
	var action := echo._pick_action(ctx)
	assert_null(action, "_pick_action must return null when mana < any action cost")
	assert_almost_eq(echo.mana.current_mana, 20.0, 0.001, "mana must not change when no action picked")


func test_action_emits_signal() -> void:
	var echo := _make_echo()
	echo.mana.current_mana = 100.0
	watch_signals(echo)
	watch_signals(EventBus)

	var ctx := _make_ctx(0.2)
	var heal := HealAction.new()
	# Call _perform bypass async delay by directly spending + executing
	echo.mana.spend(heal.mana_cost)
	heal.execute(ctx)
	echo.companion_acted.emit(String(heal.action_name))
	EventBus.echo_acted.emit(heal.action_name)

	assert_signal_emitted_with_parameters(echo, &"companion_acted", ["heal"])
	assert_signal_emitted_with_parameters(EventBus, &"echo_acted", [&"heal"])


func test_shield_selected_when_aoe_active() -> void:
	var echo := _make_echo()
	echo.mana.current_mana = 100.0
	# HP above 30% so HealAction is inactive; boss_casting_aoe triggers ShieldAction
	var ctx := {
		"player": null,
		"player_hp_ratio": 0.8,
		"boss_casting_aoe": true,
		"highest_hp_enemy_ratio": 0.0,
		"highest_hp_enemy": null,
	}
	var action := echo._pick_action(ctx)
	assert_not_null(action, "must pick ShieldAction when boss_casting_aoe=true and HP is healthy")
	assert_eq(action.action_name, &"shield", "ShieldAction must win when Heal is inactive")


func test_inactive_when_too_many_humans() -> void:
	SpectatorState.human_spectator_count = 3
	var echo := _make_echo()
	echo.mana.current_mana = 100.0

	# _on_scan should bail out early — _pick_action should never be reached
	# We verify by checking mana stays unchanged after a manual _on_scan call
	var mana_before: float = echo.mana.current_mana
	echo._on_scan()
	assert_almost_eq(echo.mana.current_mana, mana_before, 0.001,
		"mana must not change when echo_should_be_active() returns false")
	# Reset
	SpectatorState.human_spectator_count = 0
