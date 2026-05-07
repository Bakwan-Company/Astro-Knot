extends Node2D

@export var castor: CharacterBody2D
@export var pollux: RigidBody2D
@onready var rope_visual: Line2D = $HardlightVisual

# Base rope tuning
@export var current_rope_length: float = 200.0
@export var reel_speed: float = 250.0
@export var min_rope_length: float = 60.0
@export var max_rope_length: float = 500.0

# Pollux ledge-pull assist
@export var ledge_pull_up_velocity: float = 220.0
@export var ledge_pull_position_speed: float = 70.0
@export var ledge_pull_min_vertical_gap: float = 24.0
@export var ledge_pull_slack_tolerance: float = 10.0

# Fallback when Pollux is blocked by geometry and the rope keeps stretching
@export var blocked_rope_error_threshold: float = 12.0
@export var blocked_castor_pull_factor: float = 0.35
@export var blocked_castor_pull_max: float = 6.0

func is_body_grounded(body: Node) -> bool:
	if not body:
		return false

	var ground_left = body.get_node_or_null("GroundCheckL")
	var ground_right = body.get_node_or_null("GroundCheckR")
	return (ground_left and ground_left.is_colliding()) or (ground_right and ground_right.is_colliding())

func is_pollux_side_blocked() -> bool:
	var wall_left = pollux.get_node_or_null("WallCheckL") as RayCast2D
	var wall_right = pollux.get_node_or_null("WallCheckR") as RayCast2D
	return (wall_left and wall_left.is_colliding()) or (wall_right and wall_right.is_colliding())

func apply_pollux_ledge_pull(delta: float, error: float, is_p_grounded: bool) -> bool:
	# Small assist for the specific case where Pollux is airborne, side-blocked,
	# and the player is still reeling the rope inward.
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
		if c_pos.y < p_pos.y - 15 and abs(c_pos.x - p_pos.x) < 40:
			flags.is_pollux_anchored = true

	elif is_c_grounded and not is_p_grounded:
		# Castor can anchor Pollux when Pollux is hanging below it.
		if p_pos.y > c_pos.y + 10:
			flags.is_castor_anchored = true

	elif not is_c_grounded and is_p_grounded:
		# Pollux becomes the anchor when Castor is hanging below it,
		# or when Castor is directly above it in a narrow X band.
		if c_pos.y > p_pos.y + 10:
			flags.is_pollux_anchored = true
		elif c_pos.y < p_pos.y - 10 and abs(c_pos.x - p_pos.x) < 40:
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

func apply_castor_anchor_constraint(dir: Vector2, error: float, is_pollux_anchored: bool, delta: float) -> void:
	# error > 0 means the rope is longer than allowed, so we must correct it.
	# In this branch, Castor is the anchor and Pollux is the body we try to drag.
	var pos_correction = clamp(error, -3.0, 3.0)
	var move_pollux = -(dir * pos_correction)

	if is_pollux_anchored and move_pollux.y > 0:
		# In lift mode we suppress Pollux's X/Y drift and instead push Castor upward
		# a bit to sell the idea that Pollux is helping lift Castor.
		castor.global_position.y -= move_pollux.y * 1.5
		move_pollux.y = 0
		move_pollux.x = 0

	pollux.global_position += move_pollux
	apply_blocked_pollux_fallback(dir, error, delta)

	var c_vel = castor.velocity
	var p_vel = pollux.linear_velocity
	var rel_vel = (p_vel - c_vel).dot(dir)
	var vel_lambda = dir * (-rel_vel)

	var apply_vel = vel_lambda
	if is_pollux_anchored and apply_vel.y > 0:
		castor.velocity.y -= apply_vel.y * 2.0
		apply_vel.y = 0
		apply_vel.x = 0

	pollux.linear_velocity += apply_vel

func apply_pollux_anchor_constraint(dir: Vector2, error: float) -> void:
	# Pollux anchored means Castor becomes the pendulum body.
	var pos_correction = clamp(error, -5.0, 5.0)
	castor.global_position += dir * pos_correction

	# Recompute the rope direction after the position correction.
	dir = castor.global_position.direction_to(pollux.global_position)
	var tangent = dir.orthogonal()
	var swing_speed = castor.velocity.dot(tangent)
	castor.velocity = tangent * swing_speed

func apply_free_constraint(dir: Vector2, error: float) -> void:
	# Both bodies are effectively free, so share the correction 50:50.
	var pos_correction = clamp(error, -3.0, 3.0)
	castor.global_position += dir * (pos_correction * 0.5)
	pollux.global_position -= dir * (pos_correction * 0.5)

	var c_vel = castor.velocity
	var p_vel = pollux.linear_velocity
	var rel_vel = (p_vel - c_vel).dot(dir)
	var vel_lambda = dir * (-rel_vel)

	castor.velocity -= vel_lambda * 0.5
	pollux.linear_velocity += vel_lambda * 0.5

func _process(_delta: float) -> void:
	update_rope_visual()

func _physics_process(delta: float) -> void:
	if not castor or not pollux:
		return

	handle_reel_input(delta)
	apply_solid_constraint(delta)

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

	if dist < 0.1:
		return

	# error > 0: rope is overstretched and must be corrected
	# error < 0: rope is slack, so we usually let it be
	var error = dist - current_rope_length
	if error < 0 and not Input.is_action_pressed("reel_out"):
		return

	var dir = c_pos.direction_to(p_pos)
	var is_c_grounded = is_body_grounded(castor)
	var is_p_grounded = is_body_grounded(pollux)
	var is_ledge_pulling = apply_pollux_ledge_pull(delta, error, is_p_grounded)
	var anchor_flags = get_anchor_flags(c_pos, p_pos, is_c_grounded, is_p_grounded)

	if is_ledge_pulling:
		pollux.linear_velocity.x *= 0.9

	if anchor_flags.is_castor_anchored:
		apply_castor_anchor_constraint(dir, error, anchor_flags.is_pollux_anchored, delta)
	elif anchor_flags.is_pollux_anchored:
		apply_pollux_anchor_constraint(dir, error)
	else:
		apply_free_constraint(dir, error)

func update_rope_visual() -> void:
	if castor and pollux and rope_visual:
		var c_anchor = castor.get_node_or_null("RopeAnchor")
		var p_anchor = pollux.get_node_or_null("RopeAnchor")
		rope_visual.clear_points()
		rope_visual.add_point(c_anchor.global_position if c_anchor else castor.global_position)
		rope_visual.add_point(p_anchor.global_position if p_anchor else pollux.global_position)
