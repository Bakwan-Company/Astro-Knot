extends Area2D

@onready var anim_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D

var is_off = false 

func _ready():
	body_entered.connect(_on_body_entered)
	anim_sprite.play("idle")

func _on_body_entered(body: Node2D):
	if is_off:
		return
		
	if body.name == "Castor" or body.name == "Pollux":
		if body.has_method("die"):
			body.die()

func turn_off_laser():
	if is_off:
		return 
		
	is_off = true
	
	collision_shape.set_deferred("disabled", true)
	
	anim_sprite.play("turn_off")
