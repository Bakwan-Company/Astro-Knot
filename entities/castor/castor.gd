extends CharacterBody2D

@export var speed: float = 300.0 # Sedikit lebih cepat biar enak narik Pollux
@export var jump_velocity: float = -400.0
@export var air_friction: float = 0.5 # Gesekan udara biar ayunan gak abadi (tapi tipis banget)
@export var terminal_velocity: float = 1000.0 # Biar gak nembus lantai kalau jatuh kecepetan

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta: float) -> void:
	# 1. GRAVITASI
	if not is_on_floor():
		# Kita pake gravitasi yang agak berat (1.2x) biar feel jatuh robotnya dapet
		velocity.y += gravity * 1 * delta
	
	# Cap kecepatan jatuh
	velocity.y = min(velocity.y, terminal_velocity)

	# 2. LOMPAT
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# 3. INPUT GERAK HORIZONTAL
	var direction = Input.get_axis("move_left", "move_right")
	
	if direction:
		velocity.x = direction * speed
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
