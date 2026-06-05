extends Node2D

@export var bridge_camera_hold_time: float = 0.35

@onready var button_laser = %ButtonLaser 
@onready var laser_gate = %LaserGate     
@onready var button_pillar = %ButtonPillar
@onready var laser_gate_pillar = %LaserGatePillar
@onready var terminal = %Terminal 
@onready var bridge_manager = %BridgeManager
@onready var bridge_camera_focus: Marker2D = %BridgeCameraFocus
@onready var camera: Camera2D = $Camera2D

var bridge_cutscene_id: int = 0

func _ready() -> void:
	BgmManager.play_level_3()

	if button_laser and laser_gate:
		button_laser.button_toggled.connect(laser_gate._on_button_toggled)
	if button_pillar and laser_gate_pillar:
		button_pillar.button_toggled.connect(_on_button_pillar_toggled)
	if terminal and bridge_manager:
		terminal.terminal_activated.connect(_on_terminal_activated)

func _on_button_pillar_toggled(is_on: bool) -> void:
	laser_gate_pillar.set_door_status(not is_on)

func _on_terminal_activated(is_on: bool) -> void:
	bridge_cutscene_id += 1
	var current_cutscene_id := bridge_cutscene_id

	if camera and bridge_camera_focus and camera.has_method("focus_on_position"):
		camera.call("focus_on_position", bridge_camera_focus.global_position)

	bridge_manager._on_terminal_activated(is_on)

	if not is_on:
		if camera and camera.has_method("follow_players"):
			camera.call("follow_players")
		return

	await get_tree().create_timer(bridge_manager.slide_duration + bridge_camera_hold_time).timeout

	if current_cutscene_id != bridge_cutscene_id:
		return

	if camera and camera.has_method("follow_players"):
		camera.call("follow_players")
