extends GutTest


func _make_component() -> ExperienceComponent:
	var c: ExperienceComponent = ExperienceComponent.new()
	add_child_autofree(c)
	return c


func test_level_calculation_points() -> void:
	var c: ExperienceComponent = _make_component()
	assert_eq(c.get_required_xp(1), 100, "L1 threshold must be 100")
	assert_between(c.get_required_xp(5), 1117, 1119, "L5 threshold must be ~1118")
	assert_eq(c.get_required_xp(10), 3162, "L10 threshold must be ~3162")


func test_multi_level_up_processing() -> void:
	var c: ExperienceComponent = _make_component()
	# Вычисляем ожидаемый уровень и остаток не хардкодом — формула сама источник истины
	var remaining: int = 10000
	var expected_level: int = 1
	while remaining >= c.get_required_xp(expected_level):
		remaining -= c.get_required_xp(expected_level)
		expected_level += 1

	c.add_xp(10000)
	assert_eq(c.current_level, expected_level,
		"level after +10000 xp must be %d" % expected_level)
	assert_eq(c.current_xp, remaining,
		"remainder xp must be %d" % remaining)


func test_signal_emission_order() -> void:
	var c: ExperienceComponent = _make_component()
	var events: Array = []

	c.xp_gained.connect(func(amount: int, current: int, required: int) -> void:
		events.append(["xp", amount, current, required])
	)
	c.level_up.connect(func(new_level: int) -> void:
		events.append(["lvl", new_level])
	)

	watch_signals(EventBus)
	c.add_xp(150)

	# Порядок: xp_gained(150, 150, 100) → level_up(2) → xp_gained(0, 50, req_L2)
	assert_eq(events.size(), 3, "must emit 3 events for single level-up with remainder")

	assert_eq(events[0][0], "xp", "first event must be xp_gained")
	assert_eq(events[0][1], 150, "xp_gained.amount must be 150")
	assert_eq(events[0][2], 150, "xp_gained.current must be 150 before level-up")
	assert_eq(events[0][3], 100, "xp_gained.required must be L1 threshold 100")

	assert_eq(events[1][0], "lvl", "second event must be level_up")
	assert_eq(events[1][1], 2, "level_up must emit new_level=2")

	assert_eq(events[2][0], "xp", "third event must be xp_gained (UI refresh)")
	assert_eq(events[2][1], 0, "post-levelup xp_gained.amount must be 0")
	assert_eq(events[2][2], 50, "post-levelup current_xp must be 50")
	assert_eq(events[2][3], c.get_required_xp(2), "post-levelup required must be L2 threshold")

	assert_eq(c.current_level, 2, "final level must be 2")
	assert_eq(c.current_xp, 50, "final current_xp must be 50")

	assert_signal_emitted_with_parameters(EventBus, &"level_up_triggered", [2])
