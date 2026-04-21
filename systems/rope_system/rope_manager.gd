extends Node2D

@export var castor: CharacterBody2D
@export var pollux: RigidBody2D

@onready var rope_visual: Line2D = $HardlightVisual

@export var current_rope_length: float = 200.0
@export var max_rope_length: float = 400.0
@export var min_rope_length: float = 50.0
@export var reel_speed: float = 150.0
@export var rope_stiffness: float = 15.0

func _process(_delta: float) -> void:
	update_rope_visual()

func _physics_process(delta: float) -> void:
	if not castor or not pollux:
		return
		
	handle_reel_input(delta)
	apply_rope_physics()

func handle_reel_input(delta: float) -> void:
	# Tombol Q untuk narik, E untuk ulur
	if Input.is_action_pressed("reel_in"):
		current_rope_length = max(min_rope_length, current_rope_length - reel_speed * delta)
	elif Input.is_action_pressed("reel_out"):
		current_rope_length = min(max_rope_length, current_rope_length + reel_speed * delta)

func apply_rope_physics() -> void:
	# Gunakan titik tengah badan (global_position utama) agar ayunan seimbang
	var distance = pollux.global_position.distance_to(castor.global_position)
	
	if distance > current_rope_length:
		var direction = pollux.global_position.direction_to(castor.global_position)
		var stretch = distance - current_rope_length
		
		var pull_force = direction * stretch * rope_stiffness
		pollux.apply_central_force(pull_force)

func update_rope_visual() -> void:
	if castor and pollux and rope_visual:
		# Cari Marker2D bernama "RopeAnchor" di dalam robot
		var c_anchor = castor.get_node_or_null("RopeAnchor")
		var p_anchor = pollux.get_node_or_null("RopeAnchor")
		
		# Jika Marker2D ketemu, pakai titik itu. Jika tidak, pakai titik tengah (fallback)
		var draw_pos_castor = c_anchor.global_position if c_anchor else castor.global_position
		var draw_pos_pollux = p_anchor.global_position if p_anchor else pollux.global_position
		
		rope_visual.clear_points()
		rope_visual.add_point(draw_pos_castor)
		rope_visual.add_point(draw_pos_pollux)
