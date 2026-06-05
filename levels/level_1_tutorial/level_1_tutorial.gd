extends Node2D

const TETHER_CONNECT_COMIC_SCENE := preload("res://comics/level1/ConnectCastor.tscn")
const UI_FONT := preload("res://asset/Font/SuperMarioDsRegular-Ea4R8.ttf")

@export_group("Level Flow")
@export var area_title: String = "Crash Site"
@export var area_subtitle: String = "Ulbul Surface"
@export var area_title_color: Color = Color(0.18, 0.11, 0.07, 1.0)
@export var area_subtitle_color: Color = Color(0.62, 0.28, 0.08, 1.0)
@export var area_title_shadow_color: Color = Color(1.0, 0.78, 0.42, 0.45)
@export var area_title_hold_time: float = 1.4
@export var area_title_fade_time: float = 0.8
@export var next_level_scene_path: String = ""
@export var exit_prompt_text: String = "Old signal relay detected"
@export var exit_confirm_title: String = "Follow the signal?"
@export var exit_confirm_detail: String = "Continue toward The Silent Ruins"
@export var finish_walk_distance: float = 420.0
@export var finish_walk_time: float = 1.8
@export var exit_cancel_walk_distance: float = 110.0
@export var exit_cancel_walk_time: float = 0.35
@export var game_over_scene: PackedScene = preload("res://ui/game_over/GameOverOverlay.tscn")

@export var pollux_connect_radius: float = 46.0
@export var prompt_offset: Vector2 = Vector2(-26.0, -42.0)
@export var connected_message_time: float = 2.0

@onready var castor: CharacterBody2D = $Castor
@onready var pollux: RigidBody2D = $Pollux
@onready var rope_manager: Node2D = $RopeManager
@onready var camera: Camera2D = $Camera2D
@onready var fall_zone: Area2D = get_node_or_null("FallZone") as Area2D
@onready var exit_sign: Area2D = get_node_or_null("SilentRuinsSign") as Area2D
@onready var exit_prompt: Label = get_node_or_null("SilentRuinsSign/PromptLabel") as Label
@onready var level_exit: Area2D = get_node_or_null("LevelExit") as Area2D
@onready var opening_comic: CanvasLayer = get_node_or_null("ComicCutscene") as CanvasLayer

var tether_connected: bool = false
var castor_in_connect_range: bool = false
var castor_in_exit_range: bool = false
var connect_prompt: Label
var connect_zone: Area2D
var connect_collision: CollisionShape2D
var connected_message_timer: float = 0.0
var level_failed: bool = false
var level_completed: bool = false
var exit_canceling: bool = false
var title_layer: CanvasLayer
var title_group: Control
var exit_confirm_layer: CanvasLayer
var exit_confirm_open: bool = false
var tether_connect_comic_active: bool = false

func _ready() -> void:
	if opening_comic != null and opening_comic.has_signal("finished"):
		BgmManager.stop()
		opening_comic.connect("finished", _on_opening_comic_finished)
	else:
		BgmManager.play_level_1()

	if fall_zone != null:
		fall_zone.body_entered.connect(_on_fall_zone_body_entered)

	if level_exit == null and exit_sign != null:
		exit_sign.body_entered.connect(_on_exit_sign_body_entered)
		exit_sign.body_exited.connect(_on_exit_sign_body_exited)
		if exit_prompt != null:
			exit_prompt.visible = false
			exit_prompt.text = exit_prompt_text

	_create_pollux_connect_zone()
	_create_connect_prompt()
	_apply_connection_state(_is_tether_connected())
	_show_area_title()

func _on_opening_comic_finished() -> void:
	BgmManager.play_level_1()

func _process(delta: float) -> void:
	if level_failed or level_completed:
		return

	if exit_confirm_open:
		if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("ui_accept"):
			_confirm_exit()
		elif Input.is_action_just_pressed("ui_cancel"):
			_cancel_exit()
		return

	if not tether_connected and castor_in_connect_range and Input.is_action_just_pressed("interact"):
		_play_tether_connect_comic()

	if tether_connected and connected_message_timer > 0.0:
		connected_message_timer = maxf(connected_message_timer - delta, 0.0)
		connect_prompt.visible = connected_message_timer > 0.0

	if not tether_connected:
		connect_prompt.visible = castor_in_connect_range

