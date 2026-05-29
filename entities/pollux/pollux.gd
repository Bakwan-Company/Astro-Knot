extends RigidBody2D

@export var movement_threshold: float = 8.0
@export_group("Disabled Pose")
@export var disabled_pose_rotation_degrees: float = -35.0
@export var disabled_pose_offset: Vector2 = Vector2(3.0, -5.0)
@export var disabled_pose_modulate: Color = Color(0.45, 0.48, 0.5, 1.0)

var current_motion_direction: int = 0
var pending_animation: StringName = &""
var is_preturning: bool = false
var last_position_x: float = 0.0
var disabled_pose_active: bool = false
var sprite_default_position: Vector2 = Vector2.ZERO
var sprite_default_modulate: Color = Color.WHITE

# 1. TAMBAHIN VARIABEL INI BIAR BISA DIBACA ROPE MANAGER
var is_grounded: bool = false 

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	last_position_x = global_position.x
	if animated_sprite:
		sprite_default_position = animated_sprite.position
		sprite_default_modulate = animated_sprite.modulate
		animated_sprite.animation_finished.connect(_on_animation_finished)
		update_sprite_animation(0.0)

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if disabled_pose_active:
		is_grounded = false
		last_position_x = global_position.x
		_apply_disabled_pose_visual()
		return

	var floor_normal = Vector2.ZERO
	
	# 2. RESET STATUS TIAP FRAME
	is_grounded = false 
	
	for i in state.get_contact_count():
		var contact_normal = state.get_contact_local_normal(i)
		if contact_normal.y < -0.5:
			floor_normal = contact_normal
			is_grounded = true # 3. KENA LANTAI!
			break 
			
	if is_grounded:
		var target_rotation = floor_normal.angle() + (PI / 2.0)
		animated_sprite.rotation = lerp_angle(animated_sprite.rotation, target_rotation, 15.0 * state.step)
	else:
		animated_sprite.rotation = lerp_angle(animated_sprite.rotation, 0.0, 15.0 * state.step)
		
	var effective_vel_x = (global_position.x - last_position_x) / state.step
	last_position_x = global_position.x
	update_sprite_animation(effective_vel_x)

func set_disabled_pose_active(active: bool) -> void:
	disabled_pose_active = active
	if active:
		linear_velocity = Vector2.ZERO
		angular_velocity = 0.0
		current_motion_direction = 0
		pending_animation = &""
		is_preturning = false
		_apply_disabled_pose_visual()
	else:
		_restore_normal_visual()

func _apply_disabled_pose_visual() -> void:
	if not animated_sprite:
		return

	if animated_sprite.sprite_frames.has_animation(&"idle"):
		animated_sprite.play(&"idle")
	animated_sprite.position = sprite_default_position + disabled_pose_offset
	animated_sprite.rotation = deg_to_rad(disabled_pose_rotation_degrees)
	animated_sprite.modulate = disabled_pose_modulate

func _restore_normal_visual() -> void:
	if not animated_sprite:
		return

	animated_sprite.position = sprite_default_position
	animated_sprite.rotation = 0.0
	animated_sprite.modulate = sprite_default_modulate
	update_sprite_animation(0.0)

# Fungsi ini sekarang nerima "eff_vel_x" (Kecepatan Aktual)
func update_sprite_animation(eff_vel_x: float) -> void:
	if not animated_sprite:
		return
	if disabled_pose_active:
		_apply_disabled_pose_visual()
		return

	var motion_direction := 0
	
	# CEK GANDA: Apakah velocity fisik kenceng, ATAU kecepatan tarikan paksa (eff_vel) kenceng?
	if absf(eff_vel_x) > movement_threshold or absf(linear_velocity.x) > movement_threshold:
		
		# Pilih angka yang geraknya paling kenceng biar akurat
		var check_vel = eff_vel_x if absf(eff_vel_x) > absf(linear_velocity.x) else linear_velocity.x
		motion_direction = -1 if check_vel < 0.0 else 1

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
