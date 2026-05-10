class_name Portal
extends Area3D

signal portal_entered(portal: Portal, body: Node3D)

var direction: Vector2i = Vector2i.ZERO


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	portal_entered.emit(self, body)
