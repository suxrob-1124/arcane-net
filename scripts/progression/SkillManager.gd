class_name SkillManager
extends Node

@export var skill_pool: Array[SkillData] = []
@export var choices_per_level: int = 3
@export var skill_host_path: NodePath

const RARITY_WEIGHTS: Dictionary = {
	SkillData.Rarity.COMMON: 60,
	SkillData.Rarity.RARE: 25,
	SkillData.Rarity.EPIC: 10,
	SkillData.Rarity.LEGENDARY: 5,
}

var _active: Dictionary = {}
var _skill_host: Node

signal level_up_pending(choices: Array[SkillData])
signal skill_added(skill: SkillData)
signal skill_evolved(from: SkillData, to: SkillData)

func _ready() -> void:
	_skill_host = get_node_or_null(skill_host_path) if not skill_host_path.is_empty() else self
	if _skill_host == null:
		_skill_host = self

# --- Public API ----------------------------------------------------------

func get_random_choices(count: int = 3) -> Array[SkillData]:
	var available: Array[SkillData] = _build_available_pool()
	var result: Array[SkillData] = []
	var working: Array[SkillData] = available.duplicate()

	for _i: int in count:
		if working.is_empty():
			break
		var pick: SkillData = _weighted_pick(working)
		if pick == null:
			break
		result.append(pick)
		working.erase(pick)

	return result

func apply_skill(skill: SkillData) -> void:
	if skill == null:
		return

	if _active.has(skill.id):
		var entry: Dictionary = _active[skill.id]
		var data: SkillData = entry["data"]
		var current: int = entry["stacks"]
		if current >= data.max_stacks and data.evolves_into != null:
			_evolve(skill.id, data.evolves_into)
			return
		if current < data.max_stacks:
			entry["stacks"] = current + 1
			skill_added.emit(data)
		return

	_add_new(skill)

func get_active_stacks(id: StringName) -> int:
	if _active.has(id):
		return (_active[id] as Dictionary)["stacks"]
	return 0

func has_skill(id: StringName) -> bool:
	return _active.has(id)

func request_level_up_choice() -> void:
	var choices: Array[SkillData] = get_random_choices(choices_per_level)
	level_up_pending.emit(choices)

# --- Internals -----------------------------------------------------------

func _add_new(skill: SkillData) -> void:
	var instance: Node = null
	if skill.implementation_scene != null:
		instance = skill.implementation_scene.instantiate()
		if "data" in instance:
			instance.set("data", skill)
		_skill_host.add_child(instance)
	_active[skill.id] = { "data": skill, "stacks": 1, "instance": instance }
	skill_added.emit(skill)

func _evolve(old_id: StringName, new_skill: SkillData) -> void:
	var old_entry: Dictionary = _active[old_id]
	var old_data: SkillData = old_entry["data"]
	var old_instance: Node = old_entry.get("instance", null)

	if old_instance != null and is_instance_valid(old_instance):
		old_instance.queue_free()

	_active.erase(old_id)
	_add_new(new_skill)
	skill_evolved.emit(old_data, new_skill)

func _build_available_pool() -> Array[SkillData]:
	var owned_ids: Array[StringName] = []
	for id: StringName in _active.keys():
		owned_ids.append(id)

	var out: Array[SkillData] = []
	for skill: SkillData in skill_pool:
		if skill == null or skill.id == &"":
			continue

		var has_conflict: bool = false
		for cid: StringName in skill.conflicts_with:
			if cid in owned_ids:
				has_conflict = true
				break
		if has_conflict:
			continue

		var prereq_ok: bool = true
		for rid: StringName in skill.requires_skills:
			if not (rid in owned_ids):
				prereq_ok = false
				break
		if not prereq_ok:
			continue

		if skill.id in owned_ids:
			var entry: Dictionary = _active[skill.id]
			var data: SkillData = entry["data"]
			var stacks_now: int = entry["stacks"]
			if stacks_now >= data.max_stacks:
				if data.evolves_into != null:
					out.append(data.evolves_into)
				continue
		out.append(skill)

	return out

func _weighted_pick(pool: Array[SkillData]) -> SkillData:
	if pool.is_empty():
		return null

	var by_rarity: Dictionary = {}
	for s: SkillData in pool:
		if not by_rarity.has(s.rarity):
			by_rarity[s.rarity] = []
		(by_rarity[s.rarity] as Array).append(s)

	var order: Array = [
		SkillData.Rarity.LEGENDARY,
		SkillData.Rarity.EPIC,
		SkillData.Rarity.RARE,
		SkillData.Rarity.COMMON,
	]
	var total: int = 0
	for r in order:
		if by_rarity.has(r):
			total += int(RARITY_WEIGHTS[r])

	if total <= 0:
		return null

	var roll: int = randi() % total
	var acc: int = 0
	for r in order:
		if not by_rarity.has(r):
			continue
		acc += int(RARITY_WEIGHTS[r])
		if roll < acc:
			var bucket: Array = by_rarity[r]
			return bucket[randi() % bucket.size()]
	return null
