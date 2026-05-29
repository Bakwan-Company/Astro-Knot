@tool
extends Area2D

signal enter_started
signal enter_finished

enum EntryMode {
	CASTOR_ONLY,
	CASTOR_AND_POLLUX,
}

@export var auto_play_on_ready: bool = true
@export var play_on_body_entered: bool = false
@export var valid_body_names: PackedStringArray = ["Castor"]
@export var entry_mode: EntryMode = EntryMode.CASTOR_AND_POLLUX
@export var entry_direction: int = 1:
	set(value):
		entry_direction = -1 if value < 0 else 1
@export var entry_walk_distance: float = 260.0
@export var entry_walk_time: float = 1.15
@export var entry_start_delay: float = 0.15
@export var freeze_camera_during_sequence: bool = true
@export var snap_camera_to_entry_target: bool = true

@export_group("Actors")
@export var castor_path: NodePath = NodePath("../Castor")
@export var pollux_path: NodePath = NodePath("../Pollux")
@export var rope_manager_path: NodePath = NodePath("../RopeManager")
@export var camera_path: NodePath = NodePath("../Camera2D")

var castor: CharacterBody2D
var pollux: RigidBody2D
var rope_manager: Node
var camera: Camera2D
var sequence_active: bool = false
var sequence_direction: int = 1
var sequence_speed: float = 0.0
var castor_target_position: Vector2 = Vector2.ZERO
var pollux_target_position: Vector2 = Vector2.ZERO
var was_rope_processing: bool = false
var was_rope_physics_processing: bool = false
var was_camera_processing: bool = false
var was_camera_physics_processing: bool = false
var was_castor_physics_processing: bool = false
var was_pollux_freeze: bool = false
var was_pollux_sleeping: bool = false
var has_played: bool = false

func _ready() -> void:
	if Engine.is_editor_hint():
		return

	body_entered.connect(_on_body_entered)
	castor = get_node_or_null(castor_path) as CharacterBody2D
	pollux = get_node_or_null(pollux_path) as RigidBody2D
	rope_manager = get_node_or_null(rope_manager_path)
	camera = get_node_or_null(camera_path) as Camera2D

	if auto_play_on_ready:
		call_deferred("play_enter_sequence")

func _on_body_entered(body: Node2D) -> void:
	if not play_on_body_entered:
		return
	if not valid_body_names.is_empty() and String(body.name) not in valid_body_names:
		return
	play_enter_sequence()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_update_sequence_animation_state()

func play_enter_sequence() -> void:
	if has_played or sequence_active or castor == null:
		return

	has_played = true
	var move_pollux: bool = entry_mode == EntryMode.CASTOR_AND_POLLUX and pollux != null
	_cache_state()

	castor_target_position = castor.global_position
	if pollux != null:
		pollux_target_position = pollux.global_position
	if snap_camera_to_entry_target:
		_snap_camera_to_entry_target(move_pollux)

	var start_offset := Vector2(-entry_walk_distance * float(entry_direction), 0.0)
	castor.global_position = castor_target_position + start_offset
	castor.velocity = Vector2.ZERO
	castor.set_physics_process(false)

	if move_pollux:
		pollux.global_position = pollux_target_position + start_offset
		pollux.linear_velocity = Vector2.ZERO
		pollux.angular_velocity = 0.0
		pollux.freeze = true
		pollux.sleeping = true

	if rope_manager != null:
		rope_manager.set_physics_process(false)
		rope_manager.set_process(true)
		if rope_manager.has_method("update_rope_visual"):
			rope_manager.call("update_rope_visual")

	if camera != null and freeze_camera_during_sequence:
		camera.set_process(false)
		camera.set_physics_process(false)

	await get_tree().create_timer(maxf(entry_start_delay, 0.0)).timeout
	if not is_inside_tree():
		return

	_play_actor_animation(entry_direction, move_pollux)
	_start_sequence_animation_state(entry_direction, entry_walk_distance, entry_walk_time)
	enter_started.emit()

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(castor, "global_position", castor_target_position, entry_walk_time)
	if move_pollux:
		tween.tween_property(pollux, "global_position", pollux_target_position, entry_walk_time)
	tween.finished.connect(_on_enter_tween_finished)

