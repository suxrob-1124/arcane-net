class_name Projectile
extends Area3D

@export var speed: float = 18.0
@export var lifetime: float = 2.0

var direction: Vector3 = Vector3.FORWARD

func _ready() -> void:
	body_entered.connect(_on_body_hit)
	area_entered.connect(_on_area_hit)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func launch(dir: Vector3) -> void:
	direction = dir

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_body_hit(_body: Node3D) -> void:
	queue_free()

func _on_area_hit(_area: Area3D) -> void:
	queue_free()
