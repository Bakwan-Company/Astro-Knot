extends RigidBody2D

@export var movement_threshold: float = 8.0

var current_motion_direction: int = 0
var pending_animation: StringName = &""
var is_preturning: bool = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var floor_sensor: RayCast2D = $FloorSensor # <--- Ambil sensornya

func _ready() -> void:
	if animated_sprite:
		animated_sprite.animation_finished.connect(_on_animation_finished)
		update_sprite_animation()

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	var floor_normal = Vector2.ZERO
	var is_on_floor = false
	
	# Loop ngecek semua benda yang lagi nempel sama badan Pollux saat ini
	for i in state.get_contact_count():
		var contact_normal = state.get_contact_local_normal(i)
		
		# Kalau arah dorongannya ke atas (Y minus), berarti benda itu lantai!
		if contact_normal.y < -0.5:
			floor_normal = contact_normal
			is_on_floor = true
			break # Begitu nemu lantai, stop nyari
			
	# Logika miringin badannya (sama persis kayak yang lu mau)
	if is_on_floor:
		var target_rotation = floor_normal.angle() + (PI / 2.0)
		# state.step itu sama kayak delta
		animated_sprite.rotation = lerp_angle(animated_sprite.rotation, target_rotation, 15.0 * state.step)
	else:
		animated_sprite.rotation = lerp_angle(animated_sprite.rotation, 0.0, 15.0 * state.step)
		
	# Jalanin animasi jalan/idle lu
	update_sprite_animation()

func update_sprite_animation() -> void:
	if not animated_sprite:
		return

	var motion_direction := 0
	if absf(linear_velocity.x) > movement_threshold:
		motion_direction = -1 if linear_velocity.x < 0.0 else 1

	if motion_direction == 0:
		if is_preturning:
			return

		if current_motion_direction != 0:
			pending_animation = &"idle"
			is_preturning = true
			play_animation(&"preturn_left" if current_motion_direction < 0 else &"preturn_right")
			current_motion_direction = 0
			return

		pending_animation = &""
		play_animation(&"idle")
		return

	var walk_animation := &"walk_left" if motion_direction < 0 else &"walk_right"
	if current_motion_direction != motion_direction:
		current_motion_direction = motion_direction
		pending_animation = walk_animation
		is_preturning = true
		play_animation(&"preturn_left" if motion_direction < 0 else &"preturn_right")
		return

	if is_preturning:
		return

	play_animation(walk_animation)

func play_animation(animation_name: StringName) -> void:
	if animated_sprite.animation == animation_name and animated_sprite.is_playing():
		return

	if not animated_sprite.sprite_frames.has_animation(animation_name):
		return

	animated_sprite.play(animation_name)

func _on_animation_finished() -> void:
	if not is_preturning:
		return

	is_preturning = false
	if pending_animation != &"":
		play_animation(pending_animation)
