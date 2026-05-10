extends GutTest


func test_deterministic_generation() -> void:
	var first: Array[RoomNode] = DungeonGenerator.new().generate(42)
	for i: int in 99:
		var other: Array[RoomNode] = DungeonGenerator.new().generate(42)
		assert_eq(other.size(), first.size(), "Room count must match on iteration %d" % i)
		for j: int in first.size():
			assert_eq(other[j].grid_coords, first[j].grid_coords,
				"grid_coords mismatch at room %d on iteration %d" % [j, i])
			assert_eq(other[j].type, first[j].type,
				"type mismatch at room %d on iteration %d" % [j, i])
			assert_eq(other[j].connections.size(), first[j].connections.size(),
				"connections.size() mismatch at room %d on iteration %d" % [j, i])


func test_boss_reachability() -> void:
	var rooms: Array[RoomNode] = DungeonGenerator.new().generate(42)
	var start: RoomNode = _find(rooms, RoomData.RoomType.START)
	var boss: RoomNode = _find(rooms, RoomData.RoomType.BOSS)
	assert_not_null(start, "START room must exist")
	assert_not_null(boss, "BOSS room must exist")
	assert_true(_bfs_reachable(start, boss), "BOSS must be reachable from START")


func test_room_type_counts() -> void:
	for s: int in [1, 42, 1337, 9999]:
		var rooms: Array[RoomNode] = DungeonGenerator.new().generate(s)
		var counts: Dictionary = _counts(rooms)
		assert_eq(counts.get(RoomData.RoomType.START, 0), 1,
			"seed %d: must have exactly 1 START" % s)
		assert_eq(counts.get(RoomData.RoomType.BOSS, 0), 1,
			"seed %d: must have exactly 1 BOSS" % s)
		assert_eq(counts.get(RoomData.RoomType.REWARD, 0), 1,
			"seed %d: must have exactly 1 REWARD" % s)
		assert_between(counts.get(RoomData.RoomType.COMBAT, 0), 5, 7,
			"seed %d: COMBAT count out of range" % s)
		assert_between(counts.get(RoomData.RoomType.ELITE, 0), 1, 2,
			"seed %d: ELITE count out of range" % s)
		assert_between(rooms.size(), 9, 12,
			"seed %d: total room count out of range" % s)


func test_ascii_dump_smoke() -> void:
	var rooms: Array[RoomNode] = DungeonGenerator.new().generate(42)
	print(_ascii_map(rooms))
	assert_true(true, "ASCII dump must not crash")


func _find(rooms: Array[RoomNode], type: RoomData.RoomType) -> RoomNode:
	for room: RoomNode in rooms:
		if room.type == type:
			return room
	return null


func _bfs_reachable(from: RoomNode, to: RoomNode) -> bool:
	if from == null or to == null:
		return false
	var visited: Dictionary = {}
	var queue: Array[RoomNode] = [from]
	visited[from] = true
	while not queue.is_empty():
		var current: RoomNode = queue.pop_front()
		if current == to:
			return true
		for neighbor: RoomNode in current.connections:
			if not visited.has(neighbor):
				visited[neighbor] = true
				queue.append(neighbor)
	return false


func _counts(rooms: Array[RoomNode]) -> Dictionary:
	var result: Dictionary = {}
	for room: RoomNode in rooms:
		result[room.type] = result.get(room.type, 0) + 1
	return result


func _ascii_map(rooms: Array[RoomNode]) -> String:
	if rooms.is_empty():
		return "(empty)"

	var symbols: Dictionary = {
		RoomData.RoomType.START: "S",
		RoomData.RoomType.COMBAT: "C",
		RoomData.RoomType.ELITE: "E",
		RoomData.RoomType.REWARD: "R",
		RoomData.RoomType.BOSS: "B",
	}

	var min_x: int = rooms[0].grid_coords.x
	var max_x: int = rooms[0].grid_coords.x
	var min_y: int = rooms[0].grid_coords.y
	var max_y: int = rooms[0].grid_coords.y
	for room: RoomNode in rooms:
		min_x = mini(min_x, room.grid_coords.x)
		max_x = maxi(max_x, room.grid_coords.x)
		min_y = mini(min_y, room.grid_coords.y)
		max_y = maxi(max_y, room.grid_coords.y)

	var lookup: Dictionary = {}
	for room: RoomNode in rooms:
		lookup[room.grid_coords] = room

	var lines: PackedStringArray = PackedStringArray()
	for y: int in range(min_y, max_y + 1):
		var row: String = ""
		for x: int in range(min_x, max_x + 1):
			var coord: Vector2i = Vector2i(x, y)
			if lookup.has(coord):
				row += symbols.get(lookup[coord].type, "?")
			else:
				row += "."
		lines.append(row)
	return "\n".join(lines)
