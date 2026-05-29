extends StaticBody2D

@export var is_on: bool = true

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	_apply_door_status(false)

func set_door_status(active: bool) -> void:
	if is_on == active:
		return

	is_on = active
	_apply_door_status(true)

func set_terminal_status(terminal_is_on: bool) -> void:
	set_door_status(not terminal_is_on)

func _apply_door_status(animate: bool) -> void:
	collision_shape.set_deferred("disabled", !is_on)

	if not animated_sprite:
		return

	if is_on:
		if animate:
			animated_sprite.play("close")
		else:
			animated_sprite.play("closed")
	else:
		if animate:
			animated_sprite.play("open")
		else:
			animated_sprite.play("opened")
