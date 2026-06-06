extends Area2D

signal terminal_activated(is_on: bool)

const DEFAULT_CONFIRM_WINDOW := preload("res://interactables/level_exit/LevelExitConfirmWindow.tscn")
const InteractableOutline := preload("res://interactables/interactable_outline.gd")
const PolluxInteractSfx := preload("res://systems/pollux_interact_sfx.gd")

@export var terminal_off: Texture2D
@export var terminal_on: Texture2D
@export var valid_body_names: PackedStringArray = ["Castor", "Pollux"]
@export var activation_radius: float = 160.0
@export var lab_door_path: NodePath
@export var confirm_heading: String = "ULBUL LAB ACCESS"
@export var confirm_title: String = "Enter the facility?"
@export var confirm_detail: String = "Proceed to the next area"
@export var confirm_yes_text: String = "Yes"
@export var confirm_no_text: String = "No"
@export var confirm_window_scene: PackedScene = DEFAULT_CONFIRM_WINDOW
@export_group("Comic Cutscene")
@export var play_comic_before_exit: bool = false
@export var comic_cutscene_scene: PackedScene
@export var comic_focus_duration: float = 1.1
@export var comic_focus_zoom_multiplier: float = 1.45

@onready var visual_sprite: Sprite2D = $Sprite2D

var is_active: bool = false
var bodies_in_range: Array[Node2D] = []
var confirm_open: bool = false
var confirm_input_enabled: bool = false
var confirm_window: Node
var confirm_opened_at_msec: int = 0
var active_comic_cutscene: CanvasLayer
var comic_focus_camera: Camera2D
var comic_focus_camera_was_processing: bool = true
var interact_outline: Node

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	interact_outline = InteractableOutline.new()
	visual_sprite.add_child(interact_outline)
	interact_outline.setup(visual_sprite)
	_update_visual()

func _process(_delta: float) -> void:
	_update_interact_outline()

	if not confirm_open and Input.is_action_just_pressed("interact") and _can_open_confirm():
		open_confirm()
		return

	if not confirm_open or not confirm_input_enabled:
		return

	if Input.is_action_just_pressed("ui_accept"):
		UiSfx.play_click()
		confirm()
	elif Input.is_action_just_pressed("ui_cancel"):
		UiSfx.play_click()
		cancel()

func open_confirm() -> void:
	if is_active or confirm_open or confirm_window_scene == null:
		return

	PolluxInteractSfx.play_at(self, global_position)
	confirm_open = true
	confirm_input_enabled = false
	confirm_opened_at_msec = Time.get_ticks_msec()
	confirm_window = confirm_window_scene.instantiate()
	confirm_window.set("heading_text", confirm_heading)
	confirm_window.set("title_text", confirm_title)
	confirm_window.set("detail_text", confirm_detail)
	confirm_window.set("yes_text", confirm_yes_text)
	confirm_window.set("no_text", confirm_no_text)
	if confirm_window.has_method("apply_text"):
		confirm_window.call("apply_text")
	if confirm_window.has_signal("confirmed"):
		confirm_window.connect("confirmed", Callable(self, "confirm"), CONNECT_ONE_SHOT)
	if confirm_window.has_signal("canceled"):
		confirm_window.connect("canceled", Callable(self, "cancel"), CONNECT_ONE_SHOT)

	var confirm_parent := get_tree().current_scene if get_tree().current_scene != null else self
	confirm_parent.add_child(confirm_window)
	await get_tree().process_frame
	if confirm_open:
		confirm_input_enabled = true

func confirm() -> void:
	if not confirm_open:
		return
	if Time.get_ticks_msec() - confirm_opened_at_msec < 200:
		return

	GameplayInputGate.suppress_jump()
	close_confirm()
	is_active = true
	_update_visual()
	if play_comic_before_exit and comic_cutscene_scene != null:
		_play_exit_comic_cutscene()
	else:
		_activate_lab_door()

