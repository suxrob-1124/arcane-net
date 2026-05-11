class_name HealthComponent
extends Node

signal health_changed(current: int, max_value: int)
signal damaged(amount: int, source: Node)
signal died(killer: Node)

@export var max_hp: int = 100
var current_hp: int


func _ready() -> void:
	current_hp = max_hp


func take_damage(amount: int, source: Node = null) -> void:
	if amount <= 0 or current_hp <= 0:
		return
	current_hp = max(current_hp - amount, 0)
	damaged.emit(amount, source)
	health_changed.emit(current_hp, max_hp)
	if current_hp == 0:
		died.emit(source)


func heal(amount: int) -> void:
	if amount <= 0 or current_hp <= 0:
		return
	current_hp = min(current_hp + amount, max_hp)
	health_changed.emit(current_hp, max_hp)


func is_alive() -> bool:
	return current_hp > 0


func get_hp_ratio() -> float:
	if max_hp == 0:
		return 0.0
	return float(current_hp) / float(max_hp)