func _on_enter_tween_finished() -> void:
	_stop_sequence_animation_state()
	_restore_state()
	_play_actor_idle(entry_direction)
	enter_finished.emit()

func _cache_state() -> void:
	was_rope_processing = rope_manager.is_processing() if rope_manager != null else false
	was_rope_physics_processing = rope_manager.is_physics_processing() if rope_manager != null else false
	was_camera_processing = camera.is_processing() if camera != null else false
	was_camera_physics_processing = camera.is_physics_processing() if camera != null else false
	was_castor_physics_processing = castor.is_physics_processing() if castor != null else false
	was_pollux_freeze = pollux.freeze if pollux != null else false
	was_pollux_sleeping = pollux.sleeping if pollux != null else false

func _restore_state() -> void:
	if castor != null:
		castor.velocity = Vector2.ZERO
		castor.set_physics_process(was_castor_physics_processing)
	if pollux != null:
		pollux.linear_velocity = Vector2.ZERO
		pollux.angular_velocity = 0.0
		pollux.freeze = was_pollux_freeze
		pollux.sleeping = was_pollux_sleeping
	if rope_manager != null:
		rope_manager.set_process(was_rope_processing)
		rope_manager.set_physics_process(was_rope_physics_processing)
		if rope_manager.has_method("update_rope_visual"):
			rope_manager.call("update_rope_visual")
	if camera != null and freeze_camera_during_sequence:
		camera.set_process(was_camera_processing)
		camera.set_physics_process(was_camera_physics_processing)

func _snap_camera_to_entry_target(include_pollux: bool) -> void:
	if camera == null or castor == null:
		return

	var target_position: Vector2 = castor_target_position
	if include_pollux and pollux != null:
		target_position = (castor_target_position + pollux_target_position) * 0.5

	var framing_offset: Variant = camera.get("framing_offset")
	if framing_offset is Vector2:
		target_position += framing_offset

	camera.global_position = target_position

func _play_actor_animation(direction: int, include_pollux: bool) -> void:
	_play_castor_animation(&"walk", direction)
	if include_pollux:
		_play_pollux_animation(&"walk", direction)

func _play_actor_idle(direction: int) -> void:
	_play_castor_animation(&"idle", direction)
	if entry_mode == EntryMode.CASTOR_AND_POLLUX:
		_play_pollux_animation(&"idle", direction)

func _play_castor_animation(action: StringName, direction: int) -> void:
	if castor == null:
		return

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
	if pollux == null:
		return

	var sprite := pollux.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null:
		return

	var animation_name := action
	if direction != 0:
		var side := "left" if direction < 0 else "right"
		animation_name = StringName("%s_%s" % [action, side])

	if sprite.sprite_frames.has_animation(animation_name):
		sprite.play(animation_name)

func _start_sequence_animation_state(direction: int, distance: float, duration: float) -> void:
	sequence_active = true
	sequence_direction = direction
	sequence_speed = 0.0 if duration <= 0.0 else distance / duration
	_update_sequence_animation_state()

func _update_sequence_animation_state() -> void:
	if not sequence_active:
		return

	if pollux != null and entry_mode == EntryMode.CASTOR_AND_POLLUX:
		pollux.linear_velocity = Vector2(float(sequence_direction) * sequence_speed, 0.0)
		if pollux.has_method("update_sprite_animation"):
			pollux.call("update_sprite_animation", pollux.linear_velocity.x)

func _stop_sequence_animation_state() -> void:
	sequence_active = false
	sequence_direction = 0
	sequence_speed = 0.0
