extends Area2D

const LASER_SFX := preload("res://asset/Audio/laser.mp3")

@onready var anim_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D

@export var death_type: String = "laser"
@export var laser_volume_db: float = -8.0
@export var laser_fade_out_time: float = 0.25
@export var laser_silent_volume_db: float = -45.0

var is_laser_active: bool = true 
var _is_triggered: bool = false
var laser_player: AudioStreamPlayer2D
var laser_fade_tween: Tween

func _ready():
	laser_player = AudioStreamPlayer2D.new()
	laser_player.name = "LaserSfx"
	laser_player.stream = LASER_SFX
	laser_player.volume_db = laser_volume_db
	add_child(laser_player)
	_configure_laser_loop()

	body_entered.connect(_on_body_entered)
	anim_sprite.play("idle")
	_update_laser_audio()

func _on_body_entered(body: Node2D):
	if _is_triggered or not is_laser_active:
		return
		
	if body.name == "Castor" or body.name == "Pollux":
		_is_triggered = true
		var checkpoint_manager := get_node_or_null("/root/CheckpointManager")
		if checkpoint_manager != null and checkpoint_manager.has_method("kill"):
			checkpoint_manager.call("kill", death_type)
		else:
			get_tree().reload_current_scene()

func reset() -> void:
	_is_triggered = false

func _on_button_toggled(is_on: bool) -> void:
	if is_on:
		is_laser_active = false
		collision_shape.set_deferred("disabled", true)
		anim_sprite.play("turn_off")

	else:
		is_laser_active = true
		collision_shape.set_deferred("disabled", false)
		
		anim_sprite.play("idle")
	_update_laser_audio()

func _configure_laser_loop() -> void:
	var mp3_stream := LASER_SFX as AudioStreamMP3
	if mp3_stream:
		mp3_stream.loop = true

func _update_laser_audio() -> void:
	if laser_player == null:
		return

	if is_laser_active:
		if laser_fade_tween != null:
			laser_fade_tween.kill()
		laser_player.volume_db = laser_volume_db
		if not laser_player.playing:
			laser_player.play()
	else:
		_fade_out_laser_audio()

func _fade_out_laser_audio() -> void:
	if laser_player == null or not laser_player.playing:
		return

	if laser_fade_tween != null:
		laser_fade_tween.kill()

	laser_fade_tween = create_tween()
	laser_fade_tween.tween_property(
		laser_player,
		"volume_db",
		laser_silent_volume_db,
		laser_fade_out_time
	)
	laser_fade_tween.finished.connect(func() -> void:
		if laser_player != null and not is_laser_active:
			laser_player.stop()
			laser_player.volume_db = laser_volume_db
		laser_fade_tween = null
	)
