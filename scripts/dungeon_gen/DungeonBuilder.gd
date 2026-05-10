class_name DungeonBuilder
extends Node3D

const ROOM_OFFSET: float = 50.0
const FADE_DURATION: float = 0.2

# Direction name -> Vector2i mapping to find portal nodes by name
const PORTAL_DIRS: Dictionary = {
	"Portal_N": Vector2i(0, -1),
	"Portal_S": Vector2i(0, 1),
	"Portal_E": Vector2i(1, 0),
	"Portal_W": Vector2i(-1, 0),
}

signal room_changed(new_room: Node3D)

@export var player_path: NodePath
@export var fade_layer_path: NodePath

var _rooms_by_coords: Dictionary = {}
var _coords_by_room: Dictionary = {}
var _active_room: Node3D = null
var _player: Node3D = null
var _fade_layer: FadeLayer = null
var _is_transitioning: bool = false


func _ready() -> void:
	if player_path:
		_player = get_node(player_path) as Node3D
	if fade_layer_path:
		_fade_layer = get_node(fade_layer_path) as FadeLayer


func build(rooms: Array[RoomNode]) -> void:
	_rooms_by_coords.clear()
	_coords_by_room.clear()
	_active_room = null

	var start_room: Node3D = null

	for room_node: RoomNode in rooms:
		var coords: Vector2i = room_node.grid_coords
		var scene: PackedScene = load(room_node.room_data.scene_path) as PackedScene
		if not scene:
			push_warning("DungeonBuilder: could not load scene '%s'" % room_node.room_data.scene_path)
			continue

		var inst: Node3D = scene.instantiate() as Node3D
		inst.position = Vector3(coords.x * ROOM_OFFSET, 0.0, coords.y * ROOM_OFFSET)
		inst.visible = false
		inst.process_mode = PROCESS_MODE_DISABLED
		add_child(inst)

		_rooms_by_coords[coords] = inst
		_coords_by_room[inst] = coords

		_configure_portals(inst, room_node)

		if room_node.type == RoomData.RoomType.START:
			start_room = inst

	if start_room:
		set_active_room(start_room)
	elif _rooms_by_coords.size() > 0:
		set_active_room(_rooms_by_coords.values()[0] as Node3D)


func set_active_room(room: Node3D) -> void:
	if _active_room and _active_room != room:
		_active_room.visible = false
		_active_room.process_mode = PROCESS_MODE_DISABLED

	room.visible = true
	room.process_mode = PROCESS_MODE_INHERIT
	_active_room = room
	room_changed.emit(room)


func transition_to(room: Node3D) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true

	if _fade_layer:
		await _fade_layer.fade_out(FADE_DURATION)

	set_active_room(room)

	if _player:
		var spawn: Marker3D = room.get_node_or_null(^"PlayerSpawn") as Marker3D
		if spawn:
			_player.global_position = spawn.global_position

	if _fade_layer:
		await _fade_layer.fade_in(FADE_DURATION)

	_is_transitioning = false


func get_room_at(coords: Vector2i) -> Node3D:
	return _rooms_by_coords.get(coords, null) as Node3D


func _configure_portals(room_inst: Node3D, room_node: RoomNode) -> void:
	var neighbor_dirs: Dictionary = {}
	for neighbor: RoomNode in room_node.connections:
		var rel: Vector2i = neighbor.grid_coords - room_node.grid_coords
		neighbor_dirs[rel] = true

	for portal_name: String in PORTAL_DIRS:
		var dir: Vector2i = PORTAL_DIRS[portal_name]
		var portal: Portal = room_inst.get_node_or_null(NodePath(portal_name)) as Portal
		if not portal:
			continue
		if neighbor_dirs.has(dir):
			portal.direction = dir
			portal.monitoring = true
			portal.portal_entered.connect(_on_portal_entered)
		else:
			portal.monitoring = false


func _on_portal_entered(portal: Portal, body: Node3D) -> void:
	if body != _player:
		return
	if _is_transitioning:
		return

	var current_coords: Vector2i = _coords_by_room.get(_active_room, Vector2i.ZERO)
	var target_coords: Vector2i = current_coords + portal.direction
	var target_room: Node3D = get_room_at(target_coords)
	if not target_room:
		return

	transition_to(target_room)
