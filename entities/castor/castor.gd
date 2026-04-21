extends CharacterBody2D

# Variabel yang bisa diatur dari Inspector
@export var speed: float = 200.0
@export var jump_velocity: float = -400.0

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta: float) -> void:
	# Terapkan Gravitasi saat Castor tidak menginjak lantai
	if not is_on_floor():
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	var direction = Input.get_axis("move_left", "move_right")
	
	if direction:
		velocity.x = direction * speed
	else:
		# move_toward memberikan efek deselerasi agar berhentinya tidak kaku
		velocity.x = move_toward(velocity.x, 0, speed)

	move_and_slide()
