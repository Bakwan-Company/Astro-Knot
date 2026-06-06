extends Node2D

const END_ROCK_TEXTURE := preload("res://asset/Interactables and Hazards/Rock1_5_no_shadow.png")
const ENDING_PANEL_TEXTURE := preload("res://asset/Comics/Level3/last/Level4Panel6_202605291957_37449.png")
const ENDING_RUMBLE_SFX := preload("res://asset/Audio/rubble.mp3")
const MAIN_MENU_PATH := "res://ui/main_menu/MainMenu.tscn"

@export var bridge_camera_hold_time: float = 0.35
@export var bridge_camera_shake_strength: float = 9.0
@export var ending_fall_duration: float = 9.0
@export var ending_fade_start_time: float = 7.6
@export var ending_rock_spawn_interval: float = 0.11
@export var ending_camera_shake_strength: float = 12.0
@export var ending_fade_duration: float = 1.0
@export var ending_input_arm_delay: float = 0.2
@export var ending_rumble_volume_db: float = -2.0
@export var ending_rumble_fade_in_time: float = 0.35
@export var ending_rumble_fade_out_time: float = 0.85

@onready var button_laser = %ButtonLaser 
@onready var laser_gate = %LaserGate     
@onready var button_pillar = %ButtonPillar
@onready var laser_gate_pillar = %LaserGatePillar
@onready var terminal = %Terminal 
@onready var bridge_manager = %BridgeManager
@onready var bridge_camera_focus: Marker2D = %BridgeCameraFocus
@onready var camera: Camera2D = $Camera2D
@onready var skeleton_cutscene_trigger: Area2D = $EndLv/skeleton/ComicCutsceneTrigger
@onready var ending_computer_trigger: Area2D = $EndLv/computer/ComicCutsceneTrigger
@onready var castor: CharacterBody2D = $Castor
@onready var pollux: RigidBody2D = $Pollux
@onready var rope_manager: Node = $RopeManager

var bridge_cutscene_id: int = 0
var ending_sequence_started: bool = false
var ending_waiting_for_input: bool = false
var ending_input_received: bool = false
var skeleton_battery_change_applied: bool = false
var ending_rumble_player: AudioStreamPlayer

func _ready() -> void:
	BgmManager.play_level_3()
	_set_castor_battery_second()

	if button_laser and laser_gate:
		button_laser.button_toggled.connect(laser_gate._on_button_toggled)
	if button_pillar and laser_gate_pillar:
		button_pillar.button_toggled.connect(_on_button_pillar_toggled)
	if terminal and bridge_manager:
		terminal.terminal_activated.connect(_on_terminal_activated)
	if skeleton_cutscene_trigger and skeleton_cutscene_trigger.has_signal("cutscene_finished"):
		skeleton_cutscene_trigger.connect("cutscene_finished", _on_skeleton_cutscene_finished)
	if ending_computer_trigger and ending_computer_trigger.has_signal("cutscene_finished"):
		ending_computer_trigger.connect("cutscene_finished", _on_ending_computer_cutscene_finished)

func _on_button_pillar_toggled(is_on: bool) -> void:
	laser_gate_pillar.set_door_status(not is_on)

func _on_terminal_activated(is_on: bool) -> void:
	bridge_cutscene_id += 1
	var current_cutscene_id := bridge_cutscene_id

	if camera and bridge_camera_focus and camera.has_method("focus_on_position"):
		camera.call("focus_on_position", bridge_camera_focus.global_position)

	bridge_manager._on_terminal_activated(is_on)

	if is_on and camera and camera.has_method("shake"):
		camera.call("shake", bridge_manager.slide_duration, bridge_camera_shake_strength)

	await get_tree().create_timer(bridge_manager.slide_duration + bridge_camera_hold_time).timeout

	if current_cutscene_id != bridge_cutscene_id:
		return

	if camera and camera.has_method("follow_players"):
		camera.call("follow_players")

func _on_skeleton_cutscene_finished() -> void:
	if skeleton_battery_change_applied:
		return

	skeleton_battery_change_applied = true
	_set_castor_battery_first_blinking()

func _on_ending_computer_cutscene_finished() -> void:
	if ending_sequence_started:
		return

	ending_sequence_started = true
	await _play_ending_sequence()

func _play_ending_sequence() -> void:
	_freeze_ending_players()
	_play_ending_rumble()

	if camera and camera.has_method("follow_players"):
		camera.call("follow_players")
	var shake_duration := ending_fall_duration + ending_fade_duration + 0.25
	if camera and camera.has_method("shake_constant"):
		camera.call("shake_constant", shake_duration, ending_camera_shake_strength)
	elif camera and camera.has_method("shake"):
		camera.call("shake", shake_duration, ending_camera_shake_strength)

	_spawn_ending_rocks()
	await get_tree().create_timer(minf(ending_fade_start_time, ending_fall_duration)).timeout
	_fade_out_ending_rumble()
	await _show_the_end_overlay()

func _freeze_ending_players() -> void:
	if rope_manager:
		rope_manager.set_physics_process(false)
		rope_manager.set_process(false)
	if castor:
		castor.velocity = Vector2.ZERO
		castor.set_physics_process(false)
	if pollux:
		pollux.linear_velocity = Vector2.ZERO
		pollux.angular_velocity = 0.0
		pollux.freeze = true
		pollux.sleeping = true

