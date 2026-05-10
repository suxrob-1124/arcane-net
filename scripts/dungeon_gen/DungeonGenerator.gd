class_name DungeonGenerator
extends RefCounted

const MIN_ROOMS: int = 9
const MAX_ROOMS: int = 12
const DIRS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
]

var _rng: RandomNumberGenerator


func generate(seed_value: int) -> Array[RoomNode]:
	_rng = RandomNumberGenerator.new()
	_rng.seed = seed_value
	var rooms: Array[RoomNode] = _drunkard_walk()
	connect_neighbors(rooms)
	assign_room_types(rooms)
	return rooms


func _drunkard_walk() -> Array[RoomNode]:
	var target_count: int = _rng.randi_range(MIN_ROOMS, MAX_ROOMS)
	var occupied: Dictionary = {}
	var rooms: Array[RoomNode] = []

	var start: RoomNode = RoomNode.new()
	start.grid_coords = Vector2i.ZERO
	rooms.append(start)
	occupied[Vector2i.ZERO] = start

	var cur: Vector2i = Vector2i.ZERO
	var iterations: int = 0
	const MAX_ITER: int = 10000

	while rooms.size() < target_count:
		iterations += 1
		if iterations > MAX_ITER:
			push_warning("DungeonGenerator: drunkard walk exceeded %d iterations" % MAX_ITER)
			break

		var step: Vector2i = DIRS[_rng.randi() % 4]
		var next: Vector2i = cur + step

		if occupied.has(next):
			cur = next
		else:
			var room: RoomNode = RoomNode.new()
			room.grid_coords = next
			rooms.append(room)
			occupied[next] = room
			cur = next

	return rooms


func connect_neighbors(rooms: Array[RoomNode]) -> void:
	if rooms.is_empty():
		return

	var occupied: Dictionary = {}
	for room: RoomNode in rooms:
		occupied[room.grid_coords] = room

	var visited: Dictionary = {}
	var queue: Array[RoomNode] = [rooms[0]]
	visited[rooms[0].grid_coords] = true

	while not queue.is_empty():
		var current: RoomNode = queue.pop_front()
		for dir: Vector2i in DIRS:
			var neighbor_coords: Vector2i = current.grid_coords + dir
			if occupied.has(neighbor_coords) and not visited.has(neighbor_coords):
				var neighbor: RoomNode = occupied[neighbor_coords]
				current.connections.append(neighbor)
				neighbor.connections.append(current)
				visited[neighbor_coords] = true
				queue.append(neighbor)


func assign_room_types(rooms: Array[RoomNode]) -> void:
	if rooms.is_empty():
		return

	rooms[0].type = RoomData.RoomType.START

	var boss_node: RoomNode = _find_farthest_by_bfs(rooms[0])
	boss_node.type = RoomData.RoomType.BOSS

	var remaining: Array[RoomNode] = []
	for room: RoomNode in rooms:
		if room.type != RoomData.RoomType.START and room.type != RoomData.RoomType.BOSS:
			remaining.append(room)

	var total: int = rooms.size()
	var elite_min: int = maxi(1, total - 10)
	var elite_max: int = mini(2, total - 8)
	var elite_count: int = _rng.randi_range(elite_min, elite_max)

	var reward_idx: int = _rng.randi() % remaining.size()
	remaining[reward_idx].type = RoomData.RoomType.REWARD
	remaining.remove_at(reward_idx)

	var elite_assigned: int = 0
	while elite_assigned < elite_count and not remaining.is_empty():
		var idx: int = _rng.randi() % remaining.size()
		remaining[idx].type = RoomData.RoomType.ELITE
		remaining.remove_at(idx)
		elite_assigned += 1

	for room: RoomNode in remaining:
		room.type = RoomData.RoomType.COMBAT

	for room: RoomNode in rooms:
		var rd: RoomData = RoomData.new()
		rd.type = room.type
		rd.display_name = RoomData.RoomType.keys()[room.type]
		room.room_data = rd


func _find_farthest_by_bfs(start: RoomNode) -> RoomNode:
	var visited: Dictionary = {}
	var queue: Array[RoomNode] = [start]
	visited[start] = true
	var farthest: RoomNode = start

	while not queue.is_empty():
		var current: RoomNode = queue.pop_front()
		farthest = current
		for neighbor: RoomNode in current.connections:
			if not visited.has(neighbor):
				visited[neighbor] = true
				queue.append(neighbor)

	return farthest
