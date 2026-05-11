extends GutTest

var _controller: SpectatorController
var _camera_mock: IsoCamera
var _player_mock: Node3D


func before_each() -> void:
	_player_mock = Node3D.new()
	add_child_autofree(_player_mock)

	_camera_mock = IsoCamera.new()
	_camera_mock.process_mode = Node.PROCESS_MODE_DISABLED
	add_child_autofree(_camera_mock)

	_controller = SpectatorController.new()
	add_child_autofree(_controller)
	_controller._camera = _camera_mock
	_controller._player = _player_mock

	GameState.current_mode = GameState.Mode.DUNGEON


func after_each() -> void:
	GameState.current_mode = GameState.Mode.HUB


func _spawn_ally() -> Node3D:
	var ally := Node3D.new()
	ally.add_to_group(SpectatorController.ALLIES_GROUP)
	add_child_autofree(ally)
	return ally


func test_spectator_activates_on_player_died_signal() -> void:
	var _ally := _spawn_ally()

	EventBus.player_died.emit(_player_mock, &"glitch_pup", Vector3(5.0, 0.0, 5.0))

	assert_true(_controller._is_active,
		"SpectatorController must activate after player_died")
	assert_eq(GameState.current_mode, GameState.Mode.SPECTATOR,
		"Mode must switch to SPECTATOR")


func test_death_position_used_when_player_null() -> void:
	var ally := Node3D.new()
	ally.add_to_group(SpectatorController.ALLIES_GROUP)
	add_child_autofree(ally)
	ally.global_position = Vector3(3.0, 0.0, 0.0)

	var far_ally := Node3D.new()
	far_ally.add_to_group(SpectatorController.ALLIES_GROUP)
	add_child_autofree(far_ally)
	far_ally.global_position = Vector3(30.0, 0.0, 0.0)

	_controller._player = null
	EventBus.player_died.emit(null, &"glitch_pup", Vector3.ZERO)

	assert_eq(_camera_mock.target, ally,
		"Must pick ally nearest to the death position when player is null")


func test_game_over_fires_with_no_allies() -> void:
	watch_signals(EventBus)

	EventBus.player_died.emit(_player_mock, &"glitch_pup", Vector3.ZERO)

	assert_signal_emitted(EventBus, &"game_over")
