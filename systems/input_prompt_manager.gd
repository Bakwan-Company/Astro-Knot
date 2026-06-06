extends Node

const INPUT_SCAN_INTERVAL := 0.15
const JOY_MOTION_THRESHOLD := 0.35

var using_controller: bool = false
var scan_timer: float = 0.0

var prompt_pairs: Array[Array] = [
	["A & D to move", "Left Stick / D-Pad to move"],
	["Space to jump", "A to jump"],
	["E to reel out Pollux", "R2 to reel out Pollux"],
	["Q to reel in Pollux", "L2 to reel in Pollux"],
	["Q to pull Pollux", "L2 to pull Pollux"],
	["E while on top of Pollux", "R2 while on top of Pollux"],
	["move left and right to swing", "use Left Stick / D-Pad to swing"],
	["Press R to enter Throw Mode", "Press R1 to enter Throw Mode"],
	["A / D to aim", "Right Stick to aim"],
	["Hold Space to charge", "Hold A to charge"],
	["Release Space to throw", "Release A to throw"],
	["Press F to let Pollux interact", "Press B to let Pollux interact"],
	["Press F to enter the lab", "Press B to enter the lab"],
	["F to connect tether", "B to connect tether"],
	["F to inspect log", "B to inspect log"],
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_refresh_prompt_labels()

func _input(event: InputEvent) -> void:
	if _is_controller_event(event):
		_set_using_controller(true)
	elif _is_keyboard_event(event):
		_set_using_controller(false)

func _process(delta: float) -> void:
	scan_timer -= delta
	if scan_timer > 0.0:
		return

	scan_timer = INPUT_SCAN_INTERVAL
	_refresh_prompt_labels()

func _set_using_controller(value: bool) -> void:
	if using_controller == value:
		return

	using_controller = value
	_refresh_prompt_labels()

func _is_controller_event(event: InputEvent) -> bool:
	if event is InputEventJoypadButton:
		return event.pressed

	if event is InputEventJoypadMotion:
		return absf(event.axis_value) >= JOY_MOTION_THRESHOLD

	return false

func _is_keyboard_event(event: InputEvent) -> bool:
	if event is InputEventKey:
		return event.pressed and not event.echo

	if event is InputEventMouseButton:
		return event.pressed

	return false

func _refresh_prompt_labels() -> void:
	var root := get_tree().current_scene
	if root == null:
		return

	_refresh_prompt_labels_recursive(root)

func _refresh_prompt_labels_recursive(node: Node) -> void:
	if node is Label:
		var label := node as Label
		label.text = get_prompt_text(label.text)

	for child in node.get_children():
		_refresh_prompt_labels_recursive(child)

func get_prompt_text(source_text: String) -> String:
	var text := source_text

	for pair in prompt_pairs:
		text = text.replace(pair[1], pair[0])

	if using_controller:
		for pair in prompt_pairs:
			text = text.replace(pair[0], pair[1])

	return text
