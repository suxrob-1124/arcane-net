## Smoke test of Main.tscn. Drives synthetic input for ~30 seconds and exits.
##
## Two run modes:
##   Headless (CI / regression hunting):
##     "$GODOT" --path . --headless -s tests/playtest_smoke.gd
##     Wrap in `grep -E "SCRIPT ERROR|push_error"` to fail on any logged error.
##
##   Windowed (visual capture — dumps PNG screenshots to SCREENSHOT_DIR):
##     "$GODOT" --path . -s tests/playtest_smoke.gd
##     Screenshots are skipped automatically when running with --headless
##     because the dummy rendering server produces no frames.
##
## NOTE: filename has no `test_` prefix so GUT does not pick it up.
extends SceneTree

const PLAYTEST_DURATION_SEC: float = 30.0
const DIRECTION_CHANGE_INTERVAL: float = 2.0
const ATTACK_INTERVAL: float = 0.7
const DASH_INTERVAL: float = 5.0
const SCREENSHOT_INTERVAL: float = 5.0
const SCREENSHOT_DIR: String = "/tmp/arcane-net-smoke"

const DIRECTIONS: Array[StringName] = [&"move_right", &"move_down", &"move_left", &"move_up"]

var _elapsed: float = 0.0
var _next_dir_change: float = 0.0
var _next_attack: float = 0.5
var _next_dash: float = 1.5
var _next_screenshot: float = 1.0
var _dir_index: int = 0
var _current_dir: StringName = &""
var _screenshot_index: int = 0
var _visual_enabled: bool = false


func _initialize() -> void:
	var packed: PackedScene = load("res://scenes/main/Main.tscn") as PackedScene
	if packed == null:
		printerr("[playtest_smoke] FAIL: cannot load res://scenes/main/Main.tscn")
		quit(1)
		return
	var instance: Node = packed.instantiate()
	root.add_child(instance)
	current_scene = instance

	_visual_enabled = DisplayServer.get_name() != "headless"
	if _visual_enabled:
		DirAccess.make_dir_recursive_absolute(SCREENSHOT_DIR)
		print("[playtest_smoke] visual mode — screenshots → %s" % SCREENSHOT_DIR)
	else:
		print("[playtest_smoke] headless mode — screenshots disabled")
	print("[playtest_smoke] Main.tscn loaded — running %.0fs of synthetic input" % PLAYTEST_DURATION_SEC)


func _process(delta: float) -> bool:
	_elapsed += delta

	if _elapsed >= _next_dir_change:
		_next_dir_change += DIRECTION_CHANGE_INTERVAL
		_change_direction()

	if _elapsed >= _next_attack:
		_next_attack += ATTACK_INTERVAL
		_pulse_action(&"attack")

	if _elapsed >= _next_dash:
		_next_dash += DASH_INTERVAL
		_pulse_action(&"dash")

	if _visual_enabled and _elapsed >= _next_screenshot:
		_next_screenshot += SCREENSHOT_INTERVAL
		_dump_screenshot()

	if _elapsed >= PLAYTEST_DURATION_SEC:
		_cleanup_input()
		print("[playtest_smoke] DONE — %.1fs simulated, exit clean" % _elapsed)
		quit(0)
		return true
	return false


func _change_direction() -> void:
	if _current_dir != &"":
		Input.action_release(_current_dir)
	_current_dir = DIRECTIONS[_dir_index % DIRECTIONS.size()]
	_dir_index += 1
	Input.action_press(_current_dir)


func _pulse_action(action: StringName) -> void:
	Input.action_press(action)
	var timer: SceneTreeTimer = create_timer(0.1)
	timer.timeout.connect(func() -> void: Input.action_release(action))


func _dump_screenshot() -> void:
	var index: int = _screenshot_index
	_screenshot_index += 1
	RenderingServer.frame_post_draw.connect(
		func() -> void: _save_frame(index),
		CONNECT_ONE_SHOT,
	)


func _save_frame(index: int) -> void:
	var img: Image = root.get_texture().get_image()
	if img == null:
		return
	var path: String = "%s/smoke_%02d_t%04d.png" % [SCREENSHOT_DIR, index, int(_elapsed)]
	var err: int = img.save_png(path)
	if err == OK:
		print("[playtest_smoke] screenshot → %s" % path)
	else:
		printerr("[playtest_smoke] save_png failed (err=%d) → %s" % [err, path])


func _cleanup_input() -> void:
	for d: StringName in DIRECTIONS:
		Input.action_release(d)
	Input.action_release(&"attack")
	Input.action_release(&"dash")
