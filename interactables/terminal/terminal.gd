extends Area2D

signal terminal_activated(is_on: bool)

@export var terminal_off: Texture2D
@export var terminal_on: Texture2D
@export var activation_speed_threshold: float = 40.0

@onready var visual_sprite: Sprite2D = $Sprite2D

var is_active: bool = false
var pollux_body: RigidBody2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_update_visual()

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Pollux" and body is RigidBody2D:
		pollux_body = body

func _on_body_exited(body: Node2D) -> void:
	if body == pollux_body:
		pollux_body = null

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and can_pollux_activate_terminal():
		toggle_terminal()

func toggle_terminal() -> void:
	is_active = !is_active
	terminal_activated.emit(is_active)
	_update_visual()

func _update_visual() -> void:
	if not visual_sprite:
		return

	visual_sprite.texture = terminal_on if is_active else terminal_off

func can_pollux_activate_terminal() -> bool:
	if not is_instance_valid(pollux_body):
		return false

	if pollux_body.get_meta("throw_mode_active", false):
		return false

	return _is_body_grounded(pollux_body) or pollux_body.linear_velocity.length() <= activation_speed_threshold

func _is_body_grounded(body: Node) -> bool:
	if not body:
		return false

	var ground_left = body.get_node_or_null("GroundCheckL")
	var ground_right = body.get_node_or_null("GroundCheckR")
	return (ground_left and ground_left.is_colliding()) or (ground_right and ground_right.is_colliding())
