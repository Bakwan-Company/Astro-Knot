extends AnimatableBody2D

const METAL_SCREECH_SFX := preload("res://asset/Audio/metal_screech.mp3")

@export var retract_offset: Vector2 = Vector2(0, 150) 
@export var retract_duration: float = 5.0 # Waktu nariknya (1 detik)
@export var metal_screech_volume_db: float = -3.0
@export var metal_screech_fade_out_time: float = 0.35
@export var metal_screech_silent_volume_db: float = -45.0

@onready var start_position: Vector2 = global_position

var metal_screech_player: AudioStreamPlayer
var metal_screech_fade_tween: Tween

func _ready() -> void:
	metal_screech_player = AudioStreamPlayer.new()
	metal_screech_player.name = "MetalScreechSfx"
	metal_screech_player.stream = METAL_SCREECH_SFX
	metal_screech_player.volume_db = metal_screech_volume_db
	add_child(metal_screech_player)

# Fungsi yang bakal nerima teriakan sinyal dari Terminal
func _on_terminal_activated(is_on: bool) -> void:
	# Bikin animasi pergerakan (Tween) biar gesernya mulus
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_play_metal_screech()
	tween.finished.connect(func() -> void:
		_fade_out_metal_screech()
	)
	
	if is_on:
		# Pas terminal ON: Jembatan digeser sejauh nilai retract_offset
		tween.tween_property(self, "global_position", start_position + retract_offset, retract_duration)
	else:
		# Pas terminal OFF: Jembatan balik ke posisi semula
		tween.tween_property(self, "global_position", start_position, retract_duration)

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
