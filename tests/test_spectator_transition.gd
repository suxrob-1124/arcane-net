extends GutTest

var _controller: SpectatorController
var _camera_mock: IsoCamera
var _player_mock: Node3D


func before_each() -> void:
	_player_mock = Node3D.new()
	_player_mock.name = &"MockPlayer"
	add_child_autofree(_player_mock)

	_camera_mock = IsoCamera.new()
	_camera_mock.name = &"MockCamera"
	_camera_mock.process_mode = Node.PROCESS_MODE_DISABLED
	add_child_autofree(_camera_mock)

	_controller = SpectatorController.new()
	add_child_autofree(_controller)
	# Inject mocks directly — bypasses NodePath resolution in _ready()
	_controller._camera = _camera_mock
	_controller._player = _player_mock

	GameState.current_mode = GameState.Mode.DUNGEON


func after_each() -> void:
	GameState.current_mode = GameState.Mode.HUB


func _spawn_ally(pos: Vector3 = Vector3.ZERO) -> Node3D:
	var ally := Node3D.new()
	ally.add_to_group(SpectatorController.ALLIES_GROUP)
	add_child_autofree(ally)
	ally.global_position = pos  # после добавления в дерево — global_position требует is_inside_tree()
	return ally


func test_game_over_signal_exists() -> void:
	assert_true(EventBus.has_signal(&"game_over"))


func test_transition_to_spectator_on_ally_present() -> void:
	var _ally := _spawn_ally()
	watch_signals(SpectatorState)

	EventBus.player_died.emit(null, &"test", Vector3.ZERO)

	assert_eq(GameState.current_mode, GameState.Mode.SPECTATOR,
		"Mode must switch to SPECTATOR when allies alive")
	assert_signal_emitted(SpectatorState, &"spectator_mode_entered")


func test_game_over_on_no_allies() -> void:
	watch_signals(EventBus)

	EventBus.player_died.emit(null, &"test", Vector3.ZERO)

	assert_signal_emitted(EventBus, &"game_over",
		"game_over must fire when no alive allies present")
	assert_ne(GameState.current_mode, GameState.Mode.SPECTATOR,
		"Mode must NOT become SPECTATOR on game over")


func test_camera_target_assignment() -> void:
	var ally := _spawn_ally(Vector3(3.0, 0.0, 3.0))

	EventBus.player_died.emit(null, &"test", Vector3.ZERO)

	assert_eq(_camera_mock.target, ally,
		"Camera target must point to the alive ally after player_died")
	assert_true(is_instance_valid(_camera_mock.target))


func test_player_not_freed_after_ghost() -> void:
	var _ally := _spawn_ally()

	EventBus.player_died.emit(null, &"test", Vector3.ZERO)

	assert_true(is_instance_valid(_player_mock),
		"Player node must remain in tree after entering ghost state")


func test_switch_target_cycles_allies() -> void:
	var ally1 := _spawn_ally(Vector3(1.0, 0.0, 0.0))
	var ally2 := _spawn_ally(Vector3(5.0, 0.0, 0.0))

	EventBus.player_died.emit(null, &"test", Vector3.ZERO)
	var first_target: Node3D = _camera_mock.target

	_controller.switch_target()
	var second_target: Node3D = _camera_mock.target

	assert_ne(first_target, second_target,
		"switch_target must cycle to a different ally")
	assert_true(is_instance_valid(second_target))


func test_switch_target_skips_invalid_ally() -> void:
	var ally1 := _spawn_ally(Vector3(1.0, 0.0, 0.0))
	var ally2 := _spawn_ally(Vector3(5.0, 0.0, 0.0))

	EventBus.player_died.emit(null, &"test", Vector3.ZERO)

	# Free the currently focused ally
	_camera_mock.target.queue_free()
	await get_tree().process_frame

	# Must not crash; target must be valid or null
	_controller.switch_target()
	if _camera_mock.target != null:
		assert_true(is_instance_valid(_camera_mock.target),
			"After invalid ally freed, camera target must point to a valid node")
