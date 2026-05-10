class_name Player
extends CharacterBody3D

@onready var visuals: Node3D = $Visuals
@onready var movement: MovementComponent = $MovementComponent
@onready var dash: DashComponent = $DashComponent

var is_invulnerable: bool = false
var is_dashing: bool = false

func _ready() -> void:
	add_to_group(&"player")
