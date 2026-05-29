extends Area2D

signal button_toggled(is_on: bool)

@onready var anim_sprite = $AnimatedSprite2D

var is_pressed: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	anim_sprite.play("unpressed")

func _on_body_entered(body: Node2D) -> void:
	if is_pressed:
		return
		
	if body.name == "Castor" or body.name == "Pollux" or "Castor" in body.name or "Pollux" in body.name:
		press_button()

func press_button() -> void:
	is_pressed = true
	anim_sprite.play("pressed")
	button_toggled.emit(true)
