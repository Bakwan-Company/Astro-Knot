extends Node2D

signal tether_broken(death_type: String)

@export_group("Actors")
@export var castor: CharacterBody2D
@export var pollux: RigidBody2D

@export_group("Connection")
@export var start_connected: bool = true

@export_group("Hardlight Visual")
@export_range(0.0, 1.0) var rope_glow_alpha: float = 0.22
@export_range(0.0, 1.0) var rope_core_brightness: float = 0.45
@export var rope_pulse_enabled: bool = true
@export_range(0, 8) var rope_pulse_count: int = 3
@export var rope_pulse_length: float = 32.0
@export var rope_pulse_speed: float = 0.9
@export var rope_pulse_width: float = 5.0
@export_range(0.0, 1.0) var rope_pulse_alpha: float = 0.72

@onready var rope_glow_visual: Line2D = get_node_or_null("HardlightGlow") as Line2D
@onready var rope_visual: Line2D = $HardlightVisual
@onready var rope_pulse_container: Node2D = get_node_or_null("HardlightPulses") as Node2D
@onready var aim_indicator: Line2D = $AimIndicator
@onready var power_meter_bg: Line2D = $PowerMeterBg
@onready var power_meter_fill: Line2D = $PowerMeterFill
@onready var debug_panel: Control = $DebugOverlay/Panel
@onready var debug_readout: Label = $DebugOverlay/Panel/DebugReadout
@onready var reel_loop_player: AudioStreamPlayer2D = get_node_or_null("ReelLoopPlayer") as AudioStreamPlayer2D
@onready var throw_audio_player: AudioStreamPlayer2D = get_node_or_null("ThrowAudioPlayer") as AudioStreamPlayer2D

@export_group("Rope Length")
@export var current_rope_length: float = 200.0
@export var reel_speed: float = 250.0
@export var min_rope_length: float = 60.0
@export var max_rope_length: float = 300.0

@export_group("Rope Power")
@export var power_limit_length: float = 540.0
@export_range(0.0, 1.0) var power_warning_ratio: float = 0.6
@export var power_break_grace_time: float = 0.15
@export var power_warning_color: Color = Color(1.0, 0.86, 0.3, 1.0)
@export var power_break_color: Color = Color(1.0, 0.24, 0.18, 1.0)

@export_group("Anchor Poses")
@export var lift_grounded_vertical_gap: float = 15.0
@export var lift_airborne_vertical_gap: float = 10.0
@export var lift_x_band: float = 40.0
@export var hanging_pollux_vertical_gap: float = 10.0

@export_group("Constraint")
@export var castor_anchor_position_correction_max: float = 3.0
@export var pollux_anchor_position_correction_max: float = 5.0
@export var free_position_correction_max: float = 3.0
@export var lift_castor_position_factor: float = 1.5
@export var lift_castor_velocity_factor: float = 2.0

@export_group("Pollux Ledge Pull")
@export var ledge_pull_up_velocity: float = 300.0
@export var ledge_pull_position_speed: float = 100.0
@export var ledge_pull_min_vertical_gap: float = 24.0
@export var ledge_pull_slack_tolerance: float = 10.0
@export var ledge_pull_horizontal_damp: float = 0.9

@export_group("Blocked Pollux")
@export var blocked_rope_error_threshold: float = 12.0
@export var blocked_castor_pull_factor: float = 0.35
@export var blocked_castor_pull_max: float = 6.0

@export_group("Castor Swing")
@export var castor_swing_pump_accel: float = 520.0
@export var castor_swing_max_speed: float = 360.0

@export_group("Robot Unstack")
@export var stacked_robot_push_speed: float = 420.0

@export_group("Debug")
@export var debug_enabled: bool = true

@export_group("Game Over")
@export var tether_break_death_type: String = "tether_break"
@export var game_over_scene: PackedScene = preload("res://ui/game_over/GameOverOverlay.tscn")

@export_group("Pollux Throw")
@export var throw_pickup_radius: float = 72.0
@export var throw_requires_line_of_sight: bool = true
@export var throw_ready_offset: Vector2 = Vector2(0.0, -34.0)
@export var throw_charge_time: float = 0.7
@export var min_throw_power: float = 320.0
@export var max_throw_power: float = 700.0
@export var throw_aim_rotate_speed_deg: float = 180.0
@export var throw_max_up_angle_deg: float = 75.0
@export var throw_max_down_angle_deg: float = 60.0
@export var throw_gamepad_aim_deadzone: float = 0.25
@export var throw_gravity_scale: float = 1.1
@export var throw_linear_damp: float = 0.1
@export var throw_flight_grace_time: float = 0.18
@export var throw_recovery_time: float = 0.28
@export var throw_cooldown: float = 0.2
@export var throw_wall_bounce_damp: float = 0.35
@export var throw_stop_speed_threshold: float = 40.0
@export var throw_max_bonus_slack: float = 120.0
@export var throw_auto_extend_limit: float = 220.0
@export var throw_aim_preview_length: float = 68.0
@export var throw_aim_dash_count: int = 5
@export var throw_aim_dash_gap_ratio: float = 0.34
@export var throw_aim_blink_speed: float = 5.0
@export var throw_aim_tip_dark_color: Color = Color(0.04, 0.42, 0.46, 1.0)
@export var throw_power_meter_width: float = 38.0
@export var throw_ready_color: Color = Color(1.0, 0.85, 0.26, 1.0)
@export var throw_flight_color: Color = Color(1.0, 0.48, 0.2, 1.0)
@export var throw_recovery_color: Color = Color(0.75, 0.88, 1.0, 1.0)
@export var throw_aim_color: Color = Color(1.0, 0.85, 0.26, 1.0)
@export var throw_power_meter_bg_color: Color = Color(0.137, 0.161, 0.176, 0.85)
@export var throw_power_meter_fill_color: Color = Color(1.0, 0.427, 0.114, 1.0)

@export_group("Rope Audio")
@export var reel_loop_fade_time: float = 0.12
@export var reel_loop_playing_volume_db: float = -16.0
@export var reel_loop_silent_volume_db: float = -45.0
@export var throw_audio_volume_db: float = -8.0

enum ThrowState {
	NORMAL,
	THROW_READY,
	THROW_CHARGING,
	THROW_FLIGHT,
	THROW_RECOVERY,
}

