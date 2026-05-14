## Spawns projectiles toward the nearest enemy on `attack` input.
## Must be a direct child of Player. Triggers Hitstop and IsoCamera shake on each fire.
## See `.claude/docs/combat_and_progression.md` for the full attack flow.
class_name AttackComponent
extends Node3D

## Emitted after a projectile is launched. `target` may be null when no enemy was in range.
signal attack_performed(target: Node3D)

const HITSTOP_DURATION: float = 0.05
const SHAKE_INTENSITY: float = 0.05
const SHAKE_DURATION: float = 0.05

@export var cooldown: float = 0.4
@export var projectile_scene: PackedScene

@onready var _player: Player = get_parent() as Player
@onready var _detection_area: Area3D = $DetectionArea
@onready var _cooldown_timer: Timer = $CooldownTimer
var _camera: IsoCamera

func _ready() -> void:
	assert(_player != null, "AttackComponent must be a direct child of Player")
	_cooldown_timer.wait_time = cooldown
	_camera = get_tree().get_first_node_in_group(&"camera") as IsoCamera

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"attack") and can_attack():
		_perform_attack()

## True while the cooldown timer is idle. Gates `_perform_attack()`.
func can_attack() -> bool:
	return _cooldown_timer.is_stopped()

## Returns the candidate with the smallest squared distance to `origin`, or null on empty input.
func select_nearest_target(candidates: Array[Node3D], origin: Vector3) -> Node3D:
	var best: Node3D = null
	var best_d2: float = INF
	for n: Node3D in candidates:
		if n == null or not is_instance_valid(n):
			continue
		var d2: float = origin.distance_squared_to(n.global_position)
		if d2 < best_d2:
			best_d2 = d2
			best = n
	return best

func _gather_enemies_in_range() -> Array[Node3D]:
	var out: Array[Node3D] = []
	for body: Node3D in _detection_area.get_overlapping_bodies():
		if body.is_in_group(&"enemies"):
			out.append(body)
	for area: Area3D in _detection_area.get_overlapping_areas():
		if area.is_in_group(&"enemies"):
			out.append(area)
	return out

func _perform_attack() -> void:
	var target: Node3D = select_nearest_target(_gather_enemies_in_range(), global_position)
	var dir: Vector3
	if target != null:
		dir = target.global_position - global_position
		dir.y = 0.0
		dir = dir.normalized()
	else:
		var input_dir: Vector3 = _player.movement.get_input_iso_direction()
		if input_dir.length_squared() > 0.0:
			dir = input_dir
		else:
			dir = -_player.visuals.basis.z
		dir.y = 0.0
		dir = dir.normalized() if dir.length_squared() > 0.0 else Vector3.FORWARD

	_spawn_projectile(dir)
	_apply_hitstop()
	if _camera != null:
		_camera.shake(SHAKE_INTENSITY, SHAKE_DURATION)
	_cooldown_timer.start(cooldown)
	attack_performed.emit(target)

func _spawn_projectile(direction: Vector3) -> void:
	if projectile_scene == null:
		return
	var p: Node3D = projectile_scene.instantiate() as Node3D
	var parent: Node = GameState.current_scene if GameState.current_scene != null \
		else get_tree().current_scene
	parent.add_child(p)
	p.global_position = global_position
	if p.has_method(&"launch"):
		p.call(&"launch", direction)
	else:
		p.set(&"direction", direction)

func _apply_hitstop() -> void:
	# TODO Phase 3: заменить прямое управление time_scale на TimeManager,
	# чтобы не конфликтовать с паузой и другими эффектами замедления.
	Engine.time_scale = 0.0
	var t: SceneTreeTimer = get_tree().create_timer(HITSTOP_DURATION, true, false, true)
	t.timeout.connect(func() -> void: Engine.time_scale = 1.0)