func _set_castor_battery_second() -> void:
	if castor == null:
		return

	if castor.has_method("set_battery_state"):
		castor.call("set_battery_state", 2)
	else:
		castor.set("battery_state", 2)

	if castor.has_method("set_low_battery_blink"):
		castor.call("set_low_battery_blink", false)
	else:
		castor.set("low_battery_blink", false)

func _set_castor_battery_first_blinking() -> void:
	if castor == null:
		return

	if castor.has_method("set_battery_state"):
		castor.call("set_battery_state", 3)
	else:
		castor.set("battery_state", 3)

	if castor.has_method("set_low_battery_blink"):
		castor.call("set_low_battery_blink", true)
	else:
		castor.set("low_battery_blink", true)

func _play_ending_rumble() -> void:
	ending_rumble_player = AudioStreamPlayer.new()
	ending_rumble_player.name = "EndingRumbleSfx"
	ending_rumble_player.bus = "Master"
	ending_rumble_player.stream = ENDING_RUMBLE_SFX
	ending_rumble_player.volume_db = -45.0
	add_child(ending_rumble_player)
	ending_rumble_player.play()

	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(ending_rumble_player, "volume_db", ending_rumble_volume_db, ending_rumble_fade_in_time)

func _fade_out_ending_rumble() -> void:
	if ending_rumble_player == null or not is_instance_valid(ending_rumble_player):
		return

	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(ending_rumble_player, "volume_db", -45.0, ending_rumble_fade_out_time)
	await tween.finished
	if is_instance_valid(ending_rumble_player):
		ending_rumble_player.stop()
		ending_rumble_player.queue_free()
	ending_rumble_player = null

func _spawn_ending_rocks() -> void:
	var rock_layer := Node2D.new()
	rock_layer.name = "EndingRockFall"
	rock_layer.z_index = 200
	add_child(rock_layer)

	var elapsed := 0.0
	while elapsed < ending_fall_duration:
		_spawn_ending_rock(rock_layer)
		await get_tree().create_timer(ending_rock_spawn_interval).timeout
		elapsed += ending_rock_spawn_interval

func _spawn_ending_rock(parent: Node2D) -> void:
	if camera == null:
		return

	var viewport_size := get_viewport_rect().size
	var visible_size := viewport_size / camera.zoom
	var left := camera.global_position.x - visible_size.x * 0.5
	var right := camera.global_position.x + visible_size.x * 0.5
	var top := camera.global_position.y - visible_size.y * 0.5 - 160.0
	var bottom := camera.global_position.y + visible_size.y * 0.5 + 220.0

	var rock := Sprite2D.new()
	rock.texture = END_ROCK_TEXTURE
	rock.position = Vector2(randf_range(left, right), top - randf_range(0.0, 180.0))
	rock.rotation = randf_range(-PI, PI)
	rock.scale = Vector2.ONE * randf_range(0.35, 1.15)
	rock.z_index = 200
	parent.add_child(rock)

	var fall_time := randf_range(1.6, 2.7)
	var drift := randf_range(-110.0, 110.0)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(rock, "position", Vector2(rock.position.x + drift, bottom), fall_time)
	tween.tween_property(rock, "rotation", rock.rotation + randf_range(3.0, 8.0), fall_time)
	tween.tween_property(rock, "modulate:a", 0.0, 0.35).set_delay(fall_time - 0.35)
	tween.finished.connect(rock.queue_free)

func _show_the_end_overlay() -> void:
	var overlay := CanvasLayer.new()
	overlay.name = "TheEndOverlay"
	overlay.layer = 100
	add_child(overlay)

	var black_background := ColorRect.new()
	black_background.color = Color(0, 0, 0, 0)
	black_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(black_background)

	var end_image := TextureRect.new()
	end_image.texture = ENDING_PANEL_TEXTURE
	end_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	end_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	end_image.modulate = Color(1, 1, 1, 0)
	end_image.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(end_image)

	var fade_to_black := ColorRect.new()
	fade_to_black.color = Color(0, 0, 0, 0)
	fade_to_black.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(fade_to_black)

	var tween := create_tween()
	tween.tween_property(black_background, "color:a", 1.0, ending_fade_duration)
	tween.tween_property(end_image, "modulate:a", 1.0, 1.2)
	await tween.finished
	await get_tree().create_timer(ending_input_arm_delay).timeout

	ending_input_received = false
	ending_waiting_for_input = true
	while not ending_input_received:
		await get_tree().process_frame
	ending_waiting_for_input = false

	var exit_tween := create_tween()
	exit_tween.tween_property(fade_to_black, "color:a", 1.0, ending_fade_duration)
	await exit_tween.finished

	if ResourceLoader.exists(MAIN_MENU_PATH):
		get_tree().change_scene_to_file(MAIN_MENU_PATH)

func _input(event: InputEvent) -> void:
	if not ending_waiting_for_input or ending_input_received:
		return

	if _is_ending_continue_event(event):
		ending_input_received = true

func _is_ending_continue_event(event: InputEvent) -> bool:
	if event is InputEventKey:
		return event.pressed and not event.echo
	if event is InputEventMouseButton:
		return event.pressed
	if event is InputEventJoypadButton:
		return event.pressed
	if event is InputEventScreenTouch:
		return event.pressed
	if event is InputEventAction:
		return event.pressed
	return false