var throw_state: int = ThrowState.NORMAL
var throw_state_timer: float = 0.0
var throw_cooldown_timer: float = 0.0
var throw_charge_elapsed: float = 0.0
var throw_charge_ratio: float = 0.0
var throw_aim_dir: Vector2 = Vector2.RIGHT
var throw_aim_side: int = 1
var throw_aim_angle_deg: float = 0.0
var throw_last_horizontal_dir: int = 1
var throw_ready_wait_for_release: bool = false
var throw_collision_exception_active: bool = false
var throw_cached_pollux_position: Vector2 = Vector2.ZERO
var throw_cached_rope_length: float = 0.0
var rope_default_color: Color
var pollux_default_gravity_scale: float = 1.0
var pollux_default_linear_damp: float = 0.0
var debug_rope_distance: float = 0.0
var debug_rope_error: float = 0.0
var debug_castor_grounded: bool = false
var debug_pollux_grounded: bool = false
var debug_castor_anchored: bool = false
var debug_pollux_anchored: bool = false
var debug_pollux_side_blocked: bool = false
var debug_ledge_pulling: bool = false
var debug_grounded_pollux_y_lock: bool = false
var debug_constraint_state: String = "idle"
var power_limit_over_time: float = 0.0
var tether_is_broken: bool = false
var tether_connected: bool = true
var rope_pulse_lines: Array[Line2D] = []
var rope_pulse_phase: float = 0.0
var rope_segment_start: Vector2 = Vector2.ZERO
var rope_segment_end: Vector2 = Vector2.ZERO
var has_rope_segment: bool = false
var aim_dash_lines: Array[Line2D] = []
var throw_aim_blink_time: float = 0.0
var reel_loop_tween: Tween
var reel_loop_active: bool = false

func is_body_grounded(body: Node) -> bool:
	if not body:
		return false

	var character_body: CharacterBody2D = body as CharacterBody2D
	if character_body and character_body.is_on_floor():
		return true

	# Kalau body (Pollux) punya variabel is_grounded, baca nilainya!
	if "is_grounded" in body:
		return body.is_grounded

	var ground_left: RayCast2D = body.get_node_or_null("GroundCheckL") as RayCast2D
	var ground_right: RayCast2D = body.get_node_or_null("GroundCheckR") as RayCast2D
	return (ground_left and ground_left.is_colliding()) or (ground_right and ground_right.is_colliding())

func is_pollux_side_blocked() -> bool:
	var wall_left = pollux.get_node_or_null("WallCheckL") as RayCast2D
	var wall_right = pollux.get_node_or_null("WallCheckR") as RayCast2D
	for wall_check in [wall_left, wall_right]:
		if wall_check == null or not wall_check.is_colliding():
			continue

		var normal: Vector2 = wall_check.get_collision_normal()
		if absf(normal.x) > absf(normal.y) and normal.y > -0.5:
			return true

	return false

func configure_looping_audio(player: AudioStreamPlayer2D) -> void:
	if player == null or player.stream == null:
		return

	var wav_stream := player.stream as AudioStreamWAV
	if wav_stream != null:
		wav_stream.loop_mode = 2

func should_play_reel_loop_audio() -> bool:
	return tether_connected \
		and throw_state == ThrowState.NORMAL \
		and not is_gameplay_input_blocked() \
		and (Input.is_action_pressed("reel_in") or Input.is_action_pressed("reel_out"))

func update_rope_audio_position() -> void:
	if castor == null or pollux == null:
		return

	var audio_position := (castor.global_position + pollux.global_position) * 0.5
	if reel_loop_player != null:
		reel_loop_player.global_position = audio_position
	if throw_audio_player != null:
		throw_audio_player.global_position = audio_position

func update_reel_loop_audio(should_play: bool) -> void:
	if reel_loop_player == null:
		return

	if should_play == reel_loop_active:
		return

	reel_loop_active = should_play
	if reel_loop_tween != null:
		reel_loop_tween.kill()

	reel_loop_tween = create_tween()
	if should_play:
		if not reel_loop_player.playing:
			reel_loop_player.volume_db = reel_loop_silent_volume_db
			reel_loop_player.play()
		reel_loop_tween.tween_property(
			reel_loop_player,
			"volume_db",
			reel_loop_playing_volume_db,
			reel_loop_fade_time
		)
	else:
		reel_loop_tween.tween_property(
			reel_loop_player,
			"volume_db",
			reel_loop_silent_volume_db,
			reel_loop_fade_time
		)
		reel_loop_tween.finished.connect(func() -> void:
			if not reel_loop_active and reel_loop_player != null:
				reel_loop_player.stop()
		)

func play_throw_audio() -> void:
	if throw_audio_player == null:
		return

	update_rope_audio_position()
	throw_audio_player.volume_db = throw_audio_volume_db
	throw_audio_player.stop()
	throw_audio_player.play()

func _ready() -> void:
	rope_default_color = rope_visual.default_color
	pollux_default_gravity_scale = pollux.gravity_scale
	pollux_default_linear_damp = pollux.linear_damp
	configure_looping_audio(reel_loop_player)
	if throw_audio_player != null:
		throw_audio_player.volume_db = throw_audio_volume_db
	create_rope_pulse_lines()
	create_throw_aim_dashes()
	initialize_throw_aim_from_current()
	apply_throw_visual_colors()
	set_throw_state(ThrowState.NORMAL)
	set_tether_connected(start_connected)

func _process(delta: float) -> void:
	if not tether_connected:
		update_rope_visual()
		update_debug_readout()
		update_reel_loop_audio(false)
		return

	update_rope_pulse_phase(delta)
	update_rope_visual()
	update_throw_visuals()
	update_power_rope_visual()
	update_debug_readout()
	update_rope_audio_position()
	update_reel_loop_audio(should_play_reel_loop_audio())

func _physics_process(delta: float) -> void:
	if not tether_connected or tether_is_broken or not castor or not pollux:
		return

	if are_controls_frozen() or is_gameplay_input_blocked():
		update_reel_loop_audio(false)
		update_rope_debug_snapshot()
		return

	throw_cooldown_timer = max(throw_cooldown_timer - delta, 0.0)
	throw_state_timer += delta

	handle_throw_state(delta)

	if throw_state in [ThrowState.THROW_READY, ThrowState.THROW_CHARGING]:
		sync_pollux_to_throw_anchor()
		debug_constraint_state = "throw_hold"
		debug_ledge_pulling = false
		debug_grounded_pollux_y_lock = false
		update_rope_debug_snapshot()
		update_power_limit(delta)
		return

	if throw_state == ThrowState.NORMAL:
		handle_reel_input(delta)
		unstick_stacked_robots(delta)

	apply_solid_constraint(delta)
	update_rope_debug_snapshot()
	update_power_limit(delta)

