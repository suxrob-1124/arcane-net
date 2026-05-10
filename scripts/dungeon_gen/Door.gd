class_name Door
extends StaticBody3D

signal locked()
signal unlocked()

var is_locked: bool = false

func lock() -> void:
	if is_locked:
		return
	is_locked = true
	var mesh: MeshInstance3D = get_node_or_null(^"MeshInstance3D") as MeshInstance3D
	if mesh:
		mesh.visible = true
	print("Door locked")
	locked.emit()

func unlock() -> void:
	if not is_locked:
		return
	is_locked = false
	var mesh: MeshInstance3D = get_node_or_null(^"MeshInstance3D") as MeshInstance3D
	if mesh:
		mesh.visible = false
	print("Door unlocked")
	unlocked.emit()
