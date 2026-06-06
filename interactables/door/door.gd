extends StaticBody2D

const HYDRAULIC_SFX := preload("res://asset/Audio/hydraulic.mp3")

@export var is_on: bool = true
@export var hydraulic_volume_db: float = -4.0
@export var hydraulic_fade_out_time: float = 0.2
@export var hydraulic_silent_volume_db: float = -45.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var hydraulic_player: AudioStreamPlayer2D
var hydraulic_fade_tween: Tween

func _ready() -> void:
	hydraulic_player = AudioStreamPlayer2D.new()
	hydraulic_player.name = "HydraulicSfx"
	hydraulic_player.stream = HYDRAULIC_SFX
	hydraulic_player.volume_db = hydraulic_volume_db
	add_child(hydraulic_player)

	if animated_sprite:
		animated_sprite.animation_finished.connect(_on_animation_finished)

	_apply_door_status(false)

func set_door_status(active: bool) -> void:
	if is_on == active:
		return

	is_on = active
	_apply_door_status(true)

func set_terminal_status(terminal_is_on: bool) -> void:
	set_door_status(not terminal_is_on)

func _apply_door_status(animate: bool) -> void:
	collision_shape.set_deferred("disabled", !is_on)
	if animate and hydraulic_player:
		_play_hydraulic_sfx()

	if not animated_sprite:
		return

	if is_on:
		if animate:
			animated_sprite.play("close")
		else:
			animated_sprite.play("closed")
	else:
		if animate:
			animated_sprite.play("open")
		else:
			animated_sprite.play("opened")

func _play_hydraulic_sfx() -> void:
	if hydraulic_player == null:
		return

	if hydraulic_fade_tween != null:
		hydraulic_fade_tween.kill()

	hydraulic_player.stop()
	hydraulic_player.volume_db = hydraulic_volume_db
	hydraulic_player.play()

func _fade_out_hydraulic_sfx() -> void:
	if hydraulic_player == null or not hydraulic_player.playing:
		return

	if hydraulic_fade_tween != null:
		hydraulic_fade_tween.kill()

	hydraulic_fade_tween = create_tween()
	hydraulic_fade_tween.tween_property(
		hydraulic_player,
		"volume_db",
		hydraulic_silent_volume_db,
		hydraulic_fade_out_time
	)
	hydraulic_fade_tween.finished.connect(func() -> void:
		if hydraulic_player != null:
			hydraulic_player.stop()
			hydraulic_player.volume_db = hydraulic_volume_db
		hydraulic_fade_tween = null
	)

func _on_animation_finished() -> void:
	if animated_sprite.animation == &"open" or animated_sprite.animation == &"close":
		_fade_out_hydraulic_sfx()
