extends GutTest


func _make_xp_component() -> ExperienceComponent:
	var xp: ExperienceComponent = ExperienceComponent.new()
	add_child_autofree(xp)
	return xp


func test_three_kills_award_30_xp() -> void:
	var xp: ExperienceComponent = _make_xp_component()
	var dummy: Node3D = Node3D.new()
	add_child_autofree(dummy)

	EventBus.enemy_died.emit(dummy, Vector3.ZERO, 10)
	EventBus.enemy_died.emit(dummy, Vector3.ZERO, 10)
	EventBus.enemy_died.emit(dummy, Vector3.ZERO, 10)

	assert_eq(xp.current_xp, 30, "3 kills x 10 XP each must total 30 XP")


func test_xp_triggers_level_up_pending() -> void:
	var xp: ExperienceComponent = ExperienceComponent.new()
	add_child_autofree(xp)

	var pool: Array[SkillData] = []
	var sm: SkillManager = SkillManager.new()
	sm.skill_pool = pool
	add_child_autofree(sm)

	var levels_fired: Array[int] = []
	xp.level_up.connect(func(lvl: int) -> void: levels_fired.append(lvl))

	var required: int = xp.get_required_xp(1)
	var dummy: Node3D = Node3D.new()
	add_child_autofree(dummy)

	EventBus.enemy_died.emit(dummy, Vector3.ZERO, required)

	assert_eq(levels_fired.size(), 1, "Must trigger level_up after reaching required XP")
	assert_eq(levels_fired[0], 2, "Must reach level 2")
