extends GutTest


func _make_skill(id: StringName, rarity: int) -> SkillData:
	var s: SkillData = SkillData.new()
	s.id = id
	s.rarity = rarity
	s.max_stacks = 5
	return s


func _make_manager(pool: Array[SkillData]) -> SkillManager:
	var m: SkillManager = SkillManager.new()
	m.skill_pool = pool
	add_child_autofree(m)
	return m


func test_get_random_choices_returns_3() -> void:
	var pool: Array[SkillData] = [
		_make_skill(&"a", SkillData.Rarity.COMMON),
		_make_skill(&"b", SkillData.Rarity.COMMON),
		_make_skill(&"c", SkillData.Rarity.RARE),
		_make_skill(&"d", SkillData.Rarity.EPIC),
		_make_skill(&"e", SkillData.Rarity.LEGENDARY),
	]
	var m: SkillManager = _make_manager(pool)

	var choices: Array[SkillData] = m.get_random_choices(3)
	assert_eq(choices.size(), 3, "get_random_choices(3) must return exactly 3 choices")


func test_get_random_choices_no_duplicates() -> void:
	var pool: Array[SkillData] = [
		_make_skill(&"a", SkillData.Rarity.COMMON),
		_make_skill(&"b", SkillData.Rarity.COMMON),
		_make_skill(&"c", SkillData.Rarity.RARE),
		_make_skill(&"d", SkillData.Rarity.EPIC),
		_make_skill(&"e", SkillData.Rarity.LEGENDARY),
	]
	var m: SkillManager = _make_manager(pool)

	for _i: int in 30:
		var choices: Array[SkillData] = m.get_random_choices(3)
		var ids: Array[StringName] = []
		for c: SkillData in choices:
			assert_false(c.id in ids, "No duplicate skills in a single choice set")
			ids.append(c.id)


func test_level_up_triggers_skill_choices_via_eventbus() -> void:
	var pool: Array[SkillData] = [
		_make_skill(&"x", SkillData.Rarity.COMMON),
		_make_skill(&"y", SkillData.Rarity.RARE),
		_make_skill(&"z", SkillData.Rarity.EPIC),
	]
	var m: SkillManager = _make_manager(pool)
	m.choices_per_level = 3

	var pending: Array = []
	m.level_up_pending.connect(func(choices: Array[SkillData]) -> void: pending.append(choices))

	EventBus.level_up_triggered.emit(2)

	assert_eq(pending.size(), 1, "level_up_pending must fire once on level_up_triggered")
	assert_eq((pending[0] as Array).size(), 3,
		"Must return 3 skill choices on level-up")
