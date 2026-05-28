extends Node2D

@onready var button_laser = $ButtonLaser 
@onready var laser_gate = $LaserGate     

func _ready() -> void:
	if button_laser and laser_gate:
		button_laser.laser_button_pressed.connect(laser_gate.turn_off_laser)
		print("--- SYSTEM: Sinyal Tombol -> Laser Berhasil Disambungkan via Kode! ---")
	else:
		print("--- ERROR: Node ButtonLaser atau LaserGate nggak ketemu! Cek lagi namanya ---")

func _on_button_laser_body_entered(body: Node2D) -> void:
	pass # Replace with function body.


func _on_laser_gate_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
