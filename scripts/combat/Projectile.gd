class_name Projectile
extends Area3D

@export var speed: float = 18.0
@export var lifetime: float = 2.0
@export var damage: int = 10

var direction: Vector3 = Vector3.FORWARD

func _ready() -> void:
	body_entered.connect(_on_body_hit)
	area_entered.connect(_on_area_hit)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func launch(dir: Vector3) -> void:
	direction = dir

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_body_hit(body: Node3D) -> void:
	_apply_damage(body)
	queue_free()

func _on_area_hit(area: Area3D) -> void:
	_apply_damage(area)
	queue_free()

func _apply_damage(target: Node) -> void:
	if target == null:
		return
	if target.has_method(&"take_damage"):
		target.take_damage(damage, self)
		return
	var hp: Node = target.get_node_or_null(^"HealthComponent")
	if hp != null and hp.has_method(&"take_damage"):
		hp.take_damage(damage, self)
