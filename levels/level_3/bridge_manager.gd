extends Node2D

const METAL_SCREECH_SFX := preload("res://asset/Audio/metal_screech.mp3")

@export var slide_distance: float = 352.0 
@export var slide_duration: float = 2.4
@export var metal_screech_volume_db: float = -3.0
@export var metal_screech_fade_out_time: float = 0.35
@export var metal_screech_silent_volume_db: float = -45.0

@onready var left_bridge = $MaskingZone/LeftBridge
@onready var right_bridge = $MaskingZone/RightBridge

var left_formed_pos: Vector2
var right_formed_pos: Vector2
var left_hidden_pos: Vector2
var right_hidden_pos: Vector2
var active_tween: Tween
var metal_screech_player: AudioStreamPlayer
var metal_screech_fade_tween: Tween

func _ready() -> void:
	metal_screech_player = AudioStreamPlayer.new()
	metal_screech_player.name = "MetalScreechSfx"
	metal_screech_player.stream = METAL_SCREECH_SFX
	metal_screech_player.volume_db = metal_screech_volume_db
	add_child(metal_screech_player)

	left_formed_pos = left_bridge.global_position
	right_formed_pos = right_bridge.global_position
	
	left_hidden_pos = left_formed_pos + Vector2(-slide_distance, 0)
	right_hidden_pos = right_formed_pos + Vector2(slide_distance, 0)
	
	left_bridge.global_position = left_hidden_pos
	right_bridge.global_position = right_hidden_pos
	_set_bridge_collision(false)

func _on_terminal_activated(is_on: bool) -> void:
	if is_instance_valid(active_tween):
		active_tween.kill()

	_play_metal_screech()

	active_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	active_tween.finished.connect(func():
		_fade_out_metal_screech()
		active_tween = null
	)
	
	if is_on:
		# TERMINAL NYALA: Fisik ON duluan, baru jembatan muncul ke tengah
		_set_bridge_collision(true)
		active_tween.tween_property(left_bridge, "global_position", left_formed_pos, slide_duration)
		active_tween.tween_property(right_bridge, "global_position", right_formed_pos, slide_duration)
	else:
		# TERMINAL MATI: MATIIN FISIK SAAT INI JUGA!
		_set_bridge_collision(false)
		
		# Baru jembatannya ditarik ngumpet ke tembok (visual doang yang gerak)
		active_tween.tween_property(left_bridge, "global_position", left_hidden_pos, slide_duration)
		active_tween.tween_property(right_bridge, "global_position", right_hidden_pos, slide_duration)

func _set_bridge_collision(is_solid: bool) -> void:
	var layer_value = 1 if is_solid else 0
	if left_bridge and right_bridge:
		left_bridge.collision_layer = layer_value
		left_bridge.collision_mask = layer_value
		right_bridge.collision_layer = layer_value
		right_bridge.collision_mask = layer_value

func _play_metal_screech() -> void:
	if metal_screech_player == null:
		return

	if metal_screech_fade_tween != null:
		metal_screech_fade_tween.kill()

	metal_screech_player.stop()
	metal_screech_player.volume_db = metal_screech_volume_db
	metal_screech_player.play()

func _fade_out_metal_screech() -> void:
	if metal_screech_player == null or not metal_screech_player.playing:
		return

	if metal_screech_fade_tween != null:
		metal_screech_fade_tween.kill()

	metal_screech_fade_tween = create_tween()
	metal_screech_fade_tween.tween_property(
		metal_screech_player,
		"volume_db",
		metal_screech_silent_volume_db,
		metal_screech_fade_out_time
	)
	metal_screech_fade_tween.finished.connect(func() -> void:
		if metal_screech_player != null:
			metal_screech_player.stop()
			metal_screech_player.volume_db = metal_screech_volume_db
		metal_screech_fade_tween = null
	)
