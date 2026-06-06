extends RefCounted

const POLLUX_INTERACT_SFX := preload("res://asset/Audio/pollux_interact.wav")

static func play_at(parent: Node, global_position: Vector2, volume_db: float = -4.0) -> void:
	if parent == null:
		return

	var player := AudioStreamPlayer2D.new()
	player.name = "PolluxInteractSfx"
	player.stream = POLLUX_INTERACT_SFX
	player.volume_db = volume_db
	parent.add_child(player)
	player.global_position = global_position
	player.finished.connect(player.queue_free)
	player.play()
