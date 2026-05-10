class_name RoomNode
extends RefCounted

var grid_coords: Vector2i
var type: RoomData.RoomType = RoomData.RoomType.COMBAT
var room_data: RoomData = null
var connections: Array[RoomNode] = []
