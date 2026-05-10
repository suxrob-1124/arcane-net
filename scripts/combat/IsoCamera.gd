class_name IsoCamera
extends Camera3D

signal shake_started(intensity: float)

@export var target_path: NodePath
## smoothing: доля оставшегося отставания за секунду (1.0 - pow(smoothing, delta)).
## Диапазон 0.001..0.01 для плейтеста — финальное значение подбирается на ощупь.
@export_range(0.0001, 1.0, 0.0001) var smoothing: float = 0.005
@export var offset: Vector3 = Vector3(8.0, 12.0, 8.0)

var target: Node3D

var _shake_intensity: float = 0.0
var _shake_decay: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	add_to_group(&"camera")
	projection = PROJECTION_ORTHOGONAL
	size = 10.0
	current = true
	_rng.randomize()
	if not target_path.is_empty():
		target = get_node_or_null(target_path) as Node3D
	if target:
		global_position = target.global_position + offset
		look_at(target.global_position)
	else:
		push_warning(&"IsoCamera: target не задан")

func _physics_process(delta: float) -> void:
	if not target:
		return
	var desired_pos: Vector3 = target.global_position + offset
	global_position = global_position.lerp(desired_pos, 1.0 - pow(smoothing, delta))
	if _shake_intensity > 0.0:
		h_offset = _rng.randf_range(-_shake_intensity, _shake_intensity)
		v_offset = _rng.randf_range(-_shake_intensity, _shake_intensity)
		_shake_intensity = maxf(0.0, _shake_intensity - _shake_decay * delta)
	else:
		h_offset = 0.0
		v_offset = 0.0

func shake(intensity: float, duration: float) -> void:
	if duration <= 0.0 or intensity <= 0.0:
		return
	_shake_intensity = maxf(_shake_intensity, intensity)
	_shake_decay = intensity / duration
	shake_started.emit(intensity)
