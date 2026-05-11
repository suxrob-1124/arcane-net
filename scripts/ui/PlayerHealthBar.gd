class_name PlayerHealthBar
extends Label3D

@export var health_path: NodePath

var _health: HealthComponent


func _ready() -> void:
	_health = get_node_or_null(health_path) as HealthComponent
	if _health == null:
		push_warning("PlayerHealthBar: HealthComponent not found at %s" % health_path)
		return
	_health.health_changed.connect(_on_health_changed)
	_on_health_changed(_health.current_hp, _health.max_hp)


func _on_health_changed(current: int, max_value: int) -> void:
	text = "HP %d / %d" % [current, max_value]
	var ratio: float = float(current) / float(max(max_value, 1))
	modulate = Color.RED.lerp(Color.GREEN, ratio)
