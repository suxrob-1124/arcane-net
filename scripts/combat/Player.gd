class_name Player
extends CharacterBody3D

@onready var visuals: Node3D = $Visuals
@onready var movement: MovementComponent = $MovementComponent
@onready var dash: DashComponent = $DashComponent
@onready var health: HealthComponent = $HealthComponent

var is_invulnerable: bool = false
var is_dashing: bool = false
var is_ghost: bool = false

var _death_cause: StringName = &"unknown"


func _ready() -> void:
	add_to_group(&"player")
	health.died.connect(_on_died)


func take_damage(amount: int, source: Node = null) -> void:
	if is_invulnerable or is_ghost:
		return
	if source != null and source.has_method(&"get") and source.get(&"data") != null:
		_death_cause = source.data.enemy_id
	health.take_damage(amount, source)
	Hitstop.request(0.05)


func heal(amount: int) -> void:
	health.heal(amount)


func get_hp_ratio() -> float:
	return health.get_hp_ratio()


func is_alive() -> bool:
	return health.is_alive()


func _on_died(_killer: Node) -> void:
	EventBus.player_died.emit(self, _death_cause, global_position)


func enter_ghost_state() -> void:
	if is_ghost:
		return
	is_ghost = true
	visible = false
	if movement != null:
		movement.set_movement_enabled(false)
	set_physics_process(false)
