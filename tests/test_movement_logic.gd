extends GutTest

var _player: Player
var _dash: DashComponent

func before_each() -> void:
	_player = Player.new()

	var visuals := Node3D.new()
	visuals.name = "Visuals"
	_player.add_child(visuals)

	var col := CollisionShape3D.new()
	col.shape = CapsuleShape3D.new()
	_player.add_child(col)

	var movement := MovementComponent.new()
	movement.name = "MovementComponent"
	_player.add_child(movement)

	_dash = DashComponent.new()
	_dash.name = "DashComponent"
	_player.add_child(_dash)

	for cfg: Dictionary in [
		{"name": "DurationTimer", "wait_time": 0.2},
		{"name": "CooldownTimer", "wait_time": 1.5},
		{"name": "IframesTimer",  "wait_time": 0.25},
	]:
		var t := Timer.new()
		t.name = cfg["name"]
		t.wait_time = cfg["wait_time"]
		t.one_shot = true
		_dash.add_child(t)

	add_child_autofree(_player)

func test_diagonal_normalization() -> void:
	var iso_basis: Basis = Basis(Vector3.UP, deg_to_rad(45.0))
	var raw_input: Vector2 = Vector2(1.0, 1.0).normalized()
	var iso_dir: Vector3 = iso_basis * Vector3(raw_input.x, 0.0, raw_input.y)
	assert_almost_eq(iso_dir.length(), 1.0, 0.001,
		"Diagonal input vector must stay normalized after iso-rotation")

func test_dash_cooldown_locking() -> void:
	_dash.try_dash()
	assert_true(_dash.is_on_cooldown(),
		"Cooldown must be active immediately after dash activation")

func test_iframes_duration_logical() -> void:
	var iframes_timer: Timer = _dash.get_node("IframesTimer") as Timer
	assert_almost_eq(iframes_timer.wait_time, 0.25, 0.001,
		"IframesTimer.wait_time must be 0.25 s")
	assert_true(iframes_timer.one_shot,
		"IframesTimer must be one_shot")

func test_iframes_duration_async() -> void:
	_dash.try_dash()
	assert_true(_player.is_invulnerable,
		"Player must be invulnerable right after dash starts")
	await get_tree().create_timer(0.3).timeout
	assert_false(_player.is_invulnerable,
		"Player must not be invulnerable after 0.3 s (iframes last 0.25 s)")
