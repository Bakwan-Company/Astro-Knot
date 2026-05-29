extends Node2D

@onready var button_laser = %ButtonLaser 
@onready var laser_gate = %LaserGate     
@onready var terminal = %Terminal 
@onready var bridge_manager = %BridgeManager

func _ready() -> void:
	if button_laser and laser_gate:
		button_laser.button_toggled.connect(laser_gate._on_button_toggled)
	if terminal and bridge_manager:
		terminal.terminal_activated.connect(bridge_manager._on_terminal_activated)
