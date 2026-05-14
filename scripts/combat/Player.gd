## Player facade. Holds flags and `@onready` component refs only — all behaviour
## lives in MovementComponent / DashComponent / AttackComponent / HealthComponent.
## Other systems talk to the player through this node's public API, never to its components.
class_name Player
extends CharacterBody3D

@onready var visuals: Node3D = $Visuals
@onready var movement: MovementComponent = $MovementComponent
@onready var dash: DashComponent = $DashComponent
@onready var health: HealthComponent = $HealthComponent
@onready var attack: AttackComponent = get_node_or_null(^"AttackComponent") as AttackComponent

## Derived from `_invuln_sources`; true while any source (dash iframes, shield) is active.
var is_invulnerable: bool = false
## Set true by DashComponent during a dash; MovementComponent honours this flag.
var is_dashing: bool = false
## Set true after death — disables physics, rendering, and component processing.
var is_ghost: bool = false

var _death_cause: StringName = &"unknown"
var _invuln_sources: int = 0


func _ready() -> void:
	add_to_group(&"player")
	health.died.connect(_on_died)


## Applies damage from `source`. Skipped while invulnerable or ghosted.
## Records the death cause from `source.data.enemy_id` if available and requests Hitstop.
func take_damage(amount: int, source: Node = null) -> void:
	if is_invulnerable or is_ghost:
		return
	if source != null and source.has_method(&"get") and source.get(&"data") != null:
		_death_cause = source.data.enemy_id
	health.take_damage(amount, source)
	Hitstop.request(0.05)


## Registers one invulnerability source. Player becomes invulnerable on the first call.
func add_invuln_source() -> void:
	_invuln_sources += 1
	is_invulnerable = true


## Releases one invulnerability source. Invulnerability ends when all sources are removed.
func remove_invuln_source() -> void:
	_invuln_sources = max(0, _invuln_sources - 1)
	if _invuln_sources == 0:
		is_invulnerable = false


## Heals by `amount`. Forwarded directly to HealthComponent.
func heal(amount: int) -> void:
	health.heal(amount)


## Current HP as a fraction in `[0.0, 1.0]`. Used by EchoCompanion context.
func get_hp_ratio() -> float:
	return health.get_hp_ratio()


## Returns false once HealthComponent has emitted `died`.
func is_alive() -> bool:
	return health.is_alive()


func _on_died(_killer: Node) -> void:
	EventBus.player_died.emit(self, _death_cause, global_position)


## Transitions the player into ghost mode after death — hides visuals, stops physics,
## disables Movement / Attack. Called by SpectatorController on `player_died`.
func enter_ghost_state() -> void:
	if is_ghost:
		return
	is_ghost = true
	visible = false
	if movement != null:
		movement.set_movement_enabled(false)
	if attack != null:
		attack.process_mode = Node.PROCESS_MODE_DISABLED
	set_physics_process(false)
