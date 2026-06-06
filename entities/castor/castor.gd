extends CharacterBody2D

enum BatteryState {
	FULL,
	THIRD,
	SECOND,
	FIRST,
	NONE,
}

@export var speed: float = 300.0 # Sedikit lebih cepat biar enak narik Pollux
@export var air_speed: float = 300.0
@export var jump_velocity: float = -400.0
@export var air_friction: float = 0.5 # Gesekan udara biar ayunan gak abadi (tapi tipis banget)
@export var terminal_velocity: float = 1000.0 # Biar gak nembus lantai kalau jatuh kecepetan
@export var battery_state: BatteryState = BatteryState.FULL
@export var low_battery_blink: bool = false
@export var low_battery_blink_interval: float = 0.18
@export_group("Movement Audio")
@export var move_loop_fade_time: float = 0.15
@export var move_loop_playing_volume_db: float = -18.0
@export var move_loop_silent_volume_db: float = -45.0
@export var move_loop_min_speed: float = 8.0

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var facing_direction: int = 1
var is_throw_mode_locked: bool = false
var current_motion_direction: int = 0
var pending_animation: StringName = &""
var is_preturning: bool = false
var blink_timer: float = 0.0
var blink_show_empty: bool = false
var move_loop_tween: Tween
var move_loop_active: bool = false
var controls_frozen: bool = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var move_loop_player: AudioStreamPlayer2D = get_node_or_null("MoveLoopPlayer") as AudioStreamPlayer2D

func _ready() -> void:
	configure_looping_audio(move_loop_player)
	if animated_sprite:
		animated_sprite.animation_finished.connect(_on_animation_finished)
		update_sprite_animation(0.0, 0.0)

func _physics_process(delta: float) -> void:
	# 1. GRAVITASI
	if not is_on_floor():
		# Kita pake gravitasi yang agak berat (1.2x) biar feel jatuh robotnya dapet
		velocity.y += gravity * 1 * delta
	
	# Cap kecepatan jatuh
	velocity.y = min(velocity.y, terminal_velocity)

	if controls_frozen:
		velocity.x = 0.0
		move_and_slide()
		update_sprite_animation(delta, 0.0)
		update_move_loop_audio()
		return

	if is_gameplay_input_blocked():
		velocity.x = 0.0
		move_and_slide()
		update_sprite_animation(delta, 0.0)
		update_move_loop_audio()
		return

	if is_throw_mode_locked:
		velocity.x = 0.0
		move_and_slide()
		update_sprite_animation(delta, 0.0)
		update_move_loop_audio()
		return

	# 2. LOMPAT
	if Input.is_action_just_pressed("jump") and is_on_floor() and not GameplayInputGate.is_jump_suppressed():
		velocity.y = jump_velocity

	# 3. INPUT GERAK HORIZONTAL
	var direction = Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		facing_direction = -1 if direction < 0.0 else 1
	
	if direction:
		var target_speed = speed if is_on_floor() else air_speed
		velocity.x = direction * target_speed
	else:
		# --- PERBAIKAN AYUNAN DI SINI ---
		if is_on_floor():
			# Kalau di lantai, ngeremnya cepet (biar kontrol presisi)
			velocity.x = move_toward(velocity.x, 0, speed * 0.2)
		else:
			# Kalau di udara (lagi ngayun), ngeremnya super pelan (Air Drag)
			# Ini kunci biar ayunan pendulumnya kerasa luwes
			velocity.x = lerp(velocity.x, 0.0, air_friction * delta)

	# 4. EKSEKUSI
	# move_and_slide bakal pake velocity yang udah kita modif di RopeManager
	move_and_slide()
	var sprite = $AnimatedSprite2D 
	
	if is_on_floor():
		# Ambil arah kemiringan lantai tempat karakter berdiri
		var floor_normal = get_floor_normal()
		
		# Hitung target sudutnya (tambahin PI/2 alias 90 derajat biar posisinya tegak lurus sama lantai)
		var target_rotation = floor_normal.angle() + (PI / 2.0)
		
		# Putar gambarnya secara mulus (smooth) pake lerp_angle
		sprite.rotation = lerp_angle(sprite.rotation, target_rotation, 15.0 * delta)
	else:
		# Kalau karakter lagi loncat / di udara, balikin badannya lurus ke 0 derajat
		sprite.rotation = lerp_angle(sprite.rotation, 0.0, 15.0 * delta)
	
	update_sprite_animation(delta, direction)
	update_move_loop_audio()

