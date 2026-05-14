## Handles player movement in isometric space.
## Reads WASD/gamepad input, rotates it 45° to align with the isometric view,
## and applies velocity smoothing to the parent Player via move_and_slide().
## DashComponent disables this component during a dash via [set_movement_enabled].
class_name MovementComponent
extends Node

@export var speed: float = 5.0
@export var acceleration: float = 20.0
@export var deceleration: float = 30.0

var movement_enabled: bool = true

var _player: Player
## Pre-computed isometric rotation basis (+45° around Y).
## Tied to IsoCamera.offset = (8, 12, 8) — recalculate if the offset changes.
var _iso_basis: Basis

func _ready() -> void:
	_player = get_parent() as Player
	assert(_player != null, "MovementComponent must be a direct child of Player")
	_iso_basis = Basis(Vector3.UP, deg_to_rad(45.0))

func _physics_process(delta: float) -> void:
	if not movement_enabled:
		return

	var raw_input: Vector2 = Input.get_vector(
		&"move_left", &"move_right", &"move_up", &"move_down"
	)
	var target_velocity: Vector3 = Vector3.ZERO

	if raw_input != Vector2.ZERO:
		var iso_dir: Vector3 = _iso_basis * Vector3(raw_input.x, 0.0, raw_input.y)
		target_velocity = iso_dir * speed
		if not _player.is_dashing:
			_snap_visuals(iso_dir)

	var rate: float = acceleration if raw_input != Vector2.ZERO else deceleration
	_player.velocity = _player.velocity.move_toward(target_velocity, rate * delta)
	_player.move_and_slide()

func _snap_visuals(direction: Vector3) -> void:
	_player.visuals.look_at(_player.global_position + direction, Vector3.UP)

## Returns the current isometric-rotated input direction (normalized), or Vector3.ZERO when idle.
## Called by DashComponent to determine the dash direction from live input.
func get_input_iso_direction() -> Vector3:
	var raw_input: Vector2 = Input.get_vector(
		&"move_left", &"move_right", &"move_up", &"move_down"
	)
	if raw_input == Vector2.ZERO:
		return Vector3.ZERO
	return _iso_basis * Vector3(raw_input.x, 0.0, raw_input.y)

## Enables or disables movement processing. Called by DashComponent at dash start/end.
func set_movement_enabled(enabled: bool) -> void:
	movement_enabled = enabled
