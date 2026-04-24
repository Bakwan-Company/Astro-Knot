extends Node2D

@export var castor: CharacterBody2D
@export var pollux: RigidBody2D
@onready var rope_visual: Line2D = $HardlightVisual

@export var current_rope_length: float = 200.0
@export var reel_speed: float = 250.0
@export var min_rope_length: float = 60.0 
@export var max_rope_length: float = 500.0

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

func apply_solid_constraint(_delta: float) -> void:
	var c_pos = castor.global_position
	var p_pos = pollux.global_position
	var dist = c_pos.distance_to(p_pos)
	
	if dist < 0.1: return
	
	var error = dist - current_rope_length
	
	# ==========================================
	# MEKANIK HYBRID: TALI KENDOR vs PISTON
	# Jika jarak robot merapat (error negatif), tali seharusnya kendor.
	# Kita matikan fisika dorongan, KECUALI pemain sengaja menekan tombol dorong (reel_out).
	# ==========================================
	if error < 0 and not Input.is_action_pressed("reel_out"):
		return # Berhenti di sini. Castor bebas bergerak mendekat, Pollux diam.
	
	var dir = c_pos.direction_to(p_pos)
	var is_reeling_in = Input.is_action_pressed("reel_in")
	var is_castor_anchored = castor.is_on_floor() or is_reeling_in or Input.is_action_pressed("reel_out")
	
	var pollux_ground_check = pollux.get_node_or_null("GroundCheck")
	var is_pollux_anchored = false
	if pollux_ground_check and pollux_ground_check.is_colliding():
		is_pollux_anchored = true

	var pos_correction = clamp(error, -3.0, 3.0)
	
	# ==========================================
	# TAHAP 1: KOREKSI POSISI
	# ==========================================
	if is_castor_anchored:
		var move_pollux = -(dir * pos_correction)
		if is_pollux_anchored and move_pollux.y > 0:
			move_pollux.y = 0
		pollux.global_position += move_pollux
	elif is_pollux_anchored:
		castor.global_position += dir * pos_correction
	else:
		castor.global_position += dir * (pos_correction * 0.5)
		pollux.global_position -= dir * (pos_correction * 0.5)

	c_pos = castor.global_position
	p_pos = pollux.global_position
	dir = c_pos.direction_to(p_pos)

	var c_vel = castor.velocity
	var p_vel = pollux.linear_velocity
	var rel_vel = (p_vel - c_vel).dot(dir)
	var vel_lambda = dir * (-rel_vel)
	
	# ==========================================
	# TAHAP 2: KOREKSI KECEPATAN
	# ==========================================
	if is_castor_anchored:
		var apply_vel = vel_lambda
		if is_pollux_anchored and apply_vel.y > 0:
			apply_vel.y = 0
		pollux.linear_velocity += apply_vel
	elif is_pollux_anchored:
		castor.velocity -= vel_lambda
	else:
		castor.velocity -= vel_lambda * 0.5
		pollux.linear_velocity += vel_lambda * 0.5

func update_rope_visual() -> void:
	if castor and pollux and rope_visual:
		var c_anchor = castor.get_node_or_null("RopeAnchor")
		var p_anchor = pollux.get_node_or_null("RopeAnchor")
		rope_visual.clear_points()
		rope_visual.add_point(c_anchor.global_position if c_anchor else castor.global_position)
		rope_visual.add_point(p_anchor.global_position if p_anchor else pollux.global_position)
