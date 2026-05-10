extends GutTest

const CLEAVE_SCENE := preload("res://scenes/combat/Skill_Cleave.tscn")

func _make_skill(
	id: StringName,
	rarity: int,
	max_stacks: int = 5,
	evolves_into: SkillData = null,
	conflicts: Array[StringName] = [],
	requires: Array[StringName] = [],
	scene: PackedScene = null
) -> SkillData:
	var s: SkillData = SkillData.new()
	s.id = id
	s.rarity = rarity
	s.max_stacks = max_stacks
	s.evolves_into = evolves_into
	s.conflicts_with = conflicts
	s.requires_skills = requires
	s.implementation_scene = scene
	return s

func _make_manager(pool: Array[SkillData]) -> SkillManager:
	var m: SkillManager = SkillManager.new()
	m.skill_pool = pool
	add_child_autofree(m)
	return m

func test_weighted_rarity_distribution() -> void:
	seed(12345)
	var pool: Array[SkillData] = [
		_make_skill(&"c", SkillData.Rarity.COMMON),
		_make_skill(&"r", SkillData.Rarity.RARE),
		_make_skill(&"e", SkillData.Rarity.EPIC),
		_make_skill(&"l", SkillData.Rarity.LEGENDARY),
	]
	var m: SkillManager = _make_manager(pool)

	var counts: Dictionary = {
		SkillData.Rarity.COMMON: 0,
		SkillData.Rarity.RARE: 0,
		SkillData.Rarity.EPIC: 0,
		SkillData.Rarity.LEGENDARY: 0,
	}
	var n: int = 1000
	for i: int in n:
		var choices: Array[SkillData] = m.get_random_choices(1)
		assert_eq(choices.size(), 1, "must always return 1 choice from non-empty pool")
		counts[choices[0].rarity] += 1

	var p_common: float = float(counts[SkillData.Rarity.COMMON]) / float(n)
	var p_rare: float = float(counts[SkillData.Rarity.RARE]) / float(n)
	var p_epic: float = float(counts[SkillData.Rarity.EPIC]) / float(n)
	var p_legendary: float = float(counts[SkillData.Rarity.LEGENDARY]) / float(n)

	assert_between(p_common, 0.54, 0.66, "Common ~60%%, got %.3f" % p_common)
	assert_between(p_rare, 0.21, 0.29, "Rare ~25%%, got %.3f" % p_rare)
	assert_between(p_epic, 0.07, 0.13, "Epic ~10%%, got %.3f" % p_epic)
	assert_between(p_legendary, 0.03, 0.07, "Legendary ~5%%, got %.3f" % p_legendary)

func test_conflict_exclusion() -> void:
	var cleave: SkillData = _make_skill(&"cleave", SkillData.Rarity.COMMON)
	var whirlwind: SkillData = _make_skill(
		&"whirlwind", SkillData.Rarity.RARE, 5, null, [&"cleave"] as Array[StringName]
	)
	var m: SkillManager = _make_manager([cleave, whirlwind] as Array[SkillData])
	m.apply_skill(cleave)

	for i: int in 100:
		var choices: Array[SkillData] = m.get_random_choices(2)
		for c: SkillData in choices:
			assert_ne(c.id, &"whirlwind",
				"whirlwind must never appear when cleave is active")

func test_requires_skills_gating() -> void:
	var fireball: SkillData = _make_skill(&"fireball", SkillData.Rarity.COMMON)
	var meteor: SkillData = _make_skill(
		&"meteor", SkillData.Rarity.EPIC, 5, null,
		[] as Array[StringName],
		[&"fireball"] as Array[StringName]
	)
	var m: SkillManager = _make_manager([fireball, meteor] as Array[SkillData])

	for i: int in 100:
		var choices: Array[SkillData] = m.get_random_choices(2)
		for c: SkillData in choices:
			assert_ne(c.id, &"meteor",
				"meteor must not appear without fireball")

	m.apply_skill(fireball)
	var saw_meteor: bool = false
	for i: int in 200:
		var choices2: Array[SkillData] = m.get_random_choices(2)
		for c: SkillData in choices2:
			if c.id == &"meteor":
				saw_meteor = true
				break
		if saw_meteor:
			break
	assert_true(saw_meteor, "meteor must appear after fireball acquired")