func set_tether_connected(value: bool) -> void:
	tether_connected = value

	if rope_manager != null and rope_manager.has_method("set_tether_connected"):
		rope_manager.set_tether_connected(value)

	_apply_connection_state(value)

func _apply_connection_state(value: bool) -> void:
	tether_connected = value

	if pollux != null and pollux.has_method("set_disabled_pose_active"):
		pollux.call("set_disabled_pose_active", not value)

	if camera != null:
		camera.set("include_pollux", value)

	if connect_zone != null:
		connect_zone.monitoring = not value
		connect_zone.visible = not value
	if connect_collision != null:
		connect_collision.disabled = value

	if value:
		castor_in_connect_range = false
		connect_prompt.visible = false
		connected_message_timer = 0.0
	else:
		connect_prompt.text = "F to connect tether"
		connect_prompt.visible = false

func _is_tether_connected() -> bool:
	if rope_manager != null and rope_manager.has_method("is_tether_connected"):
		return rope_manager.is_tether_connected()
	return true

func _play_tether_connect_comic() -> void:
	if tether_connect_comic_active:
		return

	tether_connect_comic_active = true
	connect_prompt.visible = false

	var comic := TETHER_CONNECT_COMIC_SCENE.instantiate() as CanvasLayer
	if comic.has_signal("finished"):
		comic.connect("finished", _on_tether_connect_comic_finished)
	add_child(comic)

func _on_tether_connect_comic_finished() -> void:
	tether_connect_comic_active = false
	set_tether_connected(true)

func _create_pollux_connect_zone() -> void:
	connect_zone = Area2D.new()
	connect_zone.name = "PolluxConnectZone"
	connect_zone.collision_mask = castor.collision_layer
	connect_zone.monitoring = true
	connect_zone.monitorable = false
	pollux.add_child(connect_zone)

	var shape := CircleShape2D.new()
	shape.radius = pollux_connect_radius

	connect_collision = CollisionShape2D.new()
	connect_collision.position = Vector2(20.0, 20.0)
	connect_collision.shape = shape
	connect_zone.add_child(connect_collision)

	connect_zone.body_entered.connect(_on_pollux_connect_zone_body_entered)
	connect_zone.body_exited.connect(_on_pollux_connect_zone_body_exited)

func _create_connect_prompt() -> void:
	connect_prompt = Label.new()
	connect_prompt.name = "ConnectTetherPrompt"
	connect_prompt.text = "F to connect tether"
	connect_prompt.visible = false
	connect_prompt.z_index = 50
	connect_prompt.add_theme_font_size_override("font_size", 10)
	connect_prompt.add_theme_color_override("font_color", Color(0.05, 0.04, 0.03, 1.0))
	connect_prompt.add_theme_color_override("font_shadow_color", Color(1.0, 0.88, 0.54, 0.85))
	connect_prompt.add_theme_constant_override("shadow_offset_x", 1)
	connect_prompt.add_theme_constant_override("shadow_offset_y", 1)
	pollux.add_child(connect_prompt)
	connect_prompt.position = prompt_offset

func _on_pollux_connect_zone_body_entered(body: Node2D) -> void:
	if body == castor:
		castor_in_connect_range = true

func _on_pollux_connect_zone_body_exited(body: Node2D) -> void:
	if body == castor:
		castor_in_connect_range = false

func _on_fall_zone_body_entered(body: Node2D) -> void:
	if body == castor or body == pollux:
		_trigger_failure("fall")

func _on_exit_sign_body_entered(body: Node2D) -> void:
	if body == castor:
		castor_in_exit_range = true
		_open_exit_confirm()

func _on_exit_sign_body_exited(body: Node2D) -> void:
	if body == castor:
		castor_in_exit_range = false
		if not exit_confirm_open and exit_prompt != null:
			exit_prompt.visible = false

func _trigger_failure(death_type: String) -> void:
	if level_failed or level_completed:
		return

	level_failed = true

	if game_over_scene == null:
		get_tree().call_deferred("reload_current_scene")
		return

	var overlay: Node = game_over_scene.instantiate()
	add_child(overlay)
	if overlay.has_method("show_death"):
		overlay.call("show_death", death_type)
	get_tree().paused = true

