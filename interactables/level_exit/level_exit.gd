@tool
extends Area2D

const DEFAULT_CONFIRM_WINDOW := preload("res://interactables/level_exit/LevelExitConfirmWindow.tscn")

signal exit_confirmed
signal exit_canceled
signal player_entered
signal player_exited
signal confirm_opened
signal confirm_closed

@export var prompt_text: String = "Old signal relay detected"
@export var open_confirm_on_body_entered: bool = false
@export var confirm_heading: String = "OLD SIGNAL RELAY"
@export var confirm_title: String = "Follow the signal?"
@export var confirm_detail: String = "Continue to the next area"
@export var confirm_yes_text: String = "Yes"
@export var confirm_no_text: String = "No"
@export var confirm_window_scene: PackedScene = DEFAULT_CONFIRM_WINDOW
@export var prompt_label_path: NodePath = NodePath("PromptLabel")
@export var next_level_scene_path: String = ""
@export_group("Comic Cutscene")
@export var play_comic_before_exit: bool = false
@export var comic_cutscene_scene: PackedScene
@export_group("Actors")
@export var handle_actor_sequence: bool = true
@export var castor_path: NodePath
@export var pollux_path: NodePath
@export var rope_manager_path: NodePath
@export var camera_path: NodePath
@export var finish_walk_distance: float = 420.0
@export var finish_walk_time: float = 1.8
@export var cancel_walk_distance: float = 72.0
@export var cancel_walk_time: float = 0.35
@export var freeze_camera_during_sequence: bool = true
@export_group("Visual")
@export var exit_sprite_texture: Texture2D:
	set(value):
		exit_sprite_texture = value
		apply_visual()
@export var exit_sprite_offset: Vector2 = Vector2(-0.5, 84.0):
	set(value):
		exit_sprite_offset = value
		apply_visual()
@export var exit_sprite_scale: Vector2 = Vector2(0.2630715, 0.2745098):
	set(value):
		exit_sprite_scale = value
		apply_visual()
@export var exit_sprite_path: NodePath = NodePath("Sprite2D"):
	set(value):
		exit_sprite_path = value
		exit_sprite = null
		apply_visual()
@export var exit_animation_sprite_path: NodePath
@export var exit_open_animation: StringName = &"open"

var player_in_range: bool = false
var confirm_open: bool = false
var confirm_window: Node
var prompt_label: Label
var exit_sprite: Sprite2D
var active_comic_cutscene: CanvasLayer
var castor: CharacterBody2D
var pollux: RigidBody2D
var rope_manager: Node
var camera: Camera2D
var exit_animation_sprite: AnimatedSprite2D
var actor_sequence_active: bool = false
var exit_flow_active: bool = false
var actor_sequence_direction: int = 0
var actor_sequence_speed: float = 0.0
var was_rope_physics_processing: bool = false
var was_camera_processing: bool = false
var was_camera_physics_processing: bool = false
var was_castor_physics_processing: bool = false
var was_pollux_freeze: bool = false
var was_pollux_sleeping: bool = false

func _ready() -> void:
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)
		body_exited.connect(_on_body_exited)
	prompt_label = get_node_or_null(prompt_label_path) as Label
	exit_sprite = get_node_or_null(exit_sprite_path) as Sprite2D
	castor = get_node_or_null(castor_path) as CharacterBody2D
	pollux = get_node_or_null(pollux_path) as RigidBody2D
	rope_manager = get_node_or_null(rope_manager_path)
	camera = get_node_or_null(camera_path) as Camera2D
	exit_animation_sprite = get_node_or_null(exit_animation_sprite_path) as AnimatedSprite2D
	apply_text()
	apply_visual()

func apply_text() -> void:
	if prompt_label != null:
		prompt_label.visible = false
		prompt_label.text = prompt_text

func apply_visual() -> void:
	if exit_sprite == null:
		exit_sprite = get_node_or_null(exit_sprite_path) as Sprite2D

	if exit_sprite == null:
		return

	exit_sprite.texture = exit_sprite_texture
	exit_sprite.position = exit_sprite_offset
	exit_sprite.scale = exit_sprite_scale

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return

	_update_actor_sequence_animation_state()

	if exit_flow_active:
		return

	if not confirm_open:
		if player_in_range and Input.is_action_just_pressed("interact"):
			open_confirm()
		return

	if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("ui_accept"):
		confirm()
	elif Input.is_action_just_pressed("ui_cancel"):
		cancel()

