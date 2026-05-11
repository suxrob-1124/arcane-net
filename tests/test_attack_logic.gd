extends GutTest

var _player: Player
var _attack: AttackComponent

func before_each() -> void:
	_player = Player.new()

	var col := CollisionShape3D.new()
	col.shape = CapsuleShape3D.new()
	_player.add_child(col)

	var visuals := Node3D.new()
	visuals.name = "Visuals"
	_player.add_child(visuals)

	var health := HealthComponent.new()
	health.name = "HealthComponent"
	_player.add_child(health)

	var movement := MovementComponent.new()
	movement.name = "MovementComponent"
	_player.add_child(movement)

	var dash := DashComponent.new()
	dash.name = "DashComponent"
	_player.add_child(dash)

	for cfg: Dictionary in [
		{"name": "DurationTimer", "wait_time": 0.2},
		{"name": "CooldownTimer", "wait_time": 1.5},
		{"name": "IframesTimer",  "wait_time": 0.25},
	]:
		var t := Timer.new()
		t.name = cfg["name"]
		t.wait_time = cfg["wait_time"]
		t.one_shot = true
		dash.add_child(t)

	_attack = AttackComponent.new()
	_attack.name = "AttackComponent"
	_player.add_child(_attack)

	var detection := Area3D.new()
	detection.name = "DetectionArea"
	_attack.add_child(detection)

	var timer := Timer.new()
	timer.name = "CooldownTimer"
	timer.one_shot = true
	_attack.add_child(timer)

	add_child_autofree(_player)

func _make_enemy(pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.add_to_group(&"enemies")
	add_child_autofree(n)
	n.global_position = pos
	return n

func test_target_selection_priority() -> void:
	var far := _make_enemy(Vector3(7.0, 0.0, 0.0))
	var mid := _make_enemy(Vector3(4.0, 0.0, 0.0))
	var near := _make_enemy(Vector3(1.5, 0.0, 0.0))
	var picked: Node3D = _attack.select_nearest_target([far, mid, near], Vector3.ZERO)
	assert_eq(picked, near, "должен выбираться ближайший враг")

func test_cooldown_logic() -> void:
	await get_tree().process_frame
	assert_true(_attack.can_attack(), "стартовое состояние — атака доступна")
	_attack._cooldown_timer.start(_attack.cooldown)
	assert_false(_attack.can_attack(), "во время cooldown атака запрещена")
	await get_tree().create_timer(0.45).timeout
	assert_true(_attack.can_attack(), "после cooldown атака снова доступна")

func test_attack_signals() -> void:
	watch_signals(_attack)
	var dummy := _make_enemy(Vector3(2.0, 0.0, 0.0))
	_attack.attack_performed.emit(dummy)
	assert_signal_emitted_with_parameters(_attack, "attack_performed", [dummy])