func are_controls_frozen() -> bool:
	return castor.get_meta("controls_frozen", false) or pollux.get_meta("controls_frozen", false)

func is_gameplay_input_blocked() -> bool:
	return get_tree().get_node_count_in_group("gameplay_input_blocker") > 0

func set_tether_connected(value: bool) -> void:
	tether_connected = value
	visible = value

	if rope_visual != null:
		rope_visual.visible = value
		if not value:
			clear_rope_visual_points()
	if rope_glow_visual != null:
		rope_glow_visual.visible = value
	set_rope_pulses_visible(value and rope_pulse_enabled)

	if aim_indicator != null:
		aim_indicator.visible = false
	set_throw_aim_dashes_visible(false)
	if power_meter_bg != null:
		power_meter_bg.visible = false
	if power_meter_fill != null:
		power_meter_fill.visible = false

	if pollux != null:
		pollux.freeze = not value
		pollux.sleeping = not value
		pollux.modulate = Color.WHITE if value else Color(0.48, 0.48, 0.48, 1.0)

	if value:
		tether_is_broken = false
		power_limit_over_time = 0.0
		debug_constraint_state = "idle"
	else:
		debug_constraint_state = "disconnected"

func is_tether_connected() -> bool:
	return tether_connected

func apply_pollux_ledge_pull(delta: float, error: float, is_p_grounded: bool) -> bool:
	# Small assist for the specific case where Pollux is airborne, side-blocked,
	# and the player is still reeling the rope inward.
	if throw_state != ThrowState.NORMAL:
		return false

	if not Input.is_action_pressed("reel_in"):
		return false

	if is_p_grounded:
		return false

	if error < -ledge_pull_slack_tolerance:
		return false

	if not is_pollux_side_blocked():
		return false

	var vertical_gap = pollux.global_position.y - castor.global_position.y
	if vertical_gap < ledge_pull_min_vertical_gap:
		return false

	pollux.linear_velocity.y = min(pollux.linear_velocity.y, -ledge_pull_up_velocity)
	pollux.global_position.y -= ledge_pull_position_speed * delta
	return true

func unstick_stacked_robots(delta: float) -> void:
	if not castor or not pollux:
		return

	if not is_pollux_blocking_castor_head():
		return

	var input_dir := Input.get_axis("move_left", "move_right")
	if absf(input_dir) <= 0.001:
		return

	var castor_collision := get_body_collision_shape(castor)
	var pollux_collision := get_body_collision_shape(pollux)
	if castor_collision == null or pollux_collision == null:
		return

	var castor_half := get_collision_half_extents(castor_collision)
	var pollux_half := get_collision_half_extents(pollux_collision)
	var desired_gap := castor_half.x + pollux_half.x + 4.0
	var current_gap := absf(pollux_collision.global_position.x - castor_collision.global_position.x)
	var missing_gap = maxf(desired_gap - current_gap, 0.0)
	if missing_gap <= 0.0:
		return

	var push_dir := -signf(input_dir)
	var push_amount = minf(maxf(stacked_robot_push_speed * delta, missing_gap * 0.35), missing_gap)
	pollux.global_position.x += push_dir * push_amount
	pollux.linear_velocity.x = stacked_robot_push_speed * 0.45 * push_dir

func is_pollux_blocking_castor_head() -> bool:
	var castor_collision := get_body_collision_shape(castor)
	var pollux_collision := get_body_collision_shape(pollux)
	if castor_collision == null or pollux_collision == null:
		return false

	if castor_collision.global_position.y <= pollux_collision.global_position.y:
		return false

	var castor_half := get_collision_half_extents(castor_collision)
	var pollux_half := get_collision_half_extents(pollux_collision)
	var ray_length := castor_half.y + pollux_half.y + 4.0
	var sample_width := maxf(castor_half.x * 0.7, 1.0)
	var space_state := get_world_2d().direct_space_state

	for side in [-1.0, 0.0, 1.0]:
		var from := Vector2(
			castor_collision.global_position.x + sample_width * side,
			castor_collision.global_position.y - castor_half.y + 1.0
		)
		var to := from + Vector2.UP * ray_length
		var query := PhysicsRayQueryParameters2D.create(from, to)
		query.exclude = [castor.get_rid()]
		var result := space_state.intersect_ray(query)
		if not result.is_empty() and result.get("collider") == pollux:
			return true

	return false

func get_body_collision_shape(body: Node) -> CollisionShape2D:
	if body == null:
		return null
	return body.get_node_or_null("CollisionShape2D") as CollisionShape2D

func get_collision_half_extents(collision: CollisionShape2D) -> Vector2:
	if collision == null or collision.shape == null:
		return Vector2(20.0, 20.0)

	var rectangle := collision.shape as RectangleShape2D
	if rectangle != null:
		return rectangle.size * 0.5

	var circle := collision.shape as CircleShape2D
	if circle != null:
		return Vector2.ONE * circle.radius

	var capsule := collision.shape as CapsuleShape2D
	if capsule != null:
		return Vector2(capsule.radius, capsule.height * 0.5)

	return Vector2(20.0, 20.0)

func get_anchor_flags(
	c_pos: Vector2,
	p_pos: Vector2,
	is_c_grounded: bool,
	is_p_grounded: bool
) -> Dictionary:
	var flags := {
		"is_castor_anchored": false,
		"is_pollux_anchored": false,
	}

	if is_c_grounded and is_p_grounded:
		# When both are grounded, Castor takes anchor priority so Pollux is the body
		# that gets dragged around by player input.
		flags.is_castor_anchored = true

		# Lift mode: Castor is directly above Pollux on the same X band.
		if c_pos.y < p_pos.y - lift_grounded_vertical_gap and abs(c_pos.x - p_pos.x) < lift_x_band:
			flags.is_pollux_anchored = true

	elif is_c_grounded and not is_p_grounded:
		# Castor can anchor Pollux when Pollux is hanging below it.
		if p_pos.y > c_pos.y + hanging_pollux_vertical_gap:
			flags.is_castor_anchored = true

	elif not is_c_grounded and is_p_grounded:
		# Keep Pollux as lift support only when Castor is above it. Castor
		# passing below grounded Pollux should stay under normal air control.
		if Input.is_action_pressed("reel_out") \
		and c_pos.y < p_pos.y - lift_airborne_vertical_gap \
		and abs(c_pos.x - p_pos.x) < lift_x_band:
			flags.is_pollux_anchored = true

	return flags

