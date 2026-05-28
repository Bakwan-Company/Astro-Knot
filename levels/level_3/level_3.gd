extends Area2D

signal laser_button_pressed

@onready var anim_sprite = $AnimatedSprite2D

var is_pressed: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	anim_sprite.play("unpressed")

func _on_body_entered(body: Node2D) -> void:
	if is_pressed:
		return
		
	# Pengecekan aman, asal karakternya punya fungsi die() (kayak Castor/Pollux), tombol bakal bereaksi
	if body.has_method("die"):
		press_button()

func press_button() -> void:
	is_pressed = true
	anim_sprite.play("pressed") 
	laser_button_pressed.emit()
	print("Tombol diinjek - Laser Mati!")

func _on_laser_button_pressed() -> void:
	pass # Replace with function body.
