class_name PlayerHealthBar
extends Label3D

@export var health: HealthComponent


func _ready() -> void:
	if health == null:
		push_warning("PlayerHealthBar: health not assigned")
		return
	health.health_changed.connect(_on_health_changed)
	_on_health_changed(health.current_hp, health.max_hp)


func _on_health_changed(current: int, max_value: int) -> void:
	text = "HP %d / %d" % [current, max_value]
	var ratio: float = float(current) / float(max(max_value, 1))
	modulate = Color.RED.lerp(Color.GREEN, ratio)
