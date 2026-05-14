extends GutTest


func _make_ctx(enemy_ratio: float = 0.90) -> Dictionary:
	return {
		"player": null,
		"player_hp_ratio": 1.0,
		"boss_casting_aoe": false,
		"highest_hp_enemy_ratio": enemy_ratio,
		"highest_hp_enemy": null,
	}


func test_damage_spike_fires_when_enemy_high_hp() -> void:
	var action := DamageSpikeAction.new()
	assert_true(action.can_execute(_make_ctx(0.90)),
		"DamageSpike must fire when an enemy has HP ratio above MIN_ENEMY_HP_RATIO")


func test_damage_spike_requires_enemy_present() -> void:
	var action := DamageSpikeAction.new()
	assert_false(action.can_execute(_make_ctx(0.0)),
		"DamageSpike must not fire when no enemy meets the HP threshold")


func test_damage_spike_blocked_at_min_enemy_hp_boundary() -> void:
	var action := DamageSpikeAction.new()
	assert_false(action.can_execute(_make_ctx(DamageSpikeAction.MIN_ENEMY_HP_RATIO)),
		"DamageSpike threshold is strict greater-than — 0.80 must not pass")


func test_damage_spike_has_personal_cooldown() -> void:
	var action := DamageSpikeAction.new()
	assert_almost_eq(action.cooldown_seconds, 60.0, 0.001,
		"DamageSpike cooldown must be 60s per GDD 6.8")


func test_cooldown_blocks_immediate_recast() -> void:
	var action := DamageSpikeAction.new()
	assert_true(action.is_off_cooldown(), "cooldown is fresh and clear before first cast")
	action.mark_used()
	assert_false(action.is_off_cooldown(),
		"is_off_cooldown() must return false right after mark_used()")


func test_cooldown_zero_means_no_cooldown() -> void:
	var heal := HealAction.new()
	assert_almost_eq(heal.cooldown_seconds, 0.0, 0.001,
		"HealAction has no personal cooldown by default")
	heal.mark_used()
	assert_true(heal.is_off_cooldown(),
		"Zero cooldown means mark_used() does not block future casts")
