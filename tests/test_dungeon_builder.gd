extends GutTest


var _builder: DungeonBuilder


func before_each() -> void:
	_builder = DungeonBuilder.new()
	add_child(_builder)


func after_each() -> void:
	_builder.free()


func _make_rooms(count: int) -> Array[RoomNode]:
	var rooms: Array[RoomNode] = []
	var rd: RoomData = RoomData.new()
	rd.scene_path = "res://scenes/dungeon/Room.tscn"
	rd.type = RoomData.RoomType.START

	for i: int in count:
		var rn: RoomNode = RoomNode.new()
		rn.grid_coords = Vector2i(i, 0)
		rn.type = RoomData.RoomType.START if i == 0 else RoomData.RoomType.COMBAT
		rn.room_data = rd.duplicate() as RoomData
		rn.room_data.type = rn.type
		rooms.append(rn)

	# Chain into a line: 0-1-2-...
	for i: int in count - 1:
		rooms[i].connections.append(rooms[i + 1])
		rooms[i + 1].connections.append(rooms[i])

	return rooms


func test_build_creates_correct_node_count() -> void:
	var rooms: Array[RoomNode] = DungeonGenerator.new().generate(42)
	_builder.build(rooms)
	assert_eq(_builder.get_child_count(), rooms.size(),
		"DungeonBuilder child count must equal generated room count")


func test_room_visibility_toggle() -> void:
	var rooms: Array[RoomNode] = _make_rooms(3)
	_builder.build(rooms)

	var visible_count: int = 0
	for i: int in _builder.get_child_count():
		if (_builder.get_child(i) as Node3D).visible:
			visible_count += 1
	assert_eq(visible_count, 1, "After build exactly one room must be visible")

	var other: Node3D = _builder.get_room_at(Vector2i(1, 0))
	assert_not_null(other, "Room at (1,0) must exist")
	_builder.set_active_room(other)

	visible_count = 0
	var visible_room: Node3D = null
	for i: int in _builder.get_child_count():
		var child: Node3D = _builder.get_child(i) as Node3D
		if child.visible:
			visible_count += 1
			visible_room = child
	assert_eq(visible_count, 1, "After set_active_room exactly one room must be visible")
	assert_eq(visible_room, other, "The newly activated room must be the visible one")


func test_room_changed_signal_emission() -> void:
	var rooms: Array[RoomNode] = _make_rooms(2)
	_builder.build(rooms)
	watch_signals(_builder)

	var target: Node3D = _builder.get_room_at(Vector2i(1, 0))
	assert_not_null(target, "Room at (1,0) must exist")
	_builder.set_active_room(target)

	assert_signal_emitted_with_parameters(_builder, "room_changed", [target])