func cancel() -> void:
	if not confirm_open:
		return

	close_confirm()
	terminal_activated.emit(false)

func close_confirm() -> void:
	confirm_open = false
	confirm_input_enabled = false
	if confirm_window != null and is_instance_valid(confirm_window):
		confirm_window.queue_free()
	confirm_window = null

func _activate_lab_door() -> void:
	var lab_door := get_node_or_null(lab_door_path)
	if lab_door != null and lab_door.has_method("activate_from_terminal"):
		lab_door.call("activate_from_terminal")
		return

	terminal_activated.emit(true)

func _play_exit_comic_cutscene() -> void:
	await _play_comic_focus_intro()
	active_comic_cutscene = comic_cutscene_scene.instantiate() as CanvasLayer
	if active_comic_cutscene == null:
		_continue_exit_after_comic()
		return

	if active_comic_cutscene.has_signal("finished"):
		active_comic_cutscene.connect("finished", _continue_exit_after_comic)

	get_tree().current_scene.add_child(active_comic_cutscene)

func _continue_exit_after_comic() -> void:
	active_comic_cutscene = null
	_restore_comic_focus_camera()
	_activate_lab_door()

func _on_body_entered(body: Node2D) -> void:
	if not _is_valid_body(body):
		return

	if not bodies_in_range.has(body):
		bodies_in_range.append(body)

func _on_body_exited(body: Node2D) -> void:
	bodies_in_range.erase(body)

func _can_open_confirm() -> bool:
	if is_active or confirm_open:
		return false

	for body in bodies_in_range:
		if is_instance_valid(body):
			return true

	return _has_valid_body_nearby()

func _is_valid_body(body: Node2D) -> bool:
	if valid_body_names.is_empty():
		return true
	return String(body.name) in valid_body_names

func _update_visual() -> void:
	if visual_sprite == null:
		return

	visual_sprite.texture = terminal_on if is_active else terminal_off
	_update_interact_outline()

func _update_interact_outline() -> void:
	if interact_outline != null:
		interact_outline.set_active(_can_open_confirm())

func _has_valid_body_nearby() -> bool:
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return false

	for body_name in valid_body_names:
		var body := _find_node_recursive(current_scene, StringName(body_name)) as Node2D
		if body != null and global_position.distance_to(body.global_position) <= activation_radius:
			return true

	return false

func _find_node_recursive(root: Node, target_name: StringName) -> Node:
	if root.name == target_name:
		return root

	for child in root.get_children():
		var found := _find_node_recursive(child, target_name)
		if found != null:
			return found

	return null

func _play_comic_focus_intro() -> void:
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return

	comic_focus_camera = current_scene.get_node_or_null("Camera2D") as Camera2D
	if comic_focus_camera == null:
		comic_focus_camera = current_scene.find_child("Camera2D", true, false) as Camera2D
	if comic_focus_camera == null:
		return

	comic_focus_camera_was_processing = comic_focus_camera.is_processing()
	comic_focus_camera.set_process(false)

	var castor := _find_node_recursive(current_scene, &"Castor") as Node2D
	var pollux := _find_node_recursive(current_scene, &"Pollux") as Node2D
	var focus_position := global_position
	if castor != null and pollux != null:
		focus_position = (castor.global_position + pollux.global_position) * 0.5
	elif castor != null:
		focus_position = castor.global_position

	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(comic_focus_camera, "global_position", focus_position, comic_focus_duration)
	tween.parallel().tween_property(comic_focus_camera, "zoom", comic_focus_camera.zoom * comic_focus_zoom_multiplier, comic_focus_duration)
	await tween.finished

func _restore_comic_focus_camera() -> void:
	if comic_focus_camera == null or not is_instance_valid(comic_focus_camera):
		return

	if comic_focus_camera.has_method("follow_players"):
		comic_focus_camera.call("follow_players")
	comic_focus_camera.set_process(comic_focus_camera_was_processing)
	comic_focus_camera = null