func apply_blocked_pollux_fallback(dir: Vector2, error: float, delta: float) -> void:
	# Pollux is still the body we try to drag manually. If it is side-blocked and
	# the rope keeps overstretching, gently pull Castor back so the rope does not
	# visually stretch forever.
	if not is_pollux_side_blocked():
		return

	if error <= blocked_rope_error_threshold:
		return

	var castor_away_speed = min(castor.velocity.dot(dir), 0.0)
	var castor_correction = min(
		error * blocked_castor_pull_factor + abs(castor_away_speed) * delta,
		blocked_castor_pull_max
	)
	castor.global_position += dir * castor_correction

	# Remove the velocity component that keeps pushing Castor away from Pollux.
	if castor_away_speed < 0.0:
		castor.velocity -= dir * castor_away_speed

func apply_castor_anchor_constraint(
	dir: Vector2,
	error: float,
	is_pollux_anchored: bool,
	is_pollux_grounded: bool,
	delta: float,
	allow_blocked_fallback: bool = true
) -> void:
	# error > 0 means the rope is longer than allowed, so we must correct it.
	# In this branch, Castor is the anchor and Pollux is the body we try to drag.
	var pos_correction = clamp(
		error,
		-castor_anchor_position_correction_max,
		castor_anchor_position_correction_max
	)
	var move_pollux = -(dir * pos_correction)
	var lock_grounded_pollux_y: bool = (
		is_pollux_grounded
		and not is_pollux_anchored
		and throw_state == ThrowState.NORMAL
		and not Input.is_action_pressed("reel_in")
	)

	if is_pollux_anchored and move_pollux.y > 0:
		# In lift mode we suppress Pollux's X/Y drift and instead push Castor upward
		# a bit to sell the idea that Pollux is helping lift Castor.
		castor.global_position.y -= move_pollux.y * lift_castor_position_factor
		move_pollux.y = 0
		move_pollux.x = 0

	if lock_grounded_pollux_y and move_pollux.y < 0.0:
		move_pollux.y = 0.0
		debug_grounded_pollux_y_lock = true

	pollux.global_position += move_pollux
	if allow_blocked_fallback:
		apply_blocked_pollux_fallback(dir, error, delta)

	var c_vel = castor.velocity
	var p_vel = pollux.linear_velocity
	var rel_vel = (p_vel - c_vel).dot(dir)
	var vel_lambda = dir * (-rel_vel)

	var apply_vel = vel_lambda
	if is_pollux_anchored and apply_vel.y > 0:
		castor.velocity.y -= apply_vel.y * lift_castor_velocity_factor
		apply_vel.y = 0
		apply_vel.x = 0

	if lock_grounded_pollux_y and apply_vel.y < 0.0:
		apply_vel.y = 0.0
		debug_grounded_pollux_y_lock = true

	pollux.linear_velocity += apply_vel

func apply_pollux_anchor_constraint(dir: Vector2, error: float, delta: float) -> void:
	# Pollux anchored means Castor becomes the pendulum body.
	var pos_correction = clamp(
		error,
		-pollux_anchor_position_correction_max,
		pollux_anchor_position_correction_max
	)
	castor.global_position += dir * pos_correction
	
	# Recompute the rope direction after the position correction.
	dir = castor.global_position.direction_to(pollux.global_position)
	var tangent = dir.orthogonal().normalized()
	var swing_speed = castor.velocity.dot(tangent)
	var input_dir := Input.get_axis("move_left", "move_right")
	var tangent_input = Vector2(input_dir, 0.0).dot(tangent)

	swing_speed += tangent_input * castor_swing_pump_accel * delta
	swing_speed = clamp(swing_speed, -castor_swing_max_speed, castor_swing_max_speed)

	castor.velocity = tangent * swing_speed

func apply_free_constraint(dir: Vector2, error: float) -> void:
	# Both bodies are effectively free, so share the correction 50:50.
	var pos_correction = clamp(error, -free_position_correction_max, free_position_correction_max)
	castor.global_position += dir * (pos_correction * 0.5)
	pollux.global_position -= dir * (pos_correction * 0.5)

	var c_vel = castor.velocity
	var p_vel = pollux.linear_velocity
	var rel_vel = (p_vel - c_vel).dot(dir)
	var vel_lambda = dir * (-rel_vel)

	castor.velocity -= vel_lambda * 0.5
	pollux.linear_velocity += vel_lambda * 0.5

func handle_reel_input(delta: float) -> void:
	if Input.is_action_pressed("reel_in"):
		current_rope_length -= reel_speed * delta
	elif Input.is_action_pressed("reel_out"):
		current_rope_length += reel_speed * delta

	current_rope_length = clamp(current_rope_length, min_rope_length, max_rope_length)

func apply_solid_constraint(delta: float) -> void:
	var c_pos = castor.global_position
	var p_pos = pollux.global_position
	var dist = c_pos.distance_to(p_pos)
	debug_constraint_state = "idle"
	debug_ledge_pulling = false
	debug_grounded_pollux_y_lock = false

	if dist < 0.1:
		debug_constraint_state = "overlap"
		return

	if throw_state == ThrowState.THROW_FLIGHT and is_pollux_moving_away_from_castor():
		current_rope_length = min(
			max(current_rope_length, dist),
			get_throw_auto_extend_cap()
		)

	var effective_rope_length = current_rope_length

	# error > 0: rope is overstretched and must be corrected
	# error < 0: rope is slack, so we usually let it be
	var error = dist - effective_rope_length
	if error < 0 and not (throw_state == ThrowState.NORMAL and Input.is_action_pressed("reel_out")):
		debug_constraint_state = "slack"
		return

	var dir = c_pos.direction_to(p_pos)

	if throw_state == ThrowState.THROW_FLIGHT:
		debug_constraint_state = "throw_flight"
		apply_throw_flight_constraint(dir, error)
		return

	if throw_state == ThrowState.THROW_RECOVERY and throw_state_timer < throw_recovery_time * 0.5:
		debug_constraint_state = "throw_recovery"
		apply_free_constraint(dir, error)
		return

	var is_c_grounded = is_body_grounded(castor)
	var is_p_grounded = is_body_grounded(pollux)
	var is_ledge_pulling = apply_pollux_ledge_pull(delta, error, is_p_grounded)
	var anchor_flags = get_anchor_flags(c_pos, p_pos, is_c_grounded, is_p_grounded)
	var is_castor_anchored: bool = bool(anchor_flags.get("is_castor_anchored", false))
	var is_pollux_anchored: bool = bool(anchor_flags.get("is_pollux_anchored", false))
	debug_ledge_pulling = is_ledge_pulling

	if is_ledge_pulling:
		pollux.linear_velocity.x *= ledge_pull_horizontal_damp

	if is_ledge_pulling:
		debug_constraint_state = "ledge_haul"
		apply_castor_anchor_constraint(dir, error, false, is_p_grounded, delta, false)
	elif is_castor_anchored:
		debug_constraint_state = "castor_anchor"
		apply_castor_anchor_constraint(dir, error, is_pollux_anchored, is_p_grounded, delta)
	elif is_pollux_anchored:
		debug_constraint_state = "pollux_anchor"
		apply_pollux_anchor_constraint(dir, error, delta)
	else:
		debug_constraint_state = "free"
		apply_free_constraint(dir, error)

