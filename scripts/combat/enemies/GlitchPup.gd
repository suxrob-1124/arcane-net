## Melee enemy that telegraphs its AoE stomp before dealing damage.
## Emits enemy_telegraph_started so EchoCompanion can react with ShieldAction.
class_name GlitchPup
extends Enemy

@onready var _telegraph: Node3D = $TelegraphMarker
@onready var _attack_timer: Timer = $AttackTimer
@onready var _attack_cooldown: Timer = $AttackCooldown

var _attack_ready: bool = true


func _ready() -> void:
	super._ready()
	_attack_timer.timeout.connect(_on_attack_resolved)


func _state_attack() -> void:
	if _player == null or not is_instance_valid(_player):
		set_state(State.IDLE)
		_hide_telegraph()
		return

	var dist: float = global_position.distance_to(_player.global_position)
	if dist > data.attack_radius * 1.3:
		set_state(State.CHASE)
		_hide_telegraph()
		return

	if not _attack_ready or not _attack_cooldown.is_stopped():
		return

	_start_telegraph()


func _start_telegraph() -> void:
	_attack_ready = false
	_telegraph.global_position = _player.global_position + Vector3(0.0, 0.01, 0.0)
	_telegraph.visible = true
	_attack_timer.wait_time = data.attack_telegraph
	_attack_timer.start()
	EventBus.enemy_telegraph_started.emit(self, data.attack_telegraph)


func _on_attack_resolved() -> void:
	_hide_telegraph()
	if _player == null or not is_instance_valid(_player):
		_reset_attack_cooldown()
		return

	var dist: float = global_position.distance_to(_player.global_position)
	if dist <= data.attack_radius * 1.3:
		if _player.has_method(&"take_damage"):
			_player.take_damage(data.melee_damage, self)
		Hitstop.request(0.05)

	_reset_attack_cooldown()


func _reset_attack_cooldown() -> void:
	_attack_cooldown.start()
	await _attack_cooldown.timeout
	_attack_ready = true


func _hide_telegraph() -> void:
	_telegraph.visible = false
