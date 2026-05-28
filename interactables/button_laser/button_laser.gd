extends Area2D

signal laser_button_pressed

@onready var anim_sprite = $AnimatedSprite2D

var pollux_in_range: bool = false
var is_pressed: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	anim_sprite.play("unpressed")

func _on_body_entered(body: Node2D) -> void:
	if is_pressed:
		return

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Pollux":
		pollux_in_range = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and pollux_in_range and not is_pressed:
		press_button()

func press_button() -> void:
	is_pressed = true
	anim_sprite.play("pressed") 
	laser_button_pressed.emit()
