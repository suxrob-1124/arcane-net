extends GutTest


func _make_component() -> ManaComponent:
	var c := ManaComponent.new()
	add_child_autofree(c)
	return c


func test_spend_succeeds_when_enough() -> void:
	var c := _make_component()
	c.current_mana = 100.0
	var result := c.spend(40.0)
	assert_true(result, "spend(40) with 100 mana must return true")
	assert_almost_eq(c.current_mana, 60.0, 0.001, "current_mana must be 60 after spending 40")


func test_spend_fails_when_insufficient() -> void:
	var c := _make_component()
	c.current_mana = 30.0
	var result := c.spend(50.0)
	assert_false(result, "spend(50) with 30 mana must return false")
	assert_almost_eq(c.current_mana, 30.0, 0.001, "mana must remain 30 after failed spend")


func test_mana_regeneration_rate() -> void:
	var c := _make_component()
	c.max_mana = 100.0
	c.regen_per_minute = 8.0
	c.current_mana = 0.0
	# Simulate 60 seconds: 600 ticks × 0.1 s
	for _i in range(600):
		c._process(0.1)
	assert_almost_eq(c.current_mana, 8.0, 0.01, "mana must regenerate exactly 8 in 60 simulated seconds")
