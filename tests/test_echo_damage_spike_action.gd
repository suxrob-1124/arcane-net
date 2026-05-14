extends GutTest


func _make_ctx(hp_ratio: float, mana: float, enemy_ratio: float = 0.90) -> Dictionary:
	return {
		"player": null,
		"player_hp_ratio": hp_ratio,
		"boss_casting_aoe": false,
		"highest_hp_enemy_ratio": enemy_ratio,
		"highest_hp_enemy": null,
		"current_mana": mana,
	}


func test_damage_spike_fires_when_safe_and_full() -> void:
	var action := DamageSpikeAction.new()
	var ctx := _make_ctx(1.0, 100.0, 0.90)
	assert_true(action.can_execute(ctx),
		"DamageSpike must fire when HP is safe (1.0) and mana is full (100)")


func test_damage_spike_at_boundary() -> void:
	var action := DamageSpikeAction.new()
	var ctx := _make_ctx(DamageSpikeAction.SAFE_HP_THRESHOLD, DamageSpikeAction.MANA_RESERVE_THRESHOLD)
	assert_true(action.can_execute(ctx),
		"DamageSpike must fire at exactly the boundary values (inclusive)")


func test_damage_spike_requires_full_mana() -> void:
	var action := DamageSpikeAction.new()
	var ctx := _make_ctx(1.0, 80.0)
	assert_false(action.can_execute(ctx),
		"DamageSpike must not fire when mana (80) is below MANA_RESERVE_THRESHOLD (95)")


func test_damage_spike_requires_safe_hp() -> void:
	var action := DamageSpikeAction.new()
	var ctx := _make_ctx(0.60, 100.0)
	assert_false(action.can_execute(ctx),
		"DamageSpike must not fire when HP (0.60) is below SAFE_HP_THRESHOLD (0.70)")


func test_damage_spike_requires_enemy_present() -> void:
	var action := DamageSpikeAction.new()
	var ctx := _make_ctx(1.0, 100.0, 0.0)
	assert_false(action.can_execute(ctx),
		"DamageSpike must not fire when no enemy has HP ratio above 0.80")


func test_damage_spike_blocked_when_mana_just_below_threshold() -> void:
	var action := DamageSpikeAction.new()
	var ctx := _make_ctx(1.0, DamageSpikeAction.MANA_RESERVE_THRESHOLD - 1.0)
	assert_false(action.can_execute(ctx),
		"DamageSpike must not fire at mana one unit below threshold")


func test_damage_spike_blocked_when_hp_just_below_threshold() -> void:
	var action := DamageSpikeAction.new()
	var ctx := _make_ctx(DamageSpikeAction.SAFE_HP_THRESHOLD - 0.01, 100.0)
	assert_false(action.can_execute(ctx),
		"DamageSpike must not fire at HP just below SAFE_HP_THRESHOLD")
