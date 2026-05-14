class_name DashComponent
extends Node

signal dash_started(direction: Vector3)
signal dash_ended()

## 4.0 м / 0.2 с = 20.0 ед/с
const DASH_SPEED: float = 20.0

@onready var _duration_timer: Timer = $DurationTimer
@onready var _cooldown_timer: Timer = $CooldownTimer
@onready var _iframes_timer: Timer = $IframesTimer

var _player: Player
var _dash_dir: Vector3 = Vector3.ZERO

func _ready() -> void:
	_player = get_parent() as Player
	assert(_player != null, "DashComponent must be a direct child of Player")
	_duration_timer.timeout.connect(_on_duration_timer_timeout)
	_iframes_timer.timeout.connect(_on_iframes_timer_timeout)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"dash"):
		try_dash()

func _physics_process(_delta: float) -> void:
	if not is_dashing():
		return
	_player.velocity = _dash_dir * DASH_SPEED
	_player.move_and_slide()

func try_dash() -> void:
	if is_on_cooldown():
		return

	_dash_dir = _player.movement.get_input_iso_direction()
	if _dash_dir == Vector3.ZERO:
		_dash_dir = -_player.visuals.basis.z

	_player.add_invuln_source()
	_player.is_dashing = true
	_player.movement.set_movement_enabled(false)
	_player.velocity = _dash_dir * DASH_SPEED

	_duration_timer.start()
	_cooldown_timer.start()
	_iframes_timer.start()

	dash_started.emit(_dash_dir)

func is_on_cooldown() -> bool:
	return not _cooldown_timer.is_stopped()

func is_dashing() -> bool:
	return not _duration_timer.is_stopped()

func _on_duration_timer_timeout() -> void:
	_player.is_dashing = false
	_player.movement.set_movement_enabled(true)
	_player.velocity = Vector3.ZERO
	dash_ended.emit()

func _on_iframes_timer_timeout() -> void:
	_player.remove_invuln_source()
