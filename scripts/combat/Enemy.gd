class_name Enemy
extends CharacterBody3D

enum State { IDLE, CHASE, ATTACK, DEAD }

@export var data: EnemyData

@onready var health: HealthComponent = $HealthComponent
@onready var visuals: Node3D = $Visuals

var _state: State = State.IDLE
var _player: Node3D = null


func _ready() -> void:
	add_to_group(&"enemies")
	if data != null:
		health.max_hp = data.max_hp
		health.current_hp = data.max_hp
	health.died.connect(_on_died)
	$RetargetTimer.timeout.connect(_retarget)
	$RetargetTimer.start()
	_retarget()


func _physics_process(delta: float) -> void:
	match _state:
		State.IDLE:
			_state_idle()
		State.CHASE:
			_state_chase(delta)
		State.ATTACK:
			_state_attack()
		State.DEAD:
			pass


func _state_idle() -> void:
	if _player == null:
		return
	var dist: float = global_position.distance_to(_player.global_position)
	if dist <= data.chase_radius:
		set_state(State.CHASE)


func _state_chase(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		set_state(State.IDLE)
		return
	var dist: float = global_position.distance_to(_player.global_position)
	if dist <= data.attack_radius:
		set_state(State.ATTACK)
		return
	if dist > data.chase_radius * 1.2:
		set_state(State.IDLE)
		return

	var dir: Vector3 = (
		_player.global_position - global_position
	).normalized()
	dir.y = 0.0
	velocity = dir * data.move_speed
	move_and_slide()

	if dir.length_squared() > 0.01:
		visuals.look_at(global_position + dir, Vector3.UP)


func _state_attack() -> void:
	pass


func set_state(new_state: State) -> void:
	_state = new_state


func _retarget() -> void:
	_player = get_tree().get_first_node_in_group(&"player") as Node3D


func _on_died(killer: Node) -> void:
	set_state(State.DEAD)
	set_physics_process(false)

	var death_pos: Vector3 = global_position
	var xp: int = data.xp_reward if data != null else 0

	_play_death_fx(death_pos)
	EventBus.enemy_died.emit(self, death_pos, xp)
	Hitstop.request(0.05)

	if data != null:
		XPNumberPopup.spawn(get_tree().current_scene, death_pos + Vector3.UP * 0.5, xp)

	await get_tree().create_timer(0.4).timeout
	queue_free()


func _play_death_fx(pos: Vector3) -> void:
	var particles: CPUParticles3D = CPUParticles3D.new()
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 20
	particles.lifetime = 0.5
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 0.3
	particles.initial_velocity_min = 3.0
	particles.initial_velocity_max = 6.0
	particles.scale_amount_min = 0.08
	particles.scale_amount_max = 0.25
	particles.color = Color(0.3, 0.1, 0.9)
	particles.position = pos
	get_parent().add_child(particles)
	particles.emitting = true

	var mesh_inst: MeshInstance3D = visuals.get_child(0) if visuals.get_child_count() > 0 else null
	if mesh_inst is MeshInstance3D:
		var original_mat: Material = mesh_inst.get_active_material(0)
		var flash_mat: StandardMaterial3D = StandardMaterial3D.new()
		flash_mat.albedo_color = Color.WHITE
		flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mesh_inst.set_surface_override_material(0, flash_mat)
		await get_tree().create_timer(0.1).timeout
		mesh_inst.set_surface_override_material(0, original_mat)

	var cleanup: Timer = Timer.new()
	cleanup.wait_time = 0.7
	cleanup.one_shot = true
	get_parent().add_child(cleanup)
	cleanup.timeout.connect(particles.queue_free)
	cleanup.timeout.connect(cleanup.queue_free)
	cleanup.start()


func get_hp_ratio() -> float:
	return health.get_hp_ratio()


func is_alive() -> bool:
	return health.is_alive()
