class_name HUD
extends CanvasLayer

@export var xp_path: NodePath
@export var mana_path: NodePath

@onready var _level_label: Label = $Root/Bars/XPBox/LevelLabel
@onready var _xp_bar: ProgressBar = $Root/Bars/XPBox/XPBar
@onready var _mana_box: VBoxContainer = $Root/Bars/ManaBox
@onready var _mana_bar: ProgressBar = $Root/Bars/ManaBox/ManaBar

var _xp: ExperienceComponent
var _mana: ManaComponent


func _ready() -> void:
	_xp = get_node_or_null(xp_path) as ExperienceComponent
	if _xp != null:
		_xp.xp_gained.connect(_on_xp_gained)
		_xp.level_up.connect(_on_level_up)
		_on_xp_gained(0, _xp.current_xp, _xp.get_required_xp(_xp.current_level))
	else:
		push_warning("HUD: ExperienceComponent not found at %s" % xp_path)

	_mana = get_node_or_null(mana_path) as ManaComponent
	if _mana != null:
		_mana.mana_changed.connect(_on_mana_changed)
		_on_mana_changed(_mana.current_mana, _mana.max_mana)
	else:
		_mana_box.visible = false


func _on_xp_gained(_amount: int, current: int, required: int) -> void:
	_xp_bar.max_value = required
	_xp_bar.value = current


func _on_level_up(new_level: int) -> void:
	_level_label.text = "Lv. %d" % new_level
	_xp_bar.value = 0


func _on_mana_changed(current: float, max_value: float) -> void:
	_mana_bar.max_value = max_value
	_mana_bar.value = current
