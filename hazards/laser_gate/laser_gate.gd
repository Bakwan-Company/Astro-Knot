extends Area2D

@onready var anim_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D

var is_laser_active: bool = true 

func _ready():
	body_entered.connect(_on_body_entered)
	anim_sprite.play("idle")

func _on_body_entered(body: Node2D):
	if not is_laser_active:
		return
		
	if body.name == "Castor" or body.name == "Pollux":
		get_tree().reload_current_scene()

func _on_button_toggled(is_on: bool) -> void:
	if is_on:
		is_laser_active = false
		collision_shape.set_deferred("disabled", true)
		anim_sprite.play("turn_off")

	else:
		is_laser_active = true
		collision_shape.set_deferred("disabled", false)
		
		anim_sprite.play("idle")
