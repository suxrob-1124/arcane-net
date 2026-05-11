extends GutTest


class PlayerMock extends Node:
	var last_heal_amount: int = 0
	var hp_ratio: float = 1.0

	func heal(amount: int) -> void:
		last_heal_amount += amount

	func get_hp_ratio() -> float:
		return hp_ratio


func _make_mana(current: float = 100.0) -> ManaComponent:
	var m: ManaComponent = ManaComponent.new()
	add_child_autofree(m)
	m.current_mana = current
	return m


func test_heal_action_can_execute_below_30pct() -> void:
	var action: HealAction = HealAction.new()
	var ctx: Dictionary = {"player": PlayerMock.new(), "player_hp_ratio": 0.25}
	assert_true(action.can_execute(ctx),
		"HealAction must be executable when HP ratio < 0.30")


func test_heal_action_cannot_execute_above_30pct() -> void:
	var action: HealAction = HealAction.new()
	var ctx: Dictionary = {"player": PlayerMock.new(), "player_hp_ratio": 0.5}
	assert_false(action.can_execute(ctx),
		"HealAction must NOT execute when HP ratio >= 0.30")


func test_heal_action_calls_heal_on_player() -> void:
	var action: HealAction = HealAction.new()
	var player: PlayerMock = PlayerMock.new()
	player.hp_ratio = 0.2
	add_child_autofree(player)
	var ctx: Dictionary = {"player": player, "player_hp_ratio": 0.2}

	action.execute(ctx)

	assert_eq(player.last_heal_amount, 40,
		"HealAction must call player.heal(40)")


func test_echo_spends_mana_on_heal() -> void:
	var mana: ManaComponent = _make_mana(100.0)
	var action: HealAction = HealAction.new()

	assert_true(mana.can_spend(action.mana_cost))
	mana.spend(action.mana_cost)

	assert_almost_eq(mana.current_mana, 60.0, 0.01,
		"Mana must decrease by HealAction cost (40)")


func test_echo_cannot_heal_without_mana() -> void:
	var mana: ManaComponent = _make_mana(10.0)
	var action: HealAction = HealAction.new()

	assert_false(mana.can_spend(action.mana_cost),
		"Must not be able to cast HealAction with insufficient mana")