func update_rope_visual() -> void:
	if not tether_connected:
		clear_rope_visual_points()
		return

	if castor and pollux and rope_visual:
		var c_anchor = castor.get_node_or_null("RopeAnchor")
		var p_anchor = pollux.get_node_or_null("RopeAnchor")
		var start_pos: Vector2 = c_anchor.global_position if c_anchor else castor.global_position
		var end_pos: Vector2 = p_anchor.global_position if p_anchor else pollux.global_position
		set_rope_visual_points(start_pos, end_pos)

func update_rope_debug_snapshot() -> void:
	if not castor or not pollux:
		return

	debug_rope_distance = castor.global_position.distance_to(pollux.global_position)
	debug_rope_error = debug_rope_distance - current_rope_length
	debug_castor_grounded = is_body_grounded(castor)
	debug_pollux_grounded = is_body_grounded(pollux)
	debug_pollux_side_blocked = is_pollux_side_blocked()

	var anchor_flags: Dictionary = get_anchor_flags(
		castor.global_position,
		pollux.global_position,
		debug_castor_grounded,
		debug_pollux_grounded
	)
	debug_castor_anchored = bool(anchor_flags.get("is_castor_anchored", false))
	debug_pollux_anchored = bool(anchor_flags.get("is_pollux_anchored", false))

func update_power_limit(delta: float) -> void:
	if tether_is_broken:
		return

	if debug_rope_distance <= power_limit_length:
		power_limit_over_time = 0.0
		return

	power_limit_over_time += delta
	if power_limit_over_time >= power_break_grace_time:
		trigger_game_over(tether_break_death_type)

func update_power_rope_visual() -> void:
	if not rope_visual:
		return

	var base_color: Color = get_throw_rope_color()
	var warning_start_length: float = power_limit_length * power_warning_ratio
	if power_limit_length <= 0.0 or debug_rope_distance <= warning_start_length:
		set_rope_visual_color(base_color)
		return

	var warning_span: float = maxf(power_limit_length - warning_start_length, 0.001)
	var warning_amount: float = clampf(
		(debug_rope_distance - warning_start_length) / warning_span,
		0.0,
		1.0
	)
	set_rope_visual_color(base_color.lerp(power_warning_color, warning_amount))

	if debug_rope_distance > power_limit_length:
		set_rope_visual_color(power_break_color)

func trigger_game_over(death_type: String) -> void:
	if tether_is_broken:
		return

	tether_is_broken = true
	debug_constraint_state = "tether_broken"
	set_rope_visual_color(power_break_color)
	tether_broken.emit(death_type)

	var checkpoint_manager := get_node_or_null("/root/CheckpointManager")
	if checkpoint_manager != null and checkpoint_manager.has_method("kill_with_overlay"):
		checkpoint_manager.call("kill_with_overlay", death_type, game_over_scene)
		return

	if not game_over_scene:
		get_tree().call_deferred("reload_current_scene")
		return

	var overlay: Node = game_over_scene.instantiate()
	var overlay_parent: Node = self
	if get_tree().current_scene:
		overlay_parent = get_tree().current_scene

	overlay_parent.add_child(overlay)
	if overlay.has_method("show_death"):
		overlay.call("show_death", death_type)

	get_tree().paused = true

func get_power_state_name() -> String:
	if tether_is_broken:
		return "broken"

	if debug_rope_distance > power_limit_length:
		return "over"

	if debug_rope_distance > power_limit_length * power_warning_ratio:
		return "warn"

	return "ok"

func update_debug_readout() -> void:
	if not debug_panel or not debug_readout:
		return

	debug_panel.visible = debug_enabled
	if not debug_enabled:
		return

	debug_readout.text = "\n".join([
		"len %.1f dst %.1f" % [current_rope_length, debug_rope_distance],
		"err %.1f limit %.1f %s %.2f" % [
			debug_rope_error,
			power_limit_length,
			get_power_state_name(),
			power_limit_over_time,
		],
		"gnd C:%s P:%s anc C:%s P:%s" % [
			debug_castor_grounded,
			debug_pollux_grounded,
			debug_castor_anchored,
			debug_pollux_anchored,
		],
		"state %s throw %s" % [debug_constraint_state, get_throw_state_name()],
		"ledge %s block %s ylock %s" % [
			debug_ledge_pulling,
			debug_pollux_side_blocked,
			debug_grounded_pollux_y_lock,
		],
		get_checkpoint_debug_text(),
	])

func get_checkpoint_debug_text() -> String:
	var checkpoint_manager := get_node_or_null("/root/CheckpointManager")
	if checkpoint_manager == null or not checkpoint_manager.has_method("get_debug_summary"):
		return "cp manager missing"
	return str(checkpoint_manager.call("get_debug_summary"))

