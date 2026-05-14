extends GutTest


class PlayerMock extends Node:
	var is_invulnerable: bool = false
	var _invuln_sources: int = 0

	func add_invuln_source() -> void:
		_invuln_sources += 1
		is_invulnerable = true

	func remove_invuln_source() -> void:
		_invuln_sources = max(0, _invuln_sources - 1)
		if _invuln_sources == 0:
			is_invulnerable = false


func _make_mana(current: float = 100.0) -> ManaComponent:
	var m: ManaComponent = ManaComponent.new()
	add_child_autofree(m)
	m.current_mana = current
	return m


func test_shield_action_can_execute_when_aoe_active() -> void:
	var action: ShieldAction = ShieldAction.new()
	var ctx: Dictionary = {"player": PlayerMock.new(), "boss_casting_aoe": true}
	assert_true(action.can_execute(ctx),
		"ShieldAction must execute when boss_casting_aoe is true")


func test_shield_action_cannot_execute_when_no_aoe() -> void:
	var action: ShieldAction = ShieldAction.new()
	var ctx: Dictionary = {"player": PlayerMock.new(), "boss_casting_aoe": false}
	assert_false(action.can_execute(ctx),
		"ShieldAction must NOT execute when boss_casting_aoe is false")


func test_shield_suppressed_when_hp_below_floor() -> void:
	var action: ShieldAction = ShieldAction.new()
	var ctx: Dictionary = {
		"player": PlayerMock.new(),
		"boss_casting_aoe": true,
		"player_hp_ratio": 0.40,
	}
	assert_false(action.can_execute(ctx),
		"ShieldAction must be suppressed below HP_FLOOR so mana is reserved for HealAction")


func test_shield_fires_when_aoe_and_hp_above_floor() -> void:
	var action: ShieldAction = ShieldAction.new()
	var ctx: Dictionary = {
		"player": PlayerMock.new(),
		"boss_casting_aoe": true,
		"player_hp_ratio": 0.80,
	}
	assert_true(action.can_execute(ctx),
		"ShieldAction must execute when aoe is active and HP is safe")


func test_shield_action_sets_invulnerable() -> void:
	var action: ShieldAction = ShieldAction.new()
	var player: PlayerMock = PlayerMock.new()
	add_child_autofree(player)
	var ctx: Dictionary = {"player": player, "boss_casting_aoe": true}

	action.execute(ctx)

	assert_true(player.is_invulnerable,
		"ShieldAction must set player.is_invulnerable to true")


func test_shield_action_stacks_with_dash_iframes() -> void:
	var player: PlayerMock = PlayerMock.new()
	add_child_autofree(player)

	player.add_invuln_source()  # simulate dash
	assert_eq(player._invuln_sources, 1, "one source after dash")

	player.add_invuln_source()  # simulate shield
	assert_eq(player._invuln_sources, 2, "two sources with shield + dash")
	assert_true(player.is_invulnerable, "still invulnerable")

	player.remove_invuln_source()  # dash ends
	assert_true(player.is_invulnerable,
		"must remain invulnerable while shield source active")
	assert_eq(player._invuln_sources, 1)

	player.remove_invuln_source()  # shield ends
	assert_false(player.is_invulnerable,
		"must lose invulnerability when all sources removed")


func test_echo_spends_mana_on_shield() -> void:
	var mana: ManaComponent = _make_mana(100.0)
	var action: ShieldAction = ShieldAction.new()

	assert_true(mana.can_spend(action.mana_cost))
	mana.spend(action.mana_cost)

	assert_almost_eq(mana.current_mana, 40.0, 0.01,
		"Mana must decrease by ShieldAction cost (60)")


func test_echo_cannot_shield_without_mana() -> void:
	var mana: ManaComponent = _make_mana(30.0)
	var action: ShieldAction = ShieldAction.new()

	assert_false(mana.can_spend(action.mana_cost),
		"Must not be able to cast ShieldAction with insufficient mana")
