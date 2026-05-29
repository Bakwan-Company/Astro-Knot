extends Area2D

enum TriggerMode {
	ON_ENTER,
	INTERACT,
}

@export var cutscene_scene: PackedScene = preload("res://ui/comic_cutscene/ComicCutscene.tscn")
@export_enum("On Enter", "Interact") var trigger_mode: int = TriggerMode.ON_ENTER
@export var play_once: bool = true
@export var prompt_text: String = "F to inspect log"
@export var prompt_offset: Vector2 = Vector2(-48.0, -36.0)

@export_group("Comic Setup")
@export var pages: Array[Texture2D] = []
@export var captions: Array[String] = []
@export var skippable: bool = false
@export var pause_tree: bool = true

var player_in_range: bool = false
var has_played: bool = false
var active_cutscene: CanvasLayer
var prompt_label: Label

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
	if active_cutscene != null or (play_once and has_played):
		return

	if cutscene_scene == null:
		return

	has_played = true
	if prompt_label != null:
		prompt_label.visible = false

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

func _on_cutscene_finished() -> void:
	active_cutscene = null

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
