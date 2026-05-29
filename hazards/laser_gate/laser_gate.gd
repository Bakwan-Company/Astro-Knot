extends Area2D

@onready var anim_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D

@export var death_type: String = "laser"

var is_laser_active: bool = true 
var _is_triggered: bool = false

func _ready():
	body_entered.connect(_on_body_entered)
	anim_sprite.play("idle")

func _on_body_entered(body: Node2D):
	if _is_triggered or not is_laser_active:
		return
		
	if body.name == "Castor" or body.name == "Pollux":
		_is_triggered = true
		var checkpoint_manager := get_node_or_null("/root/CheckpointManager")
		if checkpoint_manager != null and checkpoint_manager.has_method("kill"):
			checkpoint_manager.call("kill", death_type)
		else:
			get_tree().reload_current_scene()

func reset() -> void:
	_is_triggered = false

func _on_button_toggled(is_on: bool) -> void:
	if is_on:
		is_laser_active = false
		collision_shape.set_deferred("disabled", true)
		anim_sprite.play("turn_off")

	else:
		is_laser_active = true
		collision_shape.set_deferred("disabled", false)
		
		anim_sprite.play("idle")
