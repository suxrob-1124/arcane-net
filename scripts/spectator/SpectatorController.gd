## Drives the death-to-spectator transition. Listens to `EventBus.player_died`,
## freezes the camera, ghosts the player, picks the nearest live ally, and switches
## targets on the `switch_target` input. See `.claude/docs/spectator_mode.md`.
class_name SpectatorController
extends Node

const ALLIES_GROUP: StringName = &"allies"

@export var camera_path: NodePath
@export var player_path: NodePath

var _camera: IsoCamera
var _player: Node3D
var _current_target: Node3D = null
var _allies_cache: Array[Node3D] = []
var _is_active: bool = false


func _ready() -> void:
	_camera = get_node_or_null(camera_path) as IsoCamera
	_player = get_node_or_null(player_path) as Node3D
	EventBus.player_died.connect(_on_player_died)


func _unhandled_input(event: InputEvent) -> void:
	if not _is_active:
		return
	if event.is_action_pressed(&"switch_target"):
		switch_target()


func _on_player_died(_player_node: Node3D, _cause: StringName, death_position: Vector3) -> void:
	# Detach camera from the (soon-to-be-ghost) player FIRST so it doesn't
	# end up framing whatever enemy walks over the corpse position.
	_freeze_camera_at(death_position)

	if _player != null and _player.has_method(&"enter_ghost_state"):
		_player.enter_ghost_state()
	var allies := find_alive_allies()
	if allies.is_empty():
		EventBus.game_over.emit()
		return
	_allies_cache = allies
	_current_target = _pick_nearest_ally(allies, death_position)
	_assign_camera_target(_current_target)
	_is_active = true
	SpectatorState.enter_spectator_mode()


func _freeze_camera_at(pos: Vector3) -> void:
	if _camera == null:
		return
	_camera.target = null
	_camera.global_position = pos + _camera.offset
	_camera.look_at(pos)


## Cycles to the next live ally in `_allies_cache`. Wraps around at the end.
func switch_target() -> void:
	_allies_cache = find_alive_allies()
	if _allies_cache.is_empty():
		return
	var idx: int = -1
	if is_instance_valid(_current_target):
		idx = _allies_cache.find(_current_target)
	var next_idx: int = (idx + 1) % _allies_cache.size() if idx != -1 else 0
	_current_target = _allies_cache[next_idx]
	_assign_camera_target(_current_target)


## Reserved for free-camera spectator mode. Stub.
func enable_free_look() -> void:
	pass


## Returns every Node3D in group `&"allies"` that is not in `&"enemies"` and reports `is_alive()`.
func find_alive_allies() -> Array[Node3D]:
	var out: Array[Node3D] = []
	for n in get_tree().get_nodes_in_group(ALLIES_GROUP):
		if not is_instance_valid(n):
			continue
		if n.is_in_group(&"enemies"):
			continue
		if n is Node3D and _is_alive(n):
			out.append(n)
	return out


func _is_alive(n: Node) -> bool:
	if n.has_method(&"is_alive"):
		return n.is_alive()
	return true


func _pick_nearest_ally(allies: Array[Node3D], origin: Vector3) -> Node3D:
	var best: Node3D = allies[0]
	var best_dist: float = origin.distance_squared_to(best.global_position)
	for i in range(1, allies.size()):
		var d: float = origin.distance_squared_to(allies[i].global_position)
		if d < best_dist:
			best_dist = d
			best = allies[i]
	return best


func _assign_camera_target(t: Node3D) -> void:
	if _camera == null or not is_instance_valid(t):
		return
	_camera.target = t
