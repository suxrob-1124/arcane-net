extends GutTest

func test_gamestate_initial_mode() -> void:
	assert_eq(GameState.current_mode, GameState.Mode.HUB,
		"Default mode must be HUB")

func test_eventbus_signals() -> void:
	assert_true(EventBus.has_signal(&"player_died"))
	assert_true(EventBus.has_signal(&"room_cleared"))
	assert_true(EventBus.has_signal(&"skill_picked"))

func test_input_manager_platform() -> void:
	var platform: String = InputManager.get_platform()
	assert_ne(platform, "", "Platform string must not be empty")