func open_confirm() -> void:
	if confirm_open:
		return

	confirm_open = true
	if prompt_label != null:
		prompt_label.visible = false
	_create_confirm_window()
	confirm_opened.emit()

func confirm() -> void:
	if not confirm_open:
		return

	var has_external_handler := not get_signal_connection_list(&"exit_confirmed").is_empty()
	close_confirm()
	exit_confirmed.emit()

	if play_comic_before_exit and comic_cutscene_scene != null:
		_play_exit_comic_cutscene()
		return

	if handle_actor_sequence:
		_play_exit_open_animation()
		await _wait_for_exit_open_animation()
		_play_actor_sequence(1, finish_walk_distance, finish_walk_time, true)
	elif not has_external_handler and next_level_scene_path != "" and ResourceLoader.exists(next_level_scene_path):
		_play_exit_open_animation()
		await _wait_for_exit_open_animation()
		get_tree().change_scene_to_file(next_level_scene_path)

func cancel() -> void:
	if not confirm_open:
		return

	close_confirm()
	exit_canceled.emit()
	if not handle_actor_sequence:
		return

	_play_actor_sequence(-1, cancel_walk_distance, cancel_walk_time, false)

func close_confirm() -> void:
	var was_open := confirm_open
	confirm_open = false
	if confirm_window != null and is_instance_valid(confirm_window):
		confirm_window.queue_free()
	confirm_window = null
	if was_open:
		confirm_closed.emit()

func _on_body_entered(body: Node2D) -> void:
	if not _is_player_body(body):
		return

	player_in_range = true
	if prompt_label != null:
		prompt_label.visible = true
	player_entered.emit()
	if open_confirm_on_body_entered:
		open_confirm()

func _on_body_exited(body: Node2D) -> void:
	if not _is_player_body(body):
		return

	player_in_range = false
	if prompt_label != null and not confirm_open:
		prompt_label.visible = false
	player_exited.emit()

func _is_player_body(body: Node2D) -> bool:
	return body.name == "Castor" or body.is_in_group("player")

func _create_confirm_window() -> void:
	if confirm_window_scene == null:
		return

	confirm_window = confirm_window_scene.instantiate()
	confirm_window.set("heading_text", confirm_heading)
	confirm_window.set("title_text", confirm_title)
	confirm_window.set("detail_text", confirm_detail)
	confirm_window.set("yes_text", confirm_yes_text)
	confirm_window.set("no_text", confirm_no_text)
	if confirm_window.has_method("apply_text"):
		confirm_window.call("apply_text")
	if confirm_window.has_signal("confirmed"):
		confirm_window.connect("confirmed", Callable(self, "confirm"))
	if confirm_window.has_signal("canceled"):
		confirm_window.connect("canceled", Callable(self, "cancel"))
	add_child(confirm_window)

func _play_exit_comic_cutscene() -> void:
	exit_flow_active = true
	active_comic_cutscene = comic_cutscene_scene.instantiate() as CanvasLayer
	if active_comic_cutscene == null:
		_continue_exit_after_comic()
		return

	if active_comic_cutscene.has_signal("finished"):
		active_comic_cutscene.connect("finished", _continue_exit_after_comic)
	get_tree().current_scene.add_child(active_comic_cutscene)

func _continue_exit_after_comic() -> void:
	active_comic_cutscene = null
	exit_flow_active = false

	if handle_actor_sequence:
		_play_exit_open_animation()
		await _wait_for_exit_open_animation()
		_play_actor_sequence(1, finish_walk_distance, finish_walk_time, true)
	elif next_level_scene_path != "" and ResourceLoader.exists(next_level_scene_path):
		_play_exit_open_animation()
		await _wait_for_exit_open_animation()
		get_tree().change_scene_to_file(next_level_scene_path)

func _play_exit_open_animation() -> void:
	if exit_animation_sprite == null:
		return

	if not exit_animation_sprite.sprite_frames.has_animation(exit_open_animation):
		return

	exit_animation_sprite.play(exit_open_animation)

func _wait_for_exit_open_animation() -> void:
	if exit_animation_sprite == null:
		return

	if not exit_animation_sprite.sprite_frames.has_animation(exit_open_animation):
		return

	if exit_animation_sprite.is_playing():
		await exit_animation_sprite.animation_finished