func handle_throw_state(delta: float) -> void:
	match throw_state:
		ThrowState.NORMAL:
			if Input.is_action_just_pressed("throw_pollux") and can_enter_throw_mode():
				begin_throw_mode()
		ThrowState.THROW_READY:
			if should_cancel_throw_mode():
				cancel_throw_mode()
				return
			update_throw_aim_direction(delta)
			if Input.is_action_just_pressed("throw_pollux"):
				cancel_throw_mode()
				return
			if throw_ready_wait_for_release:
				if not is_jump_pressed_for_gameplay():
					throw_ready_wait_for_release = false
				return
			if Input.is_action_just_pressed("jump") and not GameplayInputGate.is_jump_suppressed():
				set_throw_state(ThrowState.THROW_CHARGING)
				throw_charge_elapsed = 0.0
				throw_charge_ratio = 0.0
		ThrowState.THROW_CHARGING:
			if should_cancel_throw_mode():
				cancel_throw_mode()
				return
			update_throw_aim_direction(delta)
			if Input.is_action_just_pressed("throw_pollux"):
				cancel_throw_mode()
				return
			if is_jump_pressed_for_gameplay():
				throw_charge_elapsed = min(throw_charge_elapsed + delta, throw_charge_time)
				throw_charge_ratio = get_throw_charge_ratio()
			if Input.is_action_just_released("jump"):
				release_throw()
		ThrowState.THROW_FLIGHT:
			handle_throw_flight(delta)
		ThrowState.THROW_RECOVERY:
			if throw_state_timer >= throw_recovery_time:
				set_throw_state(ThrowState.NORMAL)

func can_enter_throw_mode() -> bool:
	if throw_cooldown_timer > 0.0:
		return false

	if not is_body_grounded(castor) or not is_body_grounded(pollux):
		return false

	if Input.is_action_pressed("reel_in") or Input.is_action_pressed("reel_out"):
		return false

	if castor.global_position.distance_to(pollux.global_position) > throw_pickup_radius:
		return false

	if throw_requires_line_of_sight and not has_throw_line_of_sight():
		return false

	return true

func has_throw_line_of_sight() -> bool:
	var c_anchor = castor.get_node_or_null("RopeAnchor") as Marker2D
	var p_anchor = pollux.get_node_or_null("RopeAnchor") as Marker2D
	var from_pos = c_anchor.global_position if c_anchor else castor.global_position
	var to_pos = p_anchor.global_position if p_anchor else pollux.global_position
	var query = PhysicsRayQueryParameters2D.create(from_pos, to_pos)
	query.exclude = [castor.get_rid(), pollux.get_rid()]
	query.collision_mask = 1
	var result = get_world_2d().direct_space_state.intersect_ray(query)
	return result.is_empty()

func begin_throw_mode() -> void:
	throw_cached_pollux_position = pollux.global_position
	throw_cached_rope_length = current_rope_length
	throw_charge_elapsed = 0.0
	throw_charge_ratio = 0.0
	throw_ready_wait_for_release = is_jump_pressed_for_gameplay()
	initialize_throw_aim_from_current()
	set_throw_state(ThrowState.THROW_READY)
	sync_pollux_to_throw_anchor()

func cancel_throw_mode() -> void:
	pollux.freeze = false
	pollux.global_position = throw_cached_pollux_position
	pollux.linear_velocity = Vector2.ZERO
	current_rope_length = clamp(throw_cached_rope_length, min_rope_length, max_rope_length)
	throw_cooldown_timer = max(throw_cooldown_timer, throw_cooldown * 0.5)
	set_throw_state(ThrowState.NORMAL)

func should_cancel_throw_mode() -> bool:
	if not is_body_grounded(castor):
		return true

	return false

func sync_pollux_to_throw_anchor() -> void:
	var ready_pos = get_throw_ready_position()
	pollux.freeze = true
	pollux.sleeping = false
	pollux.linear_velocity = Vector2.ZERO
	pollux.global_position = ready_pos

func get_throw_ready_anchor_position() -> Vector2:
	var castor_rope_anchor = castor.get_node_or_null("RopeAnchor") as Marker2D
	var base_anchor_global = castor_rope_anchor.global_position if castor_rope_anchor else castor.global_position
	return base_anchor_global + throw_ready_offset

func get_throw_ready_position() -> Vector2:
	var pollux_anchor = pollux.get_node_or_null("RopeAnchor") as Marker2D
	var pollux_anchor_offset = pollux_anchor.position if pollux_anchor else Vector2.ZERO
	return get_throw_ready_anchor_position() - pollux_anchor_offset

func update_throw_aim_direction(_delta: float) -> void:
	var aim_vector := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down", throw_gamepad_aim_deadzone)
	if aim_vector.length() >= throw_gamepad_aim_deadzone:
		set_throw_aim_from_vector(aim_vector)
		return

	var horizontal_input = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")

	if abs(horizontal_input) > 0.001:
		throw_aim_angle_deg += horizontal_input * throw_aim_rotate_speed_deg * _delta
		throw_aim_angle_deg = clamp(throw_aim_angle_deg, -180.0, 0.0)

	rebuild_throw_aim_dir()

func is_jump_pressed_for_gameplay() -> bool:
	return Input.is_action_pressed("jump") and not GameplayInputGate.is_jump_suppressed()

func set_throw_aim_from_vector(aim_vector: Vector2) -> void:
	if aim_vector.length() <= 0.001:
		return

	var side := -1 if aim_vector.x < -0.001 else 1
	if abs(aim_vector.x) <= 0.001:
		side = get_throw_ready_facing()

	var local_vector := Vector2(abs(aim_vector.x), aim_vector.y).normalized()
	var local_angle_deg := rad_to_deg(local_vector.angle())
	local_angle_deg = clamp(local_angle_deg, -throw_max_up_angle_deg, throw_max_down_angle_deg)

	var local_angle_rad := deg_to_rad(local_angle_deg)
	throw_aim_side = side
	throw_aim_dir = Vector2(cos(local_angle_rad) * float(side), sin(local_angle_rad)).normalized()
	throw_aim_angle_deg = rad_to_deg(throw_aim_dir.angle())

func release_throw() -> void:
	var throw_power = lerp(min_throw_power, max_throw_power, get_throw_charge_ratio())
	update_reel_loop_audio(false)
	play_throw_audio()
	pollux.freeze = false
	pollux.sleeping = false
	pollux.linear_velocity = throw_aim_dir * throw_power
	current_rope_length = max(current_rope_length, throw_cached_rope_length)
	throw_cooldown_timer = max(throw_cooldown_timer, throw_cooldown)
	set_throw_state(ThrowState.THROW_FLIGHT)

func handle_throw_flight(delta: float) -> void:
	dampen_throw_wall_hits()

	if throw_state_timer < throw_flight_grace_time:
		return

	if current_rope_length >= get_throw_auto_extend_cap() and is_pollux_moving_away_from_castor():
		begin_throw_recovery()
		return

	if not is_pollux_moving_away_from_castor():
		begin_throw_recovery()
		return

	if is_body_grounded(pollux) and pollux.linear_velocity.length() <= throw_stop_speed_threshold:
		begin_throw_recovery()
		return

	if is_body_grounded(pollux) and throw_state_timer >= throw_flight_grace_time + 0.2:
		begin_throw_recovery()
		return

	if not is_body_grounded(castor):
		begin_throw_recovery()

