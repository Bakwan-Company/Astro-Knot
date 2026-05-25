extends Camera2D

@export var castor: CharacterBody2D
@export var pollux: RigidBody2D
@export var smoothing_speed: float = 5.0 # Kecepatan kamera mengikuti gerakan

func _process(delta: float) -> void:
	if castor and pollux:
		var midpoint = (castor.global_position + pollux.global_position) / 2
		
		global_position = global_position.lerp(midpoint, smoothing_speed * delta)