func _play_actor_sequence(direction: int, distance: float, duration: float, change_level_after: bool) -> void:
	if castor == null or pollux == null:
		if change_level_after and next_level_scene_path != "" and ResourceLoader.exists(next_level_scene_path):
			get_tree().change_scene_to_file(next_level_scene_path)
		return

	_cache_actor_sequence_state()

	if rope_manager != null:
		rope_manager.set_physics_process(false)
		rope_manager.set_process(true)
	if camera != null and freeze_camera_during_sequence:
		camera.set_process(false)
		camera.set_physics_process(false)

	castor.velocity = Vector2.ZERO
	castor.set_physics_process(false)
	pollux.linear_velocity = Vector2.ZERO
	pollux.angular_velocity = 0.0
	pollux.freeze = true
	pollux.sleeping = true
	_play_actor_animation(direction)
	_start_actor_sequence_animation_state(direction, distance, duration)

	var offset := Vector2(distance * float(direction), 0.0)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(castor, "global_position", castor.global_position + offset, duration)
	tween.tween_property(pollux, "global_position", pollux.global_position + offset, duration)
	if change_level_after:
		tween.finished.connect(_on_standalone_finish_done)
	else:
		tween.finished.connect(_on_standalone_cancel_done)

func _on_standalone_finish_done() -> void:
	_stop_actor_sequence_animation_state()
	if next_level_scene_path != "" and ResourceLoader.exists(next_level_scene_path):
		get_tree().change_scene_to_file(next_level_scene_path)

func _on_standalone_cancel_done() -> void:
	_stop_actor_sequence_animation_state()
	if castor != null:
		castor.velocity = Vector2.ZERO
		castor.set_physics_process(was_castor_physics_processing)
	if pollux != null:
		pollux.linear_velocity = Vector2.ZERO
		pollux.angular_velocity = 0.0
		pollux.freeze = was_pollux_freeze
		pollux.sleeping = was_pollux_sleeping
	if rope_manager != null:
		rope_manager.set_physics_process(was_rope_physics_processing)
		if rope_manager.has_method("update_rope_visual"):
			rope_manager.call("update_rope_visual")
	if camera != null and freeze_camera_during_sequence:
		camera.set_process(was_camera_processing)
		camera.set_physics_process(was_camera_physics_processing)
	_play_actor_idle(-1)

func _play_actor_animation(direction: int) -> void:
	_play_castor_animation(&"walk", direction)
	_play_pollux_animation(&"walk", direction)

func _play_actor_idle(direction: int) -> void:
	_play_castor_animation(&"idle", direction)
	_play_pollux_animation(&"idle", direction)

func _play_castor_animation(action: StringName, direction: int) -> void:
	var sprite := castor.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null:
		return

	var animation_name: StringName = &""
	if castor.has_method("get_animation_name"):
		animation_name = castor.call("get_animation_name", action, direction)
	else:
		var side := "left" if direction < 0 else "right"
		animation_name = StringName("%s_%s" % [action, side])

	if sprite.sprite_frames.has_animation(animation_name):
		sprite.play(animation_name)

func _play_pollux_animation(action: StringName, direction: int) -> void:
	var sprite := pollux.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null:
		return

	var animation_name := action
	if direction != 0:
		var side := "left" if direction < 0 else "right"
		animation_name = StringName("%s_%s" % [action, side])

	if sprite.sprite_frames.has_animation(animation_name):
		sprite.play(animation_name)

func _cache_actor_sequence_state() -> void:
	was_rope_physics_processing = rope_manager.is_physics_processing() if rope_manager != null else false
	was_camera_processing = camera.is_processing() if camera != null else false
	was_camera_physics_processing = camera.is_physics_processing() if camera != null else false
	was_castor_physics_processing = castor.is_physics_processing() if castor != null else false
	was_pollux_freeze = pollux.freeze if pollux != null else false
	was_pollux_sleeping = pollux.sleeping if pollux != null else false

func _start_actor_sequence_animation_state(direction: int, distance: float, duration: float) -> void:
	actor_sequence_active = true
	actor_sequence_direction = direction
	actor_sequence_speed = 0.0 if duration <= 0.0 else distance / duration
	_update_actor_sequence_animation_state()

func _update_actor_sequence_animation_state() -> void:
	if not actor_sequence_active or pollux == null:
		return

	pollux.linear_velocity = Vector2(float(actor_sequence_direction) * actor_sequence_speed, 0.0)
	if pollux.has_method("update_sprite_animation"):
		pollux.call("update_sprite_animation", pollux.linear_velocity.x)

func _stop_actor_sequence_animation_state() -> void:
	actor_sequence_active = false
	actor_sequence_direction = 0
	actor_sequence_speed = 0.0
