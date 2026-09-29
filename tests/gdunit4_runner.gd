# GdUnit4 entry point used by project.yaml `commands.test`, /smoke-check and CI:
#   godot --headless --path . --script tests/gdunit4_runner.gd [gdUnit4 args]
# With no `-a/--add` argument it runs everything under res://tests. Headless mode
# is allowed on purpose: our suites are Logic/Integration tests without UI input.
extends SceneTree

var _runner: GdUnitTestCIRunner


func _initialize() -> void:
	var runner_script := load("res://addons/gdUnit4/src/core/runners/GdUnitTestCIRunner.gd")
	if runner_script == null:
		push_error("GdUnit4 not found at res://addons/gdUnit4 — see tests/README.md.")
		quit(1)
		return
	_runner = runner_script.new()
	# gdUnit4's parser skips everything up to an argument naming its own tool
	# script, so rebuild the list as: tool name + whatever followed this script.
	var raw := OS.get_cmdline_args()
	var start := 0
	for i in raw.size():
		if raw[i].ends_with("gdunit4_runner.gd"):
			start = i + 1
	var args := PackedStringArray(["GdUnitCmdTool.gd"])
	args.append_array(raw.slice(start))
	if not (args.has("-a") or args.has("--add")):
		args.append_array(PackedStringArray(["-a", "res://tests"]))
	if not args.has("--ignoreHeadlessMode"):
		args.append("--ignoreHeadlessMode")
	_runner._debug_cmd_args = args
	root.add_child(_runner)


func _finalize() -> void:
	if _runner != null:
		_runner.free()
