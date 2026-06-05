extends Camera2D

@export var castor: CharacterBody2D
@export var pollux: RigidBody2D
@export var smoothing_speed: float = 20.0 # Kecepatan kamera mengikuti gerakan

var cinematic_target: Vector2
var is_cinematic: bool = false
var shake_time: float = 0.0
var shake_duration: float = 0.0
var shake_strength: float = 0.0
var shake_constant_intensity: bool = false

func _process(delta: float) -> void:
	if is_cinematic:
		global_position = global_position.lerp(cinematic_target, smoothing_speed * delta)
	elif castor and pollux:
		var midpoint = (castor.global_position + pollux.global_position) / 2
		
		global_position = global_position.lerp(midpoint, smoothing_speed * delta)

	_update_shake(delta)

func focus_on_position(target_position: Vector2) -> void:
	cinematic_target = target_position
	is_cinematic = true

func follow_players() -> void:
	is_cinematic = false

func shake(duration: float, strength: float) -> void:
	shake_duration = maxf(duration, 0.01)
	shake_time = shake_duration
	shake_strength = strength
	shake_constant_intensity = false

func shake_constant(duration: float, strength: float) -> void:
	shake_duration = maxf(duration, 0.01)
	shake_time = shake_duration
	shake_strength = strength
	shake_constant_intensity = true

func _update_shake(delta: float) -> void:
	if shake_time <= 0.0:
		offset = Vector2.ZERO
		shake_constant_intensity = false
		return

	shake_time = maxf(shake_time - delta, 0.0)
	var intensity := shake_strength
	if not shake_constant_intensity:
		intensity *= shake_time / shake_duration
	offset = Vector2(
		randf_range(-intensity, intensity),
		randf_range(-intensity, intensity)
	)

	if shake_time <= 0.0:
		offset = Vector2.ZERO
		shake_constant_intensity = false
