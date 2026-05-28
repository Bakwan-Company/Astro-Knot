extends Node2D

@onready var button_laser = %ButtonLaser 
@onready var laser_gate = %LaserGate     

func _ready() -> void:
	if button_laser and laser_gate:
		button_laser.button_toggled.connect(laser_gate._on_button_toggled)