func _begin_finish_sequence() -> void:
	if level_completed:
		return

	level_completed = true
	set_process_input(false)
	if exit_prompt != null:
		exit_prompt.visible = false
	_close_exit_confirm()

	if rope_manager != null:
		rope_manager.set_physics_process(false)
		rope_manager.set_process(true)

	if camera != null:
		camera.set_process(false)

	castor.set_physics_process(false)
	pollux.freeze = true
	pollux.sleeping = true

	var exit_offset := Vector2(finish_walk_distance, 0.0)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(castor, "global_position", castor.global_position + exit_offset, finish_walk_time)
	tween.tween_property(pollux, "global_position", pollux.global_position + exit_offset, finish_walk_time)
	tween.finished.connect(_on_finish_sequence_done)

func _on_finish_sequence_done() -> void:
	if next_level_scene_path != "" and ResourceLoader.exists(next_level_scene_path):
		get_tree().change_scene_to_file(next_level_scene_path)

func _open_exit_confirm() -> void:
	if exit_confirm_open or level_completed:
		return

	exit_confirm_open = true
	if exit_prompt != null:
		exit_prompt.visible = false
	castor.set_physics_process(false)
	pollux.freeze = true
	pollux.sleeping = true
	_create_exit_confirm_ui()

func _confirm_exit() -> void:
	_begin_finish_sequence()

func _cancel_exit() -> void:
	if exit_canceling:
		return

	exit_canceling = true
	exit_confirm_open = false
	_close_exit_confirm()
	var exit_offset := Vector2(-exit_cancel_walk_distance, 0.0)
	castor.velocity = Vector2.ZERO
	castor.set_physics_process(false)
	pollux.linear_velocity = Vector2.ZERO
	pollux.angular_velocity = 0.0
	pollux.freeze = true
	pollux.sleeping = true
	castor_in_exit_range = false
	if exit_prompt != null:
		exit_prompt.visible = false

	if rope_manager != null:
		rope_manager.set_physics_process(false)
		rope_manager.set_process(true)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(castor, "global_position", castor.global_position + exit_offset, exit_cancel_walk_time)
	tween.tween_property(pollux, "global_position", pollux.global_position + exit_offset, exit_cancel_walk_time)
	tween.finished.connect(_finish_exit_cancel)

func _finish_exit_cancel() -> void:
	castor.velocity = Vector2.ZERO
	castor.set_physics_process(true)
	pollux.linear_velocity = Vector2.ZERO
	pollux.angular_velocity = 0.0
	pollux.freeze = not tether_connected
	pollux.sleeping = not tether_connected

	if rope_manager != null:
		rope_manager.set_physics_process(tether_connected)
		if rope_manager.has_method("update_rope_visual"):
			rope_manager.call("update_rope_visual")

	exit_canceling = false

func _close_exit_confirm() -> void:
	exit_confirm_open = false
	if exit_confirm_layer != null and is_instance_valid(exit_confirm_layer):
		exit_confirm_layer.queue_free()
	exit_confirm_layer = null