func dampen_throw_wall_hits() -> void:
	var wall_left = pollux.get_node_or_null("WallCheckL") as RayCast2D
	var wall_right = pollux.get_node_or_null("WallCheckR") as RayCast2D
	if wall_left and wall_left.is_colliding() and pollux.linear_velocity.x < 0.0:
		pollux.linear_velocity.x *= -throw_wall_bounce_damp
		pollux.linear_velocity.y *= 0.92
	if wall_right and wall_right.is_colliding() and pollux.linear_velocity.x > 0.0:
		pollux.linear_velocity.x *= -throw_wall_bounce_damp
		pollux.linear_velocity.y *= 0.92

func begin_throw_recovery() -> void:
	set_throw_state(ThrowState.THROW_RECOVERY)

func get_throw_auto_extend_cap() -> float:
	return throw_cached_rope_length + max(throw_auto_extend_limit, 0.0)

func get_pollux_throw_radial_speed() -> float:
	var dir = castor.global_position.direction_to(pollux.global_position)
	var relative_velocity = pollux.linear_velocity - castor.velocity
	return relative_velocity.dot(dir)

func is_pollux_moving_away_from_castor() -> bool:
	return get_pollux_throw_radial_speed() > 5.0

func apply_throw_flight_constraint(dir: Vector2, error: float) -> void:
	var soft_error = max(error, 0.0) * 0.35
	if soft_error <= 0.0:
		return

	var pos_correction = clamp(soft_error, 0.0, 2.0)
	castor.global_position += dir * (pos_correction * 0.2)
	pollux.global_position -= dir * (pos_correction * 0.8)

	var c_vel = castor.velocity
	var p_vel = pollux.linear_velocity
	var rel_vel = (p_vel - c_vel).dot(dir)
	var vel_lambda = dir * (-rel_vel * 0.35)
	castor.velocity -= vel_lambda * 0.15
	pollux.linear_velocity += vel_lambda * 0.85

func get_throw_charge_ratio() -> float:
	if throw_charge_time <= 0.0:
		return 1.0
	return clamp(throw_charge_elapsed / throw_charge_time, 0.0, 1.0)

func get_castor_facing() -> int:
	if castor.has_method("get_facing_direction"):
		return castor.get_facing_direction()
	return 1

func get_throw_ready_facing() -> int:
	return throw_aim_side if throw_aim_side != 0 else get_castor_facing()

func initialize_throw_aim_from_current() -> void:
	var base_dir = throw_aim_dir
	if base_dir.length() <= 0.001:
		base_dir = Vector2(float(get_castor_facing()), 0.0)

	throw_aim_angle_deg = -90.0
	rebuild_throw_aim_dir()

func rebuild_throw_aim_dir() -> void:
	var angle_radians = deg_to_rad(throw_aim_angle_deg)
	throw_aim_dir = Vector2(cos(angle_radians), sin(angle_radians))
	if throw_aim_dir.length() <= 0.001:
		throw_aim_dir = Vector2.RIGHT
	else:
		throw_aim_dir = throw_aim_dir.normalized()

func set_throw_collision_exception(active: bool) -> void:
	if throw_collision_exception_active == active:
		return

	throw_collision_exception_active = active

	if not castor or not pollux:
		return

	if active:
		castor.add_collision_exception_with(pollux)
		pollux.add_collision_exception_with(castor)
	else:
		castor.remove_collision_exception_with(pollux)
		pollux.remove_collision_exception_with(castor)

func set_pollux_throw_physics(active: bool) -> void:
	if not pollux:
		return

	if active:
		pollux.gravity_scale = throw_gravity_scale
		pollux.linear_damp = throw_linear_damp
	else:
		pollux.gravity_scale = pollux_default_gravity_scale
		pollux.linear_damp = pollux_default_linear_damp

func set_throw_state(new_state: int) -> void:
	throw_state = new_state
	throw_state_timer = 0.0

	var is_locking_castor = throw_state in [ThrowState.THROW_READY, ThrowState.THROW_CHARGING]
	if castor.has_method("set_throw_mode_locked"):
		castor.set_throw_mode_locked(is_locking_castor)

	set_throw_collision_exception(throw_state != ThrowState.NORMAL)
	set_pollux_throw_physics(throw_state == ThrowState.THROW_FLIGHT)

	if pollux:
		pollux.set_meta("throw_mode_active", throw_state in [ThrowState.THROW_READY, ThrowState.THROW_CHARGING, ThrowState.THROW_FLIGHT])

	match throw_state:
		ThrowState.NORMAL:
			throw_charge_elapsed = 0.0
			throw_charge_ratio = 0.0
			throw_ready_wait_for_release = false

	set_rope_visual_color(get_throw_rope_color())

func get_throw_state_name() -> String:
	match throw_state:
		ThrowState.THROW_READY:
			return "ready"
		ThrowState.THROW_CHARGING:
			return "charge"
		ThrowState.THROW_FLIGHT:
			return "flight"
		ThrowState.THROW_RECOVERY:
			return "recover"
		_:
			return "normal"

func get_throw_rope_color() -> Color:
	match throw_state:
		ThrowState.THROW_READY, ThrowState.THROW_CHARGING:
			return throw_ready_color
		ThrowState.THROW_FLIGHT:
			return throw_flight_color
		ThrowState.THROW_RECOVERY:
			return throw_recovery_color
		_:
			return rope_default_color

func set_rope_visual_points(start_pos: Vector2, end_pos: Vector2) -> void:
	rope_segment_start = start_pos
	rope_segment_end = end_pos
	has_rope_segment = true

	if rope_visual != null:
		rope_visual.clear_points()
		rope_visual.add_point(start_pos)
		rope_visual.add_point(end_pos)

	if rope_glow_visual != null:
		rope_glow_visual.clear_points()
		rope_glow_visual.add_point(start_pos)
		rope_glow_visual.add_point(end_pos)

	update_rope_pulse_points()

func clear_rope_visual_points() -> void:
	has_rope_segment = false
	if rope_visual != null:
		rope_visual.clear_points()
	if rope_glow_visual != null:
		rope_glow_visual.clear_points()
	for pulse_line in rope_pulse_lines:
		pulse_line.clear_points()

