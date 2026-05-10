class_name ManaComponent
extends Node

@export var max_mana: float = 100.0
@export var regen_per_minute: float = 8.0

var current_mana: float

signal mana_changed(current: float, max_value: float)


func _ready() -> void:
	current_mana = max_mana


func _process(delta: float) -> void:
	add(regen_per_minute / 60.0 * delta)


func can_spend(amount: float) -> bool:
	return current_mana >= amount


func spend(amount: float) -> bool:
	if not can_spend(amount):
		return false
	add(-amount)
	return true


func add(amount: float) -> void:
	current_mana = clampf(current_mana + amount, 0.0, max_mana)
	mana_changed.emit(current_mana, max_mana)
