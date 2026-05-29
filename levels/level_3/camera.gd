extends Camera2D

@export var castor: CharacterBody2D
@export var pollux: RigidBody2D
@export var smoothing_speed: float = 20.0 # Kecepatan kamera mengikuti gerakan

var cinematic_target: Vector2
var is_cinematic: bool = false

func _process(delta: float) -> void:
	if is_cinematic:
		global_position = global_position.lerp(cinematic_target, smoothing_speed * delta)
	elif castor and pollux:
		var midpoint = (castor.global_position + pollux.global_position) / 2
		
		global_position = global_position.lerp(midpoint, smoothing_speed * delta)

func focus_on_position(target_position: Vector2) -> void:
	cinematic_target = target_position
	is_cinematic = true

func follow_players() -> void:
	is_cinematic = false
