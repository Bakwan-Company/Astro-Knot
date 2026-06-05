extends Area2D

signal cutscene_finished

enum TriggerMode {
	ON_ENTER,
	INTERACT,
}

@export var cutscene_scene: PackedScene = preload("res://ui/comic_cutscene/ComicCutscene.tscn")
@export_enum("On Enter", "Interact") var trigger_mode: int = TriggerMode.ON_ENTER
@export var play_once: bool = true
@export var prompt_text: String = "F to inspect log"
@export var prompt_offset: Vector2 = Vector2(-48.0, -36.0)
@export_file("*.tscn") var next_scene_path: String = ""

@export_group("Intro Focus")
@export var focus_before_cutscene: bool = true
@export var focus_duration: float = 1.1
@export var focus_zoom_multiplier: float = 1.45

@export_group("Comic Setup")
@export var pages: Array[Texture2D] = []
@export var captions: Array[String] = []
@export var skippable: bool = false
@export var pause_tree: bool = true
@export var play_ending_bgm: bool = false

var player_in_range: bool = false
var has_played: bool = false
var intro_playing: bool = false
var active_cutscene: CanvasLayer
var prompt_label: Label
var focused_camera: Camera2D
var focused_camera_was_processing: bool = true

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_create_prompt()

func _process(_delta: float) -> void:
	if trigger_mode != TriggerMode.INTERACT:
		return

	if player_in_range and not has_played and Input.is_action_just_pressed("interact"):
		play_cutscene()

func play_cutscene() -> void:
	if intro_playing or active_cutscene != null or (play_once and has_played):
		return

	if cutscene_scene == null:
		return

	has_played = true
	intro_playing = true
	if prompt_label != null:
		prompt_label.visible = false

	if focus_before_cutscene:
		await _play_focus_intro()

	if play_ending_bgm:
		BgmManager.play_ending()

	active_cutscene = cutscene_scene.instantiate() as CanvasLayer
	if pages.size() > 0:
		active_cutscene.set("pages", pages)
	if captions.size() > 0:
		active_cutscene.set("captions", captions)
	active_cutscene.set("skippable", skippable)
	active_cutscene.set("pause_tree", pause_tree)

	if active_cutscene.has_signal("finished"):
		active_cutscene.connect("finished", _on_cutscene_finished)

	get_tree().current_scene.add_child(active_cutscene)
	intro_playing = false

func _on_cutscene_finished() -> void:
	active_cutscene = null
	_restore_focus_camera()
	cutscene_finished.emit()
	if next_scene_path != "" and ResourceLoader.exists(next_scene_path):
		get_tree().change_scene_to_file(next_scene_path)

func _on_body_entered(body: Node2D) -> void:
	if not _is_player_body(body):
		return

	player_in_range = true
	if trigger_mode == TriggerMode.ON_ENTER:
		play_cutscene()
	elif not has_played and prompt_label != null:
		prompt_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if not _is_player_body(body):
		return

	player_in_range = false
	if prompt_label != null:
		prompt_label.visible = false

func _is_player_body(body: Node2D) -> bool:
	return body.name == "Castor"

func _create_prompt() -> void:
	prompt_label = Label.new()
	prompt_label.name = "PromptLabel"
	prompt_label.visible = false
	prompt_label.text = prompt_text
	prompt_label.position = prompt_offset
	prompt_label.z_index = 80
	prompt_label.add_theme_font_size_override("font_size", 10)
	prompt_label.add_theme_color_override("font_color", Color(0.06, 0.045, 0.035, 1.0))
	prompt_label.add_theme_color_override("font_shadow_color", Color(1.0, 0.82, 0.5, 0.75))
	prompt_label.add_theme_constant_override("shadow_offset_x", 1)
	prompt_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(prompt_label)

func _play_focus_intro() -> void:
	focused_camera = _find_level_camera()
	if focused_camera == null:
		return

	focused_camera_was_processing = focused_camera.is_processing()
	focused_camera.set_process(false)

	var focus_position := _get_focus_position()
	var target_zoom := focused_camera.zoom * focus_zoom_multiplier
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(focused_camera, "global_position", focus_position, focus_duration)
	tween.parallel().tween_property(focused_camera, "zoom", target_zoom, focus_duration)
	await tween.finished

func _restore_focus_camera() -> void:
	if focused_camera == null or not is_instance_valid(focused_camera):
		return

	if focused_camera.has_method("follow_players"):
		focused_camera.call("follow_players")
	focused_camera.set_process(focused_camera_was_processing)
	focused_camera = null

func _find_level_camera() -> Camera2D:
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return null

	var camera := current_scene.get_node_or_null("Camera2D") as Camera2D
	if camera != null:
		return camera

	return current_scene.find_child("Camera2D", true, false) as Camera2D

func _get_focus_position() -> Vector2:
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return global_position

	var castor := current_scene.find_child("Castor", true, false) as Node2D
	var pollux := current_scene.find_child("Pollux", true, false) as Node2D
	if castor != null and pollux != null:
		return (castor.global_position + pollux.global_position) * 0.5
	if castor != null:
		return castor.global_position

	return global_position