func test_skill_evolution_logic() -> void:
	var great: SkillData = _make_skill(&"great_cleave", SkillData.Rarity.LEGENDARY, 1)
	var cleave: SkillData = _make_skill(&"cleave", SkillData.Rarity.COMMON, 3, great)
	var m: SkillManager = _make_manager([cleave] as Array[SkillData])

	var added_count: Array[int] = [0]
	var evolved_count: Array[int] = [0]
	m.skill_added.connect(func(_s: SkillData) -> void: added_count[0] += 1)
	m.skill_evolved.connect(func(_f: SkillData, _t: SkillData) -> void: evolved_count[0] += 1)

	m.apply_skill(cleave)
	m.apply_skill(cleave)
	m.apply_skill(cleave)
	assert_eq(m.get_active_stacks(&"cleave"), 3, "cleave should have 3 stacks")

	m.apply_skill(cleave)
	assert_false(m.has_skill(&"cleave"), "cleave must be removed after evolution")
	assert_true(m.has_skill(&"great_cleave"), "great_cleave must be active")
	assert_eq(m.get_active_stacks(&"great_cleave"), 1, "great_cleave starts at 1 stack")
	assert_eq(added_count[0], 4, "skill_added fires 3x for cleave + 1x for great_cleave")
	assert_eq(evolved_count[0], 1, "skill_evolved fires exactly once")

func test_evolution_frees_old_instance() -> void:
	var great: SkillData = _make_skill(&"great_cleave", SkillData.Rarity.LEGENDARY, 1, null,
		[] as Array[StringName], [] as Array[StringName], CLEAVE_SCENE)
	var cleave: SkillData = _make_skill(&"cleave", SkillData.Rarity.COMMON, 3, great,
		[] as Array[StringName], [] as Array[StringName], CLEAVE_SCENE)
	var m: SkillManager = _make_manager([cleave] as Array[SkillData])

	m.apply_skill(cleave)
	var entry: Dictionary = m._active[&"cleave"]
	var old_instance: Node = entry["instance"]
	assert_not_null(old_instance, "instance must be created from implementation_scene")
	assert_eq(m._skill_host.get_child_count(), 1, "exactly one skill instance under host")

	m.apply_skill(cleave)
	m.apply_skill(cleave)
	m.apply_skill(cleave)

	assert_true(old_instance.is_queued_for_deletion(),
		"old cleave instance must be queue_freed on evolution")

	# Дать обработать queue_free.
	await get_tree().process_frame

	assert_eq(m._skill_host.get_child_count(), 1,
		"only the new great_cleave instance remains under host")
	assert_true(m._active.has(&"great_cleave"), "great_cleave entry exists")
	var new_entry: Dictionary = m._active[&"great_cleave"]
	assert_not_null(new_entry["instance"], "new instance must be created")
	assert_true(is_instance_valid(new_entry["instance"]), "new instance is valid")

func test_max_stacks_offers_evolution_in_choices() -> void:
	var great: SkillData = _make_skill(&"great_cleave", SkillData.Rarity.LEGENDARY, 1)
	var cleave: SkillData = _make_skill(&"cleave", SkillData.Rarity.COMMON, 2, great)
	var filler: SkillData = _make_skill(&"filler", SkillData.Rarity.COMMON)
	var m: SkillManager = _make_manager([cleave, filler] as Array[SkillData])

	m.apply_skill(cleave)
	m.apply_skill(cleave)
	assert_eq(m.get_active_stacks(&"cleave"), 2, "cleave at max_stacks")

	var saw_great: bool = false
	for i: int in 50:
		var choices: Array[SkillData] = m.get_random_choices(3)
		for c: SkillData in choices:
			assert_ne(c.id, &"cleave",
				"saturated cleave must not appear in choices")
			if c.id == &"great_cleave":
				saw_great = true
	assert_true(saw_great, "great_cleave must appear when cleave saturated")

func test_no_duplicates_in_single_choice() -> void:
	var pool: Array[SkillData] = [
		_make_skill(&"a", SkillData.Rarity.COMMON),
		_make_skill(&"b", SkillData.Rarity.COMMON),
		_make_skill(&"c", SkillData.Rarity.RARE),
		_make_skill(&"d", SkillData.Rarity.EPIC),
		_make_skill(&"e", SkillData.Rarity.LEGENDARY),
	]
	var m: SkillManager = _make_manager(pool)

	for i: int in 50:
		var choices: Array[SkillData] = m.get_random_choices(3)
		assert_eq(choices.size(), 3, "should return 3 choices")
		var ids: Array[StringName] = []
		for c: SkillData in choices:
			assert_false(c.id in ids, "duplicate id %s in single choice" % c.id)
			ids.append(c.id)

func test_level_up_pending_signal() -> void:
	var pool: Array[SkillData] = [
		_make_skill(&"a", SkillData.Rarity.COMMON),
		_make_skill(&"b", SkillData.Rarity.RARE),
		_make_skill(&"c", SkillData.Rarity.EPIC),
	]
	var m: SkillManager = _make_manager(pool)
	m.choices_per_level = 3

	var emitted: Array = []
	m.level_up_pending.connect(func(choices: Array[SkillData]) -> void: emitted.append(choices))

	m.request_level_up_choice()

	assert_eq(emitted.size(), 1, "level_up_pending must emit exactly once")
	var got: Array[SkillData] = emitted[0]
	assert_eq(got.size(), 3, "must contain choices_per_level options")