func configure_looping_audio(player: AudioStreamPlayer2D) -> void:
	if player == null or player.stream == null:
		return

	var wav_stream := player.stream as AudioStreamWAV
	if wav_stream != null:
		wav_stream.loop_mode = 2

func update_move_loop_audio() -> void:
	if move_loop_player == null:
		return

	var should_play := is_on_floor() and absf(velocity.x) > move_loop_min_speed
	if should_play == move_loop_active:
		return

	move_loop_active = should_play
	if move_loop_tween != null:
		move_loop_tween.kill()

	move_loop_tween = create_tween()
	if should_play:
		if not move_loop_player.playing:
			move_loop_player.volume_db = move_loop_silent_volume_db
			move_loop_player.play()
		move_loop_tween.tween_property(
			move_loop_player,
			"volume_db",
			move_loop_playing_volume_db,
			move_loop_fade_time
		)
	else:
		move_loop_tween.tween_property(
			move_loop_player,
			"volume_db",
			move_loop_silent_volume_db,
			move_loop_fade_time
		)
		move_loop_tween.finished.connect(func() -> void:
			if not move_loop_active and move_loop_player != null:
				move_loop_player.stop()
		)

func set_throw_mode_locked(locked: bool) -> void:
	is_throw_mode_locked = locked

func set_controls_frozen(frozen: bool) -> void:
	controls_frozen = frozen
	set_meta("controls_frozen", frozen)
	if frozen:
		velocity.x = 0.0

func is_gameplay_input_blocked() -> bool:
	return get_tree().get_node_count_in_group("gameplay_input_blocker") > 0

func get_facing_direction() -> int:
	return facing_direction

func set_battery_state(new_battery_state: BatteryState) -> void:
	battery_state = new_battery_state
	is_preturning = false
	pending_animation = &""
	update_sprite_animation(0.0, current_motion_direction)

func set_low_battery_blink(enabled: bool) -> void:
	low_battery_blink = enabled
	blink_timer = 0.0
	blink_show_empty = false
	update_sprite_animation(0.0, current_motion_direction)

func update_sprite_animation(delta: float, input_direction: float) -> void:
	if not animated_sprite:
		return

	update_blink_state(delta)

	var motion_direction := 0
	if absf(input_direction) > 0.01:
		motion_direction = -1 if input_direction < 0.0 else 1
	elif absf(velocity.x) > 5.0:
		motion_direction = -1 if velocity.x < 0.0 else 1

	if motion_direction == 0:
		if is_preturning:
			return

		if current_motion_direction != 0:
			pending_animation = get_animation_name(&"idle", 0)
			is_preturning = true
			play_animation(get_animation_name(&"preturn", current_motion_direction))
			current_motion_direction = 0
			return

		pending_animation = &""
		play_animation(get_animation_name(&"idle", 0))
		return

	var walk_animation := get_animation_name(&"walk", motion_direction)

	if current_motion_direction != motion_direction:
		current_motion_direction = motion_direction
		pending_animation = walk_animation
		is_preturning = true
		play_animation(get_animation_name(&"preturn", motion_direction))
		return

	if is_preturning:
		return

	play_animation(walk_animation)

func update_blink_state(delta: float) -> void:
	if not low_battery_blink or battery_state != BatteryState.FIRST:
		blink_timer = 0.0
		blink_show_empty = false
		return

	blink_timer += delta
	if blink_timer >= low_battery_blink_interval:
		blink_timer = 0.0
		blink_show_empty = not blink_show_empty

func get_animation_name(action: StringName, direction: int) -> StringName:
	var battery_suffix := get_battery_suffix()
	if direction == 0:
		return StringName("%s_%s" % [action, battery_suffix])

	var side := "left" if direction < 0 else "right"
	return StringName("%s_%s_%s" % [action, side, battery_suffix])

func get_battery_suffix() -> String:
	if low_battery_blink and battery_state == BatteryState.FIRST and blink_show_empty:
		return "none"

	match battery_state:
		BatteryState.THIRD:
			return "third"
		BatteryState.SECOND:
			return "second"
		BatteryState.FIRST:
			return "first"
		BatteryState.NONE:
			return "none"
		_:
			return "full"

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
