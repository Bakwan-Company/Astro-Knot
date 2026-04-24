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
	var c_ground = castor.get_node_or_null("GroundCheck")
	var p_ground = pollux.get_node_or_null("GroundCheck")
	
	var is_c_grounded = c_ground and c_ground.is_colliding()
	var is_p_grounded = p_ground and p_ground.is_colliding()
	
	if Input.is_action_pressed("reel_in"):
		# LOCK MEKANIK: DILARANG MANJAT
		# Jika Pollux di lantai DAN Castor melayang, tali tidak boleh memendek!
		if is_p_grounded and not is_c_grounded:
			pass # Abaikan input, tali terkunci mati.
		else:
			current_rope_length -= reel_speed * delta
			
	elif Input.is_action_pressed("reel_out"):
		current_rope_length += reel_speed * delta
		
	current_rope_length = clamp(current_rope_length, min_rope_length, max_rope_length)

func apply_solid_constraint(delta: float) -> void:
	var c_pos = castor.global_position
	var p_pos = pollux.global_position
	var dist = c_pos.distance_to(p_pos)
	
	if dist < 0.1: return
	
	var error = dist - current_rope_length
	
	if error < 0 and not Input.is_action_pressed("reel_out"):
		return 
	
	var dir = c_pos.direction_to(p_pos)
	
	# ==========================================
	# DETEKSI LANTAI DUAL SENSOR (POLLUX & CASTOR)
	# ==========================================
	var c_l = castor.get_node_or_null("GroundCheckL")
	var c_r = castor.get_node_or_null("GroundCheckR")
	var p_l = pollux.get_node_or_null("GroundCheckL")
	var p_r = pollux.get_node_or_null("GroundCheckR")
	
	var is_c_grounded = (c_l and c_l.is_colliding()) or (c_r and c_r.is_colliding())
	var is_p_grounded = (p_l and p_l.is_colliding()) or (p_r and p_r.is_colliding())
	
	# ==========================================
	# SISTEM JANGKAR DINAMIS (MUTUAL DRAG)
	# ==========================================
	var is_castor_anchored = false
	var is_pollux_anchored = false
	
	if is_c_grounded and is_p_grounded:
		# Jika dua-duanya di lantai, Castor jadi prioritas jangkar
		is_castor_anchored = true
	
	elif is_c_grounded and not is_p_grounded:
		# KASUS DI GAMBARMU: Castor di lantai, Pollux melayang.
		# Cek: Apakah Pollux berada DI BAWAH Castor? (Berayun)
		if p_pos.y > c_pos.y + 10: 
			is_castor_anchored = true # Castor jadi jangkar untuk ayunan
		else:
			# Jika Pollux melayang di samping (seperti di gambarmu), 
			# biarkan statusnya FALSE agar mereka masuk ke Skenario 3 (Saling Tarik).
			# Ini yang bakal bikin Castor keseret ke pinggir tebing.
			pass

	elif not is_c_grounded and is_p_grounded:
		# Sebaliknya, Pollux jadi jangkar kalau Castor yang berayun di bawah
		if c_pos.y > p_pos.y + 10:
			is_pollux_anchored = true
	# ==========================================
	# EKSEKUSI FISIKA BERDASARKAN STATUS JANGKAR
	# ==========================================
	if is_castor_anchored:
		# --- SKENARIO 1: CASTOR JANGKAR (Narik/Dorong Pollux) ---
		var pos_correction = clamp(error, -3.0, 3.0)
		var move_pollux = -(dir * pos_correction)
		
		# FIX DORONG KE ATAS: Pindahkan dorongan menjadi tolakan untuk Castor
		if is_pollux_anchored and move_pollux.y > 0:
			castor.global_position.y -= move_pollux.y
			move_pollux.y = 0 
			
		pollux.global_position += move_pollux
		
		var c_vel = castor.velocity
		var p_vel = pollux.linear_velocity
		var rel_vel = (p_vel - c_vel).dot(dir)
		var vel_lambda = dir * (-rel_vel)
		
		var apply_vel = vel_lambda
		
		# FIX MOMENTUM KE ATAS: Berikan velocity lompatan ke Castor
		if is_pollux_anchored and apply_vel.y > 0:
			castor.velocity.y -= apply_vel.y
			apply_vel.y = 0
			
		pollux.linear_velocity += apply_vel

	elif is_pollux_anchored:
		# --- SKENARIO 2: POLLUX JANGKAR (Castor Berayun Pendulum) ---
		var pos_correction = clamp(error, -5.0, 5.0) 
		castor.global_position += dir * pos_correction

		# Update ulang arah tali agar tidak nyangkut di titik terendah
		dir = castor.global_position.direction_to(pollux.global_position)

		# Fisika Pendulum Murni (Spider-Man Slide)
		var tangent = dir.orthogonal()
		var swing_speed = castor.velocity.dot(tangent)
		castor.velocity = tangent * swing_speed

		# Obat Energi Bocor (Momentum Boost)
		if abs(swing_speed) > 10.0:
			castor.velocity *= 1.00 
			
	else:
		# --- SKENARIO 3: DUA-DUANYA MELAYANG (Tarik-Menarik 50:50) ---
		var pos_correction = clamp(error, -3.0, 3.0)
		castor.global_position += dir * (pos_correction * 0.5)
		pollux.global_position -= dir * (pos_correction * 0.5)

		var c_vel = castor.velocity
		var p_vel = pollux.linear_velocity
		var rel_vel = (p_vel - c_vel).dot(dir)
		var vel_lambda = dir * (-rel_vel)

		castor.velocity -= vel_lambda * 0.5
		pollux.linear_velocity += vel_lambda * 0.5

func update_rope_visual() -> void:
	if castor and pollux and rope_visual:
		var c_anchor = castor.get_node_or_null("RopeAnchor")
		var p_anchor = pollux.get_node_or_null("RopeAnchor")
		rope_visual.clear_points()
		rope_visual.add_point(c_anchor.global_position if c_anchor else castor.global_position)
		rope_visual.add_point(p_anchor.global_position if p_anchor else pollux.global_position)
