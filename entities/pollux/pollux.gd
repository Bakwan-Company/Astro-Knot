extends RigidBody2D

@export var movement_threshold: float = 8.0

var current_motion_direction: int = 0
var pending_animation: StringName = &""
var is_preturning: bool = false

# --- TAMBAHAN: Variabel buat nyatet posisi frame sebelumnya ---
var last_position_x: float = 0.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	# Catat posisi awal
	last_position_x = global_position.x
	if animated_sprite:
		animated_sprite.animation_finished.connect(_on_animation_finished)
		# update_sprite_animation sekarang minta parameter, kita kasih 0.0 dulu
		update_sprite_animation(0.0)

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	var floor_normal = Vector2.ZERO
	var is_on_floor = false
	
	# Loop ngecek semua benda yang lagi nempel sama badan Pollux saat ini
	for i in state.get_contact_count():
		var contact_normal = state.get_contact_local_normal(i)
		if contact_normal.y < -0.5:
			floor_normal = contact_normal
			is_on_floor = true
			break 
			
	# Logika miringin badannya
	if is_on_floor:
		var target_rotation = floor_normal.angle() + (PI / 2.0)
		animated_sprite.rotation = lerp_angle(animated_sprite.rotation, target_rotation, 15.0 * state.step)
	else:
		animated_sprite.rotation = lerp_angle(animated_sprite.rotation, 0.0, 15.0 * state.step)
		
	# === HITUNG KECEPATAN AKTUAL (SPEEDOMETER MANUAL) ===
	# Kecepatan = (Posisi Sekarang - Posisi Sebelumnya) dibagi Waktu (delta/step)
	var effective_vel_x = (global_position.x - last_position_x) / state.step
	
	# Update catatan posisi buat frame berikutnya
	last_position_x = global_position.x
	
	# Lempar kecepatan gabungan ini ke fungsi animasi
	update_sprite_animation(effective_vel_x)


# Fungsi ini sekarang nerima "eff_vel_x" (Kecepatan Aktual)
func update_sprite_animation(eff_vel_x: float) -> void:
	if not animated_sprite:
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
