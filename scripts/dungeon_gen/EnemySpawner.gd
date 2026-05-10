class_name EnemySpawner
extends Node

signal all_enemies_defeated()

@export var room_data: RoomData
@export var detection_area_path: NodePath
@export var door_path: NodePath
@export var spawn_points_root_path: NodePath
@export var spawn_delay_min: float = 0.1
@export var spawn_delay_max: float = 0.3

var is_cleared: bool = false
var active_enemies: Array[Node] = []

var _has_spawned: bool = false
var _is_spawning: bool = false
var _spawn_points: Array[Marker3D] = []
var _detection_area: Area3D
var _door: Door

func _ready() -> void:
	if not detection_area_path.is_empty():
		_detection_area = get_node(detection_area_path) as Area3D
		_detection_area.body_entered.connect(_on_body_entered)

	if not door_path.is_empty():
		_door = get_node(door_path) as Door

	var sp_root: Node
	if not spawn_points_root_path.is_empty():
		sp_root = get_node(spawn_points_root_path)
	else:
		sp_root = get_parent()

	for child in sp_root.get_children():
		if child is Marker3D and str(child.name).begins_with("SpawnPoint"):
			_spawn_points.append(child as Marker3D)

	EventBus.enemy_died.connect(_on_enemy_died)

func _on_body_entered(body: Node3D) -> void:
	if _has_spawned or _is_spawning:
		return
	if not body.is_in_group(&"player"):
		return
	_begin_encounter()

func _begin_encounter() -> void:
	_has_spawned = true
	_is_spawning = true
	_door.lock()

	var count: int = _calculate_spawn_count()
	var point_count: int = _spawn_points.size()

	if point_count == 0:
		push_warning("EnemySpawner: no SpawnPoint Marker3D nodes found")
		_is_spawning = false
		return

	if room_data == null or room_data.possible_enemies.is_empty():
		push_warning("EnemySpawner: room_data has no possible_enemies")
		_is_spawning = false
		return

	for i in count:
		var data: EnemyData = room_data.possible_enemies[randi() % room_data.possible_enemies.size()]
		var enemy: Node3D = data.enemy_scene.instantiate() as Node3D
		var point: Marker3D = _spawn_points[i % point_count]
		get_parent().add_child(enemy)
		enemy.global_position = point.global_position
		enemy.add_to_group(&"enemies")
		active_enemies.append(enemy)
		_spawn_flash(point.global_position)
		if spawn_delay_max > 0.0:
			await get_tree().create_timer(randf_range(spawn_delay_min, spawn_delay_max)).timeout

	_is_spawning = false

func _calculate_spawn_count() -> int:
	return room_data.base_enemy_count * room_data.difficulty_tier * GameState.player_count

func _on_enemy_died(enemy: Node) -> void:
	active_enemies.erase(enemy)
	if _is_spawning:
		return
	if active_enemies.is_empty() and not is_cleared:
		is_cleared = true
		_door.unlock()
		all_enemies_defeated.emit()
		EventBus.room_cleared.emit(str(get_path()))

func _spawn_flash(pos: Vector3) -> void:
	var particles: CPUParticles3D = CPUParticles3D.new()
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 12
	particles.lifetime = 0.4
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 0.3
	particles.color = Color(1.0, 0.5, 0.1)
	particles.initial_velocity_min = 2.0
	particles.initial_velocity_max = 4.0
	particles.scale_amount_min = 0.1
	particles.scale_amount_max = 0.3
	particles.position = pos
	particles.emitting = true
	get_parent().add_child(particles)

	var timer: Timer = Timer.new()
	timer.wait_time = 0.6
	timer.one_shot = true
	get_parent().add_child(timer)
	timer.timeout.connect(particles.queue_free)
	timer.timeout.connect(timer.queue_free)
	timer.start()
