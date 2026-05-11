class_name XPNumberPopup
extends Node3D

const RISE_AMOUNT := 1.2
const DURATION := 1.0

@onready var _label: Label3D = $Label3D


static func spawn(tree_parent: Node, pos: Vector3, amount: int) -> void:
	var scene: PackedScene = load("res://scenes/ui/XPNumberPopup.tscn")
	var popup: XPNumberPopup = scene.instantiate()
	tree_parent.add_child(popup)
	popup.global_position = pos
	popup.play(amount)


func play(amount: int) -> void:
	_label.text = "+%d XP" % amount
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y + RISE_AMOUNT, DURATION)
	tween.tween_property(_label, "modulate:a", 0.0, DURATION)
	tween.chain().tween_callback(queue_free)
