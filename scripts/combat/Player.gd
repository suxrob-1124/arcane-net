class_name Player
extends CharacterBody3D

@onready var visuals: Node3D = $Visuals
@onready var movement: MovementComponent = $MovementComponent
@onready var dash: DashComponent = $DashComponent

var is_invulnerable: bool = false
var is_dashing: bool = false
var is_ghost: bool = false

func _ready() -> void:
	add_to_group(&"player")

func enter_ghost_state() -> void:
	if is_ghost:
		return
	is_ghost = true
	visible = false
	if movement != null:
		movement.set_movement_enabled(false)
	set_physics_process(false)
