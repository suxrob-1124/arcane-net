class_name FadeLayer
extends CanvasLayer

const DEFAULT_DURATION: float = 0.2

@onready var _rect: ColorRect = $ColorRect


func _ready() -> void:
	_rect.modulate.a = 0.0


func fade_out(duration: float = DEFAULT_DURATION) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(_rect, "modulate:a", 1.0, duration)
	await tween.finished


func fade_in(duration: float = DEFAULT_DURATION) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(_rect, "modulate:a", 0.0, duration)
	await tween.finished