func _create_exit_confirm_ui() -> void:
	exit_confirm_layer = CanvasLayer.new()
	exit_confirm_layer.name = "ExitConfirmLayer"
	exit_confirm_layer.layer = 80
	add_child(exit_confirm_layer)

	var dimmer := ColorRect.new()
	dimmer.anchor_right = 1.0
	dimmer.anchor_bottom = 1.0
	dimmer.color = Color(0.035, 0.028, 0.022, 0.56)
	exit_confirm_layer.add_child(dimmer)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -190.0
	panel.offset_top = -86.0
	panel.offset_right = 190.0
	panel.offset_bottom = 92.0
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.07, 0.058, 0.048, 0.9)
	panel_style.border_color = Color(0.33, 0.62, 0.64, 0.72)
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.corner_radius_top_left = 6
	panel_style.corner_radius_top_right = 6
	panel_style.corner_radius_bottom_left = 6
	panel_style.corner_radius_bottom_right = 6
	panel.add_theme_stylebox_override("panel", panel_style)
	exit_confirm_layer.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	var relay_label := Label.new()
	relay_label.text = "OLD SIGNAL RELAY"
	relay_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	relay_label.add_theme_font_override("font", UI_FONT)
	relay_label.add_theme_font_size_override("font_size", 10)
	relay_label.add_theme_color_override("font_color", Color(0.52, 0.78, 0.78, 1.0))
	box.add_child(relay_label)

	var title := Label.new()
	title.text = exit_confirm_title
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", UI_FONT)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.88, 0.65, 0.34, 1.0))
	title.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.55))
	title.add_theme_constant_override("shadow_offset_x", 1)
	title.add_theme_constant_override("shadow_offset_y", 1)
	box.add_child(title)

	var detail := Label.new()
	detail.text = exit_confirm_detail
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.add_theme_font_override("font", UI_FONT)
	detail.add_theme_font_size_override("font_size", 12)
	detail.add_theme_color_override("font_color", Color(0.68, 0.82, 0.82, 1.0))
	box.add_child(detail)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 14)
	box.add_child(buttons)

	var yes_button := Button.new()
	yes_button.text = "Yes"
	yes_button.pressed.connect(_confirm_exit)
	_style_signal_button(yes_button, true)
	buttons.add_child(yes_button)

	var no_button := Button.new()
	no_button.text = "No"
	no_button.pressed.connect(_cancel_exit)
	_style_signal_button(no_button, false)
	buttons.add_child(no_button)

	yes_button.grab_focus()

func _style_signal_button(button: Button, is_primary: bool) -> void:
	button.custom_minimum_size = Vector2(88.0, 44.0)
	button.add_theme_font_override("font", UI_FONT)
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", Color(0.04, 0.035, 0.03, 1.0) if is_primary else Color(0.82, 0.94, 0.96, 1.0))
	button.add_theme_color_override("font_focus_color", Color(0.04, 0.035, 0.03, 1.0))

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.78, 0.48, 0.2, 1.0) if is_primary else Color(0.075, 0.085, 0.085, 0.95)
	normal.border_color = Color(0.9, 0.68, 0.38, 1.0) if is_primary else Color(0.32, 0.55, 0.56, 0.75)
	normal.border_width_left = 1
	normal.border_width_top = 1
	normal.border_width_right = 1
	normal.border_width_bottom = 1
	normal.corner_radius_top_left = 5
	normal.corner_radius_top_right = 5
	normal.corner_radius_bottom_left = 5
	normal.corner_radius_bottom_right = 5
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", normal)
	button.add_theme_stylebox_override("pressed", normal)
	button.add_theme_stylebox_override("focus", normal)

func _show_area_title() -> void:
	title_layer = CanvasLayer.new()
	title_layer.name = "AreaTitleLayer"
	title_layer.layer = 50
	add_child(title_layer)

	title_group = VBoxContainer.new()
	title_group.name = "AreaTitle"
	title_group.anchor_left = 0.5
	title_group.anchor_top = 0.18
	title_group.anchor_right = 0.5
	title_group.anchor_bottom = 0.18
	title_group.offset_left = -180.0
	title_group.offset_top = -32.0
	title_group.offset_right = 180.0
	title_group.offset_bottom = 52.0
	title_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_layer.add_child(title_group)

	var title := Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", area_title_color)
	title.add_theme_color_override("font_shadow_color", area_title_shadow_color)
	title.add_theme_constant_override("shadow_offset_x", 1)
	title.add_theme_constant_override("shadow_offset_y", 1)
	title.text = area_title
	title_group.add_child(title)

	var subtitle := Label.new()
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 11)
	subtitle.add_theme_color_override("font_color", area_subtitle_color)
	subtitle.add_theme_color_override("font_shadow_color", area_title_shadow_color)
	subtitle.add_theme_constant_override("shadow_offset_x", 1)
	subtitle.add_theme_constant_override("shadow_offset_y", 1)
	subtitle.text = area_subtitle
	title_group.add_child(subtitle)

	var tween := create_tween()
	tween.tween_interval(area_title_hold_time)
	tween.tween_property(title_group, "modulate:a", 0.0, area_title_fade_time)
	tween.tween_callback(title_layer.queue_free)
