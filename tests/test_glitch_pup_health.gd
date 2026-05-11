extends GutTest


func _make_health(max_hp: int) -> HealthComponent:
	var h: HealthComponent = HealthComponent.new()
	h.max_hp = max_hp
	add_child_autofree(h)
	return h


func test_take_damage_reduces_hp() -> void:
	var h: HealthComponent = _make_health(30)
	h.take_damage(10)
	assert_eq(h.current_hp, 20, "HP must decrease by damage amount")


func test_take_damage_emits_damaged_signal() -> void:
	var h: HealthComponent = _make_health(30)
	watch_signals(h)
	h.take_damage(5)
	assert_signal_emitted(h, &"damaged")


func test_lethal_damage_emits_died() -> void:
	var h: HealthComponent = _make_health(30)
	watch_signals(h)
	h.take_damage(30)
	assert_signal_emitted(h, &"died")
	assert_false(h.is_alive(), "Must not be alive after lethal damage")


func test_overkill_clamps_to_zero() -> void:
	var h: HealthComponent = _make_health(30)
	h.take_damage(999)
	assert_eq(h.current_hp, 0, "HP must not go below 0")


func test_heal_restores_hp() -> void:
	var h: HealthComponent = _make_health(30)
	h.take_damage(15)
	h.heal(10)
	assert_eq(h.current_hp, 25, "Heal must restore HP")


func test_heal_clamps_to_max() -> void:
	var h: HealthComponent = _make_health(30)
	h.heal(100)
	assert_eq(h.current_hp, 30, "Heal must not exceed max_hp")


func test_heal_on_dead_does_nothing() -> void:
	var h: HealthComponent = _make_health(30)
	h.take_damage(30)
	h.heal(20)
	assert_eq(h.current_hp, 0, "Heal on dead unit must be ignored")


func test_hp_ratio() -> void:
	var h: HealthComponent = _make_health(30)
	h.take_damage(15)
	assert_almost_eq(h.get_hp_ratio(), 0.5, 0.001, "HP ratio must be 0.5 at half HP")


func test_enemy_died_event_fired_on_lethal_damage() -> void:
	watch_signals(EventBus)
	var h: HealthComponent = _make_health(30)
	var dummy_enemy: Node3D = Node3D.new()
	add_child_autofree(dummy_enemy)

	h.died.connect(func(_killer: Node) -> void:
		EventBus.enemy_died.emit(dummy_enemy, dummy_enemy.global_position, 10)
	)

	h.take_damage(30)
	assert_signal_emitted(EventBus, &"enemy_died",
		"enemy_died must fire on lethal damage")
