extends StaticBody2D

@onready var collision_shape = $CollisionShape2D
@onready var visual = $ColorRect 

func _ready() -> void:
	set_bridge_status(false)

func set_bridge_status(is_active: bool) -> void:
	collision_shape.set_deferred("disabled", !is_active)
	
	if is_active:
		visual.modulate.a = 1.0
	else:
		visual.modulate.a = 0.3
