extends GutTest

var _room: Node3D
var _spawner: EnemySpawner
var _door: Door

func before_each() -> void:
	GameState.player_count = 1

	_room = Node3D.new()

	var area: Area3D = Area3D.new()
	area.name = "PlayerDetectionArea"
	_room.add_child(area)

	_door = Door.new()
	_door.name = "Door"
	_room.add_child(_door)

	var sp_root: Node3D = Node3D.new()
	sp_root.name = "SpawnPoints"
	_room.add_child(sp_root)
	for i: int in 4:
		var sp: Marker3D = Marker3D.new()
		sp.name = "SpawnPoint%d" % (i + 1)
		sp_root.add_child(sp)

	_spawner = EnemySpawner.new()
	_spawner.detection_area_path = NodePath("../PlayerDetectionArea")
	_spawner.door_path = NodePath("../Door")
	_spawner.spawn_points_root_path = NodePath("../SpawnPoints")
	_spawner.spawn_delay_min = 0.0
	_spawner.spawn_delay_max = 0.0
	_spawner.room_data = _make_room_data(2, 1)
	_room.add_child(_spawner)

	add_child_autofree(_room)

func _make_room_data(base: int, tier: int) -> RoomData:
	var rd: RoomData = RoomData.new()
	rd.base_enemy_count = base
	rd.difficulty_tier = tier
	var ed: EnemyData = EnemyData.new()
	ed.enemy_scene = load("res://scenes/combat/EnemyDummy.tscn")
	rd.possible_enemies = [ed]
	return rd

func _make_player() -> Node3D:
	var p: Node3D = Node3D.new()
	p.add_to_group(&"player")
	add_child_autofree(p)
	return p

func test_spawn_once() -> void:
	var player: Node3D = _make_player()
	_spawner._on_body_entered(player)
	var count_after_first: int = _spawner.active_enemies.size()

	_spawner._on_body_entered(player)
	var count_after_second: int = _spawner.active_enemies.size()

	assert_eq(count_after_first, count_after_second,
		"Second entry must not spawn additional enemies")
	assert_true(_spawner._has_spawned,
		"_has_spawned must be true after first entry")
	assert_true(_door.is_locked,
		"Door must remain locked with live enemies")

func test_spawn_quantity_formula() -> void:
	var cases: Array[Dictionary] = [
		{"base": 1, "tier": 1, "pc": 1, "expected": 1},
		{"base": 2, "tier": 3, "pc": 1, "expected": 6},
		{"base": 3, "tier": 2, "pc": 2, "expected": 12},
	]

	for c: Dictionary in cases:
		var room: Node3D = Node3D.new()

		var area: Area3D = Area3D.new()
		area.name = "PlayerDetectionArea"
		room.add_child(area)

		var door: Door = Door.new()
		door.name = "Door"
		room.add_child(door)

		var sp_root: Node3D = Node3D.new()
		sp_root.name = "SpawnPoints"
		room.add_child(sp_root)
		for i: int in 4:
			var sp: Marker3D = Marker3D.new()
			sp.name = "SpawnPoint%d" % (i + 1)
			sp_root.add_child(sp)

		var spawner: EnemySpawner = EnemySpawner.new()
		spawner.detection_area_path = NodePath("../PlayerDetectionArea")
		spawner.door_path = NodePath("../Door")
		spawner.spawn_points_root_path = NodePath("../SpawnPoints")
		spawner.spawn_delay_min = 0.0
		spawner.spawn_delay_max = 0.0
		spawner.room_data = _make_room_data(c["base"], c["tier"])
		room.add_child(spawner)
		add_child_autofree(room)

		GameState.player_count = c["pc"]
		var player: Node3D = _make_player()
		spawner._on_body_entered(player)

		assert_eq(spawner.active_enemies.size(), c["expected"],
			"base=%d tier=%d pc=%d → expected %d enemies" % [c["base"], c["tier"], c["pc"], c["expected"]])

func test_all_defeated_signal() -> void:
	_spawner.room_data = _make_room_data(2, 1)
	GameState.player_count = 1

	var counter: Array[int] = [0]
	_spawner.all_enemies_defeated.connect(func() -> void: counter[0] += 1)

	var player: Node3D = _make_player()
	_spawner._on_body_entered(player)

	assert_eq(_spawner.active_enemies.size(), 2,
		"Should have 2 active enemies after spawn")
	assert_true(_door.is_locked,
		"Door must be locked when encounter starts")

	var enemy1: Node = _spawner.active_enemies[0]
	EventBus.enemy_died.emit(enemy1)
	assert_eq(counter[0], 0,
		"all_enemies_defeated must not emit after first enemy death")
	assert_true(_door.is_locked,
		"Door must stay locked while one enemy remains")

	var enemy2: Node = _spawner.active_enemies[0]
	EventBus.enemy_died.emit(enemy2)
	assert_eq(counter[0], 1,
		"all_enemies_defeated must emit exactly once after last enemy death")
	assert_false(_door.is_locked,
		"Door must be unlocked after all enemies defeated")
	assert_true(_spawner.is_cleared,
		"is_cleared must be true after room is cleared")