func set_rope_visual_color(core_color: Color) -> void:
	if rope_visual != null:
		rope_visual.default_color = core_color.lerp(Color.WHITE, rope_core_brightness)

	if rope_glow_visual != null:
		var glow_color := core_color
		glow_color.a = rope_glow_alpha
		rope_glow_visual.default_color = glow_color

	for pulse_line in rope_pulse_lines:
		var pulse_color := core_color.lerp(Color.WHITE, 0.65)
		pulse_color.a = rope_pulse_alpha
		pulse_line.default_color = pulse_color

func create_rope_pulse_lines() -> void:
	rope_pulse_lines.clear()
	if rope_pulse_container == null:
		return

	for child in rope_pulse_container.get_children():
		child.queue_free()

	for index in range(rope_pulse_count):
		var pulse_line := Line2D.new()
		pulse_line.name = "Pulse%s" % index
		pulse_line.width = rope_pulse_width
		pulse_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		pulse_line.end_cap_mode = Line2D.LINE_CAP_ROUND
		pulse_line.joint_mode = Line2D.LINE_JOINT_ROUND
		rope_pulse_container.add_child(pulse_line)
		rope_pulse_lines.append(pulse_line)

func update_rope_pulse_phase(delta: float) -> void:
	if not rope_pulse_enabled:
		return

	rope_pulse_phase = fmod(rope_pulse_phase + delta * rope_pulse_speed, 1.0)

func update_rope_pulse_points() -> void:
	if not rope_pulse_enabled or not has_rope_segment:
		set_rope_pulses_visible(false)
		return

	set_rope_pulses_visible(tether_connected)

	var rope_vector := rope_segment_end - rope_segment_start
	var rope_length := rope_vector.length()
	if rope_length <= 0.001:
		for pulse_line in rope_pulse_lines:
			pulse_line.clear_points()
		return

	var direction := rope_vector / rope_length
	var segment_ratio := clampf(rope_pulse_length / rope_length, 0.02, 0.24)

	for index in range(rope_pulse_lines.size()):
		var pulse_line := rope_pulse_lines[index]
		var center_t := fmod(rope_pulse_phase + float(index) / max(rope_pulse_lines.size(), 1), 1.0)
		var start_t := clampf(center_t - segment_ratio * 0.5, 0.0, 1.0)
		var end_t := clampf(center_t + segment_ratio * 0.5, 0.0, 1.0)
		pulse_line.clear_points()
		pulse_line.add_point(rope_segment_start + direction * rope_length * start_t)
		pulse_line.add_point(rope_segment_start + direction * rope_length * end_t)

func set_rope_pulses_visible(value: bool) -> void:
	if rope_pulse_container != null:
		rope_pulse_container.visible = value
	for pulse_line in rope_pulse_lines:
		pulse_line.visible = value

func apply_throw_visual_colors() -> void:
	aim_indicator.default_color = throw_aim_color
	for dash_line in aim_dash_lines:
		dash_line.default_color = throw_aim_color
	power_meter_bg.default_color = throw_power_meter_bg_color
	power_meter_fill.default_color = throw_power_meter_fill_color

func create_throw_aim_dashes() -> void:
	for dash_line in aim_dash_lines:
		if is_instance_valid(dash_line):
			dash_line.queue_free()

	aim_dash_lines.clear()
	for index in range(maxi(throw_aim_dash_count, 1)):
		var dash_line := Line2D.new()
		dash_line.name = "AimDash%s" % index
		dash_line.visible = false
		dash_line.z_index = aim_indicator.z_index
		dash_line.width = aim_indicator.width
		dash_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		dash_line.end_cap_mode = Line2D.LINE_CAP_ROUND
		add_child(dash_line)
		aim_dash_lines.append(dash_line)

func update_throw_visuals() -> void:
	apply_throw_visual_colors()
	var show_throw_visuals = throw_state in [ThrowState.THROW_READY, ThrowState.THROW_CHARGING]
	aim_indicator.visible = false
	set_throw_aim_dashes_visible(show_throw_visuals)
	power_meter_bg.visible = show_throw_visuals
	power_meter_fill.visible = show_throw_visuals

	if not show_throw_visuals:
		return

	throw_aim_blink_time += get_process_delta_time() * throw_aim_blink_speed
	var blink_alpha := 0.55 + sin(throw_aim_blink_time) * 0.25
	var start = get_throw_ready_anchor_position()
	var end = start + throw_aim_dir * throw_aim_preview_length
	update_throw_aim_dashes(start, end, blink_alpha)

	var bar_start = start + Vector2(-throw_power_meter_width * 0.5, -16.0)
	var bar_end = bar_start + Vector2(throw_power_meter_width, 0.0)
	power_meter_bg.clear_points()
	power_meter_bg.add_point(bar_start)
	power_meter_bg.add_point(bar_end)

	power_meter_fill.clear_points()
	power_meter_fill.add_point(bar_start)
	power_meter_fill.add_point(bar_start + Vector2(throw_power_meter_width * get_throw_charge_ratio(), 0.0))

func update_throw_aim_dashes(start: Vector2, end: Vector2, alpha: float) -> void:
	var aim_vector := end - start
	var aim_length := aim_vector.length()
	if aim_length <= 0.001:
		for dash_line in aim_dash_lines:
			dash_line.clear_points()
		return

	var direction := aim_vector / aim_length
	var dash_count: int = maxi(aim_dash_lines.size(), 1)
	var slot_length: float = aim_length / float(dash_count)
	var dash_length: float = slot_length * clampf(1.0 - throw_aim_dash_gap_ratio, 0.1, 0.95)

	for index in range(aim_dash_lines.size()):
		var progress: float = float(index) / maxf(float(aim_dash_lines.size() - 1), 1.0)
		var dash_start: Vector2 = start + direction * slot_length * float(index)
		var dash_end: Vector2 = dash_start + direction * dash_length
		var dash_color: Color = throw_aim_color.lerp(throw_aim_tip_dark_color, progress * 0.78)
		dash_color.a *= clampf(alpha * (1.0 - progress * 0.32), 0.0, 1.0)
		aim_dash_lines[index].width = lerpf(aim_indicator.width * 1.25, aim_indicator.width * 0.82, progress)
		aim_dash_lines[index].default_color = dash_color
		aim_dash_lines[index].clear_points()
		aim_dash_lines[index].add_point(dash_start)
		aim_dash_lines[index].add_point(dash_end)

func set_throw_aim_dashes_visible(value: bool) -> void:
	for dash_line in aim_dash_lines:
		dash_line.visible = value
